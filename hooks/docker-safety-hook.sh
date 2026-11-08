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

# Fast path: nothing docker-related at all
echo "$COMMAND" | grep -qi 'docker' || exit 0

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
# (tokens are lowercased before matching, so -H arrives as -h)
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

# Mount source (text before the first ':' of a -v/--volume value) that grants
# host-level access: the host root or the docker socket.
is_dangerous_volume() {
    local src="${1%%:*}"
    [ "$src" = "/" ] && return 0
    case "$1" in *docker.sock*) return 0 ;; esac
    return 1
}

# --mount value: type=bind,src=/,dst=/h  or anything mounting docker.sock
is_dangerous_mount() {
    echo "$1" | grep -qiE '(^|,)(src|source)=/(,|$)|docker\.sock'
}

# Privileged / host-namespace flags in the tokens after a run/create/exec.
# Prints nothing; returns 0 if any dangerous flag is present.
has_privileged_flags() {
    local -a t=("$@")
    local n=${#t[@]} i tok next
    for ((i = 0; i < n; i++)); do
        tok="${t[i]}"
        next="${t[i+1]:-}"
        case "$tok" in
            --privileged|--privileged=true) return 0 ;;
            --cap-add=all|--cap-add=sys_admin) return 0 ;;
            --cap-add) case "$next" in all|sys_admin) return 0 ;; esac ;;
            --security-opt=*unconfined*) return 0 ;;
            --security-opt) case "$next" in *unconfined*) return 0 ;; esac ;;
            --net=host|--network=host|--pid=host|--ipc=host|--uts=host|--userns=host) return 0 ;;
            --net|--network|--pid|--ipc|--uts|--userns) [ "$next" = "host" ] && return 0 ;;
            --device=/dev/*) return 0 ;;
            --device) case "$next" in /dev/*) return 0 ;; esac ;;
            -v=*|--volume=*) is_dangerous_volume "${tok#*=}" && return 0 ;;
            -v|--volume) is_dangerous_volume "$next" && return 0 ;;
            --mount=*) is_dangerous_mount "${tok#*=}" && return 0 ;;
            --mount) is_dangerous_mount "$next" && return 0 ;;
        esac
    done
    return 1
}

DESTRUCTIVE=0
PRIVILEGED=0
DISRUPTIVE=0

# Classify one docker invocation. Arguments: the tokens AFTER the docker
# (or docker-compose) binary token. $COMPOSE=1 when the binary was docker-compose.
classify() {
    local compose="$1"; shift
    local -a t=("$@")
    local n=${#t[@]} i=0 group="" sub=""

    if [ "$compose" = "0" ]; then
        # Skip docker global options
        while ((i < n)); do
            case "${t[i]}" in
                -*=*) ((i++)) ;;
                -*) if is_global_value_opt "${t[i]}"; then ((i += 2)); else ((i++)); fi ;;
                *) break ;;
            esac
        done
        ((i < n)) || return 0
        if [ "${t[i]}" = "compose" ]; then
            compose=1; ((i++))
        elif is_mgmt_group "${t[i]}"; then
            group="${t[i]}"; ((i++))
        fi
    fi

    # Find the subcommand, skipping options of the group / compose
    while ((i < n)); do
        case "${t[i]}" in
            -*=*) ((i++)) ;;
            -*) if [ "$compose" = "1" ] && is_compose_value_opt "${t[i]}"; then ((i += 2)); else ((i++)); fi ;;
            *) sub="${t[i]}"; break ;;
        esac
    done
    [ -n "$sub" ] || return 0

    case "$sub" in
        rm|rmi|kill|prune|down) DESTRUCTIVE=1 ;;
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

# Split into simple-command segments; strip quotes; lowercase for
# case-insensitive matching.
SEGMENTS=$(printf '%s\n' "$COMMAND" \
    | tr '[:upper:]' '[:lower:]' \
    | tr -d "\"'" \
    | sed -e 's/\$(/\n/g' -e 's/[;&|()`]/\n/g')

while IFS= read -r seg; do
    [ -z "${seg// }" ] && continue
    case "$seg" in *docker*) ;; *) continue ;; esac
    read -ra toks <<< "$seg"
    for ((k = 0; k < ${#toks[@]}; k++)); do
        case "${toks[k]}" in
            docker|*/docker) classify 0 "${toks[@]:k+1}" ;;
            docker-compose|*/docker-compose) classify 1 "${toks[@]:k+1}" ;;
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
