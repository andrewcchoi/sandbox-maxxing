#!/bin/bash
# ============================================================================
# Enhanced Claude Code Credentials & Settings Persistence
# Issue #30 Extended - Full Configuration Sync
# ============================================================================
#
# This script copies ALL Claude Code configuration files from the host
# machine into the DevContainer. This includes credentials, settings,
# plugins, MCP config, and environment variables.
#
# Required docker-compose.yml configuration:
#   volumes:
#     - ~/.claude:/tmp/host-claude:ro                  # Claude config
#     - ~/.config/claude-env:/tmp/host-env:ro          # Environment secrets (optional)
#
# ============================================================================

set -euo pipefail

CLAUDE_DIR="$HOME/.claude"
HOST_CLAUDE="/tmp/host-claude"
HOST_ENV="/tmp/host-env"

echo "================================================================"
echo "Setting up Claude Code environment..."
echo "================================================================"

# ============================================================================
# 1. Create Directory Structure
# ============================================================================
mkdir -p "$CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR/plugins"
mkdir -p "$CLAUDE_DIR/mcp"

# ============================================================================
# 2. Core Configuration Files
# ============================================================================
echo ""
echo "[1/5] Copying core configuration files..."

for config_file in ".credentials.json" "settings.json" "settings.local.json" "projects.json" ".mcp.json"; do
    if [ -f "$HOST_CLAUDE/$config_file" ]; then
        cp "$HOST_CLAUDE/$config_file" "$CLAUDE_DIR/"
        chmod 600 "$CLAUDE_DIR/$config_file" 2>/dev/null || true
        echo "  ✓ $config_file"
    fi
done

# ============================================================================
# 3. Plugins Directory
# ============================================================================
echo ""
echo "[2/5] Syncing plugins directory..."

if [ -d "$HOST_CLAUDE/plugins" ]; then
    # Copy all plugins
    if [ "$(ls -A "$HOST_CLAUDE/plugins" 2>/dev/null)" ]; then
        cp -r "$HOST_CLAUDE/plugins/"* "$CLAUDE_DIR/plugins/" 2>/dev/null || true
        PLUGIN_COUNT=$(ls -1 "$CLAUDE_DIR/plugins" 2>/dev/null | wc -l)
        echo "  ✓ $PLUGIN_COUNT plugin(s) synced"
    else
        echo "  ℹ No plugins found"
    fi
else
    echo "  ℹ Plugins directory not found"
fi

# ============================================================================
# 4. MCP Configuration
# ============================================================================
echo ""
echo "[3/5] Syncing MCP configuration..."

# Copy .mcp.json if exists (already handled above, but check for mcp/ dir)
if [ -d "$HOST_CLAUDE/mcp" ]; then
    if [ "$(ls -A "$HOST_CLAUDE/mcp" 2>/dev/null)" ]; then
        cp -r "$HOST_CLAUDE/mcp/"* "$CLAUDE_DIR/mcp/" 2>/dev/null || true
        MCP_COUNT=$(ls -1 "$CLAUDE_DIR/mcp" 2>/dev/null | wc -l)
        echo "  ✓ $MCP_COUNT MCP server(s) synced"
    else
        echo "  ℹ No MCP servers found"
    fi
else
    echo "  ℹ MCP directory not found"
fi

# ============================================================================
# 5. Environment Variables (Optional)
# ============================================================================
echo ""
echo "[4/5] Loading environment variables..."

if [ -f "$HOST_ENV/.env.claude" ]; then
    # Source environment variables
    set -a
    source "$HOST_ENV/.env.claude" 2>/dev/null || true
    set +a
    echo "  ✓ Environment variables loaded from .env.claude"
elif [ -f "$HOST_ENV/claude.env" ]; then
    # Alternative filename
    set -a
    source "$HOST_ENV/claude.env" 2>/dev/null || true
    set +a
    echo "  ✓ Environment variables loaded from claude.env"
else
    echo "  ℹ No environment file found (optional)"
fi

# ============================================================================
# 6. Fix Permissions
# ============================================================================
echo ""
echo "[5/5] Setting permissions..."

chown -R "$(id -u):$(id -g)" "$CLAUDE_DIR" 2>/dev/null || true
echo "  ✓ Permissions set"

# ============================================================================
# Summary
# ============================================================================
echo ""
echo "================================================================"
echo "✓ Claude Code environment ready!"
echo "================================================================"
echo "  Config directory: $CLAUDE_DIR"
echo "  Plugins: $(ls -1 "$CLAUDE_DIR/plugins" 2>/dev/null | wc -l) installed"
echo "  MCP servers: $(ls -1 "$CLAUDE_DIR/mcp" 2>/dev/null | wc -l) configured"
echo "================================================================"
echo ""
