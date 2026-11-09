#!/usr/bin/env bash
#
# PreToolUse hook for Docker command safety checks.
# Asks before destructive commands, privileged containers, and stop/restart/pause.
#
# Matching is token-based, not a loose regex over the whole command line:
#   0. Text that is data, not shell, is dropped first: heredoc bodies (unless
#      the heredoc feeds a shell such as `bash <<EOF` or `| sh`), and the
#      quoted code passed to a non-shell interpreter (`python -c "..."`,
#      `node -e '...'`). Writing a file or test fixture that merely mentions
#      `docker rm` therefore never prompts.
#   1. The command is split into simple-command segments on ; & | ( ) ` and
#      newlines, so `docker logs x | tail; rm -f out` never ties the trailing
#      `rm` to docker.
#   2. Quotes are stripped, so `sh -c "docker rm x"` is still inspected.
#   3. In each segment, every `docker` / `docker-compose` token starts a parse:
#      global options (with their values) are skipped, management groups
#      (container, image, compose, ...) are stepped over, and only the
#      resulting subcommand is classified. `docker run --rm img` is therefore
#      a `run`, not an `rm`, and `docker exec c rm /tmp/f` is an `exec`.
#   4. run/create/exec flags are read only up to the image / container /
#      service name; what follows is the container's own command line, so
#      `docker exec app pytest -v` is not a volume mount.
#
# Like any static check over command text, this can be routed around with
# eval-built strings, aliases, or scripts. It is a guard against accidents,
# not a security boundary.
#
# Note: Using 'set -uo pipefail' (not -e) to allow graceful handling of jq failures
# If jq fails on malformed JSON, we exit 0 (allow) per fail-open security model
set -uo pipefail

# Validate jq is available
if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required but not installed" >&2
    exit 0
fi

# Read JSON from stdin with size limit (1MB max to prevent DoS)
INPUT=$(head -c 1048576)

# Extract command using jq (fail-open: allow command if jq fails)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null) || {
    # jq failed (malformed JSON) - allow command per fail-open security model
    exit 0
}

# Exit early if no command
[ -z "$COMMAND" ] && exit 0

# Working directory the command will run in (for relative mount sources)
HOOK_CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null) || HOOK_CWD=""
[ -n "$HOOK_CWD" ] || HOOK_CWD="$PWD"

# Fast path: nothing docker-related at all (ignoring quotes/backslashes,
# so d\ocker and d"o"cker still get parsed)
printf '%s' "$COMMAND" | tr -d "\\\\\"'" | grep -qi 'docker' || exit 0

# Lowercase without bash-4 ${var,,} (macOS ships bash 3.2). Forks, so it is
# only used on a handful of values; whole segments are lowercased in one pass.
lc() { printf '%s' "$1" | LC_ALL=C tr '[:upper:]' '[:lower:]'; }

# Drop heredoc bodies that are data. A body is kept when the line that opens
# it runs a shell (bash <<EOF, cat <<EOF | sh, ssh host <<EOF), and, for an
# unquoted delimiter, any body line containing $( or a backtick is kept
# because the shell expands it. `<<` inside quotes and `<<<` are ignored.
# POSIX awk only (macOS ships BWK awk).
strip_heredocs() {
    awk '
    function runs_shell(l,   s, n, i, a, w) {
        s = l; gsub(/[;&|()]/, " ", s); n = split(s, a, /[ \t]+/)
        for (i = 1; i <= n; i++) {
            w = a[i]; gsub(/["\047]/, "", w); sub(/^.*\//, "", w); w = tolower(w)
            if (w ~ /^(sh|bash|zsh|dash|ksh|ash|ssh|eval|source|su)$/) return 1
        }
        return 0
    }
    # Queue the delimiters of every unquoted << on line l.
    function scan(l,   n, i, c, q, rest, d, w, quoted, k) {
        k = runs_shell(l); n = length(l); q = ""
        for (i = 1; i <= n; i++) {
            c = substr(l, i, 1)
            if (q != "") { if (c == "\\" && q == "\"") i++; else if (c == q) q = ""; continue }
            if (c == "\\") { i++; continue }
            if (c == "\"" || c == "\047") { q = c; continue }
            if (substr(l, i, 2) != "<<") continue
            if (substr(l, i + 2, 1) == "<") { i += 2; continue }
            rest = substr(l, i + 2); d = 0
            if (substr(rest, 1, 1) == "-") { d = 1; rest = substr(rest, 2) }
            sub(/^[ \t]*/, "", rest)
            if (!match(rest, /^["\047\\]?[A-Za-z_][A-Za-z0-9_]*/)) continue
            w = substr(rest, 1, RLENGTH); quoted = (w ~ /^["\047\\]/)
            gsub(/["\047\\]/, "", w)
            nq++; delim[nq] = w; dash[nq] = d; keep[nq] = k; quo[nq] = quoted
            i += 1 + RLENGTH
        }
    }
    BEGIN { nq = 0; qi = 1 }
    {
        if (qi <= nq) {
            t = $0; if (dash[qi]) sub(/^\t+/, "", t)
            if (t == delim[qi]) {
                print; qi++
                if (qi > nq) { nq = 0; qi = 1 }
            } else if (keep[qi] || (!quo[qi] && ($0 ~ /\$\(/ || index($0, "`")))) {
                print
            }
            next
        }
        print; scan($0)
    }'
}

# Replace the quoted code argument of a non-shell interpreter
# (python -c "...", node -e '...', perl -e, ruby -e, php -r) with "". Shell
# `-c` strings (sh -c "docker rm x") are kept and still inspected.
strip_interp_code() {
    awk '
    function isinterp(w) {
        gsub(/["\047]/, "", w); sub(/^.*\//, "", w); w = tolower(w)
        return w ~ /^(python[0-9.]*|pypy[0-9.]*|node|nodejs|deno|bun|perl|ruby|php|lua|rscript|osascript)$/
    }
    function flush() { if (word != "") { if (isinterp(word)) seen = 1; last = word; word = "" } }
    { buf = buf $0 "\n" }
    END {
        n = length(buf); q = ""; seen = 0; last = ""; word = ""
        for (i = 1; i <= n; i++) {
            c = substr(buf, i, 1)
            if (q != "") {
                if (q == "\"" && c == "\\") { printf "%s", substr(buf, i, 2); word = word "xx"; i++; continue }
                if (c == q) q = ""
                printf "%s", c; word = word c; continue
            }
            if (c == "\\") { printf "%s", substr(buf, i, 2); word = word "xx"; i++; continue }
            if ((c == "\"" || c == "\047") && word == "" && seen && last ~ /^(-c|-e|-E|-r|--eval|--command|-[lnpa]+e)$/) {
                for (j = i + 1; j <= n; j++) {
                    d = substr(buf, j, 1)
                    if (c == "\"" && d == "\\") { j++; continue }
                    if (d == c) break
                }
                printf "\"\""; word = "code"; i = j; continue
            }
            if (c == "\"" || c == "\047") { q = c; printf "%s", c; word = word c; continue }
            if (c == " " || c == "\t") { flush(); printf "%s", c; continue }
            if (c == ";" || c == "&" || c == "|" || c == "(" || c == ")" || c == "\n") {
                flush(); seen = 0; last = ""; printf "%s", c; continue
            }
            printf "%s", c; word = word c
        }
    }'
}

emit_ask() {
    jq -n --arg reason "$1" '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "ask",
        permissionDecisionReason: $reason
      }
    }'
}

# docker global options that consume the next token as their value
# (names are lowercased before matching, so -H arrives as -h)
is_global_value_opt() {
    case "$1" in
        -c|--context|-h|--host|--config|-l|--log-level|--tlscacert|--tlscert|--tlskey) return 0 ;;
    esac
    return 1
}

# docker compose options that consume the next token as their value
is_compose_value_opt() {
    case "$1" in
        -f|--file|-p|--project-name|--project-directory|--env-file|--profile|--ansi|--parallel|--progress) return 0 ;;
    esac
    return 1
}

is_mgmt_group() {
    case "$1" in
        container|image|system|volume|network|builder|buildx|context|plugin|swarm|node|service|stack|secret|config|manifest|trust|checkpoint) return 0 ;;
    esac
    return 1
}

# Lexically normalize a path (collapse //, resolve . and ..) so `//`, `/.`,
# `/x/..` all compare equal to `/`. Falls back to the raw value without realpath.
norm_path() {
    case "$1" in /*) realpath -m -s -- "$1" 2>/dev/null || printf '%s\n' "$1" ;; *) printf '%s\n' "$1" ;; esac
}

# Resolve symlinks too (e.g. a link pointing at /). Empty if unavailable.
resolved_path() {
    case "$1" in /*) realpath -m -- "$1" 2>/dev/null ;; esac
}

# A host path whose bind mount grants host-level access: the root itself or a
# root alias (/proc/<pid>/root), or system dirs: /etc /root /proc /sys /dev
# /boot /run /var/run, or the /home parent itself. Ordinary project dirs under
# /home/<user>/... are fine.
is_sensitive_path() {
    case "$1" in
        /|/home) return 0 ;;
        /etc|/etc/*|/root|/root/*|/proc|/proc/*|/sys|/sys/*|/dev|/dev/*|/boot|/boot/*) return 0 ;;
        /run|/run/*|/var/run|/var/run/*) return 0 ;;
    esac
    return 1
}

# Turn a mount source into an absolute host path where we can know it:
#   ~, $HOME, ${HOME}, $PWD, ${PWD} expand; ./x, ../x, x/y resolve against the
#   command's cwd. Prints nothing for a named volume (no slash, no leading dot).
# Returns 1 when the source can't be known statically (other $VARs, backticks,
# or empty, which is what a split-off $(...) leaves behind), so it prompts.
expand_src() {
    local src="$1"
    # Glob/brace characters: the shell may rewrite the path, so ask.
    # Only the braces of a leading ${HOME}/${PWD} are exempt; check the rest.
    local rest="${src#\$\{HOME\}}"; rest="${rest#\$\{PWD\}}"
    case "$rest" in *'*'*|*'?'*|*'['*|*'{'*) return 1 ;; esac
    # Relative and variable sources are only trusted when nothing earlier in
    # the command line (cd, export, VAR=...) could have changed cwd/HOME/PWD.
    if [ "$CTX_UNTRUSTED" = "1" ]; then
        case "$src" in /*) ;; *) case "$src" in *[/.~'$']*) return 1 ;; esac ;; esac
    fi
    # Expand only exact names: $HOME, $HOME/..., never $HOMEX or ~user.
    case "$src" in
        "~"|"~/"*) src="$HOME${src#\~}" ;;
        "~"*) return 1 ;;
        '${HOME}'|'${HOME}/'*) src="$HOME${src#\$\{HOME\}}" ;;
        '$HOME'|'$HOME/'*) src="$HOME${src#\$HOME}" ;;
        '${PWD}'|'${PWD}/'*) src="$HOOK_CWD${src#\$\{PWD\}}" ;;
        '$PWD'|'$PWD/'*) src="$HOOK_CWD${src#\$PWD}" ;;
    esac
    case "$src" in ""|*'$'*|*'`'*) return 1 ;; esac
    case "$src" in
        /*) printf '%s\n' "$src" ;;
        .*|*/*) printf '%s\n' "$HOOK_CWD/$src" ;;
        *) ;;  # named volume
    esac
    return 0
}

# Check both the lexical form (//, /x/.., /.) and the symlink-resolved form.
# Sources that can't be resolved statically count as sensitive.
is_sensitive_src() {
    local path lex res
    path=$(expand_src "$1") || return 0
    [ -n "$path" ] || return 1
    lex=$(norm_path "$path"); is_sensitive_path "$lex" && return 0
    res=$(resolved_path "$path"); [ -n "$res" ] && is_sensitive_path "$res" && return 0
    case "$(lc "${res:-$lex}")" in *docker.sock) return 0 ;; esac
    return 1
}

# Mount source (text before the first ':' of a -v/--volume value) that grants
# host-level access, or anything mounting the docker socket.
is_dangerous_volume() {
    case "$(lc "$1")" in *docker.sock*) return 0 ;; esac
    is_sensitive_src "${1%%:*}"
}

# --mount value: type=bind,src=/,dst=/h  or anything mounting docker.sock
is_dangerous_mount() {
    local field
    case "$(lc "$1")" in *docker.sock*) return 0 ;; esac
    local IFS=,
    for field in $1; do
        case "$(lc "$field")" in
            src=*|source=*)
                is_sensitive_src "${field#*=}" && return 0 ;;
        esac
    done
    return 1
}

# Long run/create/exec (and compose run) flags that take no value. Any other
# long flag without `=` is assumed to consume the next token, so an unknown
# flag can only make the scan go further (toward a prompt), never stop early.
is_bool_long() {
    case "$1" in
        --rm|--init|--privileged|--read-only|--interactive|--tty|--detach|--publish-all|--sig-proxy|--no-healthcheck|--oom-kill-disable|--disable-content-trust|--quiet|--help|--no-deps|--service-ports|--use-aliases|--build|--remove-orphans|--quiet-pull|--quiet-build|--no-tty) return 0 ;;
    esac
    return 1
}

# Short-flag cluster (original case: -P is boolean, -p takes a value).
# Returns 0 when the cluster's value is the NEXT token (-v, -itv, -e), 1 when
# it is all booleans (-it, -dP) or the value is attached (-p8080:80, -v/:/h).
short_takes_next() {
    local s="${1#-}" c
    while [ -n "$s" ]; do
        c="${s:0:1}"; s="${s:1}"
        case "$c" in
            d|i|t|P|q|T) ;;
            *) [ -z "$s" ] && return 0; return 1 ;;
        esac
    done
    return 1
}

# Privileged / host-namespace flags among the options of a run/create/exec,
# starting at index $1 of the global toks/ltoks arrays. Stops at the first
# positional (image, container or service): everything after it is the
# container's own command line. Returns 0 if any dangerous flag is present.
has_privileged_flags() {
    local i="$1" n=${#toks[@]} tok ltok next lnext
    while ((i < n)); do
        tok="${toks[i]}"; ltok="${ltoks[i]}"
        next="${toks[i+1]:-}"; lnext="${ltoks[i+1]:-}"
        case "$tok" in
            --) return 1 ;;
            -?*) ;;
            *) return 1 ;;
        esac
        case "$ltok" in
            --privileged=false|--privileged=0) ;;
            --privileged*) return 0 ;;
            --cap-add=all|--cap-add=sys_admin) return 0 ;;
            --cap-add) case "$lnext" in all|sys_admin) return 0 ;; esac ;;
            --security-opt=*unconfined*) return 0 ;;
            --security-opt) case "$lnext" in *unconfined*) return 0 ;; esac ;;
            --net=host|--network=host|--pid=host|--ipc=host|--uts=host|--userns=host) return 0 ;;
            --net|--network|--pid|--ipc|--uts|--userns) [ "$lnext" = "host" ] && return 0 ;;
            --device=/dev/*) return 0 ;;
            --device) case "$next" in /dev/*) return 0 ;; esac ;;
            -v=*|--volume=*) is_dangerous_volume "${tok#*=}" && return 0 ;;
            -v|--volume) is_dangerous_volume "$next" && return 0 ;;
            # Short-flag bundle containing v (-v/:/h, -itv /:/h, -itv/:/h):
            # getopt-style, everything after the first v is the value; if
            # nothing follows, the value is the next token. Long options (--*)
            # never match because the second char must be a letter.
            -v?*|-[a-z]*v*)
                local rest="${tok#-}"; rest="${rest#*v}"; rest="${rest#=}"
                if [ -n "$rest" ]; then
                    is_dangerous_volume "$rest" && return 0
                else
                    is_dangerous_volume "$next" && return 0
                fi
                ;;
            --mount=*) is_dangerous_mount "${tok#*=}" && return 0 ;;
            --mount) is_dangerous_mount "$next" && return 0 ;;
        esac
        # Step over this flag's value, if it takes the next token.
        case "$ltok" in
            --*=*) ;;
            --*) is_bool_long "$ltok" || ((i++)) ;;
            *) short_takes_next "$tok" && ((i++)) ;;
        esac
        ((i++))
    done
    return 1
}

DESTRUCTIVE=0
PRIVILEGED=0
DISRUPTIVE=0
# Set once an earlier segment (or an inline prefix) may have changed the
# cwd or HOME/PWD that relative and variable mount sources resolve against.
CTX_UNTRUSTED=0

# Classify one docker invocation in the current segment. $1=1 when the binary
# was docker-compose; $2 is the index of the first token after the binary in
# the global toks (original case) / ltoks (lowercased) arrays. Names
# (options, groups, subcommands) are compared in ltoks; values such as mount
# paths come from toks so symlinks and real paths resolve.
classify() {
    local compose="$1" i="$2"
    local -a l=("${ltoks[@]}")
    local n=${#toks[@]} group="" sub=""

    if [ "$compose" = "0" ]; then
        # Skip docker global options
        while ((i < n)); do
            case "${l[i]}" in
                -*=*) ((i++)) ;;
                -*) if is_global_value_opt "${l[i]}"; then ((i += 2)); else ((i++)); fi ;;
                *) break ;;
            esac
        done
        ((i < n)) || return 0
        if [ "${l[i]}" = "compose" ]; then
            compose=1; ((i++))
        elif is_mgmt_group "${l[i]}"; then
            group="${l[i]}"; ((i++))
        fi
    fi

    # Find the subcommand, skipping options of the group / compose
    while ((i < n)); do
        case "${l[i]}" in
            -*=*) ((i++)) ;;
            -*) if [ "$compose" = "1" ] && is_compose_value_opt "${l[i]}"; then ((i += 2)); else ((i++)); fi ;;
            *) sub="${l[i]}"; break ;;
        esac
    done
    [ -n "$sub" ] || return 0

    case "$sub" in
        rm|rmi|remove|kill|prune|down) DESTRUCTIVE=1 ;;
        stop|restart|pause) DISRUPTIVE=1 ;;
        run|create|exec)
            # `docker run`, `docker container run`, `docker compose run` ...
            if [ -z "$group" ] || [ "$group" = "container" ]; then
                has_privileged_flags $((i + 1)) && PRIVILEGED=1
            fi
            ;;
    esac
    return 0
}

# Join backslash-newline continuations and drop remaining backslash escapes
# (so `d\ocker r\m` and multi-line commands parse like the shell sees them),
# split into simple-command segments, strip quotes. Case is preserved here;
# names are lowercased where they are compared.
SHELL_TEXT=$(printf '%s\n' "$COMMAND" | strip_heredocs | strip_interp_code)

# Second fast path: docker was only mentioned in data (heredoc, python -c).
printf '%s' "$SHELL_TEXT" | tr -d "\\\\\"'" | grep -qi 'docker' || exit 0

SEGMENTS=$(printf '%s\n' "$SHELL_TEXT" \
    | sed -e ':a' -e 'N' -e '$!ba' -e 's/\\\n//g' \
    | tr -d '\\' \
    | tr -d "\"'" \
    | sed -e 's/\$(/$\n/g' -e 's/`/$\n/g' -e 's/[;&|()]/\n/g')
# Lowercased once (one process) instead of per token; same line/token layout.
SEGMENTS_LC=$(printf '%s\n' "$SEGMENTS" | LC_ALL=C tr '[:upper:]' '[:lower:]')

# Pass 1: taint. If anything anywhere on the command line could change cwd or
# HOME/PWD, relative and variable mount sources are untrusted. This is
# position-independent on purpose: inside a loop or function, a `cd` written
# after the docker call still runs before it on the next iteration. Tokens
# after a docker binary are its arguments (-e A=1), so scanning a segment
# stops there; an inline prefix like `HOME=/ docker ...` still counts.
while IFS= read -r seg; do
    [ -z "${seg// }" ] && continue
    read -ra toks <<< "$seg"
    for ((k = 0; k < ${#toks[@]}; k++)); do
        case "${toks[k]}" in
            docker|*/docker|docker-compose|*/docker-compose) break ;;
            cd|pushd|popd|export|set|unset|source|.|eval|env|declare|typeset|readonly|local|let|printf|read|mapfile|readarray|getopts|builtin|command|for|while|until|select|coproc|case|trap|alias|function|shopt|exec|*/env|*/cd|[a-z_]*=*) CTX_UNTRUSTED=1 ;;
        esac
    done
done <<< "$SEGMENTS_LC"

# Pass 2: classify every docker invocation. toks keeps the original case,
# ltoks the lowercased copy of the same segment.
while IFS= read -r seg && IFS= read -r lseg <&3; do
    [ -z "${seg// }" ] && continue
    read -ra toks <<< "$seg"
    read -ra ltoks <<< "$lseg"
    for ((k = 0; k < ${#toks[@]}; k++)); do
        case "${ltoks[k]}" in
            docker|*/docker) classify 0 $((k + 1)) ;;
            docker-compose|*/docker-compose) classify 1 $((k + 1)) ;;
        esac
    done
done <<< "$SEGMENTS" 3<<< "$SEGMENTS_LC"

if [ "$DESTRUCTIVE" = "1" ]; then
    emit_ask "Destructive Docker command detected (prune/rm/rmi/kill/compose down). These commands can cause data loss. Allow?"
elif [ "$PRIVILEGED" = "1" ]; then
    emit_ask "Privileged container or dangerous flag detected (--privileged, --cap-add=ALL, --pid=host, --net=host, root volume mount, etc.). This grants elevated access to the host system."
elif [ "$DISRUPTIVE" = "1" ]; then
    emit_ask "Docker stop/restart/pause command detected. This will disrupt running containers and may cause service interruption."
fi

# Allow all other commands
exit 0
