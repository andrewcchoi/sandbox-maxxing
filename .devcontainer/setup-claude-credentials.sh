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
#     - ~/.config/gh:/tmp/host-gh:ro                   # GitHub CLI config (optional)
#
# ============================================================================

set -euo pipefail

CLAUDE_DIR="$HOME/.claude"
HOST_CLAUDE="/tmp/host-claude"
HOST_ENV="/tmp/host-env"
HOST_GH="/tmp/host-gh"
GH_CONFIG_DIR="$HOME/.config/gh"
DEFAULTS_DIR="/workspace/.devcontainer/defaults"

echo "================================================================"
echo "Setting up Claude Code environment..."
echo "================================================================"

# ============================================================================
# 1. Create Directory Structure
# ============================================================================
mkdir -p "$CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR/hooks"
mkdir -p "$CLAUDE_DIR/state"
mkdir -p "$CLAUDE_DIR/mcp"

# ============================================================================
# 2. Core Configuration Files
# ============================================================================
echo ""
echo "[1/7] Copying core configuration files..."

for config_file in ".credentials.json" "settings.json" "settings.local.json" "projects.json" ".mcp.json"; do
    if [ -f "$HOST_CLAUDE/$config_file" ]; then
        cp "$HOST_CLAUDE/$config_file" "$CLAUDE_DIR/"
        chmod 600 "$CLAUDE_DIR/$config_file" 2>/dev/null || true
        echo "  ✓ $config_file"
    fi
done

# ============================================================================
# 3. Hooks Directory
# ============================================================================
echo ""
echo "[2/7] Syncing hooks directory..."

if [ -d "$HOST_CLAUDE/hooks" ] && [ "$(ls -A "$HOST_CLAUDE/hooks" 2>/dev/null)" ]; then
    cp -r "$HOST_CLAUDE/hooks/"* "$CLAUDE_DIR/hooks/" 2>/dev/null || true
    chmod +x "$CLAUDE_DIR/hooks/"*.sh 2>/dev/null || true
    # Fix line endings (convert CRLF to LF)
    for hook in "$CLAUDE_DIR/hooks/"*.sh; do
        [ -f "$hook" ] && sed -i 's/\r$//' "$hook" 2>/dev/null || true
    done
    HOOKS_COUNT=$(ls -1 "$CLAUDE_DIR/hooks" 2>/dev/null | wc -l)
    echo "  ✓ $HOOKS_COUNT hook(s) synced from host"
else
    # Copy default hooks from devcontainer defaults
    if [ -d "$DEFAULTS_DIR/hooks" ]; then
        cp -r "$DEFAULTS_DIR/hooks/"* "$CLAUDE_DIR/hooks/" 2>/dev/null || true
        chmod +x "$CLAUDE_DIR/hooks/"*.sh 2>/dev/null || true
        # Fix line endings (convert CRLF to LF)
        for hook in "$CLAUDE_DIR/hooks/"*.sh; do
            [ -f "$hook" ] && sed -i 's/\r$//' "$hook" 2>/dev/null || true
        done
        echo "  ✓ Created default hooks (LangSmith tracing)"
    else
        echo "  ⚠ No hooks found and no defaults available"
    fi
fi

# ============================================================================
# 4. State Directory
# ============================================================================
echo ""
echo "[3/7] Syncing state directory..."

if [ -d "$HOST_CLAUDE/state" ] && [ "$(ls -A "$HOST_CLAUDE/state" 2>/dev/null)" ]; then
    cp -r "$HOST_CLAUDE/state/"* "$CLAUDE_DIR/state/" 2>/dev/null || true
    STATE_COUNT=$(ls -1 "$CLAUDE_DIR/state" 2>/dev/null | wc -l)
    echo "  ✓ $STATE_COUNT state file(s) synced from host"
else
    # Copy default state files from devcontainer defaults
    if [ -d "$DEFAULTS_DIR/state" ]; then
        cp -r "$DEFAULTS_DIR/state/"* "$CLAUDE_DIR/state/" 2>/dev/null || true
        echo "  ✓ Created default state files (hook.log, langsmith_state.json)"
    else
        # Fallback: create minimal state files
        touch "$CLAUDE_DIR/state/hook.log"
        echo "{}" > "$CLAUDE_DIR/state/langsmith_state.json"
        echo "  ✓ Created minimal state files"
    fi
fi

# ============================================================================
# 5. MCP Configuration
# ============================================================================
echo ""
echo "[4/7] Syncing MCP configuration..."

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
# 6. Environment Variables (Optional)
# ============================================================================
echo ""
echo "[5/7] Loading environment variables..."

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
# 7. GitHub CLI Authentication (Optional)
# ============================================================================
echo ""
echo "[6/7] Setting up GitHub CLI authentication..."

if [ -d "$HOST_GH" ]; then
    mkdir -p "$GH_CONFIG_DIR"

    # Copy GitHub CLI configuration
    if [ -f "$HOST_GH/hosts.yml" ]; then
        cp "$HOST_GH/hosts.yml" "$GH_CONFIG_DIR/"
        chmod 600 "$GH_CONFIG_DIR/hosts.yml" 2>/dev/null || true
        echo "  ✓ GitHub CLI authentication configured"
    else
        echo "  ℹ No GitHub CLI authentication found"
    fi

    # Copy config if exists
    if [ -f "$HOST_GH/config.yml" ]; then
        cp "$HOST_GH/config.yml" "$GH_CONFIG_DIR/"
        echo "  ✓ GitHub CLI config copied"
    fi
else
    echo "  ℹ GitHub CLI config not found (optional)"
fi

# ============================================================================
# 8. Fix Permissions
# ============================================================================
echo ""
echo "[7/7] Setting permissions..."

chown -R "$(id -u):$(id -g)" "$CLAUDE_DIR" 2>/dev/null || true
chown -R "$(id -u):$(id -g)" "$GH_CONFIG_DIR" 2>/dev/null || true
echo "  ✓ Permissions set"

# ============================================================================
# Summary
# ============================================================================
echo ""
echo "================================================================"
echo "✓ Development environment ready!"
echo "================================================================"
echo "  Config directory: $CLAUDE_DIR"
echo "  Hooks: $(ls -1 "$CLAUDE_DIR/hooks" 2>/dev/null | wc -l) installed"
echo "  State files: $(ls -1 "$CLAUDE_DIR/state" 2>/dev/null | wc -l) configured"
echo "  MCP servers: $(ls -1 "$CLAUDE_DIR/mcp" 2>/dev/null | wc -l) configured"
if [ -f "$GH_CONFIG_DIR/hosts.yml" ]; then
    echo "  GitHub CLI: ✓ Authenticated"
else
    echo "  GitHub CLI: Not authenticated (run 'gh auth login' in container)"
fi
echo "================================================================"
echo ""
