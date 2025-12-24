---
description: Interactive DevContainer setup with project type selection and firewall customization
argument-hint: ""
allowed-tools: [Bash, AskUserQuestion, Read]
---

# Interactive DevContainer Setup

Create a customized VS Code DevContainer configuration with:
- Project-specific base image + language tools
- Optional network firewall with domain allowlist
- All standard Claude Code sandbox features

**Quick path:** Use `/devcontainer:yolo` for instant setup with no questions (Python+Node, no firewall).

## Step 1: Ask About Project Type

Use AskUserQuestion to determine which language tools to include:

```
What type of project are you setting up?

Options:
1. Python/Node (Base only - Python 3.12 + Node 20)
2. Go (Adds Go 1.22 toolchain and linters)
3. Ruby (Adds Ruby 3.3 and bundler)
4. Rust (Adds Rust toolchain and Cargo)
5. Java (Adds OpenJDK 21, Maven, Gradle)
6. C++ (Clang) (Adds Clang 17, CMake, Ninja, vcpkg)
7. C++ (GCC) (Adds GCC, CMake, Ninja, vcpkg)
8. PHP (Adds PHP 8.3, Composer, extensions)
9. PostgreSQL Dev (Adds PostgreSQL client and dev tools)
```

Store the answer as `PROJECT_TYPE`.

## Step 2: Ask About Network Security

Use AskUserQuestion:

```
Do you need network restrictions?

Options:
1. No - Allow all outbound traffic (fastest setup)
2. Yes - Restrict to allowed domains only (more secure)
```

Store the answer as `NEEDS_FIREWALL`.

## Step 3: Domain Categories (If Firewall Enabled)

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

## Step 4: Find Plugin Directory

```bash
# Method 1: Use CLAUDE_PLUGIN_ROOT if available
if [ -n "${CLAUDE_PLUGIN_ROOT}" ]; then
  PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}"
  echo "Using CLAUDE_PLUGIN_ROOT: $PLUGIN_ROOT"
# Method 2: Find plugin in installed location
elif FOUND_ROOT=$(find ~/.claude/plugins -type f -name "plugin.json" -exec grep -l '"name": "devcontainer-setup"' {} \; 2>/dev/null | head -1 | xargs dirname 2>/dev/null); then
  PLUGIN_ROOT="$FOUND_ROOT"
  echo "Found installed plugin: $PLUGIN_ROOT"
# Method 3: Fall back to current directory
elif [ -f skills/_shared/templates/base.dockerfile ]; then
  PLUGIN_ROOT="."
  echo "Using current directory as plugin root"
else
  echo "ERROR: Cannot locate plugin templates"
  exit 1
fi
```

## Step 5: Build Dockerfile

```bash
PROJECT_NAME="$(basename $(pwd))"
TEMPLATES="$PLUGIN_ROOT/skills/_shared/templates"
PARTIALS="$TEMPLATES/partials"

# Create directories
mkdir -p .devcontainer data

# Copy base dockerfile
cp "$TEMPLATES/base.dockerfile" .devcontainer/Dockerfile

# Append language partial if needed
case "$PROJECT_TYPE" in
  "Go")
    cat "$PARTIALS/go.dockerfile" >> .devcontainer/Dockerfile
    echo "Added Go toolchain"
    ;;
  "Ruby")
    cat "$PARTIALS/ruby.dockerfile" >> .devcontainer/Dockerfile
    echo "Added Ruby toolchain"
    ;;
  "Rust")
    cat "$PARTIALS/rust.dockerfile" >> .devcontainer/Dockerfile
    echo "Added Rust toolchain"
    ;;
  "Java")
    cat "$PARTIALS/java.dockerfile" >> .devcontainer/Dockerfile
    echo "Added Java toolchain"
    ;;
  "C++ (Clang)")
    cat "$PARTIALS/cpp-clang.dockerfile" >> .devcontainer/Dockerfile
    echo "Added C++ (Clang 17) toolchain"
    ;;
  "C++ (GCC)")
    cat "$PARTIALS/cpp-gcc.dockerfile" >> .devcontainer/Dockerfile
    echo "Added C++ (GCC) toolchain"
    ;;
  "PHP")
    cat "$PARTIALS/php.dockerfile" >> .devcontainer/Dockerfile
    echo "Added PHP 8.3 and Composer"
    ;;
  "PostgreSQL Dev")
    cat "$PARTIALS/postgres.dockerfile" >> .devcontainer/Dockerfile
    echo "Added PostgreSQL development tools"
    ;;
  "Python/Node")
    echo "Using base image (Python 3.12 + Node 20)"
    ;;
esac
```

## Step 6: Generate Firewall Script

```bash
if [ "$NEEDS_FIREWALL" = "Yes" ]; then
  # Generate firewall script from selected categories
  # Read allowable-domains.json and extract domains for selected categories
  # Write to .devcontainer/init-firewall.sh based on strict.sh template

  cp "$TEMPLATES/init-firewall/strict.sh" .devcontainer/init-firewall.sh

  # TODO: Customize ALLOWED_DOMAINS array based on DOMAIN_CATEGORIES
  # For now, use strict.sh as-is

  echo "Firewall: Strict mode with domain allowlist"
else
  # Use disabled firewall
  # cp "$TEMPLATES/init-firewall/disabled.sh" .devcontainer/init-firewall.sh
  echo "Firewall: Disabled (Docker isolation only)"
fi
```

## Step 7: Copy Other Templates

```bash
# Copy devcontainer config
cp "$TEMPLATES/devcontainer.json" .devcontainer/

# Copy docker-compose
cp "$TEMPLATES/docker-compose.yml" ./

# Copy credential setup script
cp "$TEMPLATES/setup-claude-credentials.sh" .devcontainer/

# Copy data files
cp "$TEMPLATES/data/allowable-domains.json" data/

# Replace placeholders
sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" .devcontainer/devcontainer.json docker-compose.yml

# Set permissions
chmod +x .devcontainer/*.sh
```

## Step 8: Report Results

```bash
echo "=========================================="
echo "DevContainer Created Successfully"
echo "=========================================="
echo "Project: $PROJECT_NAME"
echo "Language: $PROJECT_TYPE"
echo "Firewall: $([ "$NEEDS_FIREWALL" = "Yes" ] && echo "Enabled" || echo "Disabled")"
echo ""
echo "Files created:"
echo "  .devcontainer/Dockerfile"
echo "  .devcontainer/devcontainer.json"
echo "  .devcontainer/init-firewall.sh"
echo "  .devcontainer/setup-claude-credentials.sh"
echo "  docker-compose.yml"
echo "  data/allowable-domains.json"
echo ""
echo "Next steps:"
echo "1. Open this folder in VS Code"
echo "2. Click 'Reopen in Container' when prompted"
echo "3. Wait for container to build (~2-5 minutes first time)"
echo "=========================================="
```

---

**Last Updated:** 2025-12-23
**Version:** 4.3.1 (Interactive Project-Type Flow)
