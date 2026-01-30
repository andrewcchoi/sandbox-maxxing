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

# Validate DEFAULTS_DIR if explicitly set by user
if [ -n "${DEFAULTS_DIR:-}" ] && [ "$DEFAULTS_DIR" != "/workspace/skills/_shared/templates/defaults" ]; then
    if [ ! -d "$DEFAULTS_DIR" ]; then
        echo "Error: Custom DEFAULTS_DIR does not exist: $DEFAULTS_DIR" >&2
        exit 1
    fi
    if [ ! -r "$DEFAULTS_DIR" ]; then
        echo "Error: Custom DEFAULTS_DIR is not readable: $DEFAULTS_DIR" >&2
        exit 1
    fi
fi

# ============================================================================
# Helper Functions
# ============================================================================

# Safely fix line endings (CRLF -> LF) in shell scripts
# Preserves permissions and uses atomic operations to prevent data loss
fix_line_endings() {
    local dir="$1"

    # Use find to avoid glob expansion issues with spaces in filenames
    find "$dir" -maxdepth 1 -name "*.sh" -type f 2>/dev/null | while IFS= read -r hook; do
        if [ -f "$hook" ]; then
            # Create temp file with same permissions
            local tmpfile="${hook}.tmp.$$"

            # Convert CRLF to LF
            if sed 's/\r$//' "$hook" > "$tmpfile" 2>/dev/null; then
                # Preserve original permissions
                chmod --reference="$hook" "$tmpfile" 2>/dev/null || chmod 755 "$tmpfile"

                # Atomic move
                mv -f "$tmpfile" "$hook"
            else
                # Cleanup on failure
                rm -f "$tmpfile" 2>/dev/null || true
            fi
        fi
    done
}

# Safely copy hooks with error checking
copy_hooks() {
    local src="$1"
    local dst="$2"

    if [ ! -d "$src" ]; then
        return 1
    fi

    # Check if source has any .sh files before attempting copy
    if ! find "$src" -maxdepth 1 -name "*.sh" -type f 2>/dev/null | grep -q .; then
        return 1
    fi

    # Copy using find to handle spaces in filenames
    find "$src" -maxdepth 1 -name "*.sh" -type f -exec cp {} "$dst/" \; 2>/dev/null || return 1

    # Make executable
    find "$dst" -maxdepth 1 -name "*.sh" -type f -exec chmod +x {} \; 2>/dev/null || true

    return 0
}

# Count files safely without word splitting
count_files() {
    local dir="$1"
    find "$dir" -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' '
}

# Safely copy directory contents
copy_directory() {
    local src="$1"
    local dst="$2"

    if [ ! -d "$src" ]; then
        return 1
    fi

    # Check if source has any files
    if ! find "$src" -maxdepth 1 -type f 2>/dev/null | grep -q .; then
        return 1
    fi

    # Copy all files (not directories) to avoid depth issues
    find "$src" -maxdepth 1 -type f -exec cp {} "$dst/" \; 2>/dev/null || return 1

    return 0
}

echo "================================================================"
echo "Setting up Claude Code environment..."
echo "================================================================"

# ============================================================================
# 0. Cross-Platform Git Configuration
# ============================================================================
echo ""
echo "[1/10] Configuring git for cross-platform development..."

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
echo ""
echo "[2/10] Creating directory structure..."

mkdir -p "$CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR/hooks"
mkdir -p "$CLAUDE_DIR/state"
mkdir -p "$CLAUDE_DIR/plugins"
mkdir -p "$CLAUDE_DIR/mcp"

echo "  ✓ Directories created"

# ============================================================================
# 2. Core Configuration Files
# ============================================================================
echo ""
echo "[3/10] Copying core configuration files..."

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
echo "[4/10] Syncing hooks directory..."

# Try to copy from host first
if copy_hooks "$HOST_CLAUDE/hooks" "$CLAUDE_DIR/hooks"; then
    fix_line_endings "$CLAUDE_DIR/hooks"
    HOOKS_COUNT=$(count_files "$CLAUDE_DIR/hooks")
    echo "  ✓ $HOOKS_COUNT hook(s) synced from host"
# Fallback to defaults
elif copy_hooks "$DEFAULTS_DIR/hooks" "$CLAUDE_DIR/hooks"; then
    fix_line_endings "$CLAUDE_DIR/hooks"
    echo "  ✓ Created default hooks (LangSmith tracing)"
else
    echo "  ⚠ No hooks found and no defaults available"
fi

# ============================================================================
# 4. State Directory
# ============================================================================
echo ""
echo "[5/10] Syncing state directory..."

# Try to copy from host first
if copy_directory "$HOST_CLAUDE/state" "$CLAUDE_DIR/state"; then
    STATE_COUNT=$(count_files "$CLAUDE_DIR/state")
    echo "  ✓ $STATE_COUNT state file(s) synced from host"
# Fallback to defaults
elif copy_directory "$DEFAULTS_DIR/state" "$CLAUDE_DIR/state"; then
    echo "  ✓ Created default state files (hook.log, langsmith_state.json)"
else
    # Final fallback: create minimal state files
    touch "$CLAUDE_DIR/state/hook.log"
    echo "{}" > "$CLAUDE_DIR/state/langsmith_state.json"
    echo "  ✓ Created minimal state files"
fi

# ============================================================================
# 5. MCP Configuration
# ============================================================================
echo ""
echo "[6/10] Syncing MCP configuration..."

# Note: .mcp.json is already copied in section 2 core configuration files
if copy_directory "$HOST_CLAUDE/mcp" "$CLAUDE_DIR/mcp"; then
    MCP_COUNT=$(count_files "$CLAUDE_DIR/mcp")
    echo "  ✓ $MCP_COUNT MCP server(s) synced"
else
    echo "  ℹ No MCP servers found"
fi

# ============================================================================
# 6. Environment Variables (Optional)
# ============================================================================
echo ""
echo "[7/10] Loading environment variables..."

# SECURITY NOTE: Sourcing environment files can execute arbitrary shell code.
# Only mount trusted directories to /tmp/host-env in your docker-compose.yml.
# The files should contain only KEY=value pairs, not executable commands.

if [ -f "$HOST_ENV/.env.claude" ]; then
    # Basic validation: check file doesn't contain shell commands or command substitution
    # Pattern detects: commands, backticks, $(), pipes, semicolons, background jobs
    if grep -qE '^\s*(rm|curl|wget|bash|sh|eval|exec|sudo)\s|`|\$\(|[|;&]' "$HOST_ENV/.env.claude" 2>/dev/null; then
        echo "  ⚠ Warning: .env.claude contains potential shell commands - skipping for safety" >&2
        echo "  ℹ Environment files should only contain KEY=value pairs" >&2
    else
        # Source environment variables
        set -a
        source "$HOST_ENV/.env.claude" 2>/dev/null || true
        set +a
        echo "  ✓ Environment variables loaded from .env.claude"
    fi
elif [ -f "$HOST_ENV/claude.env" ]; then
    # Basic validation: check file doesn't contain shell commands or command substitution
    # Pattern detects: commands, backticks, $(), pipes, semicolons, background jobs
    if grep -qE '^\s*(rm|curl|wget|bash|sh|eval|exec|sudo)\s|`|\$\(|[|;&]' "$HOST_ENV/claude.env" 2>/dev/null; then
        echo "  ⚠ Warning: claude.env contains potential shell commands - skipping for safety" >&2
        echo "  ℹ Environment files should only contain KEY=value pairs" >&2
    else
        # Source environment variables
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
echo "[8/10] Setting up GitHub CLI authentication..."

# Note: GitHub CLI config files (hosts.yml, config.yml) are YAML data files
# that are parsed by the gh CLI tool, not sourced as shell scripts.
# They are safe to copy without validation for shell injection.

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
# 8. Mark Native Installation Complete
# ============================================================================
echo ""
echo "[9/10] Marking native installation as complete..."

# Run claude install to suppress migration notice
# This is needed because copying host config makes Claude think it's a migration
if command -v claude &> /dev/null; then
    claude install 2>/dev/null || true
    echo "  ✓ Native installation marked complete"
else
    echo "  ⚠ Claude CLI not found in PATH"
fi

# ============================================================================
# 9. Fix Permissions
# ============================================================================
echo ""
echo "[10/10] Setting permissions..."

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
echo "  Hooks: $(count_files "$CLAUDE_DIR/hooks") installed"
echo "  State files: $(count_files "$CLAUDE_DIR/state") configured"
echo "  Plugins: $(count_files "$CLAUDE_DIR/plugins") installed"
echo "  MCP servers: $(count_files "$CLAUDE_DIR/mcp") configured"
if [ -f "$GH_CONFIG_DIR/hosts.yml" ]; then
    echo "  GitHub CLI: ✓ Authenticated"
else
    echo "  GitHub CLI: Not authenticated (run 'gh auth login' in container)"
fi
echo "================================================================"
echo ""
