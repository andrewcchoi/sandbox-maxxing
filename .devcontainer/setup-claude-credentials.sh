#!/usr/bin/env bash
# ============================================================================
# Enhanced Claude Code Credentials & Settings Persistence
# Issue #30 Extended - Full Configuration Sync (Unified Template)
# ============================================================================
#
# This script copies ALL Claude Code configuration files from the host
# machine into the DevContainer. This includes credentials, settings,
# hooks, state, plugins, MCP config, and environment variables.
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

# Configurable defaults directory - points to template defaults by default
# Override via: DEFAULTS_DIR=/custom/path ./setup-claude-credentials.sh
DEFAULTS_DIR="${DEFAULTS_DIR:-/workspace/skills/_shared/templates/defaults}"

echo "================================================================"
echo "Setting up Claude Code environment..."
echo "================================================================"

# ============================================================================
# 0. Cross-Platform Git Configuration
# ============================================================================
echo ""
echo "[0/8] Configuring git for cross-platform development..."

# Prevent file mode (755/644) differences between Linux/Windows
git config --global core.filemode false

# Use LF in the repo, convert to native on checkout (input = LF in repo)
git config --global core.autocrlf input

# Ensure .gitattributes EOL rules are applied
git config --global core.eol lf

echo "  ✓ Git configured for cross-platform compatibility"

# ============================================================================
# 1. Create Directory Structure
# ============================================================================
mkdir -p "$CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR/hooks"
mkdir -p "$CLAUDE_DIR/state"
mkdir -p "$CLAUDE_DIR/plugins"
mkdir -p "$CLAUDE_DIR/mcp"

# ============================================================================
# 2. Core Configuration Files
# ============================================================================
echo ""
echo "[1/8] Copying core configuration files..."

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
echo "[2/8] Syncing hooks directory..."

if [ -d "$HOST_CLAUDE/hooks" ] && [ "$(ls -A "$HOST_CLAUDE/hooks" 2>/dev/null)" ]; then
    cp -r "$HOST_CLAUDE/hooks/"* "$CLAUDE_DIR/hooks/" 2>/dev/null || true
    chmod +x "$CLAUDE_DIR/hooks/"*.sh 2>/dev/null || true
    # Fix line endings (convert CRLF to LF)
    for hook in "$CLAUDE_DIR/hooks/"*.sh; do
        [ -f "$hook" ] && sed 's/\r$//' "$hook" > "$hook.tmp" && mv "$hook.tmp" "$hook" 2>/dev/null || true
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
            [ -f "$hook" ] && sed 's/\r$//' "$hook" > "$hook.tmp" && mv "$hook.tmp" "$hook" 2>/dev/null || true
        done
        echo "  ✓ Default hooks directory created"
    else
        echo "  ⚠ No hooks found and no defaults available"
    fi
fi

# ============================================================================
# 4. State Directory
# ============================================================================
echo ""
echo "[3/8] Syncing state directory..."

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
echo "[4/8] Syncing MCP configuration..."

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
echo "[5/8] Loading environment variables..."

if [ -f "$HOST_ENV/.env.claude" ]; then
    # Validate environment file for security (check for shell commands)
    if grep -qE '^\s*(rm|curl|wget|bash|sh|eval|exec|sudo)\s|`|\$\(|[|;&]' "$HOST_ENV/.env.claude" 2>/dev/null; then
        echo "  ⚠ Warning: .env.claude contains potential shell commands - skipping for safety" >&2
        echo "  ℹ Environment files should only contain KEY=value pairs" >&2
    else
        set -a
        source "$HOST_ENV/.env.claude" 2>/dev/null || true
        set +a
        echo "  ✓ Environment variables loaded from .env.claude"
    fi
elif [ -f "$HOST_ENV/claude.env" ]; then
    # Validate alternative filename
    if grep -qE '^\s*(rm|curl|wget|bash|sh|eval|exec|sudo)\s|`|\$\(|[|;&]' "$HOST_ENV/claude.env" 2>/dev/null; then
        echo "  ⚠ Warning: claude.env contains potential shell commands - skipping for safety" >&2
        echo "  ℹ Environment files should only contain KEY=value pairs" >&2
    else
        set -a
        source "$HOST_ENV/claude.env" 2>/dev/null || true
        set +a
        echo "  ✓ Environment variables loaded from claude.env"
    fi
else
    echo "  ℹ No environment file found (optional)"
fi

# ============================================================================
# 7. GitHub CLI Authentication (Optional)
# ============================================================================
echo ""
echo "[6/8] Setting up GitHub CLI authentication..."

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
# 8. SSH Key Setup for DevContainer
# ============================================================================
echo ""
echo "[7/9] Setting up SSH keys for devcontainer..."

SSH_DIR="$HOME/.ssh"
SSH_KEY_PATH="$SSH_DIR/id_ed25519"
SSH_PUB_KEY_PATH="${SSH_KEY_PATH}.pub"
WORKSPACE_SSH_PUB="/workspace/.devcontainer/devcontainer-ssh.pub"

# Ensure .ssh directory exists with correct permissions
# Use sudo to create and take ownership of the directory (needed for named Docker volumes)
sudo /bin/mkdir -p /home/node/.ssh
sudo /bin/chown -R node:node /home/node/.ssh
chmod 700 "$SSH_DIR"

# Generate SSH key if it doesn't exist (idempotent)
if [ ! -f "$SSH_KEY_PATH" ]; then
    echo "  Generating new ED25519 SSH key for devcontainer..."
    ssh-keygen -t ed25519 -f "$SSH_KEY_PATH" -N "" -C "devcontainer-$(hostname)-$(date +%Y%m%d)"
    echo "  ✓ SSH key pair generated"
else
    echo "  ✓ SSH key already exists (persisted from previous session)"
fi

# Set correct permissions
chmod 600 "$SSH_KEY_PATH"
chmod 644 "$SSH_PUB_KEY_PATH"

# Copy public key to .devcontainer folder for easy access
if [ -f "$SSH_PUB_KEY_PATH" ]; then
    cp "$SSH_PUB_KEY_PATH" "$WORKSPACE_SSH_PUB"
    echo "  ✓ Public key copied to .devcontainer/devcontainer-ssh.pub"
fi

# Configure SSH to use the key for GitHub
SSH_CONFIG="$SSH_DIR/config"
if [ ! -f "$SSH_CONFIG" ] || ! grep -q "Host github.com" "$SSH_CONFIG" 2>/dev/null; then
    cat >> "$SSH_CONFIG" << 'SSHCONFIG'
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
SSHCONFIG
    chmod 600 "$SSH_CONFIG"
    echo "  ✓ SSH config created for GitHub"
fi

# Add GitHub to known_hosts if not present
if [ ! -f "$SSH_DIR/known_hosts" ] || ! grep -q "github.com" "$SSH_DIR/known_hosts" 2>/dev/null; then
    ssh-keyscan -t ed25519 github.com >> "$SSH_DIR/known_hosts" 2>/dev/null
    echo "  ✓ GitHub added to known_hosts"
fi

# ============================================================================
# 9. Mark Native Installation Complete
# ============================================================================
echo ""
echo "[8/9] Marking native installation as complete..."

# Run claude install to suppress migration notice
# This is needed because copying host config makes Claude think it's a migration
if command -v claude &> /dev/null; then
    claude install 2>/dev/null || true
    echo "  ✓ Native installation marked complete"
else
    echo "  ⚠ Claude CLI not found in PATH"
fi

# ============================================================================
# 10. Fix Permissions
# ============================================================================
echo ""
echo "[9/9] Setting permissions..."

chown -R "$(id -u):$(id -g)" "$CLAUDE_DIR" 2>/dev/null || true
chown -R "$(id -u):$(id -g)" "$GH_CONFIG_DIR" 2>/dev/null || true
chown -R "$(id -u):$(id -g)" "$SSH_DIR" 2>/dev/null || true
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
echo "  Plugins: $(ls -1 "$CLAUDE_DIR/plugins" 2>/dev/null | wc -l) installed"
echo "  MCP servers: $(ls -1 "$CLAUDE_DIR/mcp" 2>/dev/null | wc -l) configured"
if [ -f "$GH_CONFIG_DIR/hosts.yml" ]; then
    echo "  GitHub CLI: ✓ Authenticated"
else
    echo "  GitHub CLI: Not authenticated (run 'gh auth login' in container)"
fi
echo "================================================================"
echo ""
if [ -f "$WORKSPACE_SSH_PUB" ]; then
    echo "🔑 SSH Key Setup Required"
    echo "================================================================"
    echo "Add this public key to GitHub to enable git operations:"
    echo ""
    cat "$WORKSPACE_SSH_PUB"
    echo ""
    echo "Add key at: https://github.com/settings/ssh/new"
    echo "Then test with: ssh -T git@github.com"
    echo "================================================================"
    echo ""
fi
