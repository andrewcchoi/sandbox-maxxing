---
description: Quick DevContainer setup with no questions - Python+Node base, no firewall
argument-hint: "[project-name]"
allowed-tools: [Bash]
---

# YOLO DevContainer Setup

**Quick setup with zero questions.** Creates a DevContainer with:
- Python 3.12 + Node 20 (multi-language base image)
- No firewall (Docker isolation only)
- All standard development tools

**Need customization?** Use `/devcontainer:setup` for interactive mode with project type selection and firewall options.

## Determine Project Name

- If the user provided an argument (project name), use that
- Otherwise, use the current directory name: `basename $(pwd)`

## Execute These Bash Commands

### Step 1: Find Plugin Directory

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

### Step 2: Copy Templates and Process Placeholders

```bash
PROJECT_NAME="$(basename $(pwd))"
TEMPLATES="$PLUGIN_ROOT/skills/_shared/templates"
DATA="$PLUGIN_ROOT/skills/_shared/templates/data"

# Create directories
mkdir -p .devcontainer data

# Copy templates
cp "$TEMPLATES/base.dockerfile" .devcontainer/Dockerfile
cp "$TEMPLATES/devcontainer.json" .devcontainer/
cp "$TEMPLATES/docker-compose.yml" ./
cp "$TEMPLATES/setup-claude-credentials.sh" .devcontainer/

# Replace placeholders
sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" .devcontainer/devcontainer.json docker-compose.yml

# Make scripts executable
chmod +x .devcontainer/*.sh

echo "=========================================="
echo "DevContainer Created (YOLO Mode)"
echo "=========================================="
echo "Project: $PROJECT_NAME"
echo "Language: Python 3.12 + Node 20"
echo "Firewall: Disabled"
echo ""
echo "Files created:"
echo "  .devcontainer/Dockerfile"
echo "  .devcontainer/devcontainer.json"
echo "  .devcontainer/setup-claude-credentials.sh"
echo "  docker-compose.yml"
echo ""
echo "Next: Open in VS Code → 'Reopen in Container'"
echo "=========================================="
```

**Note:** If the user provided a project name argument, replace `"$(basename $(pwd))"` with that argument in the PROJECT_NAME assignment.

---

**Last Updated:** 2025-12-23
**Version:** 4.3.1 (Quick Setup Path)
