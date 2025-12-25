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

**Quick path:** Use `/devcontainer:yolo-vibe-maxxing` for instant setup with no questions (Python+Node, no firewall).

## Step 0: Pre-flight Validation

Run these checks before proceeding. Use `--skip-validation` to bypass.

```bash
echo "Running pre-flight checks..."
VALIDATION_FAILED=false

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

# Check 3: Required ports available (warn only, don't fail)
PORTS_TO_CHECK="8000 3000 5432 6379"
for port in $PORTS_TO_CHECK; do
  if command -v lsof > /dev/null 2>&1; then
    if lsof -i :$port > /dev/null 2>&1; then
      echo "  WARNING: Port $port is in use (may conflict with DevContainer)"
    fi
  elif command -v netstat > /dev/null 2>&1; then
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
      echo "  WARNING: Port $port is in use (may conflict with DevContainer)"
    fi
  fi
done
echo "  ✓ Port check complete"

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
echo "Pre-flight checks passed!"
echo ""
```

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

## Step 1.75: Show Base Stack

```bash
echo ""
echo "[Base: Python 3.12 + Node 20]"
echo ""
```

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

4. None - use base only
   → Just Python 3.12 + Node 20 - ready to code!
```

Store as `TOOL_CATEGORY`.

- If "Backend language" → continue to Step 3
- If "Database tools" → add "postgres" to SELECTED_PARTIALS, go to Step 6
- If "C++ development" → continue to Step 4
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
  PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT//\\//}"
  echo "Using CLAUDE_PLUGIN_ROOT: $PLUGIN_ROOT"
elif [ -f "skills/_shared/templates/base.dockerfile" ]; then
  PLUGIN_ROOT="."
  echo "Using current directory as plugin root"
elif [ -d "$HOME/.claude/plugins" ]; then
  PLUGIN_ROOT=$(find "$HOME/.claude/plugins" -type f -name "plugin.json" \
    -exec grep -l '"name": "devcontainer-setup"' {} \; 2>/dev/null | \
    head -1 | xargs -r dirname 2>/dev/null) || true
  [ -n "$PLUGIN_ROOT" ] && echo "Found installed plugin: $PLUGIN_ROOT"
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
  echo "Installation mode: Dev Container Features"
  if [ ${#SELECTED_FEATURES[@]} -gt 0 ]; then
    echo "Selected features:"
    for feature in "${SELECTED_FEATURES[@]}"; do
      echo "  ✓ $feature"
    done
  else
    echo "Using base image only (no additional features)"
  fi
else
  # Partials mode: append partial dockerfiles
  echo "Installation mode: Partial Dockerfiles"
  if [ ${#SELECTED_PARTIALS[@]} -gt 0 ]; then
    echo "Adding selected tools..."
    for partial in "${SELECTED_PARTIALS[@]}"; do
      cat "$PARTIALS/${partial}.dockerfile" >> .devcontainer/Dockerfile

      # Echo friendly message based on partial
      case "$partial" in
        "go")
          echo "  ✓ Go toolchain"
          ;;
        "ruby")
          echo "  ✓ Ruby toolchain"
          ;;
        "rust")
          echo "  ✓ Rust toolchain"
          ;;
        "java")
          echo "  ✓ Java toolchain"
          ;;
        "cpp-clang")
          echo "  ✓ C++ (Clang 17)"
          ;;
        "cpp-gcc")
          echo "  ✓ C++ (GCC)"
          ;;
        "php")
          echo "  ✓ PHP 8.3"
          ;;
        "postgres")
          echo "  ✓ PostgreSQL development tools"
          ;;
      esac
    done
  else
    echo "Using base image only (no additional tools)"
  fi
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
  esac
done
echo ""
```

## Step 11: Generate Firewall Script

```bash
if [ "$NEEDS_FIREWALL" = "Yes" ]; then
  # Generate firewall script from selected categories
  cp "$TEMPLATES/init-firewall.sh" .devcontainer/init-firewall.sh

  # Read allowable-domains.json and build domain list from selected categories
  DOMAINS_JSON="$TEMPLATES/data/allowable-domains.json"

  # Build ALLOWED_DOMAINS array from selected categories
  FIREWALL_DOMAINS=""

  for category in "${DOMAIN_CATEGORIES[@]}"; do
    case "$category" in
      "Package managers")
        # Add npm and python by default (basic subcategories)
        FIREWALL_DOMAINS+=$(jq -r '.categories.package_managers.sub_categories.npm.domains[]' "$DOMAINS_JSON" | sed 's/^/  "/;s/$/"/' | tr '\n' '\n')
        FIREWALL_DOMAINS+="\n"
        FIREWALL_DOMAINS+=$(jq -r '.categories.package_managers.sub_categories.python.domains[]' "$DOMAINS_JSON" | sed 's/^/  "/;s/$/"/' | tr '\n' '\n')
        ;;
      "Version control")
        FIREWALL_DOMAINS+=$(jq -r '.categories.version_control.domains[]' "$DOMAINS_JSON" | sed 's/^/  "/;s/$/"/' | tr '\n' '\n')
        ;;
      "Container registries")
        FIREWALL_DOMAINS+=$(jq -r '.categories.container_registries.domains[]' "$DOMAINS_JSON" | sed 's/^/  "/;s/$/"/' | tr '\n' '\n')
        ;;
      "Cloud platforms")
        FIREWALL_DOMAINS+=$(jq -r '.categories.cloud_platforms.sub_categories | to_entries[].value.domains[]' "$DOMAINS_JSON" | sed 's/^/  "/;s/$/"/' | tr '\n' '\n')
        ;;
      "Development tools")
        FIREWALL_DOMAINS+=$(jq -r '.categories.development_tools.domains[]' "$DOMAINS_JSON" | sed 's/^/  "/;s/$/"/' | tr '\n' '\n')
        ;;
      "VS Code extensions")
        FIREWALL_DOMAINS+=$(jq -r '.categories.vscode.domains[]' "$DOMAINS_JSON" | sed 's/^/  "/;s/$/"/' | tr '\n' '\n')
        ;;
      "Analytics/telemetry")
        FIREWALL_DOMAINS+=$(jq -r '.categories.analytics_telemetry.domains[]' "$DOMAINS_JSON" | sed 's/^/  "/;s/$/"/' | tr '\n' '\n')
        ;;
    esac
  done

  # Add Anthropic services (always required)
  ANTHROPIC_DOMAINS=$(jq -r '.categories.anthropic_services.domains[]' "$DOMAINS_JSON" | sed 's/^/  "/;s/$/"/')

  # Add Linux distributions (always required)
  LINUX_DOMAINS=$(jq -r '.categories.linux_distributions.domains[]' "$DOMAINS_JSON" | sed 's/^/  "/;s/$/"/')

  # Add custom domains if provided
  CUSTOM_DOMAIN_LIST=""
  if [ -n "${CUSTOM_DOMAINS:-}" ]; then
    for domain in $(echo "$CUSTOM_DOMAINS" | tr ',' '\n'); do
      CUSTOM_DOMAIN_LIST+="  \"$(echo $domain | xargs)\"\n"
    done
  fi

  echo "Firewall: Strict mode with domain allowlist"
  echo "  Categories: ${DOMAIN_CATEGORIES[*]}"
else
  # No firewall script needed - Docker container isolation only
  echo "Firewall: Disabled (Docker isolation only)"
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
    WORKSPACE_MODE="volume"
    echo "Using volume mode for better Windows/macOS performance"
    ;;
  *)
    WORKSPACE_MODE="bind"
    echo "Using bind mount mode (default)"
    ;;
esac
```

## Step 12: Copy Other Templates

```bash
# Copy devcontainer config
cp "$TEMPLATES/devcontainer.json" .devcontainer/

# Copy docker-compose based on workspace mode
if [ "$WORKSPACE_MODE" = "volume" ]; then
  cp "$TEMPLATES/docker-compose.volume.yml" ./docker-compose.yml
  echo "Using docker-compose.volume.yml (volume mode)"
else
  cp "$TEMPLATES/docker-compose.yml" ./docker-compose.yml
  echo "Using docker-compose.yml (bind mount mode)"
fi

# Copy credential setup script
cp "$TEMPLATES/setup-claude-credentials.sh" .devcontainer/

# Copy data files
cp "$TEMPLATES/data/allowable-domains.json" data/

# Copy .env.example (user should copy to .env and customize)
cp "$TEMPLATES/.env.example" ./.env.example

# Replace placeholders (portable sed without -i)
for f in .devcontainer/devcontainer.json docker-compose.yml; do
  sed "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$f" > "$f.tmp" && mv "$f.tmp" "$f"
done

# Add features to devcontainer.json if in features mode
if [ "$INSTALL_MODE" = "features" ] && [ ${#SELECTED_FEATURES[@]} -gt 0 ]; then
  # Build features JSON object
  FEATURES_JSON="{"
  for i in "${!SELECTED_FEATURES[@]}"; do
    if [ $i -gt 0 ]; then
      FEATURES_JSON+=","
    fi
    FEATURES_JSON+="\n    \"${SELECTED_FEATURES[$i]}\": {}"
  done
  FEATURES_JSON+="\n  }"

  # Replace empty features object with populated one
  sed "s/\"features\": {}/\"features\": $FEATURES_JSON/g" \
    .devcontainer/devcontainer.json > .devcontainer/devcontainer.json.tmp && \
    mv .devcontainer/devcontainer.json.tmp .devcontainer/devcontainer.json
  echo "Added Dev Container Features to devcontainer.json"
fi

# Add language-specific VS Code extensions based on selected partials
EXTENSIONS_TO_ADD=""
for partial in "${SELECTED_PARTIALS[@]}"; do
  case "$partial" in
    "go")
      EXTENSIONS_TO_ADD+=',\n        "golang.go"'
      ;;
    "rust")
      EXTENSIONS_TO_ADD+=',\n        "rust-lang.rust-analyzer"'
      ;;
    "java")
      EXTENSIONS_TO_ADD+=',\n        "redhat.java",\n        "vscjava.vscode-java-pack"'
      ;;
    "ruby")
      EXTENSIONS_TO_ADD+=',\n        "shopify.ruby-lsp"'
      ;;
    "php")
      EXTENSIONS_TO_ADD+=',\n        "bmewburn.vscode-intelephense-client"'
      ;;
    "cpp-clang"|"cpp-gcc")
      EXTENSIONS_TO_ADD+=',\n        "ms-vscode.cpptools",\n        "ms-vscode.cmake-tools"'
      ;;
    "postgres")
      EXTENSIONS_TO_ADD+=',\n        "ckolkman.vscode-postgres"'
      ;;
  esac
done

# Insert extensions before the closing bracket of extensions array
if [ -n "$EXTENSIONS_TO_ADD" ]; then
  sed "s/\"johnpapa.vscode-peacock\"/\"johnpapa.vscode-peacock\"$EXTENSIONS_TO_ADD/g" \
    .devcontainer/devcontainer.json > .devcontainer/devcontainer.json.tmp && \
    mv .devcontainer/devcontainer.json.tmp .devcontainer/devcontainer.json
  echo "Added language-specific VS Code extensions"
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
    esac
  done
fi
echo ""
echo "Firewall: $([ "$NEEDS_FIREWALL" = "Yes" ] && echo "Enabled (strict allowlist)" || echo "Disabled (Docker isolation only)")"
echo ""
echo "Files created:"
echo "  .devcontainer/Dockerfile"
echo "  .devcontainer/devcontainer.json"
if [ "$NEEDS_FIREWALL" = "Yes" ]; then
  echo "  .devcontainer/init-firewall.sh"
fi
echo "  .devcontainer/setup-claude-credentials.sh"
echo "  docker-compose.yml"
echo "  data/allowable-domains.json"
echo "  .env.example"
echo ""
echo "Next steps:"
echo "1. Copy .env.example to .env and add your API keys"
echo "2. Open this folder in VS Code"
echo "3. Click 'Reopen in Container' when prompted"
echo "4. Wait for container to build (~2-5 minutes first time)"
echo "=========================================="
```

---

**Last Updated:** 2025-12-24
**Version:** 4.5.0 (Command Rename)
