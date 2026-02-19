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
#     - ~/.claude:/tmp/host-claude:ro                      # Claude config
#     - ~/.config/claude-env:/tmp/host-env:ro              # Environment secrets (optional)
#     - ~/.config/gh:/tmp/host-gh:ro                       # GitHub CLI config (optional)
#     - shared-claude-data:/home/node/.claude              # Shared Claude config
#     - ssh-keys:/home/node/.ssh                           # SSH keys for git operations (optional)
#
# Architecture:
# - shared-claude-data: Shared across all devcontainers (credentials, settings, plugins, hooks)
# - claude-state: Per-project volume for runtime state (hook.log, langsmith_state.json)
#
# ============================================================================

set -euo pipefail

# Cleanup trap for temp files
cleanup() {
    rm -f /tmp/*.tmp.$$ 2>/dev/null || true
    if [ -n "${CLAUDE_DIR:-}" ]; then
        rm -f "$CLAUDE_DIR/hooks/"*.tmp.$$ 2>/dev/null || true
    fi
    if [ -n "${GITIGNORE_PATH:-}" ]; then
        rm -f "$GITIGNORE_PATH.lock" 2>/dev/null || true
    fi
}
trap cleanup EXIT INT TERM

# Configurable workspace directory - allows customization for different environments
WORKSPACE_DIR="${WORKSPACE_DIR:-/workspace}"

# Validate WORKSPACE_DIR exists
if [ ! -d "$WORKSPACE_DIR" ]; then
    echo "Error: WORKSPACE_DIR ($WORKSPACE_DIR) does not exist" >&2
    exit 1
fi

CLAUDE_DIR="$HOME/.claude"
HOST_CLAUDE="/tmp/host-claude"
HOST_ENV="/tmp/host-env"
HOST_GH="/tmp/host-gh"
GH_CONFIG_DIR="$HOME/.config/gh"

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
                if [ -x "$hook" ]; then chmod 755 "$tmpfile"; else chmod 644 "$tmpfile"; fi

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

# Validate environment file contains only safe KEY=value pairs
# Returns: 0 if valid, 1 if contains dangerous content
validate_env_file_safety() {
    local file="$1"

    # Strict allowlist validation regex breakdown:
    # ^\s*(#.*)?$                           - Allow empty lines and comment lines
    # ^\s*[A-Za-z_][A-Za-z0-9_]*=           - KEY must start with letter/underscore, followed by alphanumerics/underscores
    # (                                     - Value can be one of:
    #   '[^']*'                             -   Single-quoted string (no interpolation)
    #   |"[^"$`\n]*"                        -   Double-quoted string (no $, `, newlines)
    #   |[^$`\\;|&<>(){}\"[[:space:]]!~*?\[\]#]*  -   Unquoted value (no shell metacharacters)
    # )?\s*$                                - Optional value, optional trailing whitespace
    #
    # Rejected patterns: All shell metacharacters that could enable code execution
    # - $ (variable expansion)
    # - ` (command substitution)
    # - ; | & (command chaining)
    # - < > (redirection)
    # - ( ) { } (subshells/grouping)
    # - \ (escaping - could bypass filters)
    # - ! ~ * ? [ ] (globbing/expansion)

    if grep -vE '^\s*(#.*)?$|^\s*[A-Za-z_][A-Za-z0-9_]*=('"'"'[^'"'"']*'"'"'|"[^"$`\n]*"|[^$`\\;|&<>(){}\"[[:space:]]!~*?\[\]#]*)?\s*$' "$file" | grep -q .; then
        return 1  # Invalid content found
    fi
    return 0  # Valid
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
# 0. Fix Git Worktree Paths (if applicable)
# ============================================================================
if [ -f "$WORKSPACE_DIR/.devcontainer/fix-worktree-paths.sh" ]; then
    echo ""
    echo "[0/14] Detecting and fixing git worktree paths..."
    if bash "$WORKSPACE_DIR/.devcontainer/fix-worktree-paths.sh"; then
        echo "  ✓ Git worktree paths validated"
    else
        echo "  ⚠ Warning: Git worktree path fix failed (see above)" >&2
    fi
fi

# ============================================================================
# 1. Cross-Platform Git Configuration
# ============================================================================
echo ""
echo "[1/14] Configuring git for cross-platform development..."

# Prevent file mode (755/644) differences between Linux/Windows
git config --global core.filemode false

# Use LF in the repo, convert to native on checkout (input = LF in repo)
git config --global core.autocrlf input

# Ensure .gitattributes EOL rules are applied
git config --global core.eol lf

echo "  ✓ Git configured for cross-platform compatibility"

# ============================================================================
# 2. Create Directory Structure
# ============================================================================
echo ""
echo "[2/14] Creating directory structure..."

mkdir -p "$CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR/hooks"
mkdir -p "$CLAUDE_DIR/state"
mkdir -p "$CLAUDE_DIR/plugins"
mkdir -p "$CLAUDE_DIR/mcp"

echo "  ✓ Directories created"

# ============================================================================
# 3. Core Configuration Files
# ============================================================================
echo ""
echo "[3/14] Copying core configuration files..."

for config_file in ".credentials.json" "settings.json" "settings.local.json" "projects.json" ".mcp.json"; do
    if [ -f "$HOST_CLAUDE/$config_file" ]; then
        cp "$HOST_CLAUDE/$config_file" "$CLAUDE_DIR/"
        chmod 600 "$CLAUDE_DIR/$config_file" 2>/dev/null || true
        echo "  ✓ $config_file"
    fi
done

# ============================================================================
# 4. Hooks Directory
# ============================================================================
echo ""
echo "[4/14] Syncing hooks directory..."

# Try to copy from host
if copy_hooks "$HOST_CLAUDE/hooks" "$CLAUDE_DIR/hooks"; then
    fix_line_endings "$CLAUDE_DIR/hooks"
    HOOKS_COUNT=$(count_files "$CLAUDE_DIR/hooks")
    echo "  ✓ $HOOKS_COUNT hook(s) synced from host"
else
    echo "  ℹ No hooks found on host"
fi

# ============================================================================
# 5. State Directory
# ============================================================================
echo ""
echo "[5/14] Syncing state directory..."

# Try to copy from host
if copy_directory "$HOST_CLAUDE/state" "$CLAUDE_DIR/state"; then
    STATE_COUNT=$(count_files "$CLAUDE_DIR/state")
    echo "  ✓ $STATE_COUNT state file(s) synced from host"
else
    # Create minimal state files
    touch "$CLAUDE_DIR/state/hook.log"
    echo "{}" > "$CLAUDE_DIR/state/langsmith_state.json"
    echo "  ✓ Created minimal state files"
fi

# ============================================================================
# 6. MCP Configuration
# ============================================================================
echo ""
echo "[6/14] Syncing MCP configuration..."

# Note: .mcp.json is already copied in section 3 core configuration files
if copy_directory "$HOST_CLAUDE/mcp" "$CLAUDE_DIR/mcp"; then
    MCP_COUNT=$(count_files "$CLAUDE_DIR/mcp")
    echo "  ✓ $MCP_COUNT MCP server(s) synced"
else
    echo "  ℹ No MCP servers found"
fi

# ============================================================================
# 7. Environment Variables (Optional)
# ============================================================================
echo ""
echo "[7/14] Loading environment variables..."

# SECURITY NOTE: Sourcing environment files can execute arbitrary shell code.
# Only mount trusted directories to /tmp/host-env in your docker-compose.yml.
# The files should contain only KEY=value pairs, not executable commands.

if [ -f "$HOST_ENV/.env.claude" ]; then
    if ! validate_env_file_safety "$HOST_ENV/.env.claude"; then
        echo "  ⚠ Warning: .env.claude contains invalid entries or shell metacharacters - skipping for safety" >&2
        echo "  ℹ Environment files should only contain KEY=value pairs (with optional quotes)" >&2
    else
        # Source environment variables
        set -a
        source "$HOST_ENV/.env.claude" 2>/dev/null || true
        set +a
        echo "  ✓ Environment variables loaded from .env.claude"
    fi
elif [ -f "$HOST_ENV/claude.env" ]; then
    if ! validate_env_file_safety "$HOST_ENV/claude.env"; then
        echo "  ⚠ Warning: claude.env contains invalid entries or shell metacharacters - skipping for safety" >&2
        echo "  ℹ Environment files should only contain KEY=value pairs (with optional quotes)" >&2
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
# 8. GitHub CLI Authentication (Optional)
# ============================================================================
echo ""
echo "[8/14] Setting up GitHub CLI authentication..."

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
# 9. Mark Native Installation Complete
# ============================================================================
echo ""
echo "[9/14] Marking native installation as complete..."

# Run claude install to suppress migration notice
# This is needed because copying host config makes Claude think it's a migration
if command -v claude >/dev/null 2>&1; then
    claude install 2>/dev/null || true
    echo "  ✓ Native installation marked complete"
else
    echo "  ⚠ Claude CLI not found in PATH" >&2
fi

# ============================================================================
# 10. SSH Key Generation and Configuration
# ============================================================================
echo ""
echo "[10/14] Setting up SSH keys for Git operations..."

SSH_DIR="$HOME/.ssh"
SSH_KEY="$SSH_DIR/id_ed25519"
SSH_PUB="$SSH_KEY.pub"
DEVCONTAINER_SSH_PUB="$WORKSPACE_DIR/.devcontainer/devcontainer-ssh.pub"

# Create .ssh directory with proper permissions (use sudo for root-owned volume)
sudo mkdir -p "$SSH_DIR"
sudo chmod 700 "$SSH_DIR"
sudo chown -R "$(id -un):$(id -gn)" "$SSH_DIR"

# Generate SSH key if it doesn't exist (idempotent)
if [ ! -f "$SSH_KEY" ]; then
    if ssh-keygen -t ed25519 -f "$SSH_KEY" -N "" -C "devcontainer@sandboxxer" >/dev/null 2>&1; then
        # Validate immediately after generation
        if ! ssh-keygen -l -f "$SSH_KEY" >/dev/null 2>&1; then
            echo "  ⚠ Error: Generated SSH key is invalid. This should not happen." >&2
            rm -f "$SSH_KEY" "$SSH_PUB" 2>/dev/null || true
            exit 1
        fi
        echo "  ✓ Generated new ED25519 SSH key"
    else
        echo "  ⚠ Error: Failed to generate SSH key. Check that ssh-keygen is installed and $SSH_DIR is writable." >&2
        echo "  ℹ You may need to manually generate the key with: ssh-keygen -t ed25519 -f $SSH_KEY" >&2
        # Exit on failure to prevent later operations from assuming key exists
        exit 1
    fi
else
    # Validate existing SSH key format
    if ! ssh-keygen -l -f "$SSH_KEY" >/dev/null 2>&1; then
        echo "  ⚠ Error: SSH key exists but is invalid or corrupted. Please delete $SSH_KEY and run again." >&2
        exit 1
    fi
    echo "  ✓ Using existing SSH key"
fi

# Set correct permissions
chmod 600 "$SSH_KEY" 2>/dev/null || true
chmod 644 "$SSH_PUB" 2>/dev/null || true

# Copy public key to .devcontainer for user reference
if [ -f "$SSH_PUB" ]; then
    if ! mkdir -p "$WORKSPACE_DIR/.devcontainer" 2>/dev/null; then
        echo "  ⚠ Warning: Could not create .devcontainer directory" >&2
    else
        cp "$SSH_PUB" "$DEVCONTAINER_SSH_PUB"
        chmod 644 "$DEVCONTAINER_SSH_PUB" 2>/dev/null || true
        echo "  ✓ Public key copied to .devcontainer/devcontainer-ssh.pub"
    fi
fi

# Configure SSH for GitHub
if [ -f "$SSH_DIR/config" ] && grep -q "^Host github\.com" "$SSH_DIR/config" 2>/dev/null; then
    echo "  ✓ SSH config already contains GitHub entry (preserving existing configuration)"
else
    # Append GitHub config or create new file
    if [ -f "$SSH_DIR/config" ]; then
        echo "" >> "$SSH_DIR/config"  # Add blank line before new entry
        echo "  ℹ Appending GitHub config to existing SSH config"
    fi
    cat >> "$SSH_DIR/config" <<'EOF'
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
    StrictHostKeyChecking accept-new
EOF
    chmod 600 "$SSH_DIR/config"
    echo "  ✓ SSH config created for GitHub"
fi

# Add GitHub to known_hosts (idempotent - skips if already present)
if [ ! -f "$SSH_DIR/known_hosts" ] || ! grep -qE "^github\.com[[:space:]]" "$SSH_DIR/known_hosts" 2>/dev/null; then
    if ssh-keyscan -t ed25519 github.com >> "$SSH_DIR/known_hosts" 2>/dev/null; then
        echo "  ✓ GitHub added to known_hosts"
    else
        echo "  ⚠ Warning: Failed to fetch GitHub host key. SSH connections to GitHub may require manual verification." >&2
        echo "  ℹ You can manually add it later with: ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts" >&2
    fi
else
    echo "  ✓ GitHub already in known_hosts"
fi

# Display public key for user to add to GitHub
echo ""
echo "  ──────────────────────────────────────────────────────────────"
echo "  Your SSH public key (add this to GitHub):"
echo "  ──────────────────────────────────────────────────────────────"
if [ -f "$SSH_PUB" ]; then
    cat "$SSH_PUB"
else
    echo "  ⚠ Error: Public key not found" >&2
fi
echo "  ──────────────────────────────────────────────────────────────"
echo "  Add this key at: https://github.com/settings/keys"
echo "  ──────────────────────────────────────────────────────────────"
echo ""

# ============================================================================
# 11. Install Knowledge Sync Script (Host-Side)
# ============================================================================
echo ""
echo "[11/14] Installing knowledge sync script to host..."

# Copy sync script to host ~/.claude/scripts/ if not exists
if [ -d "$HOST_CLAUDE" ]; then
    # Check if script already exists on host
    if [ -f "$HOST_CLAUDE/scripts/sync-knowledge.sh" ]; then
        echo "  ✓ sync-knowledge.sh already installed on host"
    else
        # Copy from template if it exists
        if [ -f "$WORKSPACE_DIR/.devcontainer/sync-knowledge.sh" ]; then
            if [ -w "$HOST_CLAUDE" ]; then
                mkdir -p "$HOST_CLAUDE/scripts" 2>/dev/null || true
                cp "$WORKSPACE_DIR/.devcontainer/sync-knowledge.sh" "$HOST_CLAUDE/scripts/" 2>/dev/null && \
                    chmod +x "$HOST_CLAUDE/scripts/sync-knowledge.sh" 2>/dev/null && \
                    echo "  ✓ Installed sync-knowledge.sh to host ~/.claude/scripts/" || \
                    echo "  ℹ Could not install sync script (host volume may be read-only)"
            else
                echo "  ℹ Host .claude directory is read-only - install sync script manually"
            fi
        else
            echo "  ℹ sync-knowledge.sh template not found in .devcontainer/"
        fi
    fi
else
    echo "  ℹ Host .claude mount not available - sync script installation skipped"
fi

echo ""
echo "  ──────────────────────────────────────────────────────────────"
echo "  To enable automatic knowledge sync on host Claude startup:"
echo "  ──────────────────────────────────────────────────────────────"
echo "  1. Copy sync script to host:"
echo "     cp .devcontainer/sync-knowledge.sh ~/.claude/scripts/"
echo "     chmod +x ~/.claude/scripts/sync-knowledge.sh"
echo ""
echo "  2. Add SessionStart hook to ~/.claude/settings.local.json:"
echo '     "hooks": {'
echo '       "SessionStart": ['
echo '         {'
echo '           "hooks": ['
echo '             {'
echo '               "type": "command",'
echo '               "command": "bash ~/.claude/scripts/sync-knowledge.sh",'
echo '               "timeout": 15000'
echo '             }'
echo '           ]'
echo '         }'
echo '       ]'
echo '     }'
echo "  ──────────────────────────────────────────────────────────────"
echo ""

# ============================================================================
# 12. .gitignore Management
# ============================================================================
echo ""
echo "[12/14] Configuring .gitignore for SSH keys..."

GITIGNORE_PATH="$WORKSPACE_DIR/.gitignore"
SSH_EXCLUSION=".devcontainer/devcontainer-ssh.pub"
GITIGNORE_LOCKFILE="$GITIGNORE_PATH.lock"

# Use flock for atomic .gitignore modification (prevents race conditions)
(
    # Acquire exclusive lock (wait up to 5 seconds)
    if command -v flock >/dev/null 2>&1; then
        flock -w 5 200 || {
            echo "  ⚠ Warning: Could not acquire lock on .gitignore - skipping modification" >&2
            exit 0
        }
    fi

    if [ -f "$GITIGNORE_PATH" ]; then
        # Check if exclusion already exists
        if grep -qF "$SSH_EXCLUSION" "$GITIGNORE_PATH"; then
            echo "  ✓ .gitignore already excludes SSH key"
        else
            # Append exclusion with newline safety
            [ -s "$GITIGNORE_PATH" ] && [ "$(tail -c 1 "$GITIGNORE_PATH" 2>/dev/null)" != "" ] && echo >> "$GITIGNORE_PATH"
            echo "$SSH_EXCLUSION" >> "$GITIGNORE_PATH"
            echo "  ✓ Added SSH key exclusion to existing .gitignore"
        fi
    else
        # Create minimal .gitignore
        # Note: Using unquoted EOF to allow $SSH_EXCLUSION variable expansion
        cat > "$GITIGNORE_PATH" <<EOF
# DevContainer SSH keys (auto-generated, shared across projects)
$SSH_EXCLUSION
EOF
        echo "  ✓ Created .gitignore with SSH key exclusion"
    fi
) 200>"$GITIGNORE_LOCKFILE"

# Clean up lock file
rm -f "$GITIGNORE_LOCKFILE" 2>/dev/null || true

# ============================================================================
# 13. Fix Permissions
# ============================================================================
echo ""
echo "[13/14] Setting permissions..."

# Only attempt chown if directories exist
if [ -d "$CLAUDE_DIR" ]; then
    if chown -R "$(id -u):$(id -g)" "$CLAUDE_DIR" 2>/dev/null; then
        echo "  ✓ Claude directory permissions set"
    else
        echo "  ⚠ Warning: Could not set permissions on $CLAUDE_DIR" >&2
    fi
fi

if [ -d "$GH_CONFIG_DIR" ]; then
    if chown -R "$(id -u):$(id -g)" "$GH_CONFIG_DIR" 2>/dev/null; then
        echo "  ✓ GitHub CLI directory permissions set"
    else
        echo "  ⚠ Warning: Could not set permissions on $GH_CONFIG_DIR" >&2
    fi
fi

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
