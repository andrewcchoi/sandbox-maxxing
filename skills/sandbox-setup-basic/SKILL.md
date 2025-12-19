---
name: sandbox-setup-basic
description: Use when user wants the simplest sandbox setup - uses sandbox templates or official images only, docker-compose when appropriate, no firewall (relies on sandbox isolation)
---

# Sandbox Setup: Basic Mode

## TASK IDENTITY

You are a **DevContainer Configuration Generator**. This is a file generation task.

**Your output:** VS Code DevContainer files in `.devcontainer/` directory
**Technology:** Docker, VS Code Dev Containers
**NOT related to:** Claude Code settings, Claude Code sandbox, `.claude/` configs

## What This Skill Creates

**⚠️ CRITICAL: THIS SKILL CREATES A DEVCONTAINER SETUP, NOT CLAUDE CODE'S SANDBOX FEATURE.**

You will create VS Code DevContainer files in the project's `.devcontainer/` directory:
- `.devcontainer/Dockerfile` - Multi-stage Dockerfile with all required tools
- `.devcontainer/devcontainer.json` - DevContainer configuration for VS Code
- `.devcontainer/setup-claude-credentials.sh` - Claude credentials persistence (Issue #30)
- `docker-compose.yml` - Docker services configuration (in project root)

**NOTE:** Basic mode has NO firewall script (relies on container isolation only)

### What This Is:
- A **file generation task** that creates DevContainer configuration files
- Files that enable VS Code's "Reopen in Container" feature
- Docker-based development environment configuration

### YOUR EXCLUSIVE OUTPUT FILES:

| File | Location | Purpose |
|------|----------|---------|
| `Dockerfile` | `.devcontainer/Dockerfile` | Multi-stage Docker image |
| `devcontainer.json` | `.devcontainer/devcontainer.json` | VS Code DevContainer config |
| `setup-claude-credentials.sh` | `.devcontainer/setup-claude-credentials.sh` | Credentials helper |
| `docker-compose.yml` | `./docker-compose.yml` | Docker services |

**Task Boundary:** This skill generates DevContainer files ONLY. Claude Code configuration is a different feature.

### After Creating Files:
The user will use VS Code's "Dev Containers: Reopen in Container" command to start the environment. You only create the configuration files.

## PRE-WRITE VALIDATION (MANDATORY)

**BEFORE creating ANY file, verify the path:**

| Path Pattern | Valid? | Action |
|--------------|--------|--------|
| `.devcontainer/*` | ✓ YES | Proceed |
| `docker-compose.yml` | ✓ YES | Proceed |
| `.claude/*` | ✗ NO | STOP - Wrong task |
| `.claude-code/*` | ✗ NO | STOP - Wrong task |
| `~/.claude*` | ✗ NO | STOP - Wrong location |

**Self-Check:** "Does my file path start with `.devcontainer/` or is it `docker-compose.yml`?"
If NO → STOP and re-read the TASK IDENTITY section.

## MANDATORY FIRST STEP - COPY TEMPLATES

**⚠️ NEW WORKFLOW: Copy templates first, then customize.**

### Step 1A: Find Template Directories

Templates are organized in two locations:
- **Shared templates**: Common files used by all modes
- **Mode-specific templates**: Unique files for this mode

```bash
# Find the skill directory (relative to this SKILL.md file)
SKILL_DIR="$(dirname "${BASH_SOURCE[0]}")"

# Shared templates are at plugin root
PLUGIN_ROOT="$(cd "$SKILL_DIR/../.." && pwd)"
SHARED_DIR="$PLUGIN_ROOT/templates/shared"

# Mode-specific templates are in this skill folder
MODE_DIR="$SKILL_DIR/templates"

echo "Shared templates: $SHARED_DIR"
echo "Mode templates: $MODE_DIR"
```

**Verify templates exist:**
```bash
ls -la "$SHARED_DIR/"
ls -la "$MODE_DIR/"
```

If either directory is missing, STOP and report the error.

### Step 1B: Copy Template Files

**Use Bash to copy the complete template structure:**

```bash
# Create .devcontainer directory
mkdir -p .devcontainer

# Copy shared files (Dockerfiles, compose, credentials)
cp "$SHARED_DIR/docker-compose.yml" ./docker-compose.yml
cp "$SHARED_DIR/Dockerfile.python" .devcontainer/Dockerfile.python
cp "$SHARED_DIR/Dockerfile.node" .devcontainer/Dockerfile.node
cp "$SHARED_DIR/setup-claude-credentials.sh" .devcontainer/setup-claude-credentials.sh

# Copy mode-specific files (devcontainer.json)
cp "$MODE_DIR/devcontainer.json" .devcontainer/devcontainer.json

# Make scripts executable
chmod +x .devcontainer/setup-claude-credentials.sh
```

**NOTE:** Basic mode has NO firewall script. Only credentials + Dockerfiles + devcontainer.json.

### Step 1C: Verify Files Were Copied

**MANDATORY verification - run these commands:**

```bash
echo "=== File Verification ==="
test -f docker-compose.yml && echo "✓ docker-compose.yml" || echo "✗ MISSING: docker-compose.yml"
test -d .devcontainer && echo "✓ .devcontainer/" || echo "✗ MISSING: .devcontainer/"
test -f .devcontainer/devcontainer.json && echo "✓ devcontainer.json" || echo "✗ MISSING"
test -f .devcontainer/setup-claude-credentials.sh && echo "✓ setup-claude-credentials.sh" || echo "✗ MISSING"
test -f .devcontainer/Dockerfile.python && echo "✓ Dockerfile.python" || echo "✗ MISSING"
test -f .devcontainer/Dockerfile.node && echo "✓ Dockerfile.node" || echo "✗ MISSING"

# Verify Dockerfile has multi-stage build
echo "Dockerfile.python lines: $(wc -l < .devcontainer/Dockerfile.python)"
grep -c "^FROM.*AS" .devcontainer/Dockerfile.python && echo "✓ Multi-stage build" || echo "✗ WARNING: No multi-stage"
```

**If ANY required file is missing, STOP. Debug the copy step before continuing.**

## STEP 2: CUSTOMIZE TEMPLATE FILES

After copying templates, customize them for the user's project:

### Step 2A: Detect Project Type

```bash
# Detect language from project files
ls -la requirements.txt package.json Gemfile go.mod Cargo.toml composer.json pom.xml
```

**Detection Logic:**
- `requirements.txt` or `pyproject.toml` → Python (use Dockerfile.python)
- `package.json` → Node.js (use Dockerfile.node)
- Others → Ask user for language

### Step 2B: Rename Dockerfile for Detected Language

```bash
# For Python projects:
mv .devcontainer/Dockerfile.python .devcontainer/Dockerfile
rm .devcontainer/Dockerfile.node

# For Node.js projects:
mv .devcontainer/Dockerfile.node .devcontainer/Dockerfile
rm .devcontainer/Dockerfile.python
```

### Step 2C: Customize docker-compose.yml

Use the Edit tool to replace placeholders:

```
{{PROJECT_NAME}} → actual-project-name
{{NETWORK_NAME}} → actual-project-name-network
```

### Step 2D: Customize devcontainer.json

Use the Edit tool to:
1. Replace `{{PROJECT_NAME}}` with actual project name
2. Add language-specific extensions

**For Python**, add to extensions array:
```json
"ms-python.python",
"ms-python.vscode-pylance"
```

**For Node.js**, add to extensions array:
```json
"dbaeumer.vscode-eslint",
"esbenp.prettier-vscode"
```

### Step 2E: Update docker-compose.yml build context

The template uses `build:` with Dockerfile. Verify this is correct in docker-compose.yml.

## MANDATORY DOCKERFILE REQUIREMENTS

When generating a Dockerfile (not using docker-compose image directly), ALL Dockerfiles MUST include:

### Multi-Stage Build (Required for Python projects)
```dockerfile
# Stage 1: Get Node.js from official image (Issue #29)
FROM node:20-slim AS node-source

# Stage 2: Get uv from official Astral image (Python projects)
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS uv-source

# Stage 3: Main build
FROM <base-image>
```

### Mandatory Base Packages (ALWAYS install these)
```dockerfile
RUN apt-get update && apt-get install -y --no-install-recommends \
  # Core utilities
  git vim nano less procps sudo unzip wget curl ca-certificates gnupg gnupg2 \
  # JSON processing and manual pages
  jq man-db \
  # Shell and CLI enhancements
  zsh fzf \
  # GitHub CLI
  gh \
  # Network security tools (firewall)
  iptables ipset iproute2 dnsutils \
  && apt-get clean && rm -rf /var/lib/apt/lists/*
```

### Mandatory Tools (ALWAYS install these)
1. **git-delta** - Enhanced git diff
2. **ZSH with Powerlevel10k** - Full shell experience
3. **Claude Code CLI** - `npm install -g @anthropic-ai/claude-code`
4. **DeepAgents + Tavily** - AI/LLM tools (via uv/pip)
5. **Mermaid CLI** - Diagram generation

## Overview

The Basic mode provides the fastest path to a working sandbox environment. This mode is optimized for:

- Quick setup with minimal configuration
- Pre-built templates and official Docker images
- No firewall configuration (relies on sandbox isolation)
- Automatic project detection and sensible defaults
- 1-2 user questions maximum

Basic mode gets developers up and running in minutes using battle-tested base images without custom security layers.

## Usage

This skill is invoked via the `/sandboxxer:basic` command or by selecting "Basic Mode" from the `/sandboxxer:setup` interactive mode selector.

**Command:**
```
/sandboxxer:basic
```

The skill will:
1. Detect your project type automatically
2. Ask 1-2 minimal questions
3. Generate DevContainer configuration files in `.devcontainer/`
4. Configure docker-compose for multi-service projects

## When to Use This Skill

### Use Basic Mode When

- User wants the simplest, fastest setup
- User is a beginner or prototyping
- User accepts pre-built templates or official images
- Project is straightforward (single language, standard stack)
- User doesn't need custom network restrictions
- Getting started quickly is the priority

### Do NOT Use Basic Mode When

- User needs custom firewall rules or network restrictions
- User wants full control over Dockerfile and build process
- User is troubleshooting an existing setup (use `sandbox-troubleshoot` instead)
- User explicitly requests advanced features or YOLO mode
- Project requires complex multi-service orchestration with custom networking

**Important**: If user mentions firewall, iptables, network policies, or security hardening, recommend Advanced or YOLO mode instead.

## Key Characteristics

### Base Images

**Primary Option**: `docker/sandbox-templates` tags
- `claude-code` - Optimized for Claude Code (recommended)
- `latest` - Latest stable release
- `ubuntu-python` - Ubuntu with Python pre-installed

**Alternative**: Official Docker images
- Used when specific language/runtime is needed
- Examples: `python:3.12-slim-bookworm`, `node:20-bookworm-slim`, `ruby:3.3-slim-bookworm`

### Dockerfile

- **None** - Direct image reference in devcontainer.json (preferred)
- **Minimal** - Only if absolutely needed for basic dependencies

### Firewall

**NONE** - Relies on sandbox isolation only. No iptables, no init-firewall.sh.

### Services

- Use `docker-compose.yml` when database, cache, or other services are needed
- Common services: postgres, redis, mysql, mongo
- Services automatically networked together

### User Interaction

- Maximum 1-2 questions
- Automatic project detection from files
- Sensible defaults for everything

## Available Base Images

### Sandbox Templates

Reference: `${CLAUDE_PLUGIN_ROOT}/data/sandbox-templates.json`

**Recommended for Basic Mode:**

1. **claude-code** (366 MB)
   - Optimized for Claude Code workflows
   - Includes common development tools
   - Pull command: `docker pull docker/sandbox-templates:claude-code`

2. **latest** (329 MB)
   - Latest stable release
   - General purpose development
   - Pull command: `docker pull docker/sandbox-templates:latest`

3. **ubuntu-python** (323 MB)
   - Ubuntu base with Python pre-installed
   - Good for Python-focused projects
   - Pull command: `docker pull docker/sandbox-templates:ubuntu-python`

### Official Images

Reference: `${CLAUDE_PLUGIN_ROOT}/data/official-images.json`

**Language Runtimes:**

- **Python**: `python:3.12-slim-bookworm` (recommended default)
- **Node.js**: `node:20-bookworm-slim` (LTS, recommended)
- **Ruby**: `ruby:3.3-slim-bookworm`
- **Go**: `golang:1.22-bookworm`
- **PHP**: `php:8.4-fpm-bookworm`
- **Java**: `openjdk:21-slim-bookworm`
- **Rust**: `rust:1.75-slim-bookworm`
- **C/C++**: `gcc:13-bookworm`

**Services:**

- **PostgreSQL**: `postgres:16-bookworm`
- **Redis**: `redis:7-alpine`
- **MySQL**: `mysql:8.0`
- **MongoDB**: `mongo:7`
- **RabbitMQ**: `rabbitmq:3.13-management`
- **Nginx**: `nginx:1.25-bookworm`

## Template References

When generating configuration, use these template files:

- **Extensions**: `${CLAUDE_PLUGIN_ROOT}/templates/extensions/extensions.basic.json`
  - Read this file and merge base extensions with platform-specific extensions
  - Base extensions: `anthropic.claude-code`, `ms-azuretools.vscode-docker`, `redhat.vscode-yaml`, `eamodio.gitlens`, `PKief.material-icon-theme`, `johnpapa.vscode-peacock`
  - Platform extensions: Python (`ms-python.python`, `ms-python.vscode-pylance`), Node (`dbaeumer.vscode-eslint`, `esbenp.prettier-vscode`), etc.

- **Docker Compose**: `${CLAUDE_PLUGIN_ROOT}/templates/compose/docker-compose.basic.yml`
  - Template includes postgres and redis services
  - Add app service with credentials mount

- **Firewall**: `${CLAUDE_PLUGIN_ROOT}/templates/firewall/basic-no-firewall.sh`
  - No-op script that relies on sandbox isolation
  - Copy to `.devcontainer/init-firewall.sh`

- **Credentials Setup**: Create `.devcontainer/setup-claude-credentials.sh` for Issue #30
  - Copies Claude credentials from host mount to container
  - Essential for credentials persistence across container rebuilds

**Important**: Always read the extensions template file and merge with platform-specific extensions. DO NOT use inline extension lists.

## File Creation Location

**CRITICAL**: All generated files must be created in the user's current working directory (project root).

### Before generating files:

1. **Verify you're in the user's project directory** (where their source code is)
2. **Create the `.devcontainer/` directory**:
   ```bash
   mkdir -p .devcontainer
   ```

### Files to create (paths relative to project root):

- `docker-compose.yml` - Docker services configuration (in project root)
- `.devcontainer/devcontainer.json` - DevContainer configuration
- `.devcontainer/init-firewall.sh` - Firewall script (basic mode: no-op script)
- `.devcontainer/setup-claude-credentials.sh` - Credentials setup (Issue #30)

### DO NOT create files in:

- `~/.claude-code/` or `~/.claude/` (home directory configs)
- `/root/.claude-code/` or any user home directory
- Any system directory like `/etc/` or `/var/`

**Why this matters**: The DevContainer configuration MUST be in the project's `.devcontainer/` folder for VS Code and Claude Code to detect and use it. Creating files in the wrong location will result in a non-functional setup.

## Workflow

### Step 1: Project Detection (Automatic)

Detect project type from existing files:

```bash
# Look for language/framework indicators
ls -la requirements.txt package.json Gemfile go.mod Cargo.toml composer.json pom.xml
```

**Detection Logic:**

- `requirements.txt` or `pyproject.toml` → Python
- `package.json` → Node.js
- `Gemfile` → Ruby
- `go.mod` → Go
- `Cargo.toml` → Rust
- `composer.json` → PHP
- `pom.xml` or `build.gradle` → Java

If project type is clear, proceed automatically. If unclear, ask single question.

### Step 2: Single Question (Only if Needed)

If project type cannot be auto-detected, ask:

```
I couldn't detect your project type automatically. What's your primary language or framework?
(e.g., Python, Node.js, Ruby, Go, etc.)
```

**Do not ask:**
- About services (auto-detect from docker-compose.yml or assume none)
- About versions (use recommended defaults)
- About configuration details (use sensible defaults)

### Step 3: Generate Configuration

**Important**: ALL basic mode setups use docker-compose.yml. This enables:
- Credentials mounting for Issue #30 (persistent Claude credentials)
- Consistent configuration approach
- Easy service addition later

Generate these files:

#### File 1: `docker-compose.yml`

```yaml
version: '3.8'

services:
  app:
    image: python:3.12-slim-bookworm  # Use detected language image
    volumes:
      - .:/workspace:cached
      - ~/.claude:/tmp/host-claude:ro  # Issue #30: credentials mount
    working_dir: /workspace
    command: sleep infinity
    # Add depends_on if services needed (postgres, redis, etc.)

  # Add services from templates/compose/docker-compose.basic.yml if needed
  # postgres:
  #   image: postgres:16-bookworm
  #   environment:
  #     POSTGRES_USER: devuser
  #     POSTGRES_PASSWORD: devpass
  #     POSTGRES_DB: devdb
  #   ports:
  #     - "5432:5432"
  #   volumes:
  #     - postgres-data:/var/lib/postgresql/data
  #
  # redis:
  #   image: redis:7-alpine
  #   ports:
  #     - "6379:6379"

# volumes:
#   postgres-data:
```

#### File 2: `.devcontainer/devcontainer.json`

Read extensions from `${CLAUDE_PLUGIN_ROOT}/templates/extensions/extensions.basic.json` and merge with platform-specific extensions.

```json
{
  "name": "{{PROJECT_NAME}} Sandbox",
  "dockerComposeFile": "../docker-compose.yml",
  "service": "app",
  "workspaceFolder": "/workspace",
  "remoteUser": "node",
  "customizations": {
    "vscode": {
      "extensions": [
        // Base extensions from templates/extensions/extensions.basic.json
        "anthropic.claude-code",
        "ms-azuretools.vscode-docker",
        "redhat.vscode-yaml",
        "eamodio.gitlens",
        "PKief.material-icon-theme",
        "johnpapa.vscode-peacock",
        // Platform-specific (example for Python)
        "ms-python.python",
        "ms-python.vscode-pylance"
      ]
    }
  },
  "postStartCommand": ".devcontainer/init-firewall.sh",
  "postCreateCommand": ".devcontainer/setup-claude-credentials.sh && pip install -r requirements.txt",
  "forwardPorts": [8000, 5432, 6379]
}
```

#### File 3: `.devcontainer/init-firewall.sh`

Copy from `${CLAUDE_PLUGIN_ROOT}/templates/firewall/basic-no-firewall.sh`:

```bash
#!/bin/bash
echo "=========================================="
echo "FIREWALL: BASIC MODE"
echo "=========================================="
echo "No firewall configured (Basic mode - relies on sandbox isolation)"
echo "Firewall configuration complete (no restrictions applied)"
echo "=========================================="
exit 0
```

Make executable: `chmod +x .devcontainer/init-firewall.sh`

#### File 4: `.devcontainer/setup-claude-credentials.sh`

Create credentials setup script for Issue #30:

```bash
#!/bin/bash
# Copy Claude credentials from host mount to container
if [ -d "/tmp/host-claude" ]; then
  mkdir -p ~/.claude
  cp -r /tmp/host-claude/* ~/.claude/ 2>/dev/null || true
  echo "Claude credentials copied successfully"
fi
```

Make executable: `chmod +x .devcontainer/setup-claude-credentials.sh`

### Step 4: Auto-Pull Images

After generating configuration, ask user:

```
Configuration ready. I'll pull the following Docker images:
  - docker/sandbox-templates:claude-code (366 MB)

Ready to download? [Y/n]
```

If user confirms (or gives "Y"), run pull commands:

```bash
docker pull docker/sandbox-templates:claude-code
```

For docker-compose setups:

```bash
docker compose pull
```

**Handle errors**: If pull fails, suggest checking internet connection or Docker Hub status.

### Step 5: Next Steps

Provide clear instructions:

```
Setup complete! Next steps:

1. Open project in Dev Container:
   - VS Code: Reopen in Container (Cmd/Ctrl+Shift+P → "Dev Containers: Reopen in Container")
   - Claude Code: Use devcontainer CLI

2. Verify services (if using docker-compose):
   docker compose ps

3. Install dependencies:
   - Python: pip install -r requirements.txt
   - Node.js: npm install
   - Ruby: bundle install

Your sandbox is ready to use!
```

## Configuration Examples

### Example 1: Python Project (No Services)

**Detected files**: `requirements.txt`

**Generated files**:

**docker-compose.yml**:
```yaml
version: '3.8'

services:
  app:
    image: python:3.12-slim-bookworm
    volumes:
      - .:/workspace:cached
      - ~/.claude:/tmp/host-claude:ro
    working_dir: /workspace
    command: sleep infinity
```

**.devcontainer/devcontainer.json**:
```json
{
  "name": "Python Sandbox",
  "dockerComposeFile": "../docker-compose.yml",
  "service": "app",
  "workspaceFolder": "/workspace",
  "remoteUser": "node",
  "customizations": {
    "vscode": {
      "extensions": [
        "anthropic.claude-code",
        "ms-azuretools.vscode-docker",
        "redhat.vscode-yaml",
        "eamodio.gitlens",
        "PKief.material-icon-theme",
        "johnpapa.vscode-peacock",
        "ms-python.python",
        "ms-python.vscode-pylance"
      ]
    }
  },
  "postStartCommand": ".devcontainer/init-firewall.sh",
  "postCreateCommand": ".devcontainer/setup-claude-credentials.sh && pip install -r requirements.txt",
  "forwardPorts": [8000]
}
```

Plus `.devcontainer/init-firewall.sh` and `.devcontainer/setup-claude-credentials.sh`

### Example 2: Node.js + PostgreSQL

**Detected files**: `package.json`

**Generated files**:

**docker-compose.yml**:
```yaml
version: '3.8'

services:
  app:
    image: node:20-bookworm-slim
    volumes:
      - .:/workspace:cached
      - ~/.claude:/tmp/host-claude:ro
    working_dir: /workspace
    command: sleep infinity
    depends_on:
      - postgres

  postgres:
    image: postgres:16-bookworm
    environment:
      POSTGRES_USER: devuser
      POSTGRES_PASSWORD: devpass
      POSTGRES_DB: devdb
    ports:
      - "5432:5432"
    volumes:
      - postgres-data:/var/lib/postgresql/data

volumes:
  postgres-data:
```

**.devcontainer/devcontainer.json**:
```json
{
  "name": "Node.js + PostgreSQL Sandbox",
  "dockerComposeFile": "../docker-compose.yml",
  "service": "app",
  "workspaceFolder": "/workspace",
  "remoteUser": "node",
  "customizations": {
    "vscode": {
      "extensions": [
        "anthropic.claude-code",
        "ms-azuretools.vscode-docker",
        "redhat.vscode-yaml",
        "eamodio.gitlens",
        "PKief.material-icon-theme",
        "johnpapa.vscode-peacock",
        "dbaeumer.vscode-eslint",
        "esbenp.prettier-vscode"
      ]
    }
  },
  "postStartCommand": ".devcontainer/init-firewall.sh",
  "postCreateCommand": ".devcontainer/setup-claude-credentials.sh && npm install",
  "forwardPorts": [3000, 5432]
}
```

Plus `.devcontainer/init-firewall.sh` and `.devcontainer/setup-claude-credentials.sh`

### Example 3: Full-Stack (React + Python + PostgreSQL + Redis)

**Detected files**: `package.json`, `requirements.txt`

**Generated files**:

**docker-compose.yml**:
```yaml
version: '3.8'

services:
  app:
    image: docker/sandbox-templates:claude-code
    volumes:
      - .:/workspace:cached
      - ~/.claude:/tmp/host-claude:ro
    working_dir: /workspace
    command: sleep infinity
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:16-bookworm
    environment:
      POSTGRES_USER: devuser
      POSTGRES_PASSWORD: devpass
      POSTGRES_DB: devdb
    ports:
      - "5432:5432"
    volumes:
      - postgres-data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

volumes:
  postgres-data:
```

**.devcontainer/devcontainer.json**:
```json
{
  "name": "Full-Stack Sandbox",
  "dockerComposeFile": "../docker-compose.yml",
  "service": "app",
  "workspaceFolder": "/workspace",
  "remoteUser": "node",
  "customizations": {
    "vscode": {
      "extensions": [
        "anthropic.claude-code",
        "ms-azuretools.vscode-docker",
        "redhat.vscode-yaml",
        "eamodio.gitlens",
        "PKief.material-icon-theme",
        "johnpapa.vscode-peacock",
        "ms-python.python",
        "ms-python.vscode-pylance",
        "dbaeumer.vscode-eslint",
        "esbenp.prettier-vscode"
      ]
    }
  },
  "postStartCommand": ".devcontainer/init-firewall.sh",
  "postCreateCommand": ".devcontainer/setup-claude-credentials.sh && pip install -r requirements.txt && npm install",
  "forwardPorts": [8000, 3000, 5432, 6379]
}
```

Plus `.devcontainer/init-firewall.sh` and `.devcontainer/setup-claude-credentials.sh`

## Integration with Other Skills

### After Successful Setup

Inform user about upgrade options:

```
Your Basic sandbox is ready!

Need more control?
- Advanced mode: Custom Dockerfile + firewall rules
- YOLO mode: Full security hardening + network policies

Run `/sandbox:advanced` or `/sandbox:yolo` to upgrade.
```

### On Errors

If setup fails or user encounters issues:

```
Encountered an error during setup. For troubleshooting assistance, invoke:

/sandbox:troubleshoot

Or switch to Advanced/YOLO mode for more control:

/sandbox:advanced
/sandbox:yolo
```

Automatically invoke `sandbox-troubleshoot` skill if:
- Docker pull fails repeatedly
- devcontainer fails to start
- Services fail to connect
- Permission errors occur

## Decision Tree

```
START
  |
  v
Can detect project type automatically?
  |-- YES --> Use detected language/framework
  |-- NO  --> Ask single question: "What's your primary language?"
  |
  v
Does project need database/cache/services?
  |-- YES --> Generate docker-compose.yml + devcontainer.json
  |-- NO  --> Generate minimal devcontainer.json only
  |
  v
Which base image?
  |-- General development --> docker/sandbox-templates:claude-code
  |-- Specific language   --> Official image (python, node, ruby, etc.)
  |-- Multi-language      --> docker/sandbox-templates:claude-code
  |
  v
Generate configuration files
  |
  v
Ask: "Ready to download images? [Y/n]"
  |-- YES --> docker pull images
  |-- NO  --> Skip pull
  |
  v
Provide next steps and completion message
  |
  v
END
```

## Best Practices

### DO

- Auto-detect project type from files
- Use recommended image tags (e.g., `slim-bookworm`, LTS versions)
- Keep configuration minimal and readable
- Provide clear next steps after setup
- Use `docker/sandbox-templates:claude-code` when in doubt
- Pre-pull images to catch download issues early

### DON'T

- Don't ask unnecessary questions
- Don't create custom Dockerfiles unless absolutely required
- Don't add firewall configuration (that's Advanced/YOLO mode)
- Don't overcomplicate docker-compose.yml
- Don't use `latest` tag for official images (use specific versions)
- Don't proceed with stale/unverified images

### Error Handling

**Common Issues:**

1. **Docker pull fails**
   - Check internet connection
   - Verify Docker Hub status
   - Suggest docker login if authentication required

2. **Service fails to start**
   - Check port conflicts: `docker ps` and `lsof -i :PORT`
   - Verify docker-compose.yml syntax
   - Check Docker Desktop is running

3. **Permission errors**
   - Remind user that Basic mode uses `root` user
   - Suggest Advanced/YOLO mode if custom user needed

## Security Note

Basic mode relies on Docker sandbox isolation only. No firewall rules are configured.

**Security features:**
- Docker container isolation
- No host network access
- Limited resource access

**Not included:**
- iptables firewall rules
- Custom network policies
- Outbound traffic restrictions

For production-like security, recommend Advanced or YOLO mode.

## POST-GENERATION VALIDATION (MANDATORY)

After generating files, verify these conditions:

### Dockerfile Validation
```bash
# Check for multi-stage build
grep -c "^FROM.*AS" .devcontainer/Dockerfile  # Should be >= 1

# Check for mandatory packages
grep -q "git vim nano less procps" .devcontainer/Dockerfile || echo "MISSING: Core utilities"
grep -q "zsh fzf" .devcontainer/Dockerfile || echo "MISSING: Shell enhancements"
grep -q "git-delta" .devcontainer/Dockerfile || echo "MISSING: git-delta"
grep -q "powerlevel10k\|zsh-in-docker" .devcontainer/Dockerfile || echo "MISSING: ZSH theme"
grep -q "claude-code" .devcontainer/Dockerfile || echo "MISSING: Claude Code CLI"

# Check line count (should be substantial)
wc -l .devcontainer/Dockerfile  # Should be >= 50 lines
```

**If any check fails, RE-READ the template file and regenerate.**

## Completion Checklist

**Before finishing the setup, verify ALL these files exist:**

Run these verification commands:

```bash
# Check .devcontainer directory exists
test -d .devcontainer && echo "✓ .devcontainer/ directory exists" || echo "✗ MISSING: .devcontainer/ directory"

# Check each required file
test -f docker-compose.yml && echo "✓ docker-compose.yml exists" || echo "✗ MISSING: docker-compose.yml"
test -f .devcontainer/devcontainer.json && echo "✓ devcontainer.json exists" || echo "✗ MISSING: devcontainer.json"
test -f .devcontainer/init-firewall.sh && echo "✓ init-firewall.sh exists" || echo "✗ MISSING: init-firewall.sh"
test -f .devcontainer/setup-claude-credentials.sh && echo "✓ setup-claude-credentials.sh exists" || echo "✗ MISSING: setup-claude-credentials.sh"
```

**Required files checklist:**
1. [ ] `docker-compose.yml` in project root (NOT in .devcontainer/)
2. [ ] `.devcontainer/` directory exists
3. [ ] `.devcontainer/devcontainer.json` exists with proper configuration
4. [ ] `.devcontainer/init-firewall.sh` exists and is executable (`chmod +x`)
5. [ ] `.devcontainer/setup-claude-credentials.sh` exists and is executable (`chmod +x`)

**If ANY file is missing, CREATE IT NOW before completing.**

## PROHIBITED FILES - NEVER CREATE THESE

If you find yourself about to write ANY of these files, you are doing the WRONG task:

- ❌ `.claude-code.json` - WRONG (this is Claude Code's sandbox config, NOT DevContainer)
- ❌ `.claude/config.json` - WRONG (this is Claude Code config, NOT DevContainer)
- ❌ `.claude-code/settings.json` - WRONG (this is Claude Code settings, NOT DevContainer)
- ❌ `/root/.claude-code/settings.json` - WRONG (wrong location entirely)
- ❌ `Dockerfile` in project root - WRONG (should be in .devcontainer/ for intermediate/advanced/yolo modes)

**If you created any of these files by mistake, DELETE THEM and create the correct DevContainer files instead.**

## Summary

Basic mode is optimized for speed and simplicity:

1. Auto-detect project type
2. Ask 1 question maximum
3. Generate minimal configuration
4. Pull images with confirmation
5. Provide next steps

Total time: 2-5 minutes from start to working sandbox.

---

**Last Updated:** 2025-12-16
**Version:** 3.0.0
