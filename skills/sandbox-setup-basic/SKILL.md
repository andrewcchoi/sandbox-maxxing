---
name: sandbox-setup-basic
description: Use when user wants the simplest sandbox setup - uses sandbox templates or official images only, docker-compose when appropriate, no firewall (relies on sandbox isolation)
---

# Sandbox Setup: Basic Mode

## Overview

The Basic mode provides the fastest path to a working sandbox environment. This mode is optimized for:

- Quick setup with minimal configuration
- Pre-built templates and official Docker images
- No firewall configuration (relies on sandbox isolation)
- Automatic project detection and sensible defaults
- 1-2 user questions maximum

Basic mode gets developers up and running in minutes using battle-tested base images without custom security layers.

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

#### Option A: Simple Sandbox Template (No Services)

When project only needs runtime environment, use minimal devcontainer.json:

**File**: `.devcontainer/devcontainer.json`

```json
{
  "name": "Project Name Sandbox",
  "image": "docker/sandbox-templates:claude-code",
  "customizations": {
    "vscode": {
      "extensions": []
    }
  },
  "remoteUser": "root"
}
```

#### Option B: Official Image with Services

When project needs database, cache, or other services:

**File**: `docker-compose.yml`

```yaml
version: '3.8'

services:
  app:
    image: python:3.12-slim-bookworm
    volumes:
      - ..:/workspace:cached
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
    volumes:
      - postgres-data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine

volumes:
  postgres-data:
```

**File**: `.devcontainer/devcontainer.json`

```json
{
  "name": "Project Name Sandbox",
  "dockerComposeFile": "../docker-compose.yml",
  "service": "app",
  "workspaceFolder": "/workspace",
  "customizations": {
    "vscode": {
      "extensions": []
    }
  },
  "remoteUser": "root"
}
```

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

### Example 1: Python Project (Simple)

**Detected files**: `requirements.txt`

**Generated**: `.devcontainer/devcontainer.json`

```json
{
  "name": "Python Sandbox",
  "image": "python:3.12-slim-bookworm",
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python",
        "ms-python.vscode-pylance"
      ]
    }
  },
  "postCreateCommand": "pip install -r requirements.txt",
  "remoteUser": "root"
}
```

### Example 2: Node.js + PostgreSQL

**Detected files**: `package.json`

**Generated**: `docker-compose.yml` + `.devcontainer/devcontainer.json`

docker-compose.yml:
```yaml
version: '3.8'

services:
  app:
    image: node:20-bookworm-slim
    volumes:
      - ..:/workspace:cached
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

.devcontainer/devcontainer.json:
```json
{
  "name": "Node.js + PostgreSQL Sandbox",
  "dockerComposeFile": "../docker-compose.yml",
  "service": "app",
  "workspaceFolder": "/workspace",
  "customizations": {
    "vscode": {
      "extensions": [
        "dbaeumer.vscode-eslint",
        "esbenp.prettier-vscode"
      ]
    }
  },
  "postCreateCommand": "npm install",
  "remoteUser": "root"
}
```

### Example 3: Full-Stack (React + Python + PostgreSQL + Redis)

**Detected files**: `package.json`, `requirements.txt`

**Generated**: `docker-compose.yml` with all services

```yaml
version: '3.8'

services:
  app:
    image: docker/sandbox-templates:claude-code
    volumes:
      - ..:/workspace:cached
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
    volumes:
      - postgres-data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine

volumes:
  postgres-data:
```

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

## Summary

Basic mode is optimized for speed and simplicity:

1. Auto-detect project type
2. Ask 1 question maximum
3. Generate minimal configuration
4. Pull images with confirmation
5. Provide next steps

Total time: 2-5 minutes from start to working sandbox.
