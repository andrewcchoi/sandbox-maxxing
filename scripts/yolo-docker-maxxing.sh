#!/usr/bin/env bash
# ============================================================================
# YOLO Docker-Maxxing DevContainer Setup
# Unified script for both normal and portless modes
#
# Usage: yolo-docker-maxxing.sh [--portless] [project-name]
# ============================================================================
set -euo pipefail

# Disable history expansion (fixes ! in Windows paths)
set +H 2>/dev/null || true

# Parse arguments
MODE="normal"
PROJECT_NAME_ARG=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --portless)
      MODE="portless"
      shift
      ;;
    -*)
      echo "Unknown option: $1"
      exit 1
      ;;
    *)
      PROJECT_NAME_ARG="$1"
      shift
      ;;
  esac
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
  # Try script's directory (when called directly)
  elif [ -f "$(dirname "${BASH_SOURCE[0]}")/../skills/_shared/templates/base.dockerfile" ]; then
    dirname "$(dirname "${BASH_SOURCE[0]}")"
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
if [ -n "$PROJECT_NAME_ARG" ]; then
  RAW_PROJECT_NAME="$PROJECT_NAME_ARG"
else
  RAW_PROJECT_NAME="$(basename "$(pwd)")"
fi
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
  partials/go.dockerfile \
  partials/azure-cli.dockerfile \
  partials/terraform.dockerfile \
  partials/tailscale.dockerfile \
  partials/pdf-tools.dockerfile \
  "$DEVCONTAINER_TEMPLATE" \
  "$COMPOSE_TEMPLATE" \
  setup-claude-credentials.sh \
  setup-frontend.sh \
  .gitattributes \
  .dockerignore \
  .gitignore \
  .editorconfig || exit 1

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

# Create directories
mkdir -p .devcontainer || { echo "ERROR: Cannot create .devcontainer"; exit 1; }

# Copy and assemble Dockerfile with all enhancements
echo "Assembling enhanced Dockerfile..."
cat "$TEMPLATES/base.dockerfile" > .devcontainer/Dockerfile || { echo "ERROR: Cannot copy base"; exit 1; }

# Append language and tool partials for enhanced yolo experience
echo "" >> .devcontainer/Dockerfile
echo "# === YOLO-DOCKER-MAXXING ENHANCEMENTS ===" >> .devcontainer/Dockerfile
cat "$TEMPLATES/partials/go.dockerfile" >> .devcontainer/Dockerfile || { echo "ERROR: Cannot append go partial"; exit 1; }
echo "" >> .devcontainer/Dockerfile
cat "$TEMPLATES/partials/azure-cli.dockerfile" >> .devcontainer/Dockerfile || { echo "ERROR: Cannot append azure-cli partial"; exit 1; }
echo "" >> .devcontainer/Dockerfile
cat "$TEMPLATES/partials/terraform.dockerfile" >> .devcontainer/Dockerfile || { echo "ERROR: Cannot append terraform partial"; exit 1; }
echo "" >> .devcontainer/Dockerfile
cat "$TEMPLATES/partials/tailscale.dockerfile" >> .devcontainer/Dockerfile || { echo "ERROR: Cannot append tailscale partial"; exit 1; }
echo "" >> .devcontainer/Dockerfile
cat "$TEMPLATES/partials/pdf-tools.dockerfile" >> .devcontainer/Dockerfile || { echo "ERROR: Cannot append pdf-tools partial"; exit 1; }

# Copy other templates
echo "Copying other templates..."
cp "$TEMPLATES/$DEVCONTAINER_TEMPLATE" .devcontainer/devcontainer.json || { echo "ERROR: Template copy failed"; exit 1; }
cp "$TEMPLATES/$COMPOSE_TEMPLATE" ./docker-compose.yml || { echo "ERROR: Template copy failed"; exit 1; }
cp "$TEMPLATES/setup-claude-credentials.sh" .devcontainer/ || { echo "ERROR: Template copy failed"; exit 1; }
cp "$TEMPLATES/setup-frontend.sh" .devcontainer/ || { echo "ERROR: Template copy failed"; exit 1; }

# Copy project config files if they don't exist
if [ ! -f ".gitattributes" ]; then
  cp "$TEMPLATES/.gitattributes" ./.gitattributes || { echo "ERROR: Template copy failed"; exit 1; }
else
  echo "Skipped .gitattributes (already exists)"
fi

if [ ! -f ".dockerignore" ]; then
  cp "$TEMPLATES/.dockerignore" ./.dockerignore || { echo "ERROR: Template copy failed"; exit 1; }
else
  echo "Skipped .dockerignore (already exists)"
fi

if [ ! -f ".gitignore" ]; then
  cp "$TEMPLATES/.gitignore" ./.gitignore || { echo "ERROR: Template copy failed"; exit 1; }
else
  echo "Skipped .gitignore (already exists)"
fi

if [ ! -f ".editorconfig" ]; then
  cp "$TEMPLATES/.editorconfig" ./.editorconfig || { echo "ERROR: Template copy failed"; exit 1; }
else
  echo "Skipped .editorconfig (already exists)"
fi

# Generate no-op firewall script (YOLO mode)
cat > .devcontainer/init-firewall.sh << 'ENDOFFILE'
#!/bin/bash
# YOLO Mode - No Firewall
echo "Firewall disabled (YOLO mode) - using Docker container isolation"
exit 0
ENDOFFILE
chmod +x .devcontainer/init-firewall.sh

# Create or update .env
if [ ! -f ".env" ]; then
  # Fresh .env — write template
  cat > .env << 'ENDOFFILE'
# YOLO Mode Configuration
ENABLE_FIREWALL=false
ENDOFFILE
  echo "Created new .env"
else
  # Existing .env — merge required values only
  echo "Updating existing .env..."
  merge_env_value "ENABLE_FIREWALL" "false" .env
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
  # Use explicit -e flags for Windows Git Bash compatibility (semicolon-separated
  # multi-line sed commands fail silently on some Windows bash implementations)
  for f in .devcontainer/devcontainer.json docker-compose.yml; do
    sed -e "s|{{PROJECT_NAME}}|$PROJECT_NAME|g" \
        -e "s|{{APP_PORT}}|$APP_PORT|g" \
        -e "s|{{FRONTEND_PORT}}|$FRONTEND_PORT|g" \
        -e "s|{{POSTGRES_PORT}}|$POSTGRES_PORT|g" \
        -e "s|{{REDIS_PORT}}|$REDIS_PORT|g" \
      "$f" > "$f.tmp" || { echo "ERROR: sed template processing failed for $f"; exit 1; }
    [ -s "$f.tmp" ] || { echo "ERROR: sed produced empty output for $f"; exit 1; }
    mv "$f.tmp" "$f"
  done
else
  # Portless mode: only replace PROJECT_NAME
  for f in .devcontainer/devcontainer.json docker-compose.yml; do
    sed -e "s|{{PROJECT_NAME}}|$PROJECT_NAME|g" \
      "$f" > "$f.tmp" || { echo "ERROR: sed template processing failed for $f"; exit 1; }
    [ -s "$f.tmp" ] || { echo "ERROR: sed produced empty output for $f"; exit 1; }
    mv "$f.tmp" "$f"
  done
fi

# Make scripts executable
chmod +x .devcontainer/*.sh || { echo "ERROR: Cannot set script permissions"; exit 1; }

# Validate no unreplaced placeholders remain
echo "Validating templates..."
UNREPLACED=$(grep -oh "{{[A-Z_]*}}" .devcontainer/devcontainer.json docker-compose.yml 2>/dev/null | sort -u)
if [ -n "$UNREPLACED" ]; then
  echo "ERROR: Unreplaced placeholders found:"
  echo "$UNREPLACED" | sed 's/^/  /'
  exit 1
fi
echo "  All placeholders replaced"

# Success message
echo ""
echo "=========================================="
echo "DevContainer Created (YOLO Docker Maxxing)"
echo "=========================================="
echo "Project: $PROJECT_NAME"
echo ""
echo "Languages & Runtimes:"
echo "  - Python 3.12"
echo "  - Node.js 20"
echo "  - Go 1.22"
echo ""
echo "Cloud & Infrastructure:"
echo "  - AWS CLI v2"
echo "  - Azure CLI (az)"
echo "  - Azure Developer CLI (azd)"
echo "  - Terraform"
echo ""
echo "PDF & OCR Tools:"
echo "  - poppler-utils (pdftotext, pdfimages)"
echo "  - ghostscript (compress, convert)"
echo "  - qpdf (merge, split, encrypt)"
echo "  - tesseract (OCR engine)"
echo "  - ocrmypdf (searchable PDFs)"
echo "  - pdftk (form filling)"
echo ""
echo "Developer Tools:"
echo "  - Tailscale (secure remote access)"
echo "  - bat (syntax-highlighted cat/git diffs)"
echo "  - Zsh with Powerlevel10k"
echo "  - fzf (fuzzy finder)"
echo ""
echo "Security:"
echo "  Firewall: Disabled (Docker container isolation)"
if [ "$MODE" = "normal" ]; then
  echo ""
  echo "Port Mappings:"
  echo "  - App:        localhost:$APP_PORT"
  echo "  - Frontend:   localhost:$FRONTEND_PORT"
  echo "  - PostgreSQL: localhost:$POSTGRES_PORT"
  echo "  - Redis:      localhost:$REDIS_PORT"
else
  echo ""
  echo "Mode: Portless (no host port mappings)"
  echo "  Services accessible via Docker network only"
fi
echo ""
echo "Files Created:"
echo "  - .devcontainer/Dockerfile (base + 5 partials)"
echo "  - .devcontainer/devcontainer.json"
echo "  - .devcontainer/setup-claude-credentials.sh"
echo "  - .devcontainer/setup-frontend.sh"
echo "  - .devcontainer/init-firewall.sh"
echo "  - docker-compose.yml"
echo "  - .env"
[ ! -f ".gitattributes.backup" ] && echo "  - .gitattributes" || echo "  - .gitattributes (preserved)"
[ ! -f ".dockerignore.backup" ] && echo "  - .dockerignore" || echo "  - .dockerignore (preserved)"
[ ! -f ".gitignore.backup" ] && echo "  - .gitignore" || echo "  - .gitignore (preserved)"
[ ! -f ".editorconfig.backup" ] && echo "  - .editorconfig" || echo "  - .editorconfig (preserved)"
echo ""
echo "Recommended Next Steps:"
echo ""
echo "  1. Configure git to use bat for diffs:"
echo "     git config --global core.pager 'bat --paging=always'"
echo "     git config --global pager.diff 'bat --paging=always --style=numbers,grid'"
echo ""
echo "  2. Verify AWS CLI (credentials auto-mounted from ~/.aws):"
echo "     aws sts get-caller-identity"
echo "     If mount failed, see setup-claude-credentials.sh output for manual steps"
echo ""
echo "  3. Set up Tailscale for remote access (optional):"
echo "     sudo tailscaled --state=/var/lib/tailscale/tailscaled.state &"
echo "     sudo tailscale up --authkey=YOUR_AUTH_KEY"
echo "     Get auth key: https://login.tailscale.com/admin/settings/keys"
echo ""
echo "  4. Test PDF tools:"
echo "     pdftotext sample.pdf output.txt"
echo "     ocrmypdf scanned.pdf searchable.pdf"
echo ""
echo "Next: Open in VS Code -> 'Reopen in Container'"
echo "=========================================="
