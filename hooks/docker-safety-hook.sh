#!/usr/bin/env bash
#
# PreToolUse hook for Docker command safety checks.
# Blocks destructive commands, prompts for privileged containers.
#
set -e

# Read JSON from stdin
INPUT=$(cat)

# Extract command using jq
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

# Exit early if no command
[ -z "$COMMAND" ] && exit 0

# BLOCK patterns - destructive Docker commands
if echo "$COMMAND" | grep -qE 'docker.*prune|docker.*rm.*-f.*\$|docker.*rmi.*-f'; then
    # Return JSON with deny decision
    cat << 'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "BLOCKED: Destructive Docker command detected (prune/rm -f/rmi -f)"
  }
}
EOF
    exit 0
fi

# ASK patterns - privileged containers
if echo "$COMMAND" | grep -qE 'docker.*--privileged'; then
    cat << 'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "ask",
    "permissionDecisionReason": "Privileged container requested. This bypasses security isolation."
  }
}
EOF
    exit 0
fi

# Allow all other commands
exit 0
