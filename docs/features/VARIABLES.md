# Variables Configuration Guide

This guide covers all variable types used in DevContainer configuration and how to use them effectively across different sandbox modes.

> **⚠️ For sensitive data (passwords, API keys, certificates):** See [Secrets Management Guide](SECRETS.md)
>
> This guide covers **non-sensitive configuration only**. Never use environment variables for passwords, API keys, or other credentials in production.

## Quick Reference

| Variable Type | When to Use | Where Defined | Example |
|---------------|-------------|---------------|---------|
| **ARG** | Build-time (Dockerfile) | `docker-compose.yml` build args | `PYTHON_VERSION=3.12` |
| **ENV** | Runtime (container lifetime) | `Dockerfile`, `docker-compose.yml` env | `NODE_ENV=development` |
| **COMPOSE** | Service configuration | `docker-compose.yml` services | `POSTGRES_PASSWORD=...` |
| **VS_CODE_INPUT** | User prompts at startup | `devcontainer.json` inputs | GitHub token, API keys |
| **SECRET** | Secure credentials | Docker secrets, VS Code inputs | AWS keys, certificates |

## Variable Types Explained

### 1. Dockerfile ARG (Build-time Variables)

**Purpose:** Configure image construction before it runs.

**Characteristics:**
- Only available during Docker build
- Not present in final container
- Can be overridden via `docker-compose.yml` build args
- Not suitable for runtime configuration
- **NEVER use for secrets** (they persist in image history)

**Example:**
```dockerfile
ARG PYTHON_VERSION=3.12
ARG NODE_VERSION=20
ARG TZ=UTC

FROM python:${PYTHON_VERSION}-slim-bookworm
RUN apt-get update && apt-get install -y nodejs=${NODE_VERSION}
```

**docker-compose.yml override:**
```yaml
services:
  app:
    build:
      context: .
      args:
        PYTHON_VERSION: "3.11"  # Override default
        NODE_VERSION: "18"
```

**When to use:**
- Base image selection
- Language version selection
- Timezone configuration
- Package versions during build
- Build-time feature flags

### 2. Dockerfile ENV (Runtime Variables)

**Purpose:** Environment variables that persist in the running container.

**Characteristics:**
- Available during build AND runtime
- Persist in final image
- Can be overridden at container start
- Visible in container process environment
- Not suitable for secrets (visible in docker inspect)

**Example:**
```dockerfile
ENV NODE_ENV=development
ENV PYTHONUNBUFFERED=1
ENV GOPATH=/go
ENV PATH=/usr/local/bin:$PATH
```

**When to use:**
- Application environment (development/production)
- Language-specific settings (PYTHONUNBUFFERED, GOPATH)
- PATH modifications
- Non-sensitive configuration

### 3. Docker Compose ENV (Service Variables)

**Purpose:** Configure service behavior and connections.

**Characteristics:**
- Defined in `docker-compose.yml` or `.env` file
- Available to containers at runtime
- Can reference other variables: `${VAR:-default}`
- Separate from build args

**Example:**
```yaml
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-sandbox_user}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-devpassword}
      POSTGRES_DB: ${POSTGRES_DB:-sandbox_dev}

  app:
    environment:
      DATABASE_URL: postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}
      REDIS_HOST: redis
      REDIS_PORT: 6379
```

**.env file:**
```bash
POSTGRES_USER=myuser
POSTGRES_PASSWORD=mypassword
POSTGRES_DB=mydb
```

**When to use:**
- Database configuration
- Service connection strings
- Cache settings (Redis, Memcached)
- Message queue settings
- Development defaults (use secrets for production!)

### 4. VS Code Input Variables (User Prompts)

**Purpose:** Prompt users for sensitive or user-specific values at container start.

**Characteristics:**
- Defined in `devcontainer.json` inputs section
- Prompts user when container starts
- Can be marked as password (hidden input)
- Values stored in VS Code settings (not in repository)
- Ideal for development credentials

**Types:**
- `promptString`: Free-form text input
- `pickString`: Multiple choice selection
- `command`: Execute command to get value

**Example:**
```json
{
  "inputs": {
    "githubToken": {
      "type": "promptString",
      "description": "GitHub personal access token (repo scope)",
      "password": true
    },
    "dbPassword": {
      "type": "promptString",
      "description": "Database password",
      "password": true,
      "default": "devpassword"
    },
    "nodeVersion": {
      "type": "pickString",
      "description": "Node.js version",
      "options": ["18", "20", "22"],
      "default": "20"
    }
  },
  "containerEnv": {
    "GITHUB_TOKEN": "${input:githubToken}",
    "POSTGRES_PASSWORD": "${input:dbPassword}",
    "NODE_VERSION": "${input:nodeVersion}"
  }
}
```

**When to use:**
- API keys and tokens
- Database passwords
- User-specific credentials
- Development environment choices
- Anything that shouldn't be committed to Git

### 5. Docker Secrets (Production-Grade Security)

**Purpose:** Securely pass credentials during build or runtime.

**Characteristics:**
- Never stored in image layers or history
- Mounted as files in `/run/secrets/`
- Removed after use
- Best practice for production credentials

**Types:**
- **Build secrets:** Available during `docker build` with `--mount=type=secret`
- **Runtime secrets:** Available in running containers
- **SSH secrets:** For Git authentication during build

**Example - Build Secret:**
```dockerfile
# Use secret during npm install
RUN --mount=type=secret,id=npm_token \
    NPM_TOKEN=$(cat /run/secrets/npm_token) && \
    echo "//registry.npmjs.org/:_authToken=${NPM_TOKEN}" > ~/.npmrc && \
    npm install && \
    rm ~/.npmrc
```

**Build with secret:**
```bash
docker build --secret id=npm_token,src=$HOME/.npm_token .
```

**Example - SSH Secret:**
```dockerfile
# Clone private repository
RUN --mount=type=ssh git clone git@github.com:private/repo.git
```

**Build with SSH:**
```bash
docker build --ssh default .
```

**When to use:**
- Private package registry tokens (npm, PyPI, gems)
- Git authentication for private repos
- API keys needed during build
- Any credential that shouldn't persist in image

## Mode-Specific Variable Usage

### Basic Mode

**Variable Count:** 5 build ARGs, 6 runtime ENVs

**Philosophy:** Sensible defaults, no user prompts

```json
{
  "build_args": {
    "TZ": "UTC",
    "DEBIAN_FRONTEND": "noninteractive"
  },
  "runtime_env": {
    "NODE_ENV": "development",
    "PYTHONUNBUFFERED": "1",
    "PYTHONDONTWRITEBYTECODE": "1"
  },
  "compose_env": {
    "POSTGRES_USER": "sandbox_user",
    "POSTGRES_PASSWORD": "devpassword",
    "POSTGRES_DB": "sandbox_dev"
  }
}
```

**Security:** Development defaults only, no secrets management

### Intermediate Mode

**Variable Count:** 8 build ARGs, 12 runtime ENVs, 2-3 VS Code inputs

**Philosophy:** Customizable versions, basic secret management

**Added features:**
- Customizable Python/Node.js versions via build args
- VS Code inputs for Git authentication
- Message queue configuration (RabbitMQ)
- Permissive firewall mode

```json
{
  "build_args": {
    "PYTHON_VERSION": "3.12",
    "NODE_VERSION": "20"
  },
  "vs_code_inputs": {
    "githubToken": {
      "type": "promptString",
      "password": true
    }
  }
}
```

### Advanced Mode

**Variable Count:** 12+ build ARGs, 20+ runtime ENVs, 5+ VS Code inputs, 5+ secrets

**Philosophy:** Production-ready with comprehensive secret management

**Added features:**
- Multi-language support (Go, Rust, Java)
- Cloud provider configuration
- Comprehensive VS Code inputs for all API keys
- Docker secret mounts for credentials
- Strict firewall mode
- Resource limits

```json
{
  "build_args": {
    "GO_VERSION": "1.22",
    "RUST_VERSION": "stable",
    "JAVA_VERSION": "17"
  },
  "vs_code_inputs": {
    "openaiKey": {"type": "promptString", "password": true},
    "anthropicKey": {"type": "promptString", "password": true}
  },
  "docker_secrets": [
    "gcp_key", "aws_credentials", "ssl_cert"
  ]
}
```

### YOLO Mode

**Variable Count:** Custom (all available)

**Philosophy:** Maximum control, full responsibility

**Features:**
- All variable types available
- Template-driven with `{{PLACEHOLDER}}` syntax
- Complete cloud provider support
- Comprehensive secret management options
- User defines everything

## Best Practices

### 1. Choose the Right Variable Type

```
┌─────────────────────────────────────────────────────────┐
│ Decision Tree: Which Variable Type?                    │
├─────────────────────────────────────────────────────────┤
│                                                         │
│ Is it a SECRET? (password, API key, token)             │
│ ├─ YES → Use VS Code Input (dev) or Docker Secret (prod)│
│ └─ NO → Continue...                                     │
│                                                         │
│ Needed during build only?                              │
│ ├─ YES → ARG                                            │
│ └─ NO → Continue...                                     │
│                                                         │
│ Needed at runtime?                                      │
│ ├─ YES → ENV or COMPOSE                                 │
│ └─ NO → Not a variable, might be a mount               │
│                                                         │
│ User-specific or varies by developer?                   │
│ ├─ YES → VS Code Input                                  │
│ └─ NO → ENV or COMPOSE with defaults                    │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 2. Security Guidelines

**NEVER do this:**
```dockerfile
# BAD: Secret in ARG (persists in image history)
ARG GITHUB_TOKEN=ghp_xxxxxxxxxxxx
ENV API_KEY=sk-xxxxxxxxxxxx  # BAD: Visible in docker inspect
```

```yaml
# BAD: Secrets in docker-compose.yml committed to Git
environment:
  AWS_ACCESS_KEY_ID: AKIAIOSFODNN7EXAMPLE
  AWS_SECRET_ACCESS_KEY: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

**ALWAYS do this:**
```json
// GOOD: VS Code input for development
{
  "inputs": {
    "apiKey": {
      "type": "promptString",
      "password": true
    }
  },
  "containerEnv": {
    "API_KEY": "${input:apiKey}"
  }
}
```

```dockerfile
# GOOD: Docker secret for build-time credentials
RUN --mount=type=secret,id=npm_token \
    NPM_TOKEN=$(cat /run/secrets/npm_token) npm install
```

### 3. Environment File (.env) Guidelines

**DO:**
- Use `.env` for development defaults
- Add `.env` to `.gitignore`
- Create `.env.example` with placeholders
- Document required variables
- Use `${VAR:-default}` for fallbacks

**DON'T:**
- Commit real credentials to `.env`
- Share `.env` files between developers
- Use `.env` for production secrets
- Hardcode sensitive values

**Example .env.example:**
```bash
# Copy to .env and fill in values
POSTGRES_USER=sandbox_user
POSTGRES_PASSWORD=CHANGEME
GITHUB_TOKEN=GITHUB_TOKEN_HERE
OPENAI_API_KEY=sk-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

### 4. Variable Naming Conventions

**Follow these patterns:**
```bash
# Service configuration
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
REDIS_HOST=redis
REDIS_PORT=6379

# Application environment
NODE_ENV=development
RAILS_ENV=development
FLASK_ENV=development

# Language-specific
PYTHONUNBUFFERED=1
GOPATH=/go
JAVA_HOME=/usr/lib/jvm/java-17

# Feature flags
FIREWALL_MODE=strict
DEBUG=true
LOG_LEVEL=info

# Cloud providers
AWS_REGION=us-east-1
GCP_PROJECT_ID=my-project
AZURE_SUBSCRIPTION_ID=xxxxx
```

### 5. Documentation Requirements

For each variable in your project:
- Document purpose and usage
- Specify required vs. optional
- Provide example values
- Note security considerations
- Explain how to obtain (for tokens/keys)

## Common Patterns

### Database Connection

```yaml
# docker-compose.yml
services:
  postgres:
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-sandbox_user}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-devpassword}
      POSTGRES_DB: ${POSTGRES_DB:-sandbox_dev}

  app:
    environment:
      # Option 1: Individual variables
      POSTGRES_HOST: postgres
      POSTGRES_PORT: 5432
      POSTGRES_USER: ${POSTGRES_USER:-sandbox_user}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-devpassword}
      POSTGRES_DB: ${POSTGRES_DB:-sandbox_dev}

      # Option 2: Connection URL
      DATABASE_URL: postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}
```

### Multi-Environment Configuration

```yaml
# docker-compose.yml
services:
  app:
    environment:
      NODE_ENV: ${NODE_ENV:-development}
      DEBUG: ${DEBUG:-true}
      LOG_LEVEL: ${LOG_LEVEL:-info}
```

```bash
# .env.development
NODE_ENV=development
DEBUG=true
LOG_LEVEL=debug

# .env.production
NODE_ENV=production
DEBUG=false
LOG_LEVEL=warning
```

### Cloud Credentials (Secure)

```json
// devcontainer.json - Mount from host
{
  "mounts": [
    "source=${localEnv:HOME}/.aws,target=/home/node/.aws,type=bind",
    "source=${localEnv:HOME}/.config/gcloud,target=/home/node/.config/gcloud,type=bind"
  ],
  "containerEnv": {
    "AWS_PROFILE": "default"
  }
}
```

## Troubleshooting

### Issue: Variables not expanding

```yaml
# WRONG: Single quotes prevent expansion
environment:
  - 'DATABASE_URL=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres'

# CORRECT: Use double quotes or no quotes
environment:
  - "DATABASE_URL=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres"
  # or
  - DATABASE_URL=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres
```

### Issue: ARG not available at runtime

```dockerfile
# WRONG: ARG is build-time only
ARG NODE_ENV=development
RUN echo $NODE_ENV  # Works during build
# CMD will NOT see NODE_ENV

# CORRECT: Use ENV for runtime
ARG NODE_ENV=development
ENV NODE_ENV=${NODE_ENV}  # Copy ARG to ENV
```

### Issue: Secrets visible in image history

```dockerfile
# WRONG: Secret persists in image layer
ARG NPM_TOKEN
RUN npm config set //registry.npmjs.org/:_authToken ${NPM_TOKEN}
RUN npm install

# CORRECT: Use secret mount
RUN --mount=type=secret,id=npm_token \
    NPM_TOKEN=$(cat /run/secrets/npm_token) && \
    npm config set //registry.npmjs.org/:_authToken ${NPM_TOKEN} && \
    npm install
```

## Related Documentation

- [Secrets Management](./SECRETS.md) - Comprehensive secret handling guide
- [Modes Comparison](./MODES.md) - Variable counts per mode
- [Security Model](./security-model.md) - Overall security approach
- [Docker Build Variables](https://docs.docker.com/build/building/variables/)
- [VS Code Variables Reference](https://code.visualstudio.com/docs/reference/variables-reference)

## Reference Files

- `data/variables.json` - Complete variable catalog
- `templates/env/*.template` - Environment file templates per mode
- `templates/variables/*.json` - Variable configurations per mode

---

**Last Updated:** 2025-12-16
**Version:** 2.2.2
