---
name: sandbox-setup-yolo
description: Use when user wants full customization with no restrictions - unofficial images allowed, optional firewall, complete control over all settings
---

# Sandbox Setup YOLO Mode

## WARNING - READ THIS FIRST

```
╔═══════════════════════════════════════════════════════════════╗
║                    YOLO MODE ACTIVATED                        ║
║                                                               ║
║  You are in full control. This mode:                         ║
║  • Allows unofficial Docker images (security risk)           ║
║  • Does not enforce firewall restrictions                    ║
║  • Provides no security guardrails                           ║
║  • Permits experimental and untested configurations          ║
║                                                               ║
║  Ensure you understand the security implications.            ║
╔═══════════════════════════════════════════════════════════════╗
```

**DISPLAY THIS WARNING** prominently at the start of every YOLO mode session.

## TASK IDENTITY

You are a **DevContainer Configuration Generator**. This is a file generation task.

**Your output:** VS Code DevContainer files in `.devcontainer/` directory
**Technology:** Docker, VS Code Dev Containers
**NOT related to:** Claude Code settings, Claude Code sandbox, `.claude/` configs

## What This Skill Creates

**⚠️ CRITICAL: THIS SKILL CREATES A DEVCONTAINER SETUP, NOT CLAUDE CODE'S SANDBOX FEATURE.**

You will create VS Code DevContainer files in the project's `.devcontainer/` directory:
- `.devcontainer/Dockerfile` - Custom Dockerfile (allows ANY image in YOLO mode)
- `.devcontainer/devcontainer.json` - DevContainer configuration for VS Code
- `.devcontainer/init-firewall.sh` - Firewall initialization script (optional in YOLO mode)
- `.devcontainer/setup-claude-credentials.sh` - Claude credentials persistence (Issue #30)
- `docker-compose.yml` - Docker services configuration (in project root)

### What This Is:
- A **file generation task** that creates DevContainer configuration files
- Files that enable VS Code's "Reopen in Container" feature
- Docker-based development environment with full customization

### YOUR EXCLUSIVE OUTPUT FILES:

| File | Location | Purpose |
|------|----------|---------|
| `Dockerfile` | `.devcontainer/Dockerfile` | Custom container image (ANY image allowed) |
| `devcontainer.json` | `.devcontainer/devcontainer.json` | VS Code DevContainer config |
| `init-firewall.sh` | `.devcontainer/init-firewall.sh` | Firewall script (YOLO: optional/configurable) |
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

## MANDATORY FIRST STEP - READ TEMPLATES

**STOP. BEFORE doing ANYTHING else, you MUST read these template files using the Read tool:**

1. Extensions template: `${CLAUDE_PLUGIN_ROOT}/templates/extensions/extensions.yolo.json`
2. Firewall template: `${CLAUDE_PLUGIN_ROOT}/templates/firewall/yolo-configurable.sh`
3. Compose template (master): `${CLAUDE_PLUGIN_ROOT}/templates/master/docker-compose.master.yml`
4. Credentials template: `${CLAUDE_PLUGIN_ROOT}/templates/master/setup-claude-credentials.master.sh`
5. MCP template: `${CLAUDE_PLUGIN_ROOT}/templates/mcp/mcp.yolo.json`
6. Variables template: `${CLAUDE_PLUGIN_ROOT}/templates/variables/variables.yolo.json`
7. Dockerfile master: `${CLAUDE_PLUGIN_ROOT}/templates/master/Dockerfile.master`
8. DevContainer master: `${CLAUDE_PLUGIN_ROOT}/templates/master/devcontainer.json.master`

**DO NOT proceed to user configuration until you have read ALL template files.**
**DO NOT use the inline examples in this skill - use the actual template file contents.**
**If you skip reading templates, you will generate incorrect configuration.**

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
1. READ `${CLAUDE_PLUGIN_ROOT}/templates/master/Dockerfile.master`
2. COPY the template content EXACTLY (or appropriate language template)
3. Only modify placeholder values (PROJECT_NAME, etc.)

The templates contain:
- Proper multi-stage builds
- All mandatory packages
- ZSH + Powerlevel10k configuration
- AI tools (DeepAgents, Tavily)
- Claude Code CLI

**If you generate a Dockerfile with fewer than 50 lines, you are doing it wrong.** YOLO mode should have the MOST comprehensive setup, not the least.

## Overview

YOLO mode provides **complete control with NO restrictions**. You get:
- ANY Docker image (official, unofficial, custom registries)
- OPTIONAL firewall (any mode or disabled entirely)
- ALL customization options from master templates
- Experimental features (nightly builds, alpha releases)
- Full access to every configuration option
- No default safety nets or validation

This is for users who:
- Know exactly what they want
- Understand Docker and security implications
- Need maximum flexibility
- Are willing to debug edge cases
- Want to experiment with cutting-edge tools

## When to Use This Skill

Use YOLO mode when:
- User explicitly requests "YOLO", "full control", "no restrictions", or "maximum customization"
- User wants to use unofficial/custom Docker images
- User wants to disable security features like firewall
- User wants experimental versions (nightly, alpha, beta)
- User needs configurations not possible in other modes
- User is experienced and rejects simpler mode suggestions

Do NOT use YOLO mode when:
- User is a beginner → Suggest **Basic** mode instead
- User wants security guidance → Suggest **Advanced** mode instead
- User wants quick setup → Suggest **Basic** mode instead
- User doesn't explicitly request full control → Ask if they really need YOLO

## Key Characteristics

| Feature                   | YOLO Mode                                                                            |
| ------------------------- | ------------------------------------------------------------------------------------ |
| **Base Images**           | ANY (official, unofficial, custom registries)                                        |
| **Dockerfile**            | Full customization from master template                                              |
| **Firewall**              | OPTIONAL - strict/permissive/disabled/custom                                         |
| **Services**              | All possible services (postgres, redis, mysql, mongo, rabbitmq, nginx, ollama, etc.) |
| **Build Args**            | All exposed (timezone, versions, custom args)                                        |
| **VS Code Extensions**    | All language extensions available                                                    |
| **Environment Variables** | Complete control over all env vars                                                   |
| **Port Forwarding**       | Full control over all port mappings                                                  |
| **User Interaction**      | Extensive - every option presented                                                   |
| **Validation**            | Minimal - assumes user knows what they're doing                                      |
| **Documentation**         | Comprehensive with all commands and implications                                     |

## Available Images

### 1. Sandbox Templates (docker/sandbox-templates)
All tags from official sandbox-templates registry:

**Stable (Recommended)**:
- `latest` - Latest stable release (329MB amd64)
- `claude-code` - Optimized for Claude Code (366MB amd64)
- `ubuntu-python` - Ubuntu base with Python (323MB amd64)
- `0.1.0` - Version 0.1.0 stable (329MB amd64)

**Agent-Focused**:
- `cagent` - Agent-focused template (319MB amd64)
- `cursor-agent` - Cursor agent template (356MB amd64)
- `gemini` - Gemini integration template (420MB amd64)
- `kiro` - Kiro template (507MB amd64)

**Experimental (YOLO-specific)**:
- `nightly` - Nightly build (UNSTABLE, may break)
- `0.1.0-alpha.1` - Alpha release (for testing)

### 2. Official Docker Images
All official images from Docker Hub:

**Languages**:
- `python:3.12-slim-bookworm`, `python:3.13-slim-bookworm`
- `node:20-bookworm-slim`, `node:22-bookworm-slim`
- `golang:1.22-bookworm`, `golang:1.23-bookworm`
- `rust:1.75-slim-bookworm`, `rust:1.76-slim-bookworm`
- `ruby:3.3-slim-bookworm`
- `php:8.4-fpm-bookworm`, `php:8.3-fpm-bookworm`
- `openjdk:21-slim-bookworm`, `openjdk:17-slim-bookworm`
- `gcc:13-bookworm`, `gcc:14-bookworm`

**Databases**:
- `postgres:16-bookworm`, `postgres:16-alpine`
- `mysql:8.0`, `mysql:8.4`
- `mongo:7`, `mongo:6`
- `redis:7-alpine`, `redis:6-alpine`

**Services**:
- `nginx:1.25-bookworm`, `nginx:1.26-bookworm`
- `rabbitmq:3.13-management`

### 3. Unofficial Images (USE WITH CAUTION)
YOLO mode allows any Docker image from any registry:

**Examples**:
- Custom registries: `myregistry.io/myimage:tag`
- Third-party images: `username/repo:tag`
- Private registries: `gcr.io/project/image:tag`
- Experimental builds: `image:dev`, `image:edge`

**WARNING**: Unofficial images may contain:
- Security vulnerabilities
- Malicious code
- Incompatible dependencies
- Outdated packages
- No support or updates

**Always review**:
- Image source and maintainer
- Number of pulls and stars (if Docker Hub)
- Last updated date
- Security scan results
- Dockerfile source (if available)

## File Creation Location

**CRITICAL**: All generated files must be created in the user's current working directory (project root).

### Before generating files:

1. **Verify you're in the user's project directory** (where their source code is)
2. **Create the `.devcontainer/` directory**:
   ```bash
   mkdir -p .devcontainer
   ```

### Files to create (paths relative to project root):

- `.devcontainer/Dockerfile` - Comprehensive custom Dockerfile with ALL language toolchains and tools
- `docker-compose.yml` - Docker services configuration with full customization (in project root)
- `.devcontainer/devcontainer.json` - DevContainer configuration with user-selected firewall mode
- `.devcontainer/init-firewall.sh` - Firewall script (yolo: disabled/permissive/strict based on user choice)
- `.devcontainer/setup-claude-credentials.sh` - Credentials setup (Issue #30)
- `.devcontainer/mcp.json` - MCP server configuration with all selected servers
- `.devcontainer/variables.json` - Custom build args and environment variables (optional)

### DO NOT create files in:

- `~/.claude-code/` or `~/.claude/` (home directory configs)
- `/root/.claude-code/` or any user home directory
- Any system directory like `/etc/` or `/var/`

**Why this matters**: The DevContainer configuration MUST be in the project's `.devcontainer/` folder for VS Code and Claude Code to detect and use it. Creating files in the wrong location will result in a non-functional setup. YOLO mode gives users complete control, but this location requirement is non-negotiable.

## Workflow

### Phase 1: Image Selection

**Ask**: "What base image do you want to use?"

**Present options**:
1. **Sandbox Template** (docker/sandbox-templates:*)
   - Show all tags including nightly/alpha
   - Recommend stable for production
2. **Official Docker Image** (python, node, postgres, etc.)
   - Show recommended tags for language
   - Note size and architecture support
3. **Unofficial/Custom Image**
   - User provides full image reference
   - **Warn**: "⚠️ Unofficial images may contain security vulnerabilities or malicious code. Ensure you trust the source."

**For unofficial images**:
- Ask for full image reference (registry/repo:tag)
- Confirm: "This image is not official. Proceed? (yes/no)"
- Document the risk in generated files

### Phase 2: Full Configuration

Present ALL configuration options. Don't skip anything.

#### A. Project Configuration
- **Project name**: (default: current directory name)
- **Network name**: (default: `{project-name}-network`)
- **Container name**: (default: `{project-name}-devcontainer`)

#### B. Language & Tools
Ask which languages/tools to include:
- [ ] Python (with version: 3.11/3.12/3.13)
- [ ] Node.js (already in base if using node image)
- [ ] Go
- [ ] Rust
- [ ] Java/OpenJDK
- [ ] Ruby
- [ ] PHP
- [ ] C/C++ build tools (gcc, g++, make, cmake)
- [ ] Database clients (psql, mysql, redis-cli, mongosh)
- [ ] Docker CLI (for Docker-in-Docker)
- [ ] Claude Code CLI (version: latest or specific)

#### C. Services
Ask which services to include in docker-compose:
- [ ] PostgreSQL (version: 16/15/14)
  - Port: (default: 5432)
  - Database name: (default: `{project-name}_db`)
  - Volume: (default: `postgres_data`)
- [ ] MySQL (version: 8.0/8.4)
  - Port: (default: 3306)
- [ ] MongoDB (version: 7/6)
  - Port: (default: 27017)
- [ ] Redis (version: 7-alpine/6-alpine)
  - Port: (default: 6379)
- [ ] RabbitMQ (version: 3.13-management)
  - Port: (default: 5672, management: 15672)
- [ ] Nginx (version: 1.25/1.26)
  - Port: (default: 80)
- [ ] Ollama (AI model server)
  - ⚠️ **Warning**: Requires GPU access and significant resources
  - Port: (default: 11434)
  - Volume for models: (default: `ollama_data`)

For each service, ask:
- Custom port mapping?
- Custom environment variables?
- Resource limits (memory/CPU)?
- Health check configuration?
- Volume mount strategy?

#### D. Firewall Configuration

**Ask**: "Firewall configuration?"

**Options**:
1. **Strict with custom allowlist** (recommended unless disabled)
   - Whitelisted domains only
   - Show all available categories:
     - Version control (GitHub, GitLab, Bitbucket)
     - Package registries (npm, PyPI, RubyGems, Crates.io, etc.)
     - AI providers (Anthropic, OpenAI, Groq)
     - Analytics/Telemetry (Sentry, Statsig)
     - VS Code (marketplace, updates)
     - CDN (jsDelivr, unpkg, cdnjs)
     - Container registries (Docker Hub, GHCR, GCR, Quay)
     - Cloud providers (AWS S3, GCS, Azure Blob)
     - Language tools (Go downloads, Rust installer)
     - Custom domains (user-specified)
   - Ask which categories to include
   - Ask for additional custom domains

2. **Permissive**
   - Allow all outbound traffic
   - No restrictions
   - **Warn**: "All traffic allowed. Not recommended for production."

3. **Disabled**
   - No firewall configuration
   - **Warn**: "⚠️ Container will have unrestricted network access. This is a security risk."
   - Confirm: "Are you sure you want to disable the firewall? (yes/no)"

4. **Custom script**
   - User provides custom init-firewall.sh script
   - Ask for script path or content
   - **Warn**: "Custom firewall script. Ensure it's properly configured."

#### E. Build Arguments
Ask which build args to customize:
- `TZ` - Timezone (default: America/Los_Angeles)
- `CLAUDE_CODE_VERSION` - Claude Code version (default: latest)
- `GIT_DELTA_VERSION` - git-delta version (default: 0.18.2)
- `ZSH_IN_DOCKER_VERSION` - ZSH installer version (default: 1.2.0)
- Custom build args?

#### F. VS Code Configuration
Ask which VS Code extensions to include:
- Git extensions (GitLens, Git Graph)
- JavaScript/TypeScript (ESLint, Prettier, Volar)
- Python (Pylance, Ruff, Black)
- Go (Go extension)
- Rust (rust-analyzer)
- C/C++ (C++ extension, CMake tools)
- Java (Language Support, Debugger)
- Ruby (Solargraph, Rubocop)
- PHP (Intelephense)
- Docker (Docker extension)
- YAML (YAML extension)
- Custom extensions? (provide extension IDs)

VS Code settings:
- Custom editor settings?
- Language-specific settings?
- Custom keybindings?

#### G. Environment Variables
Ask which environment variables to set:
- `NODE_OPTIONS` (for Node.js)
- `PYTHONPATH` (for Python)
- `GOPATH` / `GOPROXY` (for Go)
- `CARGO_HOME` / `RUSTUP_HOME` (for Rust)
- `DOCKER_HOST` (for Docker CLI)
- Database connection strings
- API keys (warn about using `${localEnv:VAR}` for secrets)
- Custom env vars?

#### H. Port Forwarding
Ask which ports to forward:
- Application ports
- Service ports (databases, cache, etc.)
- Debug ports
- Custom port mappings?

For each port:
- Port number
- Label/description
- Expose to host? (yes/no)
- Port attributes (onAutoForward: notify/silent/openBrowser)

#### I. Dev Container Features
Ask which dev container features to include:
- GitHub CLI (gh)
- Git LFS
- Docker-in-Docker / Docker-from-Docker
- Kubernetes tools (kubectl, helm)
- Cloud CLIs (AWS, GCP, Azure)
- Custom features? (provide feature references)

#### J. Lifecycle Scripts
- `postCreateCommand` - Run after container creation
- `postStartCommand` - Run on container start
- `postAttachCommand` - Run when attaching to container

Ask for custom commands or scripts.

### Phase 3: Template Generation

Use master templates from `templates/master/`:

1. **Read master templates**:
   - `Dockerfile.master`
   - `devcontainer.json.master`
   - `init-firewall.master.sh`
   - `docker-compose.master.yml`

2. **Strip unused sections** based on user selections:
   - Use section markers: `# ===SECTION_START:name===` / `# ===SECTION_END:name===`
   - Remove language packages not selected
   - Remove extensions for unused languages
   - Remove firewall categories not selected
   - Remove services not selected

3. **Replace placeholders**:
   - `{{PROJECT_NAME}}` → actual project name
   - `{{NETWORK_NAME}}` → actual network name
   - `{{FIREWALL_MODE}}` → strict/permissive/disabled
   - `{{BASE_IMAGE}}` → selected base image
   - `{{IMAGE_NAME}}` → selected pre-built image (if using)
   - Custom placeholders for user-specified values

4. **Generate all files**:
   - `.devcontainer/devcontainer.json`
   - `.devcontainer/Dockerfile`
   - `.devcontainer/init-firewall.sh` (if firewall enabled)
   - `docker-compose.yml` (if services selected)
   - `.devcontainer/.env.example` (if env vars specified)

5. **Add comments** documenting all custom choices:
```dockerfile
# YOLO MODE CONFIGURATION
# Base image: <selected-image> (unofficial: yes/no)
# Firewall: <mode>
# Custom build args: <list>
# Generated: <timestamp>
```

### Phase 4: Image Pulling

**Ask**: "Pull all required images now?"

If yes:
1. Show pull commands for all images:
```bash
# Base image
docker pull <base-image>

# Services
docker pull postgres:16-bookworm
docker pull redis:7-alpine
# ... etc
```

2. Execute pulls with progress:
```bash
docker pull <image> && echo "✓ Pulled <image>" || echo "✗ Failed to pull <image>"
```

3. Verify images:
```bash
docker images | grep "<image-name>"
```

4. Report total size and disk usage

### Phase 5: Comprehensive Documentation

Generate extensive documentation in `.devcontainer/README.md`:

#### A. Configuration Summary
- Mode: YOLO
- Base image: `<image>` (official/unofficial)
- Firewall: `<mode>`
- Languages: `<list>`
- Services: `<list>`
- Total configuration options: `<count>`

#### B. Security Warnings
If unofficial image:
```
⚠️ SECURITY WARNING ⚠️
This configuration uses an unofficial Docker image: <image>
- Source: <registry/repo>
- Last updated: <unknown or date>
- Security scans: Not verified
- Recommendation: Review the image Dockerfile and consider using official alternatives
```

If firewall disabled:
```
⚠️ SECURITY WARNING ⚠️
Firewall is disabled. Container has unrestricted network access.
- All outbound connections allowed
- No domain filtering
- Increased attack surface
- Recommendation: Enable strict firewall mode for production use
```

#### C. All Pull Commands
List every image with pull command:
```bash
# Pull all images
docker pull <base-image>
docker pull postgres:16-bookworm
docker pull redis:7-alpine
# ... etc

# Or pull all at once
docker compose pull
```

#### D. Service Connection Strings
For each service:
```bash
# PostgreSQL
DATABASE_URL=postgresql://user:password@postgres:5432/dbname
psql postgresql://user:password@postgres:5432/dbname

# Redis
REDIS_URL=redis://redis:6379
redis-cli -h redis -p 6379

# MongoDB
MONGO_URL=mongodb://mongo:27017/dbname
mongosh mongodb://mongo:27017/dbname
```

#### E. Port Mappings
List all forwarded ports:
```
- 3000: Frontend application
- 5000: Backend API
- 5432: PostgreSQL
- 6379: Redis
- ... etc
```

#### F. Custom Configuration Notes
Document all custom choices:
- Why certain options were selected
- Trade-offs made
- Performance implications
- Security implications

#### G. Troubleshooting
Common issues specific to the configuration:
- Image pull failures
- Service connection errors
- Firewall blocking necessary domains
- Resource constraints
- Custom configuration pitfalls

#### H. Next Steps
```bash
# 1. Review configuration
cat .devcontainer/devcontainer.json
cat .devcontainer/Dockerfile
cat docker-compose.yml

# 2. Start services
docker compose up -d

# 3. Verify services
docker compose ps
docker compose logs

# 4. Open in DevContainer
code .
# Ctrl+Shift+P → "Dev Containers: Reopen in Container"

# 5. Test inside container
# Database connection
psql postgresql://user:pass@postgres:5432/db
# Cache connection
redis-cli -h redis ping
# Network test
curl -I https://github.com

# 6. Monitor resources
docker stats
```

### Phase 6: Final Validation

Even in YOLO mode, perform basic validation:

1. **File existence check**:
   - [ ] `.devcontainer/devcontainer.json` created
   - [ ] `.devcontainer/Dockerfile` created
   - [ ] `.devcontainer/init-firewall.sh` created (if enabled)
   - [ ] `docker-compose.yml` created (if services)

2. **Syntax validation**:
   - [ ] devcontainer.json is valid JSON
   - [ ] Dockerfile has valid syntax
   - [ ] docker-compose.yml is valid YAML
   - [ ] init-firewall.sh is executable

3. **Security audit** (informational only - don't block):
   - ⚠️ Unofficial image detected: `<image>`
   - ⚠️ Firewall disabled or permissive
   - ⚠️ Default passwords in configuration (warn to use env vars)
   - ⚠️ Unnecessary ports exposed to host
   - ⚠️ Running as root user (if detected)
   - ℹ️ List all findings with severity (high/medium/low)

4. **Disk space check**:
   - Calculate total image sizes
   - Warn if > 5GB total
   - Show `docker system df`

5. **Ask**: "Configuration complete. Proceed with container creation? (yes/no)"

## Templates Used

YOLO mode uses the complete master templates with full customization. Always read these template files:

### 1. Extensions Template
**File**: `${CLAUDE_PLUGIN_ROOT}/templates/extensions/extensions.yolo.json`
- Comprehensive extension list (35+ extensions)
- All language extensions (Python, JS, Go, Rust, Java, Ruby, PHP, C++)
- Productivity tools (GitLens, Error Lens, TODO Tree, Code Spell Checker)
- Themes (GitHub, Dracula, Monokai)
- Fun extensions (Power Mode, Rainbow Brackets)
- **Important**: Read this file and merge with platform-specific extensions

### 2. MCP Configuration Template
**File**: `${CLAUDE_PLUGIN_ROOT}/templates/mcp/mcp.yolo.json`
- All 11+ MCP servers available
- Includes: filesystem, memory, sqlite, fetch, github, postgres, docker, brave-search, puppeteer, slack, google-drive, custom
- Copy to `.devcontainer/mcp.json` with user selections

### 3. Variables Template
**File**: `${CLAUDE_PLUGIN_ROOT}/templates/variables/variables.yolo.json`
- User-defined build args and container environment variables
- Custom configuration based on user needs
- Copy to `.devcontainer/variables.json`

### 4. Dockerfile.master
All sections available:
- `packages_python` - Python 3 + pip + venv
- `packages_build` - Build tools (gcc, g++, make, cmake)
- `packages_go` - Go language toolchain
- `packages_rust` - Rust language toolchain
- `packages_java` - Java JDK + Maven + Gradle
- `packages_ruby` - Ruby + bundler
- `packages_php` - PHP + Composer
- `packages_database` - Database clients (psql, mysql, sqlite, redis)
- `packages_docker` - Docker CLI
- `npm_config` - NPM global configuration
- `claude_code` - Claude Code CLI installation
- `python_packages` - Common Python packages
- `node_packages` - Common Node packages

### devcontainer.json.master
All sections available (37 total):
- Build and image configuration
- All language extensions (git, javascript, python, go, rust, cpp, java, ruby, php, docker, yaml)
- All language-specific settings
- All port configurations
- All environment variables
- All dev container features

### init-firewall.master.sh
All categories available (10 total):
- `version_control` - GitHub, GitLab, Bitbucket
- `package_registries` - npm, PyPI, RubyGems, Crates.io, etc.
- `ai_providers` - Anthropic, OpenAI, Groq
- `analytics_telemetry` - Sentry, Statsig
- `vscode` - VS Code marketplace and updates
- `cdn` - jsDelivr, unpkg, cdnjs
- `container_registries` - Docker Hub, GHCR, GCR, Quay
- `cloud_providers` - AWS S3, Google Cloud Storage, Azure Blob
- `language_tools` - Go downloads, Rust installer
- `custom` - User-defined domains

### docker-compose.master.yml
All services available:
- PostgreSQL (with variants: bookworm, alpine)
- MySQL (with variants)
- MongoDB
- Redis (with variants)
- RabbitMQ (with management UI)
- Nginx
- Ollama (AI model server)
- Custom services

### Credentials Persistence (Issue #30)

All YOLO mode setups must include Claude credentials mounting:

1. **In docker-compose.yml**, add volume mount to app service:
   ```yaml
   app:
     volumes:
       - .:/workspace:cached
       - ~/.claude:/tmp/host-claude:ro  # Issue #30: credentials mount
   ```

2. **Create setup script** `.devcontainer/setup-claude-credentials.sh`:
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

3. **In devcontainer.json**, add to lifecycle commands:
   ```json
   "postStartCommand": ".devcontainer/init-firewall.sh",
   "postCreateCommand": ".devcontainer/setup-claude-credentials.sh && ..."
   ```

**Important**: Always read template files and use them as the source of truth. DO NOT use inline configuration examples without reading templates first.

## Key Principles

1. **Maximum Flexibility**
   - Never say "no" to user requests
   - Provide all options, let user decide
   - Support any valid Docker configuration

2. **Informed Decisions**
   - Warn about risks, don't prevent them
   - Explain implications of choices
   - Document everything comprehensively

3. **No Assumptions**
   - Ask about every option
   - Don't auto-select defaults
   - Let user make all choices

4. **Transparency**
   - Show all commands before running
   - Document security implications
   - Explain trade-offs clearly

5. **Comprehensive Documentation**
   - Every configuration choice documented
   - All connection strings provided
   - Complete troubleshooting guide
   - Security warnings prominent

6. **Validation Without Blocking**
   - Validate syntax and structure
   - Warn about security issues
   - But always proceed if user confirms

## Example Invocations

**Via slash command**:
```
/sandbox:yolo
```

**Via natural language**:
- "I want full control over my devcontainer setup"
- "Set up sandbox in YOLO mode"
- "I need to use an unofficial Docker image"
- "Configure devcontainer with no restrictions"
- "Give me maximum customization options"

## Integration with Other Skills

- **After setup**: Suggest `sandbox-security` to audit the configuration
- **If errors occur**: Automatically invoke `sandbox-troubleshoot`
- **For updates**: Warn that YOLO configurations may need manual updates

## User Interaction Flow Example

```
Assistant: I'll set up your sandbox in YOLO mode.

╔═══════════════════════════════════════════════════════════════╗
║                    YOLO MODE ACTIVATED                        ║
║                                                               ║
║  You are in full control. This mode:                         ║
║  • Allows unofficial Docker images (security risk)           ║
║  • Does not enforce firewall restrictions                    ║
║  • Provides no security guardrails                           ║
║  • Permits experimental and untested configurations          ║
║                                                               ║
║  Ensure you understand the security implications.            ║
╔═══════════════════════════════════════════════════════════════╗

What base image do you want to use?
1. Sandbox Template (docker/sandbox-templates:*)
2. Official Docker Image (python, node, etc.)
3. Unofficial/Custom Image

User: 3 - custom image: myregistry.io/myimage:dev


Assistant: ⚠️ WARNING: Unofficial image detected.

I will now configure your YOLO sandbox with this custom image.
This will take approximately 5-10 minutes. Ready to proceed?
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

# Check line count (should be substantial - YOLO should have the MOST comprehensive setup)
wc -l .devcontainer/Dockerfile  # Should be >= 100 lines for YOLO mode
```

**If any check fails, RE-READ the template file and regenerate.** YOLO mode is about giving users full control, not generating minimal configurations.

## Completion Checklist

**Before finishing the setup, verify ALL these files exist:**

**Required files checklist:**
1. [ ] `docker-compose.yml` in project root (NOT in .devcontainer/)
2. [ ] `.devcontainer/` directory exists
3. [ ] `.devcontainer/devcontainer.json` exists with proper configuration
4. [ ] `.devcontainer/init-firewall.sh` exists (even if firewall disabled, create no-op script)
5. [ ] `.devcontainer/setup-claude-credentials.sh` exists and is executable (`chmod +x`)
6. [ ] `.devcontainer/Dockerfile` exists (YOLO mode uses custom Dockerfile with ANY image)
7. [ ] `.devcontainer/mcp.json` exists (if MCP servers configured)

**Verify Configuration Content:**
- [ ] `docker-compose.yml` includes credentials mount: `~/.claude:/tmp/host-claude:ro`
- [ ] `devcontainer.json` references docker-compose and has proper postCreateCommand
- [ ] `init-firewall.sh` contains selected firewall configuration (or no-op if disabled)
- [ ] `setup-claude-credentials.sh` handles credential copying from /tmp/host-claude
- [ ] `Dockerfile` uses the custom/unofficial image specified by user (if applicable)

## PROHIBITED FILES - NEVER CREATE THESE

If you find yourself about to write ANY of these files, you are doing the WRONG task:

- ❌ `.claude-code.json` - WRONG (this is Claude Code's sandbox config, NOT DevContainer)
- ❌ `.claude/config.json` - WRONG (this is Claude Code config, NOT DevContainer)
- ❌ `.claude-code/settings.json` - WRONG (this is Claude Code settings, NOT DevContainer)
- ❌ `/root/.claude-code/settings.json` - WRONG (wrong location entirely)
- ❌ `Dockerfile` in project root - WRONG (should be in .devcontainer/)

**If you created any of these files by mistake, DELETE THEM and create the correct DevContainer files instead.**

**If ANY required file is missing, CREATE IT NOW before completing the skill.**

**After File Creation:**
1. Make init-firewall.sh and setup-claude-credentials.sh executable
2. Display the YOLO mode warning again if using unofficial images or disabled firewall
3. Inform user that files are ready
4. Provide "Next Steps" with VS Code instructions (do NOT run containers yourself)

---

**Last Updated:** 2025-12-16
**Version:** 2.2.2
