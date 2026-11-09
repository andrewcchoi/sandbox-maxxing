#!/usr/bin/env bash
#
# PreToolUse hook for Docker command safety checks.
# Asks before destructive commands, privileged containers, and stop/restart/pause.
#
# Matching is token-based, not a loose regex over the whole command line:
#   1. The command is split into simple-command segments on ; & | ( ) ` and
#      newlines, so `docker logs x | tail; rm -f out` never ties the trailing
#      `rm` to docker.
#   2. Quotes are stripped, so `sh -c "docker rm x"` is still inspected.
#   3. In each segment, every `docker` / `docker-compose` token starts a parse:
#      global options (with their values) are skipped, management groups
#      (container, image, compose, ...) are stepped over, and only the
#      resulting subcommand is classified. `docker run --rm img` is therefore
#      a `run`, not an `rm`, and `docker exec c rm /tmp/f` is an `exec`.
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

# Lowercase without bash-4 ${var,,} (macOS ships bash 3.2).
lc() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

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
    case "$src" in *'*'*|*'?'*|*'['*|*'{'*) case "$src" in '${HOME}'|'${HOME}/'*|'${PWD}'|'${PWD}/'*) ;; *) return 1 ;; esac ;; esac
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

# Privileged / host-namespace flags in the tokens after a run/create/exec.
# Prints nothing; returns 0 if any dangerous flag is present.
has_privileged_flags() {
    local -a t=("$@")
    local n=${#t[@]} i tok next lnext
    for ((i = 0; i < n; i++)); do
        tok="${t[i]}"
        next="${t[i+1]:-}"
        lnext=$(lc "$next")
        case "$(lc "$tok")" in
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
    done
    return 1
}

DESTRUCTIVE=0
PRIVILEGED=0
DISRUPTIVE=0
# Set once an earlier segment (or an inline prefix) may have changed the
# cwd or HOME/PWD that relative and variable mount sources resolve against.
CTX_UNTRUSTED=0

# Classify one docker invocation. Arguments: the tokens AFTER the docker
# (or docker-compose) binary token. $COMPOSE=1 when the binary was docker-compose.
classify() {
    local compose="$1"; shift
    local -a t=("$@")
    # Names (options, groups, subcommands) compare case-insensitively; values
    # such as mount paths keep their case so symlinks and real paths resolve.
    local -a l=()
    local x
    for x in ${t[@]+"${t[@]}"}; do l+=("$(lc "$x")"); done
    local n=${#t[@]} i=0 group="" sub=""

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
                has_privileged_flags "${t[@]:i+1}" && PRIVILEGED=1
            fi
            ;;
    esac
    return 0
}

# Join backslash-newline continuations and drop remaining backslash escapes
# (so `d\ocker r\m` and multi-line commands parse like the shell sees them),
# split into simple-command segments, strip quotes. Case is preserved here;
# names are lowercased where they are compared.
SEGMENTS=$(printf '%s\n' "$COMMAND" \
    | sed -e ':a' -e 'N' -e '$!ba' -e 's/\\\n//g' \
    | tr -d '\\' \
    | tr -d "\"'" \
    | sed -e 's/\$(/$\n/g' -e 's/`/$\n/g' -e 's/[;&|()]/\n/g')

while IFS= read -r seg; do
    [ -z "${seg// }" ] && continue
    read -ra toks <<< "$seg"
    for ((k = 0; k < ${#toks[@]}; k++)); do
        case "$(lc "${toks[k]}")" in
            docker|*/docker) classify 0 "${toks[@]:k+1}" ;;
            docker-compose|*/docker-compose) classify 1 "${toks[@]:k+1}" ;;
            # cwd/env changers and inline VAR=... prefixes taint what follows
            cd|pushd|popd|export|set|source|.|eval|env|declare|typeset|readonly|[a-z_]*=*) CTX_UNTRUSTED=1 ;;
        esac
    done
done <<< "$SEGMENTS"

if [ "$DESTRUCTIVE" = "1" ]; then
    emit_ask "Destructive Docker command detected (prune/rm/rmi/kill/compose down). These commands can cause data loss. Allow?"
elif [ "$PRIVILEGED" = "1" ]; then
    emit_ask "Privileged container or dangerous flag detected (--privileged, --cap-add=ALL, --pid=host, --net=host, root volume mount, etc.). This grants elevated access to the host system."
elif [ "$DISRUPTIVE" = "1" ]; then
    emit_ask "Docker stop/restart/pause command detected. This will disrupt running containers and may cause service interruption."
fi

# Allow all other commands
exit 0
