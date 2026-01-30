---
description: YOLO vibe-maxxing DevContainer setup with no questions - Python+Node base, no firewall
argument-hint: "[project-name] [--portless]"
allowed-tools: [Bash]
---

# YOLO Vibe-Maxxing DevContainer Setup

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

## Determine Mode

Check if the user provided `--portless` flag:
- **Portless Mode**: No host port mappings, services accessible only via Docker network
- **Normal Mode**: Standard port mappings (default)

**If Normal Mode:** Execute the Normal Mode bash block below.
**If Portless Mode:** Execute the Portless Mode bash block below.

## Execute These Bash Commands

### Normal Mode (with port mappings)

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
  PLUGIN_JSON=$(find "$HOME/.claude/plugins" -maxdepth 3 -type f -name "plugin.json" \
    -exec grep -l '"name": "sandboxxer"' {} \; 2>/dev/null | head -1);
  if [ -n "$PLUGIN_JSON" ]; then
    PLUGIN_ROOT=$(dirname "$(dirname "$PLUGIN_JSON")");
    echo "Found installed plugin: $PLUGIN_ROOT";
  fi;
fi

[ -z "$PLUGIN_ROOT" ] && { echo "ERROR: Cannot locate plugin templates"; exit 1; }

# Sanitize project name for Docker compatibility (yolo mode: auto-fix, no prompts)
sanitize_project_name() {
  local name="$1"
  local sanitized
  sanitized=$(echo "$name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')
  sanitized=$(echo "$sanitized" | sed 's/^-*//;s/-*$//;s/--*/-/g')
  [ -z "$sanitized" ] && sanitized="sandbox-app"
  echo "$sanitized"
}

RAW_PROJECT_NAME="$(basename "$(pwd)")"
PROJECT_NAME="$(sanitize_project_name "$RAW_PROJECT_NAME")"
[ "$PROJECT_NAME" != "$RAW_PROJECT_NAME" ] && echo "Auto-sanitized: $RAW_PROJECT_NAME -> $PROJECT_NAME"

TEMPLATES="$PLUGIN_ROOT/skills/_shared/templates"

# Validate templates exist
for tmpl in base.dockerfile devcontainer.json docker-compose.yml setup-claude-credentials.sh setup-frontend.sh; do
  [ -f "$TEMPLATES/$tmpl" ] || { echo "ERROR: Missing template: $TEMPLATES/$tmpl"; exit 1; }
done

# Initialize port variables with defaults
APP_PORT=8000
FRONTEND_PORT=3000
POSTGRES_PORT=5432
REDIS_PORT=6379

# Function to check if a port is in use (with fallback to multiple tools)
port_in_use() {
  local port=$1
  if command -v lsof >/dev/null 2>&1; then
    lsof -i ":$port" >/dev/null 2>&1 && return 0
  fi
  if command -v ss >/dev/null 2>&1; then
    ss -tuln 2>/dev/null | grep -q ":$port " && return 0
  fi
  if command -v netstat >/dev/null 2>&1; then
    netstat -tuln 2>/dev/null | grep -q ":$port " && return 0
  fi
  # Can't determine, assume free
  return 1
}

# Function to find the next available port, excluding already-assigned ports
find_available_port() {
  local port=$1
  shift
  local exclude=("$@")
  local max_port=65535
  while [ $port -le $max_port ]; do
    # Skip excluded ports
    local skip=false
    for ex in "${exclude[@]}"; do
      [ "$port" = "$ex" ] && { skip=true; break; }
    done
    $skip && { port=$((port + 1)); continue; }

    if ! port_in_use "$port"; then
      echo "$port"
      return 0
    fi
    port=$((port + 1))
  done
  echo "ERROR: No available port found starting from $1" >&2
  return 1
}

# Check and reassign ports if occupied
APP_PORT=$(find_available_port 8000) || { echo "FATAL: Cannot allocate APP_PORT"; exit 1; }
FRONTEND_PORT=$(find_available_port 3000 "$APP_PORT") || { echo "FATAL: Cannot allocate FRONTEND_PORT"; exit 1; }
POSTGRES_PORT=$(find_available_port 5432 "$APP_PORT" "$FRONTEND_PORT") || { echo "FATAL: Cannot allocate POSTGRES_PORT"; exit 1; }
REDIS_PORT=$(find_available_port 6379 "$APP_PORT" "$FRONTEND_PORT" "$POSTGRES_PORT") || { echo "FATAL: Cannot allocate REDIS_PORT"; exit 1; }

# Backup existing .env if present
if [ -f ".env" ]; then
  cp .env .env.backup
  echo "Backed up existing .env"
fi

# Create directories
mkdir -p .devcontainer || { echo "ERROR: Cannot create .devcontainer"; exit 1; }

# Copy templates
cp "$TEMPLATES/base.dockerfile" .devcontainer/Dockerfile || { echo "ERROR: Template copy failed"; exit 1; }
cp "$TEMPLATES/devcontainer.json" .devcontainer/ || { echo "ERROR: Template copy failed"; exit 1; }
cp "$TEMPLATES/docker-compose.yml" ./ || { echo "ERROR: Template copy failed"; exit 1; }
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
      $1 == key { $0 = key "=" val }
      { print }
    ' "$target_file" > "${target_file}.tmp"

    if [ -s "${target_file}.tmp" ]; then
      mv "${target_file}.tmp" "$target_file"
    else
      rm -f "${target_file}.tmp"
      return 1
    fi
  else
    # Ensure trailing newline before appending
    [ -f "$target_file" ] && [ -n "$(tail -c 1 "$target_file" 2>/dev/null)" ] && echo "" >> "$target_file"
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

# Write discovered ports to .env for docker-compose
merge_env_value "APP_PORT" "$APP_PORT" .env
merge_env_value "FRONTEND_PORT" "$FRONTEND_PORT" .env
merge_env_value "POSTGRES_PORT" "$POSTGRES_PORT" .env
merge_env_value "REDIS_PORT" "$REDIS_PORT" .env

# Replace all placeholders including ports (using | delimiter for safety)
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

# Make scripts executable
chmod +x .devcontainer/*.sh || { echo "ERROR: Cannot set script permissions"; exit 1; }

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

---

### Portless Mode (no port mappings)

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
  PLUGIN_JSON=$(find "$HOME/.claude/plugins" -maxdepth 3 -type f -name "plugin.json" \
    -exec grep -l '"name": "sandboxxer"' {} \; 2>/dev/null | head -1);
  if [ -n "$PLUGIN_JSON" ]; then
    PLUGIN_ROOT=$(dirname "$(dirname "$PLUGIN_JSON")");
    echo "Found installed plugin: $PLUGIN_ROOT";
  fi;
fi

[ -z "$PLUGIN_ROOT" ] && { echo "ERROR: Cannot locate plugin templates"; exit 1; }

# Sanitize project name for Docker compatibility (yolo mode: auto-fix, no prompts)
sanitize_project_name() {
  local name="$1"
  local sanitized
  sanitized=$(echo "$name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')
  sanitized=$(echo "$sanitized" | sed 's/^-*//;s/-*$//;s/--*/-/g')
  [ -z "$sanitized" ] && sanitized="sandbox-app"
  echo "$sanitized"
}

RAW_PROJECT_NAME="$(basename "$(pwd)")"
PROJECT_NAME="$(sanitize_project_name "$RAW_PROJECT_NAME")"
[ "$PROJECT_NAME" != "$RAW_PROJECT_NAME" ] && echo "Auto-sanitized: $RAW_PROJECT_NAME -> $PROJECT_NAME"

TEMPLATES="$PLUGIN_ROOT/skills/_shared/templates"

# Validate portless templates exist
for tmpl in base.dockerfile devcontainer.portless.json docker-compose.portless.yml setup-claude-credentials.sh setup-frontend.sh; do
  [ -f "$TEMPLATES/$tmpl" ] || { echo "ERROR: Missing template: $TEMPLATES/$tmpl"; exit 1; }
done

# Backup existing .env if present
if [ -f ".env" ]; then
  cp .env .env.backup
  echo "Backed up existing .env"
fi

# Create directories
mkdir -p .devcontainer || { echo "ERROR: Cannot create .devcontainer"; exit 1; }

# Copy portless templates
cp "$TEMPLATES/base.dockerfile" .devcontainer/Dockerfile || { echo "ERROR: Template copy failed"; exit 1; }
cp "$TEMPLATES/devcontainer.portless.json" .devcontainer/devcontainer.json || { echo "ERROR: Template copy failed"; exit 1; }
cp "$TEMPLATES/docker-compose.portless.yml" ./docker-compose.yml || { echo "ERROR: Template copy failed"; exit 1; }
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
      $1 == key { $0 = key "=" val }
      { print }
    ' "$target_file" > "${target_file}.tmp"

    if [ -s "${target_file}.tmp" ]; then
      mv "${target_file}.tmp" "$target_file"
    else
      rm -f "${target_file}.tmp"
      return 1
    fi
  else
    # Ensure trailing newline before appending
    [ -f "$target_file" ] && [ -n "$(tail -c 1 "$target_file" 2>/dev/null)" ] && echo "" >> "$target_file"
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

# Replace only PROJECT_NAME placeholder (no ports in portless mode, using | delimiter for safety)
for f in .devcontainer/devcontainer.json docker-compose.yml; do
  sed "s|{{PROJECT_NAME}}|$PROJECT_NAME|g" \
    "$f" > "$f.tmp" || { echo "ERROR: sed template processing failed for $f"; exit 1; }
  [ -s "$f.tmp" ] || { echo "ERROR: sed produced empty output for $f"; exit 1; }
  mv "$f.tmp" "$f"
done

# Make scripts executable
chmod +x .devcontainer/*.sh || { echo "ERROR: Cannot set script permissions"; exit 1; }

echo "=========================================="
echo "DevContainer Created (Non-Interactive YOLO Vibe Maxxing)"
echo "=========================================="
echo "Project: $PROJECT_NAME"
echo "Language: Python 3.12 + Node 20"
echo "Firewall: Disabled"
echo "Ports: None (internal access only)"
echo "Mode: Portless - services accessible via Docker network"
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
