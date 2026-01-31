#!/usr/bin/env bash
#
# PreToolUse hook for Docker command safety checks.
# Blocks destructive commands, prompts for privileged containers.
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

# BLOCK patterns - destructive Docker commands (case-insensitive)
# Blocks: prune, rm (all forms), rmi (all forms), kill, compose down
# Using word boundaries (\b) to prevent false positives
if echo "$COMMAND" | grep -qiE 'docker.*(\bprune\b|\brm\b|\brmi\b|\bkill\b|compose.*down)'; then
    # Return JSON with deny decision
    cat << 'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: Destructive Docker command detected (prune/rm/rmi/kill/compose down). These commands can cause data loss."
  }
}
EOF
    exit 0
fi

# ASK patterns - privileged/disruptive operations (case-insensitive)
# Check for privileged container flags (security risk)
if echo "$COMMAND" | grep -qiE 'docker.*(--privileged|--cap-add=(ALL|SYS_ADMIN)|--security-opt.*(seccomp|apparmor)=unconfined|--pid=host|--net(work)?=host|--ipc=host|--device=/dev/|-v.*/:/|-v.*docker\.sock:)'; then
    cat << 'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "ask",
    "permissionDecisionReason": "Privileged container or dangerous flag detected (--privileged, --cap-add=ALL, --pid=host, --net=host, root volume mount, etc.). This grants elevated access to the host system."
  }
}
EOF
    exit 0
fi

# Check for disruptive container operations (service interruption)
if echo "$COMMAND" | grep -qiE 'docker.*(\bstop\b|\brestart\b|\bpause\b)'; then
    cat << 'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "ask",
    "permissionDecisionReason": "Docker stop/restart/pause command detected. This will disrupt running containers and may cause service interruption."
  }
}
EOF
    exit 0
fi

# Allow all other commands
exit 0
