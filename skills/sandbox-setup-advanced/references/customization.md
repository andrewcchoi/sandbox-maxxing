# Customization Guide

This guide explains how to adapt the Claude Code Docker sandbox template for your specific project.

## Table of Contents

- [Quick Customization Checklist](#quick-customization-checklist)
- [DevContainer Configuration](#devcontainer-configuration)
- [Dockerfile Customization](#dockerfile-customization)
- [Docker Compose Services](#docker-compose-services)
- [Firewall Configuration](#firewall-configuration)
- [Language-Specific Setup](#language-specific-setup)

## Quick Customization Checklist

Follow these steps in order for fastest setup:

- [ ] 1. **Copy template files** to your project
- [ ] 2. **Update network name** in both `devcontainer.json` and `docker-compose.yml`
- [ ] 3. **Choose your database** in `docker-compose.yml` (uncomment and configure)
- [ ] 4. **Configure base image** in `Dockerfile` for your primary language
- [ ] 5. **Add project-specific domains** to firewall whitelist (if using strict mode)
- [ ] 6. **Pre-install dependencies** in Dockerfile (optional but recommended)
- [ ] 7. **Configure environment variables** in `devcontainer.json`

## DevContainer Configuration

### File: `.devcontainer/devcontainer.json`

#### 1. Change Project Name

```json
{
  "name": "Your Project Sandbox",  // Change this
```

#### 2. Update Network Name

The network name MUST match between `devcontainer.json` and `docker-compose.yml`:

```json
"runArgs": [
  "--cap-add=NET_ADMIN",
  "--cap-add=NET_RAW",
  "--network=your-project-network"  // CHANGE THIS
]
```

Then update `docker-compose.yml`:

```yaml
networks:
  default:
    name: your-project-network  # MUST MATCH devcontainer.json
```

#### 3. Add Project-Specific Environment Variables

```json
"containerEnv": {
  "HISTFILE": "/home/node/.bash_history_dir/.bash_history",

  // Add your variables here:
  "DATABASE_URL": "postgresql://user:pass@postgres:5432/mydb",
  "REDIS_URL": "redis://redis:6379",
  "API_KEY": "${localEnv:API_KEY}",  // Pass from host
  "NODE_ENV": "development"
}
```

**Note:** Use `${localEnv:VAR_NAME}` to pass environment variables from your host machine.

#### 4. Add Project-Specific VS Code Extensions

```json
"customizations": {
  "vscode": {
    "extensions": [
      "anthropic.claude-code",
      "dbaeumer.vscode-eslint",
      "esbenp.prettier-vscode",
      "eamodio.gitlens",

      // Add language-specific extensions:
      // Python:
      "ms-python.python",
      "ms-python.vscode-pylance",

      // Rust:
      // "rust-lang.rust-analyzer",

      // Go:
      // "golang.go"
    ]
  }
}
```

#### 5. Configure Post-Create Commands (Optional)

Run commands after container creation (first time only):

```json
"postCreateCommand": "npm install && pip install -r requirements.txt",
```

## Dockerfile Customization

### File: `.devcontainer/Dockerfile`

#### 1. Choose Base Image

Change the `FROM` line based on your primary language:

```dockerfile
# Python (current default)
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim

# Node.js
# FROM node:20-bookworm-slim

# Go
# FROM golang:1.21-bookworm

# Rust
# FROM rust:1.75-slim-bookworm

# Multi-language (Python + Node)
# FROM python:3.12-slim-bookworm
# (Then install Node.js separately as shown in template)
```

#### 2. Add Language-Specific System Packages

Find the section marked "CUSTOMIZE: Add language-specific packages":

```dockerfile
# Python
RUN apt-get update && apt-get install -y --no-install-recommends \
  python3-venv \
  python3-pip \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Ruby
# RUN apt-get update && apt-get install -y --no-install-recommends \
#   ruby-full \
#   build-essential \
#   && apt-get clean && rm -rf /var/lib/apt/lists/*

# Java
# RUN apt-get update && apt-get install -y --no-install-recommends \
#   default-jdk \
#   maven \
#   && apt-get clean && rm -rf /var/lib/apt/lists/*
```

#### 3. Pre-Install Project Dependencies

**Why?** Pre-installing dependencies:
- Speeds up container startup
- Improves Docker layer caching
- Makes development faster

**Node.js example:**

```dockerfile
# Copy package files first (for layer caching)
COPY --chown=node:node package*.json /workspace/
RUN cd /workspace && npm ci
```

**Python with pip:**

```dockerfile
COPY requirements.txt /tmp/
RUN pip install --no-cache-dir -r /tmp/requirements.txt && rm /tmp/requirements.txt
```

**Python with uv:**

```dockerfile
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --locked --no-install-project
```

**Multiple package managers:**

```dockerfile
# Frontend dependencies
COPY --chown=node:node frontend/package*.json /workspace/frontend/
RUN cd /workspace/frontend && npm ci

# Backend dependencies
COPY backend/requirements.txt /tmp/
RUN pip install --no-cache-dir -r /tmp/requirements.txt
```

#### 4. Configure Environment Variables

Add language-specific environment variables:

```dockerfile
# Python with uv
ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy
ENV PATH="/workspace/.venv/bin:$PATH"

# Go
ENV GOPATH=/home/node/go
ENV PATH=$PATH:/usr/local/go/bin:$GOPATH/bin

# Rust
ENV CARGO_HOME=/home/node/.cargo
ENV PATH=$PATH:$CARGO_HOME/bin

# Node.js (already configured in template)
ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$PATH:/usr/local/share/npm-global/bin
```

## Docker Compose Services

### File: `docker-compose.base.yml`

#### 1. Choose Your Database

Uncomment and configure the database your project uses:

**PostgreSQL:**
```yaml
postgres:
  image: postgres:15
  container_name: my-project-postgres
  environment:
    POSTGRES_DB: mydb          # Your database name
    POSTGRES_USER: myuser      # Your username
    POSTGRES_PASSWORD: devpassword
  ports:
    - "5432:5432"
  volumes:
    - postgres_data:/var/lib/postgresql/data
```

**MySQL:**
```yaml
mysql:
  image: mysql:8
  container_name: my-project-mysql
  environment:
    MYSQL_DATABASE: mydb
    MYSQL_USER: myuser
    MYSQL_PASSWORD: devpassword
    MYSQL_ROOT_PASSWORD: rootpassword
  ports:
    - "3306:3306"
```

**MongoDB:**
```yaml
mongodb:
  image: mongo:7
  container_name: my-project-mongodb
  environment:
    MONGO_INITDB_ROOT_USERNAME: admin
    MONGO_INITDB_ROOT_PASSWORD: devpassword
  ports:
    - "27017:27017"
```

#### 2. Add Cache Services (Optional)

**Redis:**
```yaml
redis:
  image: redis:7-alpine
  container_name: my-project-redis
  ports:
    - "6379:6379"
  volumes:
    - redis_data:/data
```

#### 3. Add AI Services (Optional)

**Ollama (local LLM):**
```yaml
ollama:
  image: ollama/ollama:latest
  container_name: my-project-ollama
  ports:
    - "11434:11434"
  volumes:
    - ollama_data:/root/.ollama
  deploy:
    resources:
      reservations:
        devices:
          - driver: nvidia
            count: all
            capabilities: [gpu]
```

**Requirements:**
- NVIDIA GPU
- nvidia-docker2 installed
- NVIDIA drivers

#### 4. Update Volumes

Add volumes for each service you've enabled:

```yaml
volumes:
  postgres_data:
  redis_data:
  ollama_data:
```

## Firewall Configuration

### File: `.devcontainer/init-firewall.sh`

#### 1. Choose Security Mode

**Option A: Set via environment variable (recommended)**

In `devcontainer.json`:
```json
"containerEnv": {
  "FIREWALL_MODE": "strict"  // or "permissive"
}
```

**Option B: Edit script directly**

In `init-firewall.sh`:
```bash
FIREWALL_MODE="${FIREWALL_MODE:-strict}"  # Change default here
```

#### 2. Add Project-Specific Domains (Strict Mode Only)

Find the `ALLOWED_DOMAINS` array:

```bash
ALLOWED_DOMAINS=(
  # Version control
  "github.com"
  "gitlab.com"

  # Package registries
  "registry.npmjs.org"
  "pypi.org"

  # AI providers
  "api.anthropic.com"
  "api.openai.com"

  # ADD YOUR DOMAINS HERE:
  "api.yourproject.com"
  "cdn.yourproject.com"
  "external-api.com"
)
```

#### 3. Security Recommendations

**Development (local work):** Permissive mode is fine for convenience
**Production/CI:** Always use strict mode
**Team environments:** Use strict mode with documented allowed domains

## Language-Specific Setup

### Python Projects

#### 1. Base Image

```dockerfile
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim
```

#### 2. Dependencies

**With uv:**
```dockerfile
COPY pyproject.toml uv.lock ./
RUN uv sync --locked --no-install-project
```

**With pip:**
```dockerfile
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
```

#### 3. Environment Variables

```json
"containerEnv": {
  "PYTHONPATH": "/workspace",
  "DATABASE_URL": "postgresql://user:pass@postgres:5432/mydb"
}
```

### Node.js Projects

#### 1. Base Image

```dockerfile
FROM node:20-bookworm-slim
```

#### 2. Dependencies

```dockerfile
COPY package*.json ./
RUN npm ci
```

#### 3. Environment Variables

```json
"containerEnv": {
  "NODE_ENV": "development",
  "DATABASE_URL": "mongodb://admin:pass@mongodb:27017/mydb"
}
```

### Go Projects

#### 1. Base Image

```dockerfile
FROM golang:1.21-bookworm
```

#### 2. Dependencies

```dockerfile
WORKDIR /workspace
COPY go.mod go.sum ./
RUN go mod download
```

#### 3. Environment Variables

```dockerfile
ENV GOPATH=/home/node/go
ENV PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
```

### Rust Projects

#### 1. Base Image

```dockerfile
FROM rust:1.75-slim-bookworm
```

#### 2. Dependencies

```dockerfile
COPY Cargo.toml Cargo.lock ./
RUN cargo fetch
```

#### 3. Environment Variables

```dockerfile
ENV CARGO_HOME=/home/node/.cargo
ENV PATH=$PATH:$CARGO_HOME/bin
```

### Full-Stack Projects (Multiple Languages)

Use Python or Node.js base image and install the other language:

```dockerfile
# Start with Python
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim

# Install Node.js
RUN apt-get update && apt-get install -y --no-install-recommends \
  curl gnupg && \
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
  apt-get install -y nodejs && \
  apt-get clean && rm -rf /var/lib/apt/lists/*

# Install frontend dependencies
COPY frontend/package*.json /workspace/frontend/
RUN cd /workspace/frontend && npm ci

# Install backend dependencies
COPY backend/requirements.txt /tmp/
RUN pip install --no-cache-dir -r /tmp/requirements.txt
```

## Testing Your Configuration

### 1. Build and Start

```bash
# Start supporting services
docker compose up -d

# Open in VS Code
code .

# Reopen in container
# Ctrl+Shift+P → "Dev Containers: Reopen in Container"
```

### 2. Verify Service Connectivity

Inside the DevContainer terminal:

```bash
# Test database connection
# PostgreSQL:
psql postgresql://myuser:devpassword@postgres:5432/mydb

# Redis:
redis-cli -h redis ping

# Ollama:
curl http://ollama:11434/api/tags
```

### 3. Verify Firewall (Strict Mode)

```bash
# Should fail:
curl https://example.com

# Should succeed:
curl https://api.github.com/zen
```

## Common Customization Patterns

### Pattern 1: Monorepo with Multiple Services

```dockerfile
# Pre-install all service dependencies
COPY services/api/package*.json /workspace/services/api/
COPY services/web/package*.json /workspace/services/web/
RUN cd /workspace/services/api && npm ci && \
    cd /workspace/services/web && npm ci
```

### Pattern 2: Private Package Registry

Add to firewall:
```bash
ALLOWED_DOMAINS=(
  "npm.yourcompany.com"
  "artifactory.yourcompany.com"
)
```

Configure in `.npmrc` or `.pypirc`.

### Pattern 3: Multiple Databases

```yaml
# docker-compose.yml
services:
  postgres:
    # ... main database
  mongodb:
    # ... document store
  redis:
    # ... cache/sessions
```

### Pattern 4: GPU-Accelerated AI Development

```yaml
ollama:
  deploy:
    resources:
      reservations:
        devices:
          - driver: nvidia
            count: all
            capabilities: [gpu]
```

And update firewall for AI provider APIs.

## Next Steps

- Review [security.md](security.md) to understand the security model
- Check [troubleshooting.md](troubleshooting.md) for common issues
- Browse [examples/](examples/) for complete configuration examples
