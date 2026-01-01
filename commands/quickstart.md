---
description: Interactive DevContainer quickstart with project type selection and firewall customization
argument-hint: ""
allowed-tools: [Bash, AskUserQuestion, Read]
---

# Interactive DevContainer Quickstart

Create a customized VS Code DevContainer configuration with:
- Project-specific base image + language tools
- Optional network firewall with domain allowlist
- All standard Claude Code sandbox features

**Quick path:** Use `/sandboxxer:yolo-vibe-maxxing` for instant setup with no questions (Python+Node, no firewall).

## Step 0: Pre-flight Validation

Run these checks before proceeding. Use `--skip-validation` to bypass.

```bash
echo "Running pre-flight checks..."
VALIDATION_FAILED=false

# Initialize port variables with defaults
APP_PORT=8000
FRONTEND_PORT=3000
POSTGRES_PORT=5432
REDIS_PORT=6379

# Check 1: Docker daemon running
if ! docker info > /dev/null 2>&1; then
  echo "ERROR: Docker is not running"
  echo "  Fix: Start Docker Desktop or run 'sudo systemctl start docker'"
  VALIDATION_FAILED=true
else
  echo "  ✓ Docker is running"
fi

# Check 2: Docker Compose available
if ! docker compose version > /dev/null 2>&1; then
  echo "ERROR: Docker Compose not found"
  echo "  Fix: Install Docker Compose v2 or update Docker Desktop"
  VALIDATION_FAILED=true
else
  echo "  ✓ Docker Compose available"
fi

# Check 3: Port availability check with conflict detection
PORT_CONFLICTS_FOUND=false
CONFLICTED=()

for port in 8000 3000 5432 6379; do
  port_in_use=false

  if command -v lsof > /dev/null 2>&1; then
    if lsof -i :$port > /dev/null 2>&1; then
      port_in_use=true
    fi
  elif command -v netstat > /dev/null 2>&1; then
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
      port_in_use=true
    fi
  fi

  if [ "$port_in_use" = "true" ]; then
    CONFLICTED+=("$port")
    PORT_CONFLICTS_FOUND=true
  fi
done

if [ "$PORT_CONFLICTS_FOUND" = "false" ]; then
  echo "  ✓ All ports available"
fi

# Check 4: Disk space (minimum 5GB recommended)
if command -v df > /dev/null 2>&1; then
  AVAILABLE_GB=$(df -BG . 2>/dev/null | tail -1 | awk '{print $4}' | tr -d 'G')
  if [ -n "$AVAILABLE_GB" ] && [ "$AVAILABLE_GB" -lt 5 ] 2>/dev/null; then
    echo "  WARNING: Low disk space (${AVAILABLE_GB}GB available, 5GB+ recommended)"
  else
    echo "  ✓ Disk space OK"
  fi
fi

# Exit if critical checks failed
if [ "$VALIDATION_FAILED" = "true" ]; then
  echo ""
  echo "Pre-flight checks failed. Please fix the errors above and try again."
  exit 1
fi

echo ""
if [ "$PORT_CONFLICTS_FOUND" = "true" ]; then
  echo "Pre-flight checks passed (with port conflicts to resolve)!"
else
  echo "Pre-flight checks passed!"
fi
echo ""
```

## Step 0.5: Port Configuration (If Conflicts Detected)

If port conflicts were detected in Step 0, resolve them automatically or interactively.

```bash
# Function to find the next available port
find_available_port() {
  local port=$1
  while lsof -i :$port > /dev/null 2>&1 || netstat -tuln 2>/dev/null | grep -q ":$port "; do
    port=$((port + 1))
  done
  echo $port
}

# Only run if conflicts were detected
if [ "$PORT_CONFLICTS_FOUND" = "true" ]; then
  echo "Port conflicts detected:"
  for port in "${CONFLICTED[@]}"; do
    case $port in
      8000) echo "  - Port 8000 (App) is in use" ;;
      3000) echo "  - Port 3000 (Frontend) is in use" ;;
      5432) echo "  - Port 5432 (PostgreSQL) is in use" ;;
      6379) echo "  - Port 6379 (Redis) is in use" ;;
    esac
  done
  echo ""

  # Auto-assign alternative ports (default behavior)
  echo "Auto-assigning alternative ports..."
  for port in "${CONFLICTED[@]}"; do
    new_port=$(find_available_port $port)
    case $port in
      8000)
        APP_PORT=$new_port
        echo "  App: 8000 → $new_port"
        ;;
      3000)
        FRONTEND_PORT=$new_port
        echo "  Frontend: 3000 → $new_port"
        ;;
      5432)
        POSTGRES_PORT=$new_port
        echo "  PostgreSQL: 5432 → $new_port"
        ;;
      6379)
        REDIS_PORT=$new_port
        echo "  Redis: 6379 → $new_port"
        ;;
    esac
  done
  echo ""
fi
```

**Note:** For interactive port selection, users can add `--interactive` flag support in the future. Currently, the command auto-assigns the next available port for any conflicts.

## Step 0.8: Detect Existing Configuration

```bash
EXISTING_CONFIG_FOUND=false
EXISTING_EXTENSIONS=""
EXISTING_CONTAINER_ENV=""
EXISTING_REMOTE_ENV=""
EXISTING_FORWARD_PORTS=""
EXISTING_POST_CREATE=""
EXISTING_POST_START=""
EXISTING_FEATURES=""
EXISTING_CUSTOM_SERVICES=""

if [ -f ".devcontainer/devcontainer.json" ]; then
  EXISTING_CONFIG_FOUND=true
  echo "Existing DevContainer configuration detected"

  # Extract custom extensions (exclude base extensions)
  EXISTING_EXTENSIONS=$(jq -r '.customizations.vscode.extensions[]?' .devcontainer/devcontainer.json 2>/dev/null | \
    grep -v "anthropic.claude-code\|ms-azuretools.vscode-docker\|ms-python.python\|ms-python.vscode-pylance\|redhat.vscode-yaml\|eamodio.gitlens\|PKief.material-icon-theme\|johnpapa.vscode-peacock" | \
    tr '\n' ' ')

  # Extract environment variables
  EXISTING_CONTAINER_ENV=$(jq -c '.containerEnv // {}' .devcontainer/devcontainer.json 2>/dev/null)
  EXISTING_REMOTE_ENV=$(jq -c '.remoteEnv // {}' .devcontainer/devcontainer.json 2>/dev/null)

  # Extract custom ports (beyond defaults)
  EXISTING_FORWARD_PORTS=$(jq -r '.forwardPorts[]?' .devcontainer/devcontainer.json 2>/dev/null | \
    grep -v "^8000$\|^3000$\|^5432$\|^6379$" | tr '\n' ' ')

  # Extract lifecycle hooks
  EXISTING_POST_CREATE=$(jq -r '.postCreateCommand // empty' .devcontainer/devcontainer.json 2>/dev/null)
  EXISTING_POST_START=$(jq -r '.postStartCommand // empty' .devcontainer/devcontainer.json 2>/dev/null)

  # Extract existing features
  EXISTING_FEATURES=$(jq -c '.features // {}' .devcontainer/devcontainer.json 2>/dev/null)

  # Backup existing configuration
  mkdir -p .devcontainer.backup
  cp -r .devcontainer/* .devcontainer.backup/ 2>/dev/null || true
  [ -f "docker-compose.yml" ] && cp docker-compose.yml .devcontainer.backup/
  [ -f ".env" ] && cp .env .devcontainer.backup/
  echo "Backed up existing configuration to .devcontainer.backup/"
fi

# Extract custom services from docker-compose.yml
if [ -f "docker-compose.yml" ]; then
  EXISTING_CUSTOM_SERVICES=$(docker compose config --services 2>/dev/null | \
    grep -v "^app$\|^postgres$\|^redis$" | tr '\n' ' ')
fi

# Report findings
if [ "$EXISTING_CONFIG_FOUND" = "true" ]; then
  echo ""
  echo "Extractable settings found:"
  [ -n "$EXISTING_EXTENSIONS" ] && echo "  - VS Code extensions: $(echo $EXISTING_EXTENSIONS | wc -w) custom"
  [ "$EXISTING_CONTAINER_ENV" != "{}" ] && echo "  - Container environment variables"
  [ -n "$EXISTING_FORWARD_PORTS" ] && echo "  - Custom ports: $EXISTING_FORWARD_PORTS"
  [ -n "$EXISTING_POST_CREATE" ] && echo "  - postCreateCommand hook"
  [ -n "$EXISTING_CUSTOM_SERVICES" ] && echo "  - Custom services: $EXISTING_CUSTOM_SERVICES"
  echo ""
fi
```

## Step 0.9: Confirm Configuration Handling

If `EXISTING_CONFIG_FOUND` is true, use AskUserQuestion:

```
Existing DevContainer configuration detected.

We can preserve these settings:
- Custom VS Code extensions
- Environment variables
- Custom port forwards
- Lifecycle hooks (postCreateCommand, etc.)
- Custom docker-compose services

Options:
1. Merge existing settings into new configuration (Recommended)
2. Start fresh (backup saved to .devcontainer.backup/)
```

Store as `CONFIG_MERGE_CHOICE`.

## Step 1: Initialize Tool Selection Tracking

```bash
# Array to track all selected partial dockerfiles OR features
SELECTED_PARTIALS=()
SELECTED_FEATURES=()

# Track which categories have been selected (to avoid duplicates in loop)
SELECTED_CATEGORIES=()

# Installation mode: "partials" (custom dockerfiles) or "features" (official Dev Container Features)
INSTALL_MODE="partials"

# Workspace mode: "bind" (default) or "volume" (better I/O on Windows/macOS)
WORKSPACE_MODE="bind"

# Pre-built image mode: "false" (default, build from scratch) or "true" (pull pre-built)
USE_PREBUILT_IMAGE="false"
```

## Step 1.5: Choose Installation Mode

Use AskUserQuestion:

```
How should additional languages be installed?

Options:
1. Dev Container Features (Recommended)
   → Uses official ghcr.io/devcontainers/features/*
   → Faster builds, maintained by community
   → Requires internet during build

2. Custom Dockerfiles (Partials)
   → Uses bundled partial dockerfiles
   → Works offline/air-gapped
   → Full control over versions
```

Store as `INSTALL_MODE_CHOICE`.

```bash
if [ "$INSTALL_MODE_CHOICE" = "Dev Container Features (Recommended)" ]; then
  INSTALL_MODE="features"
  echo "Using Dev Container Features"
else
  INSTALL_MODE="partials"
  echo "Using custom partial dockerfiles"
fi
```

## Step 1.6: Choose Pre-built Image Option

Use AskUserQuestion:

```
Do you want to use pre-built images for faster startup?

Options:
1. Build from scratch (default)
   → Full control over build process
   → Works offline
   → Takes 2-5 minutes

2. Use pre-built image
   → Instant startup (~30 seconds)
   → Requires GHCR authentication (docker login ghcr.io)
   → Will fail with 403 if not authenticated
```

Store as `PREBUILT_IMAGE_CHOICE`.

```bash
if [ "$PREBUILT_IMAGE_CHOICE" = "Use pre-built image" ]; then
  USE_PREBUILT_IMAGE="true"
  echo "Using pre-built image from GHCR"
else
  USE_PREBUILT_IMAGE="false"
  echo "Building from scratch"
fi
```

## Step 1.7: Validate GHCR Access (If Pre-built Selected)

```bash
if [ "$USE_PREBUILT_IMAGE" = "true" ]; then
  echo "Checking GHCR access..."
  PREBUILT_IMAGE="${PREBUILT_IMAGE:-ghcr.io/andrewcchoi/sandbox-maxxing/sandboxxer-base:latest}"
  if ! docker manifest inspect "$PREBUILT_IMAGE" > /dev/null 2>&1; then
    echo ""
    echo "ERROR: Cannot access pre-built image at GHCR"
    echo "  Image: $PREBUILT_IMAGE"
    echo ""
    echo "Options:"
    echo "  1. Authenticate: docker login ghcr.io"
    echo "  2. Fall back to building from scratch"
    echo ""
    exit 1
  fi
  echo "  ✓ GHCR access verified"
fi
```

## Step 1.75: Show Base Stack

```bash
echo ""
echo "[Base: Python 3.12 + Node 20]"
echo ""
```

## Step 1.8: Detect Web Frameworks

```bash
DETECTED_JS_FRAMEWORK=""
DETECTED_PY_FRAMEWORK=""
JS_FRAMEWORK_EXTENSIONS=""
PY_FRAMEWORK_EXTENSIONS=""

# Detect JavaScript frameworks from package.json
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

# Detect Python frameworks from pyproject.toml or requirements.txt
if [ -f "pyproject.toml" ]; then
  PY_DEPS=$(cat pyproject.toml)
elif [ -f "requirements.txt" ]; then
  PY_DEPS=$(cat requirements.txt)
else
  PY_DEPS=""
fi

if [ -n "$PY_DEPS" ]; then
  if echo "$PY_DEPS" | grep -qi "fastapi"; then
    DETECTED_PY_FRAMEWORK="FastAPI"
  elif echo "$PY_DEPS" | grep -qi "django"; then
    DETECTED_PY_FRAMEWORK="Django"
    PY_FRAMEWORK_EXTENSIONS="batisteo.vscode-django"
  elif echo "$PY_DEPS" | grep -qi "flask"; then
    DETECTED_PY_FRAMEWORK="Flask"
  elif echo "$PY_DEPS" | grep -qi "quart"; then
    DETECTED_PY_FRAMEWORK="Quart"
  elif echo "$PY_DEPS" | grep -qi "starlette"; then
    DETECTED_PY_FRAMEWORK="Starlette"
  fi
fi

# Report detection results
if [ -n "$DETECTED_JS_FRAMEWORK" ] || [ -n "$DETECTED_PY_FRAMEWORK" ]; then
  echo "Detected web frameworks:"
  [ -n "$DETECTED_JS_FRAMEWORK" ] && echo "  JavaScript: $DETECTED_JS_FRAMEWORK"
  [ -n "$DETECTED_PY_FRAMEWORK" ] && echo "  Python: $DETECTED_PY_FRAMEWORK"
fi

# Detect application service directories (for Docker Compose profiles - Issue #88)
HAS_BACKEND_DIR=false
HAS_FRONTEND_DIR=false

# Check for backend directory with app indicators
if [ -d "backend" ]; then
  if [ -f "backend/Dockerfile" ] || [ -f "backend/pyproject.toml" ] || [ -f "backend/package.json" ] || [ -f "backend/go.mod" ]; then
    HAS_BACKEND_DIR=true
  fi
fi

# Check for frontend directory with app indicators
if [ -d "frontend" ]; then
  if [ -f "frontend/Dockerfile" ] || [ -f "frontend/package.json" ]; then
    HAS_FRONTEND_DIR=true
  fi
fi

# Report detection
if [ "$HAS_BACKEND_DIR" = "true" ] || [ "$HAS_FRONTEND_DIR" = "true" ]; then
  echo ""
  echo "Detected application service directories:"
  [ "$HAS_BACKEND_DIR" = "true" ] && echo "  - backend/ (containerizable)"
  [ "$HAS_FRONTEND_DIR" = "true" ] && echo "  - frontend/ (containerizable)"
fi
```

## Step 1.85: Ask About Docker Compose Profiles (Issue #88)

If `HAS_BACKEND_DIR` or `HAS_FRONTEND_DIR` is true, use AskUserQuestion:

```
We detected application directories in your project:
${HAS_BACKEND_DIR:+  - backend/ (containerizable)}
${HAS_FRONTEND_DIR:+  - frontend/ (containerizable)}

Do you want to add Docker Compose profiles for containerized app services?

This enables two modes:
  • docker compose up → DevContainer + infrastructure only
  • docker compose --profile app up → Full containerized stack

Options:
1. Yes - Add app service profiles (Recommended)
   → Use when you want to test the full containerized deployment
2. No - DevContainer only
   → Use for direct development in DevContainer without containerized app services
```

Store as `APP_PROFILES_CHOICE`.

```bash
# Initialize variable
USE_APP_PROFILES=false

# Check if user wants app profiles
if [ "$APP_PROFILES_CHOICE" = "Yes - Add app service profiles (Recommended)" ]; then
  USE_APP_PROFILES=true
  echo "Will use docker-compose with app service profiles"
else
  echo "Will use standard docker-compose (DevContainer only)"
fi
```

## Step 1.9: Confirm Detected Frameworks

If `DETECTED_JS_FRAMEWORK` or `DETECTED_PY_FRAMEWORK` is set, use AskUserQuestion:

```
We detected web frameworks in your project:
${DETECTED_JS_FRAMEWORK:+  - JavaScript: $DETECTED_JS_FRAMEWORK}
${DETECTED_PY_FRAMEWORK:+  - Python: $DETECTED_PY_FRAMEWORK}

Options:
1. Accept detected frameworks (install extensions & configure ports)
2. Skip framework-specific configuration
```

Store as `FRAMEWORK_CHOICE`.

If "Accept detected frameworks":
- Add framework extensions to `FRAMEWORK_EXTENSIONS` variable
- Note: Port configuration uses existing defaults (APP_PORT=8000, FRONTEND_PORT=3000)

## Step 2: Ask About Tool Category (LOOP START)

Use AskUserQuestion:

```
What ADDITIONAL tools do you want to add to your stack?

Options:
1. Backend language (Go, Rust, Java, Ruby, PHP)
   → Add a compiled backend language alongside Python

2. Database tools (PostgreSQL client + extensions)
   → PostgreSQL client, dev libraries, pgvector

3. C++ development
   → Clang 17 or GCC compiler toolchain

4. Web framework support (React, Vue, Django, FastAPI, etc.)
   → Install framework-specific VS Code extensions

5. None - use base only
   → Just Python 3.12 + Node 20 - ready to code!
```

Store as `TOOL_CATEGORY`.

- If "Backend language" → continue to Step 3
- If "Database tools" → add "postgres" to SELECTED_PARTIALS, go to Step 6
- If "C++ development" → continue to Step 4
- If "Web framework support" → continue to Step 5
- If "None - use base only" → skip to Step 7 (Find Plugin Directory)

## Step 3: Backend Language Selection

Use AskUserQuestion:

```
Which backend language?

Options:
1. Go (Go 1.22 + linters)
2. Rust (Rust toolchain + Cargo)
3. Java (OpenJDK 21, Maven, Gradle)
4. More languages...
```

Store as `BACKEND_CHOICE`.

```bash
case "$BACKEND_CHOICE" in
  "Go")
    SELECTED_PARTIALS+=("go")
    SELECTED_FEATURES+=("ghcr.io/devcontainers/features/go:1")
    echo "Selected: Go toolchain"
    ;;
  "Rust")
    SELECTED_PARTIALS+=("rust")
    SELECTED_FEATURES+=("ghcr.io/devcontainers/features/rust:1")
    echo "Selected: Rust toolchain"
    ;;
  "Java")
    SELECTED_PARTIALS+=("java")
    SELECTED_FEATURES+=("ghcr.io/devcontainers/features/java:1")
    echo "Selected: Java toolchain"
    ;;
  "More languages...")
    # Continue to Step 3b
    ;;
esac
```

If "More languages..." selected, continue to Step 3b. Otherwise, skip to Step 6.

### Step 3b: Additional Backend Languages

Use AskUserQuestion:

```
Which additional language?

Options:
1. Ruby (Ruby 3.3 + bundler)
2. PHP (PHP 8.3 + Composer)
3. Back to main menu
```

Store as `MORE_BACKEND_CHOICE`.

```bash
case "$MORE_BACKEND_CHOICE" in
  "Ruby")
    SELECTED_PARTIALS+=("ruby")
    SELECTED_FEATURES+=("ghcr.io/devcontainers/features/ruby:1")
    echo "Selected: Ruby toolchain"
    ;;
  "PHP")
    SELECTED_PARTIALS+=("php")
    SELECTED_FEATURES+=("ghcr.io/devcontainers/features/php:1")
    echo "Selected: PHP toolchain"
    ;;
  "Back to main menu")
    # Return to Step 2
    ;;
esac
```

Continue to Step 6.

## Step 4: C++ Compiler Selection

Use AskUserQuestion:

```
Which C++ compiler?

Options:
1. Clang 17 (recommended for modern C++)
2. GCC (traditional, wider compatibility)
```

Store as `CPP_COMPILER`.

```bash
case "$CPP_COMPILER" in
  "Clang 17")
    SELECTED_PARTIALS+=("cpp-clang")
    SELECTED_FEATURES+=("ghcr.io/devcontainers-community/features/llvm:3")
    echo "Selected: C++ with Clang 17"
    ;;
  "GCC")
    SELECTED_PARTIALS+=("cpp-gcc")
    # Note: No official GCC feature, using partial dockerfile
    INSTALL_MODE="partials"
    echo "Selected: C++ with GCC (using partial dockerfile)"
    ;;
esac
```

Continue to Step 6.

## Step 5: Web Framework Selection

Use AskUserQuestion:

```
Which web framework(s) are you using?

Options:
1. React / Next.js
2. Vue
3. Svelte
4. Angular
5. FastAPI / Starlette
6. Django
7. Flask / Quart
8. None / Other
```

Store as `WEB_FRAMEWORK_CHOICE`.

```bash
case "$WEB_FRAMEWORK_CHOICE" in
  "React / Next.js")
    FRAMEWORK_EXTENSIONS="dsznajder.es7-react-js-snippets"
    echo "Selected: React/Next.js"
    ;;
  "Vue")
    FRAMEWORK_EXTENSIONS="Vue.volar"
    echo "Selected: Vue"
    ;;
  "Svelte")
    FRAMEWORK_EXTENSIONS="svelte.svelte-vscode"
    echo "Selected: Svelte"
    ;;
  "Angular")
    FRAMEWORK_EXTENSIONS="Angular.ng-template"
    echo "Selected: Angular"
    ;;
  "FastAPI / Starlette")
    echo "Selected: FastAPI/Starlette (Python extensions already included)"
    ;;
  "Django")
    FRAMEWORK_EXTENSIONS="batisteo.vscode-django"
    echo "Selected: Django"
    ;;
  "Flask / Quart")
    echo "Selected: Flask/Quart (Python extensions already included)"
    ;;
esac
```

Continue to Step 6.

## Step 6: Add More Tools?

Use AskUserQuestion:

```
Add more tools to your stack?

Options:
1. Yes - add another tool category
2. No - continue to firewall setup
```

Store as `ADD_MORE`.

- If "Yes - add another tool category" → return to Step 2 (loop back)
- If "No - continue to firewall setup" → continue to Step 7

**Note:** Before looping back to Step 2, skip categories already selected to avoid duplicates.

## Step 7: Ask About Network Security

Use AskUserQuestion:

```
Do you need network restrictions?

Options:
1. No - Allow all outbound traffic (fastest setup)
2. Yes - Restrict to allowed domains only (more secure)
```

Store the answer as `NEEDS_FIREWALL`.

## Step 8: Domain Categories (If Firewall Enabled)

If `NEEDS_FIREWALL` is "Yes", read `/skills/_shared/data/allowable-domains.json` and present domain categories:

```
Which domain categories should be allowed?

Options (multiple choice):
- Package managers (npm, PyPI, etc.)
- Version control (GitHub, GitLab, BitBucket)
- Container registries (Docker Hub, GHCR)
- Cloud platforms (AWS, GCP, Azure)
- Development tools (Kubernetes, HashiCorp)
- VS Code extensions
- Analytics/telemetry
```

Store selections as `DOMAIN_CATEGORIES` array.

Optionally ask:
```
Any custom domains to allow? (comma-separated)
```

Store as `CUSTOM_DOMAINS`.

## Step 9: Find Plugin Directory

```bash
# Disable history expansion (fixes ! in Windows paths)
set +H 2>/dev/null || true

# Handle Windows paths - convert backslashes to forward slashes
PLUGIN_ROOT=""
if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ]; then
  PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT//\\//}";
  echo "Using CLAUDE_PLUGIN_ROOT: $PLUGIN_ROOT";
elif [ -f "skills/_shared/templates/base.dockerfile" ]; then
  PLUGIN_ROOT=".";
  echo "Using current directory as plugin root";
elif [ -d "$HOME/.claude/plugins" ]; then
  PLUGIN_JSON=$(find "$HOME/.claude/plugins" -type f -name "plugin.json" \
    -exec grep -l '"name": "sandboxxer"' {} \; 2>/dev/null | head -1);
  if [ -n "$PLUGIN_JSON" ]; then
    PLUGIN_ROOT=$(dirname "$(dirname "$PLUGIN_JSON")");
    echo "Found installed plugin: $PLUGIN_ROOT";
  fi;
fi

[ -z "$PLUGIN_ROOT" ] && { echo "ERROR: Cannot locate plugin templates"; exit 1; }
```

## Step 10: Build Dockerfile

```bash
PROJECT_NAME="$(basename $(pwd))"
TEMPLATES="$PLUGIN_ROOT/skills/_shared/templates"
PARTIALS="$TEMPLATES/partials"

# Create directories
mkdir -p .devcontainer data

# Copy base dockerfile (includes Python 3.12 + Node 20)
cp "$TEMPLATES/base.dockerfile" .devcontainer/Dockerfile
echo "Base image: Python 3.12 + Node 20"

# Handle tool installation based on mode
if [ "$INSTALL_MODE" = "features" ]; then
  # Features mode: tools installed via devcontainer.json features section
  echo "Installation mode: Dev Container Features";
  if [ ${#SELECTED_FEATURES[@]} -gt 0 ]; then
    echo "Selected features:";
    for feature in "${SELECTED_FEATURES[@]}"; do
      echo "  ✓ $feature";
    done;
  else
    echo "Using base image only (no additional features)";
  fi;
else
  # Partials mode: append partial dockerfiles
  echo "Installation mode: Partial Dockerfiles";
  if [ ${#SELECTED_PARTIALS[@]} -gt 0 ]; then
    echo "Adding selected tools...";
    for partial in "${SELECTED_PARTIALS[@]}"; do
      cat "$PARTIALS/${partial}.dockerfile" >> .devcontainer/Dockerfile;

      # Echo friendly message based on partial
      case "$partial" in
        "go")
          echo "  ✓ Go toolchain";
          ;;
        "ruby")
          echo "  ✓ Ruby toolchain";
          ;;
        "rust")
          echo "  ✓ Rust toolchain";
          ;;
        "java")
          echo "  ✓ Java toolchain";
          ;;
        "cpp-clang")
          echo "  ✓ C++ (Clang 17)";
          ;;
        "cpp-gcc")
          echo "  ✓ C++ (GCC)";
          ;;
        "php")
          echo "  ✓ PHP 8.3";
          ;;
        "postgres")
          echo "  ✓ PostgreSQL development tools";
          ;;
      esac;
    done;
  else
    echo "Using base image only (no additional tools)";
  fi;
fi

# Show final stack summary
echo ""
echo "Your DevContainer stack:"
echo "  - Python 3.12"
echo "  - Node 20"
for partial in "${SELECTED_PARTIALS[@]}"; do
  case "$partial" in
    "go") echo "  - Go 1.22" ;;
    "ruby") echo "  - Ruby 3.3" ;;
    "rust") echo "  - Rust" ;;
    "java") echo "  - Java (OpenJDK 21)" ;;
    "cpp-clang") echo "  - C++ (Clang 17)" ;;
    "cpp-gcc") echo "  - C++ (GCC)" ;;
    "php") echo "  - PHP 8.3" ;;
    "postgres") echo "  - PostgreSQL tools" ;;
  esac;
done
echo ""
```

## Step 11: Generate Firewall Script

```bash
if [ "$NEEDS_FIREWALL" = "Yes" ]; then
  # Update .env to enable firewall
  sed -i 's/ENABLE_FIREWALL=false/ENABLE_FIREWALL=true/' .env || \
    sed 's/ENABLE_FIREWALL=false/ENABLE_FIREWALL=true/' .env > .env.tmp && mv .env.tmp .env

  # Generate firewall script from selected categories
  cp "$TEMPLATES/init-firewall.sh" .devcontainer/init-firewall.sh;

  # Read allowable-domains.json and build domain list from selected categories
  DOMAINS_JSON="$TEMPLATES/data/allowable-domains.json";

  # Build ALLOWED_DOMAINS array from selected categories
  FIREWALL_DOMAINS="";

  for category in "${DOMAIN_CATEGORIES[@]}"; do
    case "$category" in
      "Package managers")
        # Add npm and python by default (basic subcategories)
        FIREWALL_DOMAINS+=$(jq -r '.categories.package_managers.sub_categories.npm.domains[]' "$DOMAINS_JSON" | sed 's/^/  "/;s/$/"/' | tr '\n' '\n');
        FIREWALL_DOMAINS+="\n";
        FIREWALL_DOMAINS+=$(jq -r '.categories.package_managers.sub_categories.python.domains[]' "$DOMAINS_JSON" | sed 's/^/  "/;s/$/"/' | tr '\n' '\n');
        ;;
      "Version control")
        FIREWALL_DOMAINS+=$(jq -r '.categories.version_control.domains[]' "$DOMAINS_JSON" | sed 's/^/  "/;s/$/"/' | tr '\n' '\n');
        ;;
      "Container registries")
        FIREWALL_DOMAINS+=$(jq -r '.categories.container_registries.domains[]' "$DOMAINS_JSON" | sed 's/^/  "/;s/$/"/' | tr '\n' '\n');
        ;;
      "Cloud platforms")
        FIREWALL_DOMAINS+=$(jq -r '.categories.cloud_platforms.sub_categories | to_entries[].value.domains[]' "$DOMAINS_JSON" | sed 's/^/  "/;s/$/"/' | tr '\n' '\n');
        ;;
      "Development tools")
        FIREWALL_DOMAINS+=$(jq -r '.categories.development_tools.domains[]' "$DOMAINS_JSON" | sed 's/^/  "/;s/$/"/' | tr '\n' '\n');
        ;;
      "VS Code extensions")
        FIREWALL_DOMAINS+=$(jq -r '.categories.vscode.domains[]' "$DOMAINS_JSON" | sed 's/^/  "/;s/$/"/' | tr '\n' '\n');
        ;;
      "Analytics/telemetry")
        FIREWALL_DOMAINS+=$(jq -r '.categories.analytics_telemetry.domains[]' "$DOMAINS_JSON" | sed 's/^/  "/;s/$/"/' | tr '\n' '\n');
        ;;
    esac;
  done;

  # Add language-specific package manager domains based on SELECTED_PARTIALS
  for partial in "${SELECTED_PARTIALS[@]}"; do
    case "$partial" in
      "go")
        echo "Adding Go domains for selected language...";
        FIREWALL_DOMAINS+=$(jq -r '.categories.package_managers.sub_categories.go.domains[]' "$DOMAINS_JSON" | sed 's/^/  "/;s/$/"/');
        FIREWALL_DOMAINS+="\n";
        ;;
      "rust")
        echo "Adding Rust domains for selected language...";
        FIREWALL_DOMAINS+=$(jq -r '.categories.package_managers.sub_categories.rust.domains[]' "$DOMAINS_JSON" | sed 's/^/  "/;s/$/"/');
        FIREWALL_DOMAINS+="\n";
        ;;
      "ruby")
        echo "Adding Ruby domains for selected language...";
        FIREWALL_DOMAINS+=$(jq -r '.categories.package_managers.sub_categories.ruby.domains[]' "$DOMAINS_JSON" | sed 's/^/  "/;s/$/"/');
        FIREWALL_DOMAINS+="\n";
        ;;
      "java")
        echo "Adding Maven/Java domains for selected language...";
        FIREWALL_DOMAINS+=$(jq -r '.categories.package_managers.sub_categories.maven.domains[]' "$DOMAINS_JSON" | sed 's/^/  "/;s/$/"/');
        FIREWALL_DOMAINS+="\n";
        ;;
      "php")
        echo "Adding PHP domains for selected language...";
        FIREWALL_DOMAINS+=$(jq -r '.categories.package_managers.sub_categories.php.domains[]' "$DOMAINS_JSON" | sed 's/^/  "/;s/$/"/');
        FIREWALL_DOMAINS+="\n";
        ;;
    esac;
  done;

  # Add Anthropic services (always required)
  ANTHROPIC_DOMAINS=$(jq -r '.categories.anthropic_services.domains[]' "$DOMAINS_JSON" | sed 's/^/  "/;s/$/"/');

  # Add Linux distributions (always required)
  LINUX_DOMAINS=$(jq -r '.categories.linux_distributions.domains[]' "$DOMAINS_JSON" | sed 's/^/  "/;s/$/"/');

  # Add custom domains if provided
  CUSTOM_DOMAIN_LIST="";
  if [ -n "${CUSTOM_DOMAINS:-}" ]; then
    for domain in $(echo "$CUSTOM_DOMAINS" | tr ',' '\n'); do
      CUSTOM_DOMAIN_LIST+="  \"$(echo $domain | xargs)\"\n";
    done;
  fi;

  echo "Firewall: Strict mode with domain allowlist";
  echo "  Categories: ${DOMAIN_CATEGORIES[*]}";
else
  # Create minimal no-op firewall script (Dockerfile always expects it)
  cat > .devcontainer/init-firewall.sh << 'NOOP_EOF'
#!/bin/bash
# Firewall disabled - this is a no-op script
# The Dockerfile requires this file to exist even when firewall is not enabled
echo "Firewall is disabled. Using Docker container isolation only."
exit 0
NOOP_EOF
  chmod +x .devcontainer/init-firewall.sh;
  echo "Firewall: Disabled (Docker isolation only)";
fi
```

## Step 11.5: Workspace Mode Selection

Use AskUserQuestion:

```
Which workspace mode do you prefer?

Options:
1. Bind mount (default)
   → Real-time file sync between host and container
   → Best for Linux hosts
   → Works seamlessly with all development workflows

2. Volume mode
   → Isolated Docker volume for better I/O performance
   → Recommended for Windows/macOS hosts
   → Trade-off: Files exist only in container
```

Store as `WORKSPACE_MODE_CHOICE`.

```bash
case "$WORKSPACE_MODE_CHOICE" in
  "Volume mode")
    WORKSPACE_MODE="volume";
    echo "Using volume mode for better Windows/macOS performance";
    ;;
  *)
    WORKSPACE_MODE="bind";
    echo "Using bind mount mode (default)";
    ;;
esac
```

## Step 12: Copy Other Templates

```bash
# Copy devcontainer config
cp "$TEMPLATES/devcontainer.json" .devcontainer/

# Copy docker-compose based on modes (pre-built takes precedence)
if [ "$USE_PREBUILT_IMAGE" = "true" ]; then
  cp "$TEMPLATES/docker-compose.prebuilt.yml" ./docker-compose.yml;
  echo "Using docker-compose.prebuilt.yml (pre-built image mode)";
elif [ "$WORKSPACE_MODE" = "volume" ]; then
  cp "$TEMPLATES/docker-compose.volume.yml" ./docker-compose.yml;
  echo "Using docker-compose.volume.yml (volume mode)";
  # Copy volume initialization script for volume mode
  cp "$TEMPLATES/init-volume.sh" .devcontainer/;
  chmod +x .devcontainer/init-volume.sh;
  echo "Copied volume initialization script";
elif [ "$USE_APP_PROFILES" = "true" ]; then
  cp "$TEMPLATES/docker-compose-profiles.yml" ./docker-compose.yml;
  echo "Using docker-compose-profiles.yml (with app service profiles)";
else
  cp "$TEMPLATES/docker-compose.yml" ./docker-compose.yml;
  echo "Using docker-compose.yml (bind mount mode)";
fi

# Copy credential setup script
cp "$TEMPLATES/setup-claude-credentials.sh" .devcontainer/
cp "$TEMPLATES/setup-frontend.sh" .devcontainer/

# Copy data files
cp "$TEMPLATES/data/allowable-domains.json" data/

# Copy .env.example (user should copy to .env and customize)
cp "$TEMPLATES/.env.example" ./.env.example

# Replace placeholders (portable sed without -i)
for f in .devcontainer/devcontainer.json docker-compose.yml; do
  sed "s/{{PROJECT_NAME}}/$PROJECT_NAME/g; \
       s/{{APP_PORT}}/$APP_PORT/g; \
       s/{{FRONTEND_PORT}}/$FRONTEND_PORT/g; \
       s/{{POSTGRES_PORT}}/$POSTGRES_PORT/g; \
       s/{{REDIS_PORT}}/$REDIS_PORT/g" \
    "$f" > "$f.tmp" && mv "$f.tmp" "$f";
done

# Generate .env file with configured ports
cat > .env << EOF
# ============================================================================
# Environment Variables
# ============================================================================
# Generated by DevContainer quickstart
# Edit these values as needed for your project
# ============================================================================

# ----------------------------------------------------------------------------
# Port Configuration
# ----------------------------------------------------------------------------
APP_PORT=$APP_PORT
FRONTEND_PORT=$FRONTEND_PORT
POSTGRES_PORT=$POSTGRES_PORT
REDIS_PORT=$REDIS_PORT

# ----------------------------------------------------------------------------
# Database Configuration
# ----------------------------------------------------------------------------
POSTGRES_DB=devdb
POSTGRES_USER=devuser
POSTGRES_PASSWORD=devpassword

# Database URLs (for application use)
DATABASE_URL=postgresql://\${POSTGRES_USER}:\${POSTGRES_PASSWORD}@postgres:5432/\${POSTGRES_DB}
REDIS_URL=redis://redis:6379

# ----------------------------------------------------------------------------
# API Keys
# ----------------------------------------------------------------------------
# Add your API keys here (do not commit to git!)
ANTHROPIC_API_KEY=
OPENAI_API_KEY=
GITHUB_TOKEN=

# ----------------------------------------------------------------------------
# Build Configuration
# ----------------------------------------------------------------------------
INSTALL_SHELL_EXTRAS=true
INSTALL_DEV_TOOLS=true
INSTALL_CA_CERT=false
ENABLE_FIREWALL=false
EOF
echo "Generated .env file with port configuration"

# Configure volume initialization for volume mode
if [ "$WORKSPACE_MODE" = "volume" ]; then
  # Use Docker array command (bypasses host shell, works on Windows/Mac/Linux)
  VOLUME_NAME="${PROJECT_NAME}-workspace-volume";
  INIT_CMD='["docker", "run", "--rm", "-v", ".:/source:ro", "-v", "'$VOLUME_NAME':/dest", "alpine", "sh", "-c", "cp -a /source/. /dest/ 2>/dev/null || true"]';
  sed 's/"initializeCommand": ""/"initializeCommand": '"$(echo "$INIT_CMD" | sed 's/\//\\\//g')"'/g' \
    .devcontainer/devcontainer.json > .devcontainer/devcontainer.json.tmp && \
    mv .devcontainer/devcontainer.json.tmp .devcontainer/devcontainer.json;
  echo "Configured initializeCommand for volume mode";
fi

# Add features to devcontainer.json if in features mode
if [ "$INSTALL_MODE" = "features" ] && [ ${#SELECTED_FEATURES[@]} -gt 0 ]; then
  # Build features JSON object
  FEATURES_JSON="{";
  for i in "${!SELECTED_FEATURES[@]}"; do
    if [ $i -gt 0 ]; then
      FEATURES_JSON+=",";
    fi;
    FEATURES_JSON+="\n    \"${SELECTED_FEATURES[$i]}\": {}";
  done;
  FEATURES_JSON+="\n  }";

  # Replace empty features object with populated one
  sed "s/\"features\": {}/\"features\": $FEATURES_JSON/g" \
    .devcontainer/devcontainer.json > .devcontainer/devcontainer.json.tmp && \
    mv .devcontainer/devcontainer.json.tmp .devcontainer/devcontainer.json;
  echo "Added Dev Container Features to devcontainer.json";
fi

# Add language-specific VS Code extensions based on selected partials
EXTENSIONS_TO_ADD=""
for partial in "${SELECTED_PARTIALS[@]}"; do
  case "$partial" in
    "go")
      EXTENSIONS_TO_ADD+=',\n        "golang.go"';
      ;;
    "rust")
      EXTENSIONS_TO_ADD+=',\n        "rust-lang.rust-analyzer"';
      ;;
    "java")
      EXTENSIONS_TO_ADD+=',\n        "redhat.java",\n        "vscjava.vscode-java-pack"';
      ;;
    "ruby")
      EXTENSIONS_TO_ADD+=',\n        "shopify.ruby-lsp"';
      ;;
    "php")
      EXTENSIONS_TO_ADD+=',\n        "bmewburn.vscode-intelephense-client"';
      ;;
    "cpp-clang"|"cpp-gcc")
      EXTENSIONS_TO_ADD+=',\n        "ms-vscode.cpptools",\n        "ms-vscode.cmake-tools"';
      ;;
    "postgres")
      EXTENSIONS_TO_ADD+=',\n        "ckolkman.vscode-postgres"';
      ;;
  esac;
done

# Add framework-specific extensions
if [ -n "$FRAMEWORK_EXTENSIONS" ]; then
  for ext in $FRAMEWORK_EXTENSIONS; do
    EXTENSIONS_TO_ADD+=',\n        "'"$ext"'"'
  done
  echo "Added framework extensions: $FRAMEWORK_EXTENSIONS"
fi

# Also add auto-detected framework extensions
if [ -n "$JS_FRAMEWORK_EXTENSIONS" ]; then
  EXTENSIONS_TO_ADD+=',\n        "'"$JS_FRAMEWORK_EXTENSIONS"'"'
fi
if [ -n "$PY_FRAMEWORK_EXTENSIONS" ]; then
  EXTENSIONS_TO_ADD+=',\n        "'"$PY_FRAMEWORK_EXTENSIONS"'"'
fi

# Merge preserved extensions from existing config
if [ "$CONFIG_MERGE_CHOICE" = "Merge existing settings into new configuration (Recommended)" ] && [ -n "$EXISTING_EXTENSIONS" ]; then
  for ext in $EXISTING_EXTENSIONS; do
    EXTENSIONS_TO_ADD+=',\n        "'"$ext"'"'
  done
  echo "Preserved $(echo $EXISTING_EXTENSIONS | wc -w) custom extensions from existing config"
fi

# Insert extensions before the closing bracket of extensions array
if [ -n "$EXTENSIONS_TO_ADD" ]; then
  sed "s/\"johnpapa.vscode-peacock\"/\"johnpapa.vscode-peacock\"$EXTENSIONS_TO_ADD/g" \
    .devcontainer/devcontainer.json > .devcontainer/devcontainer.json.tmp && \
    mv .devcontainer/devcontainer.json.tmp .devcontainer/devcontainer.json;
  echo "Added language-specific VS Code extensions";
fi

# Merge preserved environment variables and settings
if [ "$CONFIG_MERGE_CHOICE" = "Merge existing settings into new configuration (Recommended)" ]; then

  # Merge containerEnv (existing values, new takes precedence on conflict)
  if [ "$EXISTING_CONTAINER_ENV" != "{}" ]; then
    jq --argjson existing "$EXISTING_CONTAINER_ENV" \
      '.containerEnv = ($existing + .containerEnv)' \
      .devcontainer/devcontainer.json > .devcontainer/devcontainer.json.tmp
    mv .devcontainer/devcontainer.json.tmp .devcontainer/devcontainer.json
    echo "Merged existing containerEnv variables"
  fi

  # Merge remoteEnv
  if [ "$EXISTING_REMOTE_ENV" != "{}" ]; then
    jq --argjson existing "$EXISTING_REMOTE_ENV" \
      '.remoteEnv = ($existing + .remoteEnv)' \
      .devcontainer/devcontainer.json > .devcontainer/devcontainer.json.tmp
    mv .devcontainer/devcontainer.json.tmp .devcontainer/devcontainer.json
    echo "Merged existing remoteEnv variables"
  fi

  # Add custom forward ports
  if [ -n "$EXISTING_FORWARD_PORTS" ]; then
    for port in $EXISTING_FORWARD_PORTS; do
      jq ".forwardPorts += [$port]" \
        .devcontainer/devcontainer.json > .devcontainer/devcontainer.json.tmp
      mv .devcontainer/devcontainer.json.tmp .devcontainer/devcontainer.json
    done
    echo "Added custom ports: $EXISTING_FORWARD_PORTS"
  fi

  # Chain postCreateCommand (run new setup, then existing)
  if [ -n "$EXISTING_POST_CREATE" ] && [ "$EXISTING_POST_CREATE" != ".devcontainer/setup-claude-credentials.sh" ]; then
    CHAINED_POST_CREATE=".devcontainer/setup-claude-credentials.sh && $EXISTING_POST_CREATE"
    jq --arg cmd "$CHAINED_POST_CREATE" '.postCreateCommand = $cmd' \
      .devcontainer/devcontainer.json > .devcontainer/devcontainer.json.tmp
    mv .devcontainer/devcontainer.json.tmp .devcontainer/devcontainer.json
    echo "Chained existing postCreateCommand"
  fi

  # Merge existing features
  if [ "$EXISTING_FEATURES" != "{}" ]; then
    jq --argjson existing "$EXISTING_FEATURES" \
      '.features = (.features + $existing)' \
      .devcontainer/devcontainer.json > .devcontainer/devcontainer.json.tmp
    mv .devcontainer/devcontainer.json.tmp .devcontainer/devcontainer.json
    echo "Merged existing Dev Container Features"
  fi

  # Preserve .env values (API keys, custom vars)
  if [ -f ".devcontainer.backup/.env" ]; then
    while IFS='=' read -r key value; do
      # Skip empty lines and comments
      [[ -z "$key" || "$key" =~ ^# ]] && continue
      # Only preserve non-empty values that aren't in new .env
      if [ -n "$value" ] && ! grep -q "^${key}=" .env 2>/dev/null; then
        echo "${key}=${value}" >> .env
      fi
    done < .devcontainer.backup/.env
    echo "Preserved existing .env values"
  fi
fi

# Set permissions
chmod +x .devcontainer/*.sh
```

## Step 13: Report Results

```bash
echo "=========================================="
echo "DevContainer Created Successfully"
echo "=========================================="
echo "Project: $PROJECT_NAME"
echo ""
echo "Your Stack:"
echo "  Base: Python 3.12 + Node 20"
if [ ${#SELECTED_PARTIALS[@]} -gt 0 ]; then
  for partial in "${SELECTED_PARTIALS[@]}"; do
    case "$partial" in
      "go") echo "  + Go 1.22" ;;
      "ruby") echo "  + Ruby 3.3" ;;
      "rust") echo "  + Rust" ;;
      "java") echo "  + Java (OpenJDK 21)" ;;
      "cpp-clang") echo "  + C++ (Clang 17)" ;;
      "cpp-gcc") echo "  + C++ (GCC)" ;;
      "php") echo "  + PHP 8.3" ;;
      "postgres") echo "  + PostgreSQL tools" ;;
    esac;
  done;
fi
if [ -n "$DETECTED_JS_FRAMEWORK" ] || [ -n "$WEB_FRAMEWORK_CHOICE" ]; then
  echo "  Framework: ${DETECTED_JS_FRAMEWORK:-$WEB_FRAMEWORK_CHOICE}"
fi
if [ -n "$DETECTED_PY_FRAMEWORK" ]; then
  echo "  Framework: $DETECTED_PY_FRAMEWORK"
fi
echo ""
echo "Firewall: $([ "$NEEDS_FIREWALL" = "Yes" ] && echo "Enabled (strict allowlist)" || echo "Disabled (Docker isolation only)")"
echo ""

# Report merged settings
if [ "$CONFIG_MERGE_CHOICE" = "Merge existing settings into new configuration (Recommended)" ]; then
  echo "Merged from existing configuration:"
  [ -n "$EXISTING_EXTENSIONS" ] && echo "  - $(echo $EXISTING_EXTENSIONS | wc -w) custom VS Code extensions"
  [ "$EXISTING_CONTAINER_ENV" != "{}" ] && echo "  - Container environment variables"
  [ -n "$EXISTING_FORWARD_PORTS" ] && echo "  - Custom ports: $EXISTING_FORWARD_PORTS"
  [ -n "$EXISTING_POST_CREATE" ] && echo "  - postCreateCommand hook (chained)"
  echo "  - Backup saved to .devcontainer.backup/"
fi
echo ""
echo "Port Configuration:"
echo "  App:        localhost:$APP_PORT -> container:8000"
echo "  Frontend:   localhost:$FRONTEND_PORT -> container:3000"
echo "  PostgreSQL: localhost:$POSTGRES_PORT -> container:5432"
echo "  Redis:      localhost:$REDIS_PORT -> container:6379"
if [ "$PORT_CONFLICTS_FOUND" = "true" ]; then
  echo "  Note: Alternative ports assigned due to conflicts"
fi
echo ""
echo "Files created:"
echo "  .devcontainer/Dockerfile"
echo "  .devcontainer/devcontainer.json"
if [ "$NEEDS_FIREWALL" = "Yes" ]; then
  echo "  .devcontainer/init-firewall.sh";
fi
echo "  .devcontainer/setup-claude-credentials.sh"
echo "  .devcontainer/setup-frontend.sh"
echo "  docker-compose.yml"
echo "  data/allowable-domains.json"
echo "  .env.example"
echo "  .env (with configured ports)"
echo ""
echo "Next steps:"
echo "1. Edit .env and add your API keys (ANTHROPIC_API_KEY, etc.)"
echo "2. Open this folder in VS Code"
echo "3. Click 'Reopen in Container' when prompted"
echo "4. Wait for container to build (~2-5 minutes first time)"
echo ""
echo "After container starts, access your services at:"
echo "  - App:        http://localhost:$APP_PORT"
echo "  - Frontend:   http://localhost:$FRONTEND_PORT"
echo "  - PostgreSQL: localhost:$POSTGRES_PORT"
echo "  - Redis:      localhost:$REDIS_PORT"
echo "=========================================="
```

## Troubleshooting

### "No space left on device" Error on Windows

**Symptom:** VS Code fails to open Dev Container with error:
```
tar: write error: No space left on device
Could not connect to WSL.
```

**Cause:** Docker Desktop's `docker-desktop` WSL distro has a small 129MB root partition that fills up when VS Code installs its server binaries (~60MB).

**Solution:** Create a symlink to redirect VS Code Server to the larger data disk:

```powershell
# 1. Shutdown WSL
wsl --shutdown

# 2. Create symlink (run in PowerShell)
wsl -d docker-desktop -u root -e sh -c "mkdir -p /mnt/docker-desktop-disk/vscode-remote-containers && ln -s /mnt/docker-desktop-disk/vscode-remote-containers /root/.vscode-remote-containers"

# 3. Verify symlink was created
wsl -d docker-desktop -e sh -c "ls -la /root/.vscode-remote-containers"
# Should show: .vscode-remote-containers -> /mnt/docker-desktop-disk/vscode-remote-containers
```

**Note:** This symlink may need to be recreated after Docker Desktop updates or factory resets. If the disk becomes corrupted (read-only filesystem), you may need to fully unregister and recreate the distros:

```powershell
# Close Docker Desktop first (Quit from system tray)
wsl --shutdown
wsl --unregister docker-desktop
wsl --unregister docker-desktop-data
# Start Docker Desktop again to recreate distros, then apply the symlink fix above
```

### initializeCommand Fails on Windows

**Symptom:** Error during Dev Container startup:
```
'.devcontainer' is not recognized as an internal or external command
```

**Cause:** `initializeCommand` is set to a shell script path like `".devcontainer/init-volume.sh"`, but Windows `cmd.exe` cannot execute shell scripts.

**Solution:** Use Docker JSON array format for cross-platform compatibility:

**Instead of:**
```json
"initializeCommand": ".devcontainer/init-volume.sh"
```

**Use:**
```json
"initializeCommand": ["docker", "run", "--rm", "-v", ".:/source:ro", "-v", "YOUR-PROJECT-workspace-volume:/dest", "alpine", "sh", "-c", "cp -a /source/. /dest/ 2>/dev/null || true"]
```

Replace `YOUR-PROJECT` with your project name. This approach bypasses the host shell entirely and works on Windows, macOS, and Linux.

---

**Last Updated:** 2025-12-25
**Version:** 4.6.0
