---
description: YOLO docker-maxxing DevContainer setup with no questions - Python+Node base, no firewall
argument-hint: "[project-name] [--portless]"
allowed-tools: [Bash]
---

# YOLO Docker-Maxxing DevContainer Setup

**Quick setup with zero questions.** Creates a DevContainer with:
- Python 3.12 + Node 20 (multi-language base image)
- No firewall (Docker isolation only)
- All standard development tools

**Portless mode:** Add `--portless` flag to create containers without host port mappings for running multiple devcontainers in parallel.

**Need customization?** Use `/sandboxxer:quickstart` for interactive mode with project type selection and firewall options.

## Determine Project Name

**Note:** Claude performs argument substitution before execution. If the user provides a project name argument, Claude replaces the `basename $(pwd)` expression in the bash script with that value. The bash script itself does not process command-line arguments.

- If the user provided an argument (project name), Claude substitutes it in the script
- Otherwise, the script uses the current directory name: `basename $(pwd)`

## Execute These Bash Commands

**Note:** This command automatically detects mode (normal vs portless) from the `--portless` flag and executes the appropriate setup in a single unified bash block.

```bash
# ============================================================================
# YOLO Docker-Maxxing DevContainer Setup
# Unified script for both normal and portless modes
# ============================================================================

# Disable history expansion (fixes ! in Windows paths)
set +H 2>/dev/null || true

# Detect mode from arguments
MODE="normal"
for arg in "$@"; do
  if [ "$arg" = "--portless" ]; then
    MODE="portless"
    break
  fi
done

echo "=== Mode: ${MODE} ==="
echo ""

# Find plugin root and source common functions
PLUGIN_ROOT=$(
  # Try CLAUDE_PLUGIN_ROOT environment variable
  if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ]; then
    echo "${CLAUDE_PLUGIN_ROOT//\\//}"
  # Try current directory (development mode)
  elif [ -f "skills/_shared/templates/base.dockerfile" ]; then
    echo "."
  # Search ~/.claude/plugins (installed mode)
  elif [ -d "$HOME/.claude/plugins" ]; then
    find "$HOME/.claude/plugins" -type f -name "plugin.json" \
      -exec grep -l '"name".*:.*"sandboxxer"' {} \; 2>/dev/null | head -1 | \
      xargs dirname | \
      while read dir; do
        if [ "$(basename "$dir")" = ".claude-plugin" ]; then
          dirname "$dir"
        else
          echo "$dir"
        fi
      done | head -1
  fi
)

[ -z "$PLUGIN_ROOT" ] && { echo "ERROR: Cannot locate plugin root"; exit 1; }
echo "Plugin root: $PLUGIN_ROOT"

# Source common utility functions
source "$PLUGIN_ROOT/scripts/common.sh" || { echo "ERROR: Cannot load common.sh"; exit 1; }

# Get and sanitize project name
RAW_PROJECT_NAME="$(basename "$(pwd)")"
PROJECT_NAME="$(sanitize_project_name "$RAW_PROJECT_NAME")"
[ "$PROJECT_NAME" != "$RAW_PROJECT_NAME" ] && echo "Auto-sanitized: $RAW_PROJECT_NAME -> $PROJECT_NAME"

# Determine templates to use based on mode
TEMPLATES="$PLUGIN_ROOT/skills/_shared/templates"
if [ "$MODE" = "portless" ]; then
  DEVCONTAINER_TEMPLATE="devcontainer.portless.json"
  COMPOSE_TEMPLATE="docker-compose.portless.yml"
else
  DEVCONTAINER_TEMPLATE="devcontainer.json"
  COMPOSE_TEMPLATE="docker-compose.yml"
fi

# Validate required templates exist
validate_templates "$PLUGIN_ROOT" \
  base.dockerfile \
  "$DEVCONTAINER_TEMPLATE" \
  "$COMPOSE_TEMPLATE" \
  setup-claude-credentials.sh \
  setup-frontend.sh || exit 1

# Port allocation (only for normal mode)
if [ "$MODE" = "normal" ]; then
  echo "Allocating ports..."
  APP_PORT=$(find_available_port 8000) || { echo "FATAL: Cannot allocate APP_PORT"; exit 1; }
  FRONTEND_PORT=$(find_available_port 3000 "$APP_PORT") || { echo "FATAL: Cannot allocate FRONTEND_PORT"; exit 1; }
  POSTGRES_PORT=$(find_available_port 5432 "$APP_PORT" "$FRONTEND_PORT") || { echo "FATAL: Cannot allocate POSTGRES_PORT"; exit 1; }
  REDIS_PORT=$(find_available_port 6379 "$APP_PORT" "$FRONTEND_PORT" "$POSTGRES_PORT") || { echo "FATAL: Cannot allocate REDIS_PORT"; exit 1; }
  echo "  APP_PORT=$APP_PORT"
  echo "  FRONTEND_PORT=$FRONTEND_PORT"
  echo "  POSTGRES_PORT=$POSTGRES_PORT"
  echo "  REDIS_PORT=$REDIS_PORT"
  echo ""
fi

# Backup existing .env if present
if [ -f ".env" ]; then
  cp .env .env.backup
  echo "Backed up existing .env"
fi

# Create directories
mkdir -p .devcontainer || { echo "ERROR: Cannot create .devcontainer"; exit 1; }

# Copy templates
echo "Copying templates..."
cp "$TEMPLATES/base.dockerfile" .devcontainer/Dockerfile || { echo "ERROR: Template copy failed"; exit 1; }
cp "$TEMPLATES/$DEVCONTAINER_TEMPLATE" .devcontainer/devcontainer.json || { echo "ERROR: Template copy failed"; exit 1; }
cp "$TEMPLATES/$COMPOSE_TEMPLATE" ./docker-compose.yml || { echo "ERROR: Template copy failed"; exit 1; }
cp "$TEMPLATES/setup-claude-credentials.sh" .devcontainer/ || { echo "ERROR: Template copy failed"; exit 1; }
cp "$TEMPLATES/setup-frontend.sh" .devcontainer/ || { echo "ERROR: Template copy failed"; exit 1; }

# Generate no-op firewall script (YOLO mode)
cat > .devcontainer/init-firewall.sh << 'EOF'
#!/bin/bash
# YOLO Mode - No Firewall
echo "Firewall disabled (YOLO mode) - using Docker container isolation"
exit 0
EOF
chmod +x .devcontainer/init-firewall.sh

# Create .env with ENABLE_FIREWALL=false
cat > .env << 'EOF'
# YOLO Mode Configuration
ENABLE_FIREWALL=false
EOF

# Preserve values from backup
if [ -f ".env.backup" ]; then
  echo "Preserving .env values..."
  preserved_count=0
  while IFS='=' read -r key value || [ -n "$key" ]; do
    [ -z "$key" ] && continue
    [[ "$key" =~ ^[[:space:]]*# ]] && continue

    # Always overlay backup values (user data wins over template defaults)
    merge_env_value "$key" "$value" .env
    preserved_count=$((preserved_count + 1))
    echo "  Preserved: $key"
  done < .env.backup
  echo "  Preserved $preserved_count values"
  rm -f .env.backup
fi

# Write ports to .env (normal mode only)
if [ "$MODE" = "normal" ]; then
  echo "Writing port configuration..."
  merge_env_value "APP_PORT" "$APP_PORT" .env
  merge_env_value "FRONTEND_PORT" "$FRONTEND_PORT" .env
  merge_env_value "POSTGRES_PORT" "$POSTGRES_PORT" .env
  merge_env_value "REDIS_PORT" "$REDIS_PORT" .env
fi

# Replace placeholders in templates
echo "Processing templates..."
if [ "$MODE" = "normal" ]; then
  # Replace PROJECT_NAME and all port placeholders
  for f in .devcontainer/devcontainer.json docker-compose.yml; do
    sed "s|{{PROJECT_NAME}}|$PROJECT_NAME|g; \
         s|{{APP_PORT}}|$APP_PORT|g; \
         s|{{FRONTEND_PORT}}|$FRONTEND_PORT|g; \
         s|{{POSTGRES_PORT}}|$POSTGRES_PORT|g; \
         s|{{REDIS_PORT}}|$REDIS_PORT|g" \
      "$f" > "$f.tmp" || { echo "ERROR: sed template processing failed for $f"; exit 1; }
    [ -s "$f.tmp" ] || { echo "ERROR: sed produced empty output for $f"; exit 1; }
    mv "$f.tmp" "$f"
  done
else
  # Portless mode: only replace PROJECT_NAME
  for f in .devcontainer/devcontainer.json docker-compose.yml; do
    sed "s|{{PROJECT_NAME}}|$PROJECT_NAME|g" \
      "$f" > "$f.tmp" || { echo "ERROR: sed template processing failed for $f"; exit 1; }
    [ -s "$f.tmp" ] || { echo "ERROR: sed produced empty output for $f"; exit 1; }
    mv "$f.tmp" "$f"
  done
fi

# Make scripts executable
chmod +x .devcontainer/*.sh || { echo "ERROR: Cannot set script permissions"; exit 1; }

# Success message
echo ""
echo "=========================================="
echo "DevContainer Created (YOLO Docker Maxxing)"
echo "=========================================="
echo "Project: $PROJECT_NAME"
echo "Language: Python 3.12 + Node 20"
echo "Firewall: Disabled"
if [ "$MODE" = "normal" ]; then
  echo "Ports: App=$APP_PORT, Frontend=$FRONTEND_PORT, PostgreSQL=$POSTGRES_PORT, Redis=$REDIS_PORT"
else
  echo "Mode: Portless (no host port mappings)"
  echo "Services: Accessible via Docker network only"
fi
echo ""
echo "Files created:"
echo "  .devcontainer/Dockerfile"
echo "  .devcontainer/devcontainer.json"
echo "  .devcontainer/setup-claude-credentials.sh"
echo "  .devcontainer/setup-frontend.sh"
echo "  .devcontainer/init-firewall.sh"
echo "  docker-compose.yml"
echo "  .env"
echo ""
echo "Next: Open in VS Code → 'Reopen in Container'"
echo "=========================================="
```
