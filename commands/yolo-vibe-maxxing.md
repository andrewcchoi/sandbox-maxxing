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
# Sanitize project name for Docker compatibility (yolo mode: auto-fix, no prompts)
sanitize_project_name() {
  local name="$1"
  local sanitized
  sanitized=$(echo "$name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')
  sanitized=$(echo "$sanitized" | sed 's/^-*//;s/-*$//;s/--*/-/g')
  [ -z "$sanitized" ] && sanitized="sandbox-app"
  echo "$sanitized"
}

RAW_PROJECT_NAME="$(basename $(pwd))"
PROJECT_NAME="$(sanitize_project_name "$RAW_PROJECT_NAME")"
[ "$PROJECT_NAME" != "$RAW_PROJECT_NAME" ] && echo "Auto-sanitized: $RAW_PROJECT_NAME -> $PROJECT_NAME"

TEMPLATES="$PLUGIN_ROOT/skills/_shared/templates"
DATA="$PLUGIN_ROOT/skills/_shared/templates/data"

# Initialize port variables with defaults
APP_PORT=8000
FRONTEND_PORT=3000
POSTGRES_PORT=5432
REDIS_PORT=6379

# Function to find the next available port
find_available_port() {
  local port=$1
  local max_port=65535
  while [ $port -le $max_port ]; do
    if ! (lsof -i :$port > /dev/null 2>&1 || netstat -tuln 2>/dev/null | grep -q ":$port "); then
      echo $port
      return 0
    fi
    port=$((port + 1))
  done
  echo "ERROR: No available port found" >&2
  return 1
}

# Check and reassign ports if occupied
APP_PORT=$(find_available_port $APP_PORT)
FRONTEND_PORT=$(find_available_port $FRONTEND_PORT)
POSTGRES_PORT=$(find_available_port $POSTGRES_PORT)
REDIS_PORT=$(find_available_port $REDIS_PORT)

# Backup existing .env if present
if [ -f ".env" ]; then
  cp .env .env.backup
  echo "Backed up existing .env"
fi

# Create directories
mkdir -p .devcontainer

# Copy templates
cp "$TEMPLATES/base.dockerfile" .devcontainer/Dockerfile
cp "$TEMPLATES/devcontainer.json" .devcontainer/
cp "$TEMPLATES/docker-compose.yml" ./
cp "$TEMPLATES/setup-claude-credentials.sh" .devcontainer/
cp "$TEMPLATES/setup-frontend.sh" .devcontainer/

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

# Robust merge using awk (handles |, &, \, etc.)
merge_env_value() {
  local key="$1"
  local value="$2"
  local target_file="$3"

  local escaped_key
  escaped_key=$(printf '%s' "$key" | sed 's/[.[\*^$()+?{|\\]/\\&/g')

  if grep -q "^${escaped_key}=" "$target_file" 2>/dev/null; then
    awk -v key="$key" -v val="$value" '
      BEGIN { FS="="; OFS="=" }
      $1 == key { $0 = key "=" val; found=1 }
      { print }
    ' "$target_file" > "${target_file}.tmp"

    if [ -s "${target_file}.tmp" ]; then
      mv "${target_file}.tmp" "$target_file"
    else
      rm -f "${target_file}.tmp"
      return 1
    fi
  else
    printf '%s=%s\n' "$key" "$value" >> "$target_file"
  fi
}

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

# Replace placeholders (portable sed without -i)
for f in .devcontainer/devcontainer.json docker-compose.yml; do
  sed "s/{{PROJECT_NAME}}/$PROJECT_NAME/g; \
       s/{{APP_PORT}}/$APP_PORT/g; \
       s/{{FRONTEND_PORT}}/$FRONTEND_PORT/g; \
       s/{{POSTGRES_PORT}}/$POSTGRES_PORT/g; \
       s/{{REDIS_PORT}}/$REDIS_PORT/g" \
    "$f" > "$f.tmp" && mv "$f.tmp" "$f";
done

# Make scripts executable
chmod +x .devcontainer/*.sh

echo "=========================================="
echo "DevContainer Created (Non-Interactive YOLO Vibe Maxxing)"
echo "=========================================="
echo "Project: $PROJECT_NAME"
echo "Language: Python 3.12 + Node 20"
echo "Firewall: Disabled"
echo "Ports: App=$APP_PORT, Frontend=$FRONTEND_PORT, PostgreSQL=$POSTGRES_PORT, Redis=$REDIS_PORT"
echo ""
echo "Files created:"
echo "  .devcontainer/Dockerfile"
echo "  .devcontainer/devcontainer.json"
echo "  .devcontainer/setup-claude-credentials.sh"
echo "  .devcontainer/setup-frontend.sh"
echo "  docker-compose.yml"
echo ""
echo "Next: Open in VS Code → 'Reopen in Container'"
echo "=========================================="
```

**Note:** If the user provided a project name argument, replace `"$(basename $(pwd))"` with that argument in the PROJECT_NAME assignment.

---

**Last Updated:** 2025-12-24
**Version:** 4.6.0
