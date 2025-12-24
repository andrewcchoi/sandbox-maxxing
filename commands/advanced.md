---
description: Setup advanced devcontainer by copying templates from skills/_shared/templates/
argument-hint: "[project-name]"
allowed-tools: [Bash]
---

# Advanced DevContainer Setup

Copy DevContainer templates from `skills/_shared/templates/` and replace placeholders.

**Security Level:** Strict firewall with customizable domain allowlist.

## Determine Project Name

- If the user provided an argument (project name), use that
- Otherwise, use the current directory name: `basename $(pwd)`

## Execute These Bash Commands

### Step 1: Find Plugin Directory

First, determine where the plugin is located:

```bash
# Method 1: Use CLAUDE_PLUGIN_ROOT if available (inline/development plugins)
if [ -n "${CLAUDE_PLUGIN_ROOT}" ]; then
  PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}"
  echo "Using CLAUDE_PLUGIN_ROOT: $PLUGIN_ROOT"
# Method 2: Try to find plugin in installed location
elif FOUND_ROOT=$(find ~/.claude/plugins -type f -name "plugin.json" -exec grep -l '"name": "devcontainer-setup"' {} \; 2>/dev/null | head -1 | xargs dirname 2>/dev/null); then
  PLUGIN_ROOT="$FOUND_ROOT"
  echo "Found installed plugin: $PLUGIN_ROOT"
# Method 3: Fall back to current directory if templates exist here
elif [ -f skills/_shared/templates/base.dockerfile ]; then
  PLUGIN_ROOT="."
  echo "Using current directory as plugin root"
else
  echo "ERROR: Cannot locate plugin templates"
  exit 1
fi
```

### Step 2: Copy Templates and Process Placeholders

Determine the project name, then copy templates and replace placeholders:

```bash
# Set project name (replace with actual value)
PROJECT_NAME="$(basename $(pwd))"

# Set paths
TEMPLATES="$PLUGIN_ROOT/skills/_shared/templates"
DATA="$PLUGIN_ROOT/skills/_shared/data"

# Create directories
mkdir -p .devcontainer data

# Copy and rename template files
cp "$TEMPLATES/base.dockerfile" .devcontainer/Dockerfile
cp "$TEMPLATES/devcontainer.json" .devcontainer/
cp "$TEMPLATES/docker-compose.yml" ./
cp "$TEMPLATES/setup-claude-credentials.sh" .devcontainer/
cp "$TEMPLATES/init-firewall/strict.sh" .devcontainer/init-firewall.sh

# Copy data file required by Dockerfile
cp "$DATA/allowable-domains.json" data/

# Replace placeholders
sed -i "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" .devcontainer/devcontainer.json docker-compose.yml

# Make scripts executable
chmod +x .devcontainer/*.sh

# List created files
echo "✓ Created files:"
ls -lh .devcontainer/ docker-compose.yml data/allowable-domains.json
```

**Note:** If the user provided a project name argument, replace `"$(basename $(pwd))"` with that argument value in the PROJECT_NAME assignment.

## Expected Output

After running, you should see:
- `.devcontainer/Dockerfile` (from base.dockerfile)
- `.devcontainer/devcontainer.json` (with project name)
- `.devcontainer/init-firewall.sh` (strict firewall with domain allowlist)
- `.devcontainer/setup-claude-credentials.sh`
- `docker-compose.yml` (at project root, with project name in network)
- `data/allowable-domains.json` (domain allowlist for firewall)

Report the results to the user, including file sizes and confirmation that all files were created.

---

**Last Updated:** 2025-12-23
**Version:** 4.2.1
