---
description: YOLO vibe-maxxing DevContainer setup with no questions - Python+Node base, no firewall
argument-hint: "[project-name]"
allowed-tools: [Bash]
---

# YOLO Vibe-Maxxing DevContainer Setup

**Quick setup with zero questions.** Creates a DevContainer with:
- Python 3.12 + Node 20 (multi-language base image)
- No firewall (Docker isolation only)
- All standard development tools

**Need customization?** Use `/sandboxxer:quickstart` for interactive mode with project type selection and firewall options.

## Determine Project Name

- If the user provided an argument (project name), use that
- Otherwise, use the current directory name: `basename $(pwd)`

## Execute These Bash Commands

### Step 1: Find Plugin Directory

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

# Create minimal no-op firewall script (Dockerfile always expects it)
cat > .devcontainer/init-firewall.sh << 'NOOP_EOF'
#!/bin/bash
# Firewall disabled - this is a no-op script
# The Dockerfile requires this file to exist even when firewall is not enabled
echo "Firewall is disabled. Using Docker container isolation only."
exit 0
NOOP_EOF
chmod +x .devcontainer/init-firewall.sh

# Replace placeholders (portable sed without -i)
for f in .devcontainer/devcontainer.json docker-compose.yml; do
  sed "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$f" > "$f.tmp" && mv "$f.tmp" "$f";
done

# Make scripts executable
chmod +x .devcontainer/*.sh

echo "=========================================="
echo "DevContainer Created (Non-Interactive YOLO Vibe Maxxing)"
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

**Last Updated:** 2025-12-24
**Version:** 4.6.0 (Command Rename)
