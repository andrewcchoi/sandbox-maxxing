#!/bin/bash
# Setup Claude Code credentials from host mount (Issue #30)

set -euo pipefail

CLAUDE_DIR="$HOME/.claude"
HOST_CLAUDE="/tmp/host-claude"

mkdir -p "$CLAUDE_DIR"

# Copy credentials if they exist
if [ -f "$HOST_CLAUDE/.credentials.json" ]; then
    cp "$HOST_CLAUDE/.credentials.json" "$CLAUDE_DIR/"
    echo "✓ Claude credentials copied"
fi

# Copy settings if they exist
if [ -f "$HOST_CLAUDE/settings.json" ]; then
    cp "$HOST_CLAUDE/settings.json" "$CLAUDE_DIR/"
    echo "✓ Claude settings copied"
fi

echo "✓ Demo app development environment ready!"
