---
description: Interactive DevContainer quickstart with project type selection and firewall customization
argument-hint: "[--yes] [--profile=NAME] [--tools=LIST] [--firewall|--no-firewall] [--volume]"
allowed-tools: [Bash, AskUserQuestion, Read]
---

# Interactive DevContainer Quickstart (v2)

Create a customized VS Code DevContainer configuration with:
- Project-specific base image + language tools
- Optional network firewall with domain allowlist
- All standard Claude Code sandbox features

**Quick paths:**
- Use `/sandboxxer:yolo-docker-maxxing` for instant setup with no questions
- Use `--yes` flag to accept all defaults from settings file

---

## Phase 0: Settings Load

Load user preferences from `.claude/sandboxxer.local.md` if it exists.

```bash
# ============================================================================
# Phase 0: Load Settings and Parse CLI Flags
# ============================================================================
source "${CLAUDE_PLUGIN_ROOT}/scripts/common.sh"

# Parse CLI flags
AUTO_ACCEPT=false
FORCE_INTERACTIVE=false
CLI_PROFILE=""
CLI_TOOLS=""
CLI_FIREWALL=""
CLI_WORKSPACE=""
SKIP_VALIDATION=false
FRESH_ENV=false
USE_FEATURES_FLAG=false

for arg in "$@"; do
  case $arg in
    --yes|-y)           AUTO_ACCEPT=true ;;
    --interactive)      FORCE_INTERACTIVE=true ;;
    --profile=*)        CLI_PROFILE="${arg#*=}" ;;
    --tools=*)          CLI_TOOLS="${arg#*=}" ;;
    --firewall)         CLI_FIREWALL="true" ;;
    --no-firewall)      CLI_FIREWALL="false" ;;
    --volume)           CLI_WORKSPACE="volume" ;;
    --skip-validation)  SKIP_VALIDATION=true ;;
    --fresh-env)        FRESH_ENV=true ;;
    --use-features)     USE_FEATURES_FLAG=true ;;
  esac
done

# Load settings with defaults
SETTING_PROFILE=$(read_setting "default_profile" "")
SETTING_TOOLS=$(read_setting_list "default_tools" "")
SETTING_FIREWALL=$(read_setting "default_firewall" "disabled")
SETTING_FIREWALL_PRESET=$(read_setting "firewall_preset" "essentials")
SETTING_WORKSPACE=$(read_setting "default_workspace_mode" "auto")
SETTING_SKIP_QUESTIONS=$(read_setting "skip_all_questions" "false")

# CLI overrides settings
[ -n "$CLI_PROFILE" ] && SETTING_PROFILE="$CLI_PROFILE"
[ -n "$CLI_TOOLS" ] && SETTING_TOOLS="$CLI_TOOLS"
[ -n "$CLI_FIREWALL" ] && SETTING_FIREWALL="$CLI_FIREWALL"
[ -n "$CLI_WORKSPACE" ] && SETTING_WORKSPACE="$CLI_WORKSPACE"

# Auto-accept if settings say so OR --yes flag
[ "$SETTING_SKIP_QUESTIONS" = "true" ] && AUTO_ACCEPT=true

echo "Quickstart v2 - Settings loaded"
[ "$AUTO_ACCEPT" = "true" ] && echo "  Mode: Auto-accept (--yes or settings)"
[ -n "$SETTING_PROFILE" ] && echo "  Profile: $SETTING_PROFILE"
```

---

## Phase 1: Discovery

Automatically detect environment and project characteristics.

```bash
# ============================================================================
# Phase 1: Discovery - Pre-flight Validation and Detection
# ============================================================================

echo ""
echo "[Phase 1/4] Discovery"

# 1.1 Pre-flight validation (unless skipped)
VALIDATION_FAILED=false
PORT_CONFLICTS_FOUND=false
CONFLICTED=()

if [ "$SKIP_VALIDATION" = "false" ]; then
  echo "  [1.1] Running pre-flight checks..."

  # Docker daemon check
  if ! docker info > /dev/null 2>&1; then
    echo "  ERROR: Docker is not running"
    echo "    Fix: Start Docker Desktop or run 'sudo systemctl start docker'"
    VALIDATION_FAILED=true
  else
    echo "    ✓ Docker is running"
  fi

  # Docker Compose check
  if ! docker compose version > /dev/null 2>&1; then
    echo "  ERROR: Docker Compose not found"
    echo "    Fix: Install Docker Compose v2 or update Docker Desktop"
    VALIDATION_FAILED=true
  else
    echo "    ✓ Docker Compose available"
  fi

  # Port availability check
  for port in 8000 3000 5432 6379; do
    if port_in_use "$port"; then
      CONFLICTED+=("$port")
      PORT_CONFLICTS_FOUND=true
    fi
  done

  [ "$PORT_CONFLICTS_FOUND" = "false" ] && echo "    ✓ All default ports available"

  # Disk space check
  if command -v df > /dev/null 2>&1; then
    AVAILABLE_GB=$(df -BG . 2>/dev/null | tail -1 | awk '{print $4}' | tr -d 'G')
    if [ -n "$AVAILABLE_GB" ] && [ "$AVAILABLE_GB" -lt 5 ] 2>/dev/null; then
      echo "    WARNING: Low disk space (${AVAILABLE_GB}GB, 5GB+ recommended)"
    else
      echo "    ✓ Disk space OK"
    fi
  fi

  if [ "$VALIDATION_FAILED" = "true" ]; then
    echo ""
    echo "Pre-flight checks failed. Fix the errors above and try again."
    exit 1
  fi
else
  echo "  [1.1] Skipped pre-flight checks (--skip-validation)"
fi

# 1.2 Port allocation
APP_PORT=8000
FRONTEND_PORT=3000
POSTGRES_PORT=5432
REDIS_PORT=6379

if [ "$PORT_CONFLICTS_FOUND" = "true" ]; then
  echo "  [1.2] Resolving port conflicts..."
  for port in "${CONFLICTED[@]}"; do
    new_port=$(find_available_port "$port")
    case $port in
      8000) APP_PORT=$new_port; echo "    App: 8000 → $new_port" ;;
      3000) FRONTEND_PORT=$new_port; echo "    Frontend: 3000 → $new_port" ;;
      5432) POSTGRES_PORT=$new_port; echo "    PostgreSQL: 5432 → $new_port" ;;
      6379) REDIS_PORT=$new_port; echo "    Redis: 6379 → $new_port" ;;
    esac
  done
else
  echo "  [1.2] Using default ports"
fi

# 1.3 Detect existing configuration
echo "  [1.3] Checking for existing configuration..."
EXISTING_CONFIG_FOUND=false
EXISTING_EXTENSIONS=""
EXISTING_CONTAINER_ENV="{}"
EXISTING_REMOTE_ENV="{}"
EXISTING_FORWARD_PORTS=""
EXISTING_POST_CREATE=""
EXISTING_FEATURES="{}"

if [ -f ".devcontainer/devcontainer.json" ]; then
  EXISTING_CONFIG_FOUND=true
  echo "    Found existing .devcontainer/"

  # Extract custom extensions
  EXISTING_EXTENSIONS=$(jq -r '.customizations.vscode.extensions[]?' .devcontainer/devcontainer.json 2>/dev/null | \
    grep -v "anthropic.claude-code\|ms-azuretools.vscode-docker\|ms-python.python\|ms-python.vscode-pylance\|redhat.vscode-yaml\|eamodio.gitlens\|PKief.material-icon-theme\|johnpapa.vscode-peacock" | \
    tr '\n' ' ')

  # Extract environment variables
  EXISTING_CONTAINER_ENV=$(jq -c '.containerEnv // {}' .devcontainer/devcontainer.json 2>/dev/null)
  EXISTING_REMOTE_ENV=$(jq -c '.remoteEnv // {}' .devcontainer/devcontainer.json 2>/dev/null)

  # Extract custom ports
  EXISTING_FORWARD_PORTS=$(jq -r '.forwardPorts[]?' .devcontainer/devcontainer.json 2>/dev/null | \
    grep -v "^8000$\|^3000$\|^5432$\|^6379$" | tr '\n' ' ')

  # Extract lifecycle hooks
  EXISTING_POST_CREATE=$(jq -r '.postCreateCommand // empty' .devcontainer/devcontainer.json 2>/dev/null)
  EXISTING_FEATURES=$(jq -c '.features // {}' .devcontainer/devcontainer.json 2>/dev/null)

  # Backup existing configuration
  mkdir -p .devcontainer.backup
  cp -r .devcontainer/* .devcontainer.backup/ 2>/dev/null || true
  [ -f "docker-compose.yml" ] && cp docker-compose.yml .devcontainer.backup/
  echo "    Backed up to .devcontainer.backup/"
fi

# Backup .env if exists
if [ -f ".env" ]; then
  mkdir -p .devcontainer.backup
  cp .env .devcontainer.backup/.env.user-backup
  echo "    Backed up .env"
fi

# 1.4 Detect web frameworks
echo "  [1.4] Detecting project frameworks..."
DETECTED_JS_FRAMEWORK=""
DETECTED_PY_FRAMEWORK=""
JS_FRAMEWORK_EXTENSIONS=""
PY_FRAMEWORK_EXTENSIONS=""

if [ -f "package.json" ]; then
  if jq -e '.dependencies.react // .devDependencies.react' package.json > /dev/null 2>&1; then
    DETECTED_JS_FRAMEWORK="React"
    JS_FRAMEWORK_EXTENSIONS="dsznajder.es7-react-js-snippets"
  elif jq -e '.dependencies.vue // .devDependencies.vue' package.json > /dev/null 2>&1; then
    DETECTED_JS_FRAMEWORK="Vue"
    JS_FRAMEWORK_EXTENSIONS="Vue.volar"
  elif jq -e '.dependencies.next // .devDependencies.next' package.json > /dev/null 2>&1; then
    DETECTED_JS_FRAMEWORK="Next.js"
    JS_FRAMEWORK_EXTENSIONS="dsznajder.es7-react-js-snippets"
  elif jq -e '.dependencies.svelte // .devDependencies.svelte' package.json > /dev/null 2>&1; then
    DETECTED_JS_FRAMEWORK="Svelte"
    JS_FRAMEWORK_EXTENSIONS="svelte.svelte-vscode"
  elif jq -e '.dependencies["@angular/core"]' package.json > /dev/null 2>&1; then
    DETECTED_JS_FRAMEWORK="Angular"
    JS_FRAMEWORK_EXTENSIONS="Angular.ng-template"
  fi
fi

# Detect Python frameworks
PY_DEPS=""
[ -f "pyproject.toml" ] && PY_DEPS=$(cat pyproject.toml)
[ -f "requirements.txt" ] && PY_DEPS=$(cat requirements.txt)

if [ -n "$PY_DEPS" ]; then
  if echo "$PY_DEPS" | grep -qi "fastapi"; then
    DETECTED_PY_FRAMEWORK="FastAPI"
  elif echo "$PY_DEPS" | grep -qi "django"; then
    DETECTED_PY_FRAMEWORK="Django"
    PY_FRAMEWORK_EXTENSIONS="batisteo.vscode-django"
  elif echo "$PY_DEPS" | grep -qi "flask"; then
    DETECTED_PY_FRAMEWORK="Flask"
  fi
fi

# Report detections
[ -n "$DETECTED_JS_FRAMEWORK" ] && echo "    Detected JS framework: $DETECTED_JS_FRAMEWORK"
[ -n "$DETECTED_PY_FRAMEWORK" ] && echo "    Detected Python framework: $DETECTED_PY_FRAMEWORK"
[ -z "$DETECTED_JS_FRAMEWORK" ] && [ -z "$DETECTED_PY_FRAMEWORK" ] && echo "    No specific frameworks detected"

# 1.5 Detect app directories for Docker Compose profiles
HAS_BACKEND_DIR=false
HAS_FRONTEND_DIR=false
USE_APP_PROFILES=false

[ -d "backend" ] && [ -f "backend/Dockerfile" -o -f "backend/pyproject.toml" ] && HAS_BACKEND_DIR=true
[ -d "frontend" ] && [ -f "frontend/Dockerfile" -o -f "frontend/package.json" ] && HAS_FRONTEND_DIR=true

if [ "$HAS_BACKEND_DIR" = "true" ] || [ "$HAS_FRONTEND_DIR" = "true" ]; then
  USE_APP_PROFILES=true
  echo "    App directories detected (Docker Compose profiles will be enabled)"
fi

# 1.6 Find plugin directory
echo "  [1.5] Locating plugin templates..."
PLUGIN_ROOT=$(find_plugin_root 2>/dev/null) || {
  echo "  ERROR: Cannot locate plugin templates"
  echo "    Please ensure the sandboxxer plugin is installed"
  exit 1
}

TEMPLATES="$PLUGIN_ROOT/skills/_shared/templates"
if [ ! -f "$TEMPLATES/base.dockerfile" ]; then
  echo "  ERROR: Template not found at $TEMPLATES/base.dockerfile"
  exit 1
fi
echo "    Templates found at: $TEMPLATES"

echo "[Phase 1/4] Complete"
echo ""
```

---

## Phase 2: Configuration

Ask user questions to configure the DevContainer. Maximum 4 questions, each with 4 options.

### Question 1: Initial Setup (Conditional)

If existing configuration was detected OR frameworks were detected, ask for confirmation.

Skip this question if: `AUTO_ACCEPT=true` OR (no existing config AND no frameworks detected)

```
We detected:
${EXISTING_CONFIG_FOUND:+- Existing DevContainer configuration}
${DETECTED_JS_FRAMEWORK:+- JavaScript framework: $DETECTED_JS_FRAMEWORK}
${DETECTED_PY_FRAMEWORK:+- Python framework: $DETECTED_PY_FRAMEWORK}

How would you like to proceed?

Options:
1. Accept detected settings (Recommended)
   → Merge existing config, install framework extensions

2. Start fresh with tool selection
   → Backup saved, choose new configuration

3. Start completely fresh
   → Backup saved, no merge

4. Cancel setup
   → Exit without changes
```

Store as `INITIAL_SETUP_CHOICE`.

**Logic:**
- If `INITIAL_SETUP_CHOICE` is "Cancel setup" → exit 0
- If "Accept detected settings" → `MERGE_EXISTING=true`, `ACCEPT_FRAMEWORKS=true`
- If "Start fresh with tool selection" → `MERGE_EXISTING=false`
- If "Start completely fresh" → `MERGE_EXISTING=false`, `FRESH_ENV=true`

### Question 2: Stack Profile Selection

Main question to select development stack. Uses presets to stay within 4-option limit.

Skip this question if: `AUTO_ACCEPT=true` AND `SETTING_PROFILE` is set

```
Choose your development stack profile:

Options:
1. Minimal (Python 3.12 + Node 20)
   → Ready to code immediately, no additional tools

2. Backend Developer (+ Go, PostgreSQL)
   → APIs, microservices, database development

3. Full Stack (+ Go, Rust, PostgreSQL)
   → Multi-language backend development

4. Custom (specify tools)
   → Enter tools manually: go,rust,ruby,php,postgres
```

Store as `PROFILE_CHOICE`.

**If "Custom" selected**, Claude will prompt for free-text input:
```
Enter tools to add (comma-separated):
Available: go, rust, ruby, php, cpp-clang, cpp-gcc, postgres
Example: go,postgres
```

Store as `CUSTOM_TOOLS`.

```bash
# Process profile choice
case "$PROFILE_CHOICE" in
  "Minimal"*|"1")
    SELECTED_TOOLS=""
    echo "Selected: Minimal (base only)"
    ;;
  "Backend"*|"2")
    SELECTED_TOOLS="go,postgres"
    echo "Selected: Backend Developer (Go + PostgreSQL)"
    ;;
  "Full Stack"*|"3")
    SELECTED_TOOLS="go,rust,postgres"
    echo "Selected: Full Stack (Go + Rust + PostgreSQL)"
    ;;
  "Custom"*|"4")
    SELECTED_TOOLS="$CUSTOM_TOOLS"
    echo "Selected: Custom ($SELECTED_TOOLS)"
    ;;
esac

# Convert to array for processing
IFS=',' read -ra SELECTED_PARTIALS <<< "$SELECTED_TOOLS"
```

### Question 3: Network & Workspace

Combined security and workspace configuration.

Skip this question if: `AUTO_ACCEPT=true`

```
Security and workspace configuration:

Options:
1. Standard (no firewall, bind mount)
   → Recommended for Linux, real-time file sync

2. Secure (firewall enabled, bind mount)
   → Network restrictions with domain allowlist

3. Performance (no firewall, volume mount)
   → Recommended for Windows/macOS, better I/O

4. Maximum Security (firewall + volume mount)
   → Full restrictions with isolated storage
```

Store as `SECURITY_CHOICE`.

```bash
# Process security choice
case "$SECURITY_CHOICE" in
  "Standard"*|"1")
    NEEDS_FIREWALL="No"
    WORKSPACE_MODE="bind"
    ;;
  "Secure"*|"2")
    NEEDS_FIREWALL="Yes"
    WORKSPACE_MODE="bind"
    ;;
  "Performance"*|"3")
    NEEDS_FIREWALL="No"
    WORKSPACE_MODE="volume"
    ;;
  "Maximum"*|"4")
    NEEDS_FIREWALL="Yes"
    WORKSPACE_MODE="volume"
    ;;
esac

echo "Firewall: $NEEDS_FIREWALL, Workspace: $WORKSPACE_MODE"
```

### Question 4: Firewall Categories (Conditional)

Only asked if firewall was enabled in Question 3.

Skip this question if: `AUTO_ACCEPT=true` OR `NEEDS_FIREWALL="No"`

```
Which services should be allowed through the firewall?

Options:
1. Development essentials (Recommended)
   → npm, PyPI, GitHub, GitLab, Docker Hub

2. + Cloud services
   → Essentials + AWS, GCP, Azure

3. + All categories
   → Everything including analytics and CDNs

4. Custom domains
   → Enter your own domain allowlist
```

Store as `FIREWALL_CHOICE`.

**If "Custom domains" selected**, Claude will prompt:
```
Enter domains to allow (comma-separated):
Example: api.mycompany.com,cdn.internal.corp
```

Store as `CUSTOM_DOMAINS`.

```bash
# Process firewall choice
if [ "$NEEDS_FIREWALL" = "Yes" ]; then
  DOMAIN_CATEGORIES=$(get_firewall_categories "$FIREWALL_CHOICE")
  echo "Firewall categories: $DOMAIN_CATEGORIES"
fi
```

---

## Phase 3: Generation

Generate all DevContainer configuration files in a single unified block.

```bash
# ============================================================================
# Phase 3: Generate DevContainer Configuration
# ============================================================================

echo ""
echo "[Phase 3/4] Generation"

# Project name
RAW_PROJECT_NAME="$(basename "$(pwd)")"
PROJECT_NAME="$(sanitize_project_name "$RAW_PROJECT_NAME")"
[ "$PROJECT_NAME" != "$RAW_PROJECT_NAME" ] && echo "  Project name sanitized: '$RAW_PROJECT_NAME' → '$PROJECT_NAME'"

# Create directories
mkdir -p .devcontainer data

# 3.1 Build Dockerfile
echo "  [3.1] Building Dockerfile..."
cp "$TEMPLATES/base.dockerfile" .devcontainer/Dockerfile

# Add selected language partials
PARTIALS="$TEMPLATES/partials"
for partial in "${SELECTED_PARTIALS[@]}"; do
  [ -z "$partial" ] && continue
  partial_file="$PARTIALS/${partial}.dockerfile"
  if [ -f "$partial_file" ]; then
    cat "$partial_file" >> .devcontainer/Dockerfile
    echo "    + $partial"
  else
    echo "    WARNING: Partial not found: $partial_file"
  fi
done

echo "    Dockerfile: $(wc -l < .devcontainer/Dockerfile) lines"

# 3.2 Generate devcontainer.json
echo "  [3.2] Generating devcontainer.json..."
cp "$TEMPLATES/devcontainer.json" .devcontainer/

# Build extensions list
EXTENSIONS_TO_ADD=""
for partial in "${SELECTED_PARTIALS[@]}"; do
  case "$partial" in
    go)       EXTENSIONS_TO_ADD+=',\n        "golang.go"' ;;
    rust)     EXTENSIONS_TO_ADD+=',\n        "rust-lang.rust-analyzer"' ;;
    ruby)     EXTENSIONS_TO_ADD+=',\n        "shopify.ruby-lsp"' ;;
    php)      EXTENSIONS_TO_ADD+=',\n        "bmewburn.vscode-intelephense-client"' ;;
    cpp-*)    EXTENSIONS_TO_ADD+=',\n        "ms-vscode.cpptools",\n        "ms-vscode.cmake-tools"' ;;
    postgres) EXTENSIONS_TO_ADD+=',\n        "ckolkman.vscode-postgres"' ;;
  esac
done

# Add framework extensions
[ -n "$JS_FRAMEWORK_EXTENSIONS" ] && EXTENSIONS_TO_ADD+=",\n        \"$JS_FRAMEWORK_EXTENSIONS\""
[ -n "$PY_FRAMEWORK_EXTENSIONS" ] && EXTENSIONS_TO_ADD+=",\n        \"$PY_FRAMEWORK_EXTENSIONS\""

# Add preserved extensions
if [ "$MERGE_EXISTING" = "true" ] && [ -n "$EXISTING_EXTENSIONS" ]; then
  for ext in $EXISTING_EXTENSIONS; do
    EXTENSIONS_TO_ADD+=",\n        \"$ext\""
  done
fi

# Insert extensions
if [ -n "$EXTENSIONS_TO_ADD" ]; then
  sed "s/\"johnpapa.vscode-peacock\"/\"johnpapa.vscode-peacock\"$EXTENSIONS_TO_ADD/g" \
    .devcontainer/devcontainer.json > .devcontainer/devcontainer.json.tmp
  mv .devcontainer/devcontainer.json.tmp .devcontainer/devcontainer.json
fi

# 3.3 Generate docker-compose.yml
echo "  [3.3] Generating docker-compose.yml..."
if [ "$WORKSPACE_MODE" = "volume" ]; then
  cp "$TEMPLATES/docker-compose.volume.yml" ./docker-compose.yml
  cp "$TEMPLATES/init-volume.sh" .devcontainer/
  chmod +x .devcontainer/init-volume.sh
  echo "    Using volume mode"
elif [ "$USE_APP_PROFILES" = "true" ]; then
  cp "$TEMPLATES/docker-compose-profiles.yml" ./docker-compose.yml
  echo "    Using Docker Compose profiles"
else
  cp "$TEMPLATES/docker-compose.yml" ./docker-compose.yml
  echo "    Using bind mount mode"
fi

# Replace placeholders
for f in .devcontainer/devcontainer.json docker-compose.yml; do
  sed "s/{{PROJECT_NAME}}/$PROJECT_NAME/g; \
       s/{{APP_PORT}}/$APP_PORT/g; \
       s/{{FRONTEND_PORT}}/$FRONTEND_PORT/g; \
       s/{{POSTGRES_PORT}}/$POSTGRES_PORT/g; \
       s/{{REDIS_PORT}}/$REDIS_PORT/g" \
    "$f" > "$f.tmp" && mv "$f.tmp" "$f"
done

# 3.4 Generate firewall script
echo "  [3.4] Configuring firewall..."
if [ "$NEEDS_FIREWALL" = "Yes" ]; then
  cp "$TEMPLATES/init-firewall.sh" .devcontainer/init-firewall.sh
  chmod +x .devcontainer/init-firewall.sh
  echo "    Firewall enabled with categories: $DOMAIN_CATEGORIES"
else
  # Create no-op firewall script
  cat > .devcontainer/init-firewall.sh << 'EOF'
#!/bin/bash
# Firewall disabled - using Docker container isolation only
echo "Firewall is disabled."
exit 0
EOF
  chmod +x .devcontainer/init-firewall.sh
  echo "    Firewall disabled"
fi

# 3.5 Generate .env file
echo "  [3.5] Generating .env..."
if [ "$FRESH_ENV" != "true" ] && [ -f ".devcontainer.backup/.env.user-backup" ]; then
  cp .devcontainer.backup/.env.user-backup .env
  echo "    Preserved existing .env"
else
  cat > .env << EOF
# Environment Variables - Generated by DevContainer quickstart
APP_PORT=$APP_PORT
FRONTEND_PORT=$FRONTEND_PORT
POSTGRES_PORT=$POSTGRES_PORT
REDIS_PORT=$REDIS_PORT

# Database
POSTGRES_DB=sandbox_dev
POSTGRES_USER=sandbox_user
POSTGRES_PASSWORD=devpassword
DATABASE_URL=postgresql://\${POSTGRES_USER}:\${POSTGRES_PASSWORD}@postgres:5432/\${POSTGRES_DB}
REDIS_URL=redis://redis:6379

# API Keys (add your keys here)
ANTHROPIC_API_KEY=
OPENAI_API_KEY=
GITHUB_TOKEN=

# Build options
INSTALL_SHELL_EXTRAS=true
INSTALL_DEV_TOOLS=true
ENABLE_FIREWALL=$( [ "$NEEDS_FIREWALL" = "Yes" ] && echo "true" || echo "false" )
EOF
  echo "    Generated fresh .env"
fi

# 3.6 Copy supporting files
echo "  [3.6] Copying supporting files..."
cp "$TEMPLATES/setup-claude-credentials.sh" .devcontainer/
cp "$TEMPLATES/setup-frontend.sh" .devcontainer/
cp "$TEMPLATES/data/allowable-domains.json" data/
cp "$TEMPLATES/.env.example" ./.env.example
chmod +x .devcontainer/*.sh

# Merge existing config if requested
if [ "$MERGE_EXISTING" = "true" ]; then
  echo "  [3.7] Merging existing configuration..."

  # Merge containerEnv
  if [ "$EXISTING_CONTAINER_ENV" != "{}" ]; then
    jq --argjson existing "$EXISTING_CONTAINER_ENV" \
      '.containerEnv = ($existing + .containerEnv)' \
      .devcontainer/devcontainer.json > .devcontainer/devcontainer.json.tmp
    mv .devcontainer/devcontainer.json.tmp .devcontainer/devcontainer.json
    echo "    Merged containerEnv"
  fi

  # Merge remoteEnv
  if [ "$EXISTING_REMOTE_ENV" != "{}" ]; then
    jq --argjson existing "$EXISTING_REMOTE_ENV" \
      '.remoteEnv = ($existing + .remoteEnv)' \
      .devcontainer/devcontainer.json > .devcontainer/devcontainer.json.tmp
    mv .devcontainer/devcontainer.json.tmp .devcontainer/devcontainer.json
    echo "    Merged remoteEnv"
  fi

  # Add custom ports
  if [ -n "$EXISTING_FORWARD_PORTS" ]; then
    for port in $EXISTING_FORWARD_PORTS; do
      jq ".forwardPorts += [$port]" \
        .devcontainer/devcontainer.json > .devcontainer/devcontainer.json.tmp
      mv .devcontainer/devcontainer.json.tmp .devcontainer/devcontainer.json
    done
    echo "    Added custom ports: $EXISTING_FORWARD_PORTS"
  fi
fi

echo "[Phase 3/4] Complete"
echo ""
```

---

## Phase 4: Report

Display summary of generated configuration and next steps.

```bash
# ============================================================================
# Phase 4: Report Results
# ============================================================================

echo "[Phase 4/4] Summary"
echo ""
echo "=========================================="
echo "DevContainer Created Successfully"
echo "=========================================="
echo ""
echo "Project: $PROJECT_NAME"
echo ""
echo "Stack:"
echo "  Base: Python 3.12 + Node 20 + Claude CLI"
for partial in "${SELECTED_PARTIALS[@]}"; do
  case "$partial" in
    go)       echo "  + Go 1.22" ;;
    rust)     echo "  + Rust" ;;
    ruby)     echo "  + Ruby 3.3" ;;
    php)      echo "  + PHP 8.3" ;;
    cpp-*)    echo "  + C++ tools" ;;
    postgres) echo "  + PostgreSQL tools" ;;
  esac
done
[ -n "$DETECTED_JS_FRAMEWORK" ] && echo "  Framework: $DETECTED_JS_FRAMEWORK"
[ -n "$DETECTED_PY_FRAMEWORK" ] && echo "  Framework: $DETECTED_PY_FRAMEWORK"
echo ""
echo "Security: $([ "$NEEDS_FIREWALL" = "Yes" ] && echo "Firewall enabled" || echo "Docker isolation only")"
echo "Workspace: $([ "$WORKSPACE_MODE" = "volume" ] && echo "Volume mode" || echo "Bind mount")"
echo ""
echo "Ports:"
echo "  App:        localhost:$APP_PORT → container:8000"
echo "  Frontend:   localhost:$FRONTEND_PORT → container:3000"
echo "  PostgreSQL: localhost:$POSTGRES_PORT → container:5432"
echo "  Redis:      localhost:$REDIS_PORT → container:6379"
echo ""
echo "Files created:"
echo "  .devcontainer/Dockerfile"
echo "  .devcontainer/devcontainer.json"
echo "  .devcontainer/init-firewall.sh"
echo "  .devcontainer/setup-claude-credentials.sh"
echo "  docker-compose.yml"
echo "  .env"
echo ""
echo "Next steps:"
echo "1. Edit .env and add your API keys"
echo "2. Open this folder in VS Code"
echo "3. Click 'Reopen in Container' when prompted"
echo "4. Wait for container build (~2-5 minutes first time)"
echo ""
echo "=========================================="
```

---

## Troubleshooting

### "No space left on device" on Windows

Docker Desktop's WSL2 distro has limited root space. Fix:

```powershell
wsl --shutdown
wsl -d docker-desktop -u root -e sh -c "mkdir -p /mnt/docker-desktop-disk/vscode-remote-containers && ln -s /mnt/docker-desktop-disk/vscode-remote-containers /root/.vscode-remote-containers"
```

### initializeCommand fails on Windows

Use Docker JSON array format instead of shell scripts for `initializeCommand` in `devcontainer.json`.

### Port conflicts

Run with `--skip-validation` to skip port checks, or the command will auto-assign alternative ports.
