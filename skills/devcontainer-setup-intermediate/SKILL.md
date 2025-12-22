---
name: devcontainer-setup-intermediate
description: Use when user wants standard sandbox with Dockerfile, permissive firewall for convenience, and common service options - good balance of flexibility and simplicity
---

# Sandbox Setup - Intermediate Mode

## NON-INTERACTIVE MODE (Automated Testing)

**CRITICAL: Check for automated test mode FIRST before any other action.**

If the user's message contains responses in this format:
```
AUTOMATED_TEST_MODE
RESPONSES:
response1
response2
response3
...
```

Then:
1. **DO NOT call AskUserQuestion** - use provided responses instead
2. Extract responses into an array
3. Use responses sequentially when questions would normally be asked
4. Execute the entire skill workflow without interaction

**Response order for intermediate mode:**
1. Project name (e.g., "demo-app")
2. Programming language (e.g., "python", "node")
3. Services needed (e.g., "postgres", "redis", "mysql", or comma-separated)
4. Confirmation (e.g., "yes", "y")

**Example automated invocation:**
```
AUTOMATED_TEST_MODE
RESPONSES:
demo-app
python
postgres
yes
```

When in automated mode, proceed directly to file generation without any interaction.

## TASK IDENTITY

You are a **DevContainer Configuration Generator**. This is a file generation task.

**Your output:** VS Code DevContainer files in `.devcontainer/` directory
**Technology:** Docker, VS Code Dev Containers
**NOT related to:** Claude Code settings, Claude Code sandbox, `.claude/` configs

## What This Skill Creates

**⚠️ CRITICAL: THIS SKILL CREATES A DEVCONTAINER SETUP, NOT CLAUDE CODE'S SANDBOX FEATURE.**

You will create VS Code DevContainer files in the project's `.devcontainer/` directory:
- `.devcontainer/Dockerfile` - Custom Dockerfile with language-specific tools
- `.devcontainer/devcontainer.json` - DevContainer configuration for VS Code
- `.devcontainer/init-firewall.sh` - Firewall initialization script (intermediate: permissive)
- `.devcontainer/setup-claude-credentials.sh` - Claude credentials persistence (Issue #30)
- `docker-compose.yml` - Docker services configuration (in project root)

### What This Is:
- A **file generation task** that creates DevContainer configuration files
- Files that enable VS Code's "Reopen in Container" feature
- Docker-based development environment with custom Dockerfile

### YOUR EXCLUSIVE OUTPUT FILES:

| File | Location | Purpose |
|------|----------|---------|
| `Dockerfile` | `.devcontainer/Dockerfile` | Custom container image |
| `devcontainer.json` | `.devcontainer/devcontainer.json` | VS Code DevContainer config |
| `init-firewall.sh` | `.devcontainer/init-firewall.sh` | Firewall script (intermediate: permissive) |
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

### Step 1A: Find Template Directory

All templates for this mode are in the skill's `templates/` folder (self-contained).

```bash
# Find the skill directory (relative to this SKILL.md file)
SKILL_DIR="$(dirname "${BASH_SOURCE[0]}")"
TEMPLATES="$SKILL_DIR/templates"

echo "Templates location: $TEMPLATES"
```

**Verify templates exist:**
```bash
ls -la "$TEMPLATES/"
```

If the directory is missing, STOP and report the error.

### Step 1B: Copy Template Files

```bash
# Create .devcontainer directory
mkdir -p .devcontainer

# Copy ALL templates from skill folder
cp "$TEMPLATES/docker-compose.yml" ./docker-compose.yml
cp "$TEMPLATES/Dockerfile.python" .devcontainer/Dockerfile.python
cp "$TEMPLATES/Dockerfile.node" .devcontainer/Dockerfile.node
cp "$TEMPLATES/setup-claude-credentials.sh" .devcontainer/setup-claude-credentials.sh
cp "$TEMPLATES/devcontainer.json" .devcontainer/devcontainer.json
cp "$TEMPLATES/init-firewall.sh" .devcontainer/init-firewall.sh
cp "$TEMPLATES/.env.template" ./.env.template
cp "$TEMPLATES/extensions.json" .devcontainer/extensions.json
cp "$TEMPLATES/mcp.json" .devcontainer/mcp.json
cp "$TEMPLATES/variables.json" .devcontainer/variables.json

# Make scripts executable
chmod +x .devcontainer/setup-claude-credentials.sh .devcontainer/init-firewall.sh
```

**NOTE:** Intermediate mode INCLUDES permissive firewall script.

### Step 1C: Verify Files

```bash
echo "=== File Verification ==="
test -f docker-compose.yml && echo "✓ docker-compose.yml" || echo "✗ MISSING"
test -f .devcontainer/Dockerfile.python && echo "✓ Dockerfile.python" || echo "✗ MISSING"
test -f .devcontainer/Dockerfile.node && echo "✓ Dockerfile.node" || echo "✗ MISSING"
test -f .devcontainer/devcontainer.json && echo "✓ devcontainer.json" || echo "✗ MISSING"
test -f .devcontainer/init-firewall.sh && echo "✓ init-firewall.sh" || echo "✗ MISSING"
test -f .devcontainer/setup-claude-credentials.sh && echo "✓ setup-claude-credentials.sh" || echo "✗ MISSING"
test -f .env.template && echo "✓ .env.template" || echo "✗ MISSING"
test -f .devcontainer/extensions.json && echo "✓ extensions.json" || echo "✗ MISSING"
test -f .devcontainer/mcp.json && echo "✓ mcp.json" || echo "✗ MISSING"
test -f .devcontainer/variables.json && echo "✓ variables.json" || echo "✗ MISSING"
echo "Dockerfile.python lines: $(wc -l < .devcontainer/Dockerfile.python)"
```

**If ANY file is missing, STOP.**

## STEP 2: CUSTOMIZE TEMPLATE FILES

### Step 2A: Detect Project Type & Rename Dockerfile

```bash
# For Python:
mv .devcontainer/Dockerfile.python .devcontainer/Dockerfile && rm .devcontainer/Dockerfile.node

# For Node.js:
mv .devcontainer/Dockerfile.node .devcontainer/Dockerfile && rm .devcontainer/Dockerfile.python
```

### Step 2B: Customize Placeholders

Use Edit tool to replace `{{PROJECT_NAME}}` and add language-specific extensions.

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

## CRITICAL: USE ACTUAL TEMPLATE FILES

**DO NOT generate simplified Dockerfiles.** Always:
1. READ `${CLAUDE_PLUGIN_ROOT}/skills/devcontainer-setup-intermediate/templates/Dockerfile.<language>`
2. COPY the template content EXACTLY
3. Only modify placeholder values (PROJECT_NAME, etc.)

The templates contain:
- Proper multi-stage builds
- All mandatory packages
- ZSH + Powerlevel10k configuration
- AI tools (DeepAgents, Tavily)
- Claude Code CLI

**If you generate a Dockerfile with fewer than 50 lines, you are doing it wrong.**

## Overview

Intermediate mode provides a standard Dockerfile-based development sandbox with a permissive firewall configuration and flexible service options. This mode offers a good balance between flexibility and simplicity, making it ideal for developers who want Docker customization capabilities without the complexity of fine-grained firewall rules.

**Key Features:**
- Standard Dockerfile template with common development tools
- Permissive firewall (no network restrictions)
- Full service selection (databases, caches, message queues)
- Official base images only
- 4-6 configuration questions for streamlined setup

## Usage

This skill is invoked via the `/devcontainer:intermediate` command or by selecting "Intermediate Mode" from the `/devcontainer:setup` interactive mode selector.

**Command:**
```
/devcontainer:intermediate
```

The skill will:
1. Ask 4-6 configuration questions (project details, services, extensions)
2. Generate a custom Dockerfile with development tools
3. Create DevContainer configuration in `.devcontainer/`
4. Configure docker-compose with selected services
5. Set up permissive firewall (no network restrictions)

## When to Use This Skill

**Use Intermediate Mode When:**
- User wants a standard sandbox with common service options
- User is comfortable with basic Docker concepts
- User needs database or cache services
- User wants convenience over security restrictions
- User is setting up a development environment (not production-like)
- User wants quick setup with some customization options

**Do NOT Use Intermediate Mode When:**
- User wants minimal setup with no Dockerfile → Use `devcontainer-setup-basic` instead
- User needs custom firewall rules or specific network restrictions → Use `devcontainer-setup-advanced` instead
- User wants complete control over all configuration → Use `devcontainer-setup-yolo` instead
- User needs production-grade security → Use `devcontainer-setup-advanced` with restricted firewall

## Usage

**Via slash command:**
```
/devcontainer:intermediate
```

**Via natural language:**
- "Set up intermediate mode"
- "I need a sandbox with custom Dockerfile"
- "Create a development environment with my own base image"
- "Set up intermediate sandbox"

## Key Characteristics

### Base Images
- **Source**: Official Docker images only (validated against `official-images.json`)
- **Examples**: `python:3.11`, `node:20`, `golang:1.21`
- **Validation**: All images must be from official Docker repositories

### Dockerfile
- **Template**: Standard language-specific templates from `skills/devcontainer-setup-intermediate/templates/Dockerfile.<language>`
- **Contents**:
  - Base image from official sources
  - Common development tools (git, curl, wget, vim, etc.)
  - Language-specific package managers
  - User setup with proper permissions
  - Health check configuration
- **Customization**: Limited to package additions

### Firewall Configuration
- **Mode**: PERMISSIVE (always)
- **Script**: `skills/devcontainer-setup-intermediate/templates/init-firewall.sh`
- **Behavior**: No network restrictions, all outbound traffic allowed
- **Configuration**: `FIREWALL_MODE: permissive` in devcontainer.json
- **Security Notice**: User must be warned about permissive nature

### Services
- **Source**: Master template (`templates/master/docker-compose.master.yml`)
- **Selection**: User chooses from available services:
  - **Databases**: PostgreSQL, MySQL, MongoDB, Redis
  - **Caching**: Redis (if not selected as database)
  - **Message Queues**: RabbitMQ, Kafka
  - **Multiple Services**: Can combine multiple services
- **Configuration**: Extract only selected services from master template

### User Interaction
- **Questions**: 4-6 focused questions
- **Goal**: Balance between customization and simplicity
- **Approach**: Provide sensible defaults with clear options

## Template References

When generating configuration, use these template files:

- **Extensions**: `${CLAUDE_PLUGIN_ROOT}/skills/devcontainer-setup-intermediate/templates/extensions.json`
  - Read this file and merge with platform-specific extensions
  - Includes ~15-20 extensions covering common development tools
  - Base + language-specific + productivity tools

- **MCP Configuration**: `${CLAUDE_PLUGIN_ROOT}/skills/devcontainer-setup-intermediate/templates/mcp.json`
  - Includes 5 MCP servers: filesystem, memory, sqlite, fetch, github
  - Copy to `.devcontainer/mcp.json`

- **Variables**: `${CLAUDE_PLUGIN_ROOT}/skills/devcontainer-setup-intermediate/templates/variables.json`
  - Build args and container environment variables
  - Standard development configuration

- **Docker Compose**: `${CLAUDE_PLUGIN_ROOT}/skills/devcontainer-setup-intermediate/templates/docker-compose.yml`
  - Template with postgres, redis, rabbitmq services
  - Includes healthchecks and named networks

- **Dockerfile**: `${CLAUDE_PLUGIN_ROOT}/skills/devcontainer-setup-intermediate/templates/Dockerfile.<language>`
  - Language-specific dockerfiles (Python, Node, Go, etc.)
  - Multi-stage build with Node.js for corporate proxy support (Issue #29)

- **Firewall**: `${CLAUDE_PLUGIN_ROOT}/skills/devcontainer-setup-intermediate/templates/init-firewall.sh`
  - Permissive firewall configuration (no restrictions)
  - Copy to `.devcontainer/init-firewall.sh`

- **Credentials Setup**: Create `.devcontainer/setup-claude-credentials.sh` for Issue #30
  - Copies Claude credentials from host mount to container
  - Essential for credentials persistence across container rebuilds

**Important**: Always read template files and use them as the source of truth. DO NOT use inline configuration examples.

### Credentials Persistence (Issue #30)

All intermediate mode setups must include Claude credentials mounting:

1. **In docker-compose.yml**, add volume mount to app service:
   ```yaml
   app:
     volumes:
       - .:/workspace:cached
       - ~/.claude:/tmp/host-claude:ro  # Credentials mount
   ```

2. **Create setup script** `.devcontainer/setup-claude-credentials.sh`:
   ```bash
   #!/bin/bash
   if [ -d "/tmp/host-claude" ]; then
     mkdir -p ~/.claude
     cp -r /tmp/host-claude/* ~/.claude/ 2>/dev/null || true
     echo "Claude credentials copied successfully"
   fi
   ```

3. **In devcontainer.json**, add to postCreateCommand:
   ```json
   "postCreateCommand": ".devcontainer/setup-claude-credentials.sh && ..."
   ```

## File Creation Location

**CRITICAL**: All generated files must be created in the user's current working directory (project root).

### Before generating files:

1. **Verify you're in the user's project directory** (where their source code is)
2. **Create the `.devcontainer/` directory**:
   ```bash
   mkdir -p .devcontainer
   ```

### Files to create (paths relative to project root):

- `.devcontainer/Dockerfile` - Custom Dockerfile with language-specific tools
- `docker-compose.yml` - Docker services configuration (in project root)
- `.devcontainer/devcontainer.json` - DevContainer configuration
- `.devcontainer/init-firewall.sh` - Firewall script (intermediate: permissive)
- `.devcontainer/setup-claude-credentials.sh` - Credentials setup (Issue #30)
- `.devcontainer/mcp.json` - MCP server configuration (optional)

### DO NOT create files in:

- `~/.claude-code/` or `~/.claude/` (home directory configs)
- `/root/.claude-code/` or any user home directory
- Any system directory like `/etc/` or `/var/`

**Why this matters**: The DevContainer configuration MUST be in the project's `.devcontainer/` folder for VS Code and Claude Code to detect and use it. Creating files in the wrong location will result in a non-functional setup.

## Workflow

### Step 1: Project Detection

**Auto-detect project type:**
- Scan workspace for language indicators:
  - Python: `requirements.txt`, `pyproject.toml`, `setup.py`, `*.py` files
  - Node.js: `package.json`, `*.js`, `*.ts` files
  - Go: `go.mod`, `*.go` files
  - Java: `pom.xml`, `build.gradle`, `*.java` files
  - PHP: `composer.json`, `*.php` files
  - Ruby: `Gemfile`, `*.rb` files
  - .NET: `*.csproj`, `*.sln` files

**Confirm with user:**
```
I detected a [LANGUAGE] project. Is this correct?
- Yes, proceed with [LANGUAGE] setup
- No, let me specify a different language
```

### Step 2: Configuration Questions (4-6 Questions)

**Question 1: Confirm Project Type**
```
What language/framework is your project using?
1. Python (3.11)
2. Node.js (20 LTS)
3. Go (1.21)
4. Java (17)
5. PHP (8.2)
6. Ruby (3.2)
7. .NET (8.0)
8. Other (specify)
```

**Question 2: Database Selection**
```
Do you need a database service?
1. PostgreSQL (latest)
2. MySQL (8.0)
3. MongoDB (7.0)
4. Redis (for data storage)
5. Multiple databases (select multiple)
6. None
```

**Question 3: Additional Services**
```
Do you need any additional services?
1. Redis (caching layer)
2. RabbitMQ (message queue)
3. Kafka (event streaming)
4. Multiple services
5. None
```

**Question 4: GPU Support** (if relevant for AI/ML projects)
```
Do you need GPU support for AI/ML workloads?
⚠️  Warning: GPU support requires NVIDIA Docker runtime and compatible hardware.
- Yes, enable GPU support
- No, CPU only
```

**Question 5: Custom Project Name** (optional)
```
Would you like to customize the project name?
Current: [detected-or-default-name]
- Keep current name
- Specify custom name: _______
```

**Question 6: Additional Packages** (optional)
```
Do you need any additional system packages in the Dockerfile?
Examples: postgresql-client, imagemagick, ffmpeg
- No additional packages
- Specify packages: _______
```

### Step 3: Generate Configuration

**Process:**

1. **Load Base Dockerfile Template**
   - Location: `skills/devcontainer-setup-intermediate/templates/Dockerfile.<language>`
   - Variables to replace:
     - `{{BASE_IMAGE}}`: Official image (e.g., `python:3.11`)
     - `{{ADDITIONAL_PACKAGES}}`: User-specified packages
     - `{{PROJECT_NAME}}`: Custom or detected name

2. **Extract Services from Master Template**
   - Source: `templates/master/docker-compose.master.yml`
   - Extract sections for selected services only:
     - If PostgreSQL selected → extract `postgres` service
     - If MySQL selected → extract `mysql` service
     - If MongoDB selected → extract `mongodb` service
     - If Redis selected → extract `redis` service
     - If RabbitMQ selected → extract `rabbitmq` service
     - If Kafka selected → extract `kafka` and `zookeeper` services
   - Preserve dependencies and networks

3. **Configure Firewall Script**
   - Source: `skills/devcontainer-setup-intermediate/templates/init-firewall.sh`
   - Copy as-is (no modifications needed)
   - Set permissions: `chmod +x .devcontainer/init-firewall.sh`

4. **Generate devcontainer.json**
   - Base template: `skills/devcontainer-setup-intermediate/templates/devcontainer.json`
   - Read extensions from `skills/devcontainer-setup-intermediate/templates/extensions.json`
   - Merge base + platform-specific extensions
   - Key settings:
     ```json
     {
       "name": "[PROJECT_NAME]",
       "dockerComposeFile": "../docker-compose.yml",
       "service": "app",
       "workspaceFolder": "/workspace",
       "customizations": {
         "vscode": {
           "settings": {
             "terminal.integrated.defaultProfile.linux": "bash"
           },
           "extensions": [
             // From templates/extensions.json
             // Base: anthropic.claude-code, ms-azuretools.vscode-docker, etc.
             // Platform-specific: ms-python.python, dbaeumer.vscode-eslint, etc.
           ]
         }
       },
       "features": {},
       "postStartCommand": ".devcontainer/init-firewall.sh",
       "postCreateCommand": ".devcontainer/setup-claude-credentials.sh && echo 'Setup complete!'",
       "remoteEnv": {
         "FIREWALL_MODE": "permissive"
       },
       "remoteUser": "node"
     }
     ```

5. **Create docker-compose.yml**
   - Base structure from `skills/devcontainer-setup-intermediate/templates/docker-compose.yml`
   - Add `app` service with Dockerfile build
   - Include credentials mount for Issue #30
   - Append extracted services from master template
   - Configure networks and volumes
   - Example structure:
     ```yaml
     version: '3.8'

     services:
       app:
         build:
           context: .
           dockerfile: .devcontainer/Dockerfile
         volumes:
           - .:/workspace:cached
           - ~/.claude:/tmp/host-claude:ro  # Issue #30: credentials mount
         working_dir: /workspace
         command: sleep infinity
         networks:
           - dev-network
         depends_on:
           # Based on selected services

       # Extracted services here (postgres, redis, etc.)

     networks:
       dev-network:
         driver: bridge

     volumes:
       # Service-specific volumes
     ```

### Step 4: Document Pull Commands

**Generate list of all required images:**

```
The following Docker images will be pulled:

Base Images:
- docker pull python:3.11
  Size: ~850 MB

Service Images:
- docker pull postgres:16-alpine
  Size: ~220 MB
- docker pull redis:7-alpine
  Size: ~30 MB

Total estimated download: ~1.1 GB
```

**Include pull commands in generated README:**
- Create or update `.devcontainer/README.md`
- List all images with sizes
- Provide manual pull commands
- Include troubleshooting tips

### Step 5: Auto-pull Images

**Ask user for confirmation:**
```
Would you like me to automatically pull all required Docker images now?
This will download approximately [SIZE] GB.

- Yes, pull images now (recommended)
- No, I'll pull them manually later
```

**If user confirms, execute pulls:**
```bash
# Pull base image
docker pull python:3.11

# Pull service images
docker pull postgres:16-alpine
docker pull redis:7-alpine

# Verify all images
docker images
```

**Report results:**
- Success: List all pulled images with sizes
- Failures: Report which pulls failed and suggest manual retry
- Next steps: Explain how to open in Dev Container

### Step 6: Security Notice

**Always display this warning:**

```
⚠️  SECURITY NOTICE: Permissive Firewall Mode

Your sandbox is configured with PERMISSIVE firewall mode, which means:
- ✓ All outbound network traffic is allowed
- ✓ Convenient for development and testing
- ✗ No network restrictions or filtering
- ✗ Not suitable for production-like environments

For production-like environments with network restrictions:
→ Use Advanced Mode: devcontainer-setup-advanced

To review firewall settings:
→ Check: .devcontainer/init-firewall.sh
→ Environment variable: FIREWALL_MODE=permissive
```

**Additional security notes:**
- Remind user this is for development only
- Suggest periodic security audits for long-running containers
- Link to security documentation if available

## Templates Used

### Dockerfile Template
**Location**: `skills/devcontainer-setup-intermediate/templates/Dockerfile.<language>`

**Example for Python**:
```dockerfile
FROM python:3.11-slim

# Install common development tools
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    vim \
    nano \
    build-essential \
    {{ADDITIONAL_PACKAGES}} \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Set working directory
WORKDIR /workspace

# Switch to non-root user
USER $USERNAME

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python --version || exit 1
```

### Firewall Script
**Location**: `skills/devcontainer-setup-intermediate/templates/init-firewall.sh`

```bash
#!/bin/bash
set -e

echo "🔓 Initializing Permissive Firewall Mode"
echo "========================================"

# Verify firewall mode
if [ "${FIREWALL_MODE}" != "permissive" ]; then
    echo "⚠️  Warning: FIREWALL_MODE is not set to 'permissive'"
    echo "Expected: FIREWALL_MODE=permissive"
    echo "Actual: FIREWALL_MODE=${FIREWALL_MODE}"
fi

# No firewall rules to configure - all traffic allowed
echo "✓ No firewall restrictions applied"
echo "✓ All outbound traffic allowed"
echo "✓ All inbound traffic allowed"

echo ""
echo "Security Notice:"
echo "- This configuration is for development only"
echo "- No network filtering is active"
echo "- Use Advanced Mode for production-like environments"
echo ""
echo "Firewall initialization complete."
```

### Docker Compose Services
**Location**: `templates/master/docker-compose.master.yml`

**Extract only needed services. Examples:**

**PostgreSQL**:
```yaml
postgres:
  image: postgres:16-alpine
  environment:
    POSTGRES_USER: devuser
    POSTGRES_PASSWORD: devpassword
    POSTGRES_DB: devdb
  volumes:
    - postgres-data:/var/lib/postgresql/data
  networks:
    - dev-network
  ports:
    - "5432:5432"
  healthcheck:
    test: ["CMD-SHELL", "pg_isready -U devuser"]
    interval: 10s
    timeout: 5s
    retries: 5
```

**Redis**:
```yaml
redis:
  image: redis:7-alpine
  volumes:
    - redis-data:/data
  networks:
    - dev-network
  ports:
    - "6379:6379"
  healthcheck:
    test: ["CMD", "redis-cli", "ping"]
    interval: 10s
    timeout: 3s
    retries: 3
```

**MongoDB**:
```yaml
mongodb:
  image: mongo:7
  environment:
    MONGO_INITDB_ROOT_USERNAME: devuser
    MONGO_INITDB_ROOT_PASSWORD: devpassword
  volumes:
    - mongodb-data:/data/db
  networks:
    - dev-network
  ports:
    - "27017:27017"
  healthcheck:
    test: ["CMD", "mongosh", "--eval", "db.adminCommand('ping')"]
    interval: 10s
    timeout: 5s
    retries: 3
```

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

## Example Interaction

### Full Setup Example

```
User: I need a development sandbox for my Python project with PostgreSQL

Assistant: I'll set up an Intermediate mode sandbox for your Python project with PostgreSQL. Let me ask a few quick questions to configure it properly.

What version of Python would you like to use?
1. Python 3.11 (Recommended)
2. Python 3.10
3. Python 3.12

[User selects: 1. Python 3.11]

Would you like any additional system packages in the Dockerfile?
Examples: postgresql-client, imagemagick, ffmpeg

[User responds: postgresql-client]

Great\! I'll generate your Intermediate mode sandbox with:
- Base image: python:3.11
- Database: PostgreSQL 16
- Additional packages: postgresql-client
- Firewall: Permissive (no restrictions)

Creating configuration files...
✓ Generated .devcontainer/Dockerfile
✓ Generated docker-compose.yml with PostgreSQL service
✓ Generated .devcontainer/devcontainer.json
✓ Added permissive firewall script

Would you like me to pull the required Docker images now? (Total: ~1.1 GB)

[User responds: Yes]

Pulling images...
✓ docker pull python:3.11
✓ docker pull postgres:16-alpine

⚠️  SECURITY NOTICE: Permissive Firewall Mode
Your sandbox allows all outbound traffic for development convenience.
For production-like security, use Advanced Mode instead.

Setup complete\! Next steps:
1. Reopen folder in Dev Container
2. PostgreSQL will be available at localhost:5432
3. Credentials in docker-compose.yml
```

This example demonstrates the balanced questioning approach of Intermediate mode - enough customization to be useful, but streamlined for efficiency.

## Completion Checklist

**Before finishing the setup, verify ALL these files exist:**

Run these verification commands:

```bash
# Check .devcontainer directory exists
test -d .devcontainer && echo "✓ .devcontainer/ directory exists" || echo "✗ MISSING: .devcontainer/ directory"

# Check each required file
test -f docker-compose.yml && echo "✓ docker-compose.yml exists" || echo "✗ MISSING: docker-compose.yml"
test -f .devcontainer/Dockerfile && echo "✓ Dockerfile exists" || echo "✗ MISSING: Dockerfile"
test -f .devcontainer/devcontainer.json && echo "✓ devcontainer.json exists" || echo "✗ MISSING: devcontainer.json"
test -f .devcontainer/init-firewall.sh && echo "✓ init-firewall.sh exists" || echo "✗ MISSING: init-firewall.sh"
test -f .devcontainer/setup-claude-credentials.sh && echo "✓ setup-claude-credentials.sh exists" || echo "✗ MISSING: setup-claude-credentials.sh"
```

**Required files checklist:**
1. [ ] `docker-compose.yml` in project root (NOT in .devcontainer/)
2. [ ] `.devcontainer/` directory exists
3. [ ] `.devcontainer/Dockerfile` exists with proper language-specific tools
4. [ ] `.devcontainer/devcontainer.json` exists with proper configuration
5. [ ] `.devcontainer/init-firewall.sh` exists and is executable (`chmod +x`)
6. [ ] `.devcontainer/setup-claude-credentials.sh` exists and is executable (`chmod +x`)

**If ANY file is missing, CREATE IT NOW before completing.**

## PROHIBITED FILES - NEVER CREATE THESE

If you find yourself about to write ANY of these files, you are doing the WRONG task:

- ❌ `.claude-code.json` - WRONG (this is Claude Code's sandbox config, NOT DevContainer)
- ❌ `.claude/config.json` - WRONG (this is Claude Code config, NOT DevContainer)
- ❌ `.claude-code/settings.json` - WRONG (this is Claude Code settings, NOT DevContainer)
- ❌ `/root/.claude-code/settings.json` - WRONG (wrong location entirely)
- ❌ `Dockerfile` in project root - WRONG (should be in .devcontainer/)

**If you created any of these files by mistake, DELETE THEM and create the correct DevContainer files instead.**

---

**Last Updated:** 2025-12-16
**Version:** 3.0.0
