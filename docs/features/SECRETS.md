# Secrets Management Guide

This guide covers secure credential handling in DevContainers, including Docker secrets, VS Code input variables, and best practices for different sandbox modes.

> **📝 For non-sensitive configuration:** See [Variables Guide](VARIABLES.md)
>
> This guide covers **sensitive credentials only**. For application configuration that doesn't need protection (versions, feature flags, non-sensitive settings), use the Variables Guide instead.

## Table of Contents

1. [Quick Reference](#quick-reference)
2. [Why Secrets Management Matters](#why-secrets-management-matters)
3. [Secret Types and Methods](#secret-types-and-methods)
4. [Mode-Specific Approaches](#mode-specific-approaches)
5. [Common Use Cases](#common-use-cases)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)

## Quick Reference

| Secret Type | Best Method | Mode | Example |
|-------------|-------------|------|---------|
| API Keys (dev) | VS Code Input | Intermediate+ | GitHub token, OpenAI key |
| API Keys (prod) | Docker Secret | Advanced+ | Production API credentials |
| Database Passwords | VS Code Input (dev) / Secret (prod) | Basic+ | PostgreSQL password |
| Git Auth | VS Code Input or SSH | Intermediate+ | GitHub/GitLab tokens |
| Cloud Credentials | Host Mount | Advanced+ | ~/.aws, ~/.gcloud |
| Private Registry | Docker Build Secret | Advanced+ | NPM, PyPI tokens |
| SSL Certificates | Docker Secret | Advanced+ | TLS cert and key |

## Why Secrets Management Matters

### The Problem

**NEVER do this:**
```dockerfile
# ❌ WRONG: Secrets in Dockerfile
ARG GITHUB_TOKEN=ghp_xxxxxxxxxxxx
ENV API_KEY=sk-xxxxxxxxxxxx
RUN git clone https://${GITHUB_TOKEN}@github.com/private/repo.git
```

**Why this is dangerous:**
- ARG values persist in image history (`docker history`)
- ENV values visible in `docker inspect`
- Anyone with image access can extract secrets
- Secrets remain even if removed in later layers
- Committed to version control if Dockerfile is tracked

### The Solution

Use proper secret management methods:
1. **VS Code Input Variables** - For development
2. **Docker Build Secrets** - For build-time credentials
3. **Docker Runtime Secrets** - For production deployments
4. **Host Mounts** - For cloud provider CLIs

## Secret Types and Methods

### 1. VS Code Input Variables (Development)

**Best for:** Development credentials, user-specific tokens, API keys

**How it works:**
- Defined in `devcontainer.json`
- Prompts user when container starts
- Values stored in VS Code settings (not in repository)
- Can be marked as password (hidden input)

**Example:**
```json
{
  "inputs": {
    "githubToken": {
      "type": "promptString",
      "description": "GitHub personal access token (repo scope)",
      "password": true
    },
    "openaiKey": {
      "type": "promptString",
      "description": "OpenAI API key (starts with sk-)",
      "password": true
    }
  },
  "containerEnv": {
    "GITHUB_TOKEN": "${input:githubToken}",
    "OPENAI_API_KEY": "${input:openaiKey}"
  }
}
```

**Advantages:**
- User-specific credentials
- Not committed to Git
- Simple setup
- Good for development

**Limitations:**
- Not suitable for production
- Manual input required
- Stored in VS Code settings
- Not centrally managed

### 2. Docker Build Secrets (Build-time)

**Best for:** Private package registries, Git authentication, build-time credentials

**How it works:**
- Mounted temporarily during build with `--mount=type=secret`
- Never persists in image layers or history
- Removed after RUN command completes
- Requires Docker BuildKit

**Example - NPM Token:**
```dockerfile
# Mount secret during npm install
RUN --mount=type=secret,id=npm_token \
    if [ -f /run/secrets/npm_token ]; then \
        NPM_TOKEN=$(cat /run/secrets/npm_token) && \
        echo "//registry.npmjs.org/:_authToken=${NPM_TOKEN}" > ~/.npmrc && \
        npm install && \
        rm ~/.npmrc; \
    else \
        npm install; \
    fi
```

**Build with secret:**
```bash
# From file
docker build --secret id=npm_token,src=$HOME/.npm_token .

# From environment variable
echo $NPM_TOKEN | docker build --secret id=npm_token,src=- .
```

**docker-compose.yml:**
```yaml
services:
  app:
    build:
      context: .
      secrets:
        - npm_token

secrets:
  npm_token:
    file: ~/.npm_token
```

**Example - PyPI Token:**
```dockerfile
RUN --mount=type=secret,id=pypi_token \
    if [ -f /run/secrets/pypi_token ]; then \
        PYPI_TOKEN=$(cat /run/secrets/pypi_token) && \
        pip config set global.extra-index-url \
            https://token:${PYPI_TOKEN}@pypi.example.com/simple && \
        pip install -r requirements.txt && \
        pip config unset global.extra-index-url; \
    else \
        pip install -r requirements.txt; \
    fi
```

**Advantages:**
- Secure (doesn't persist in image)
- Works during build
- Supports multiple secrets
- Industry standard

**Limitations:**
- Requires BuildKit
- More complex setup
- Build-time only

### 3. SSH Secret Mounts (Git Authentication)

**Best for:** Cloning private Git repositories during build

**How it works:**
- Forwards SSH agent to build
- No keys copied to image
- Automatic Git authentication

**Example:**
```dockerfile
# Clone private repository
RUN --mount=type=ssh git clone git@github.com:private/repo.git /app/repo
```

**Build with SSH:**
```bash
# Use default SSH agent
docker build --ssh default .

# Specify SSH agent socket
docker build --ssh default=$SSH_AUTH_SOCK .
```

**docker-compose.yml:**
```yaml
services:
  app:
    build:
      context: .
      ssh:
        - default
```

**Setup:**
```bash
# Start SSH agent
eval $(ssh-agent)

# Add your key
ssh-add ~/.ssh/id_ed25519

# Build with forwarded agent
docker compose build
```

**Advantages:**
- No keys in image
- Uses existing SSH setup
- Multiple repos supported

**Limitations:**
- Requires SSH agent
- Build-time only
- Unix/Linux/macOS only (Windows WSL)

### 4. Host Mounts (Cloud Credentials)

**Best for:** AWS, GCP, Azure CLI credentials

**How it works:**
- Mount credentials directory from host
- Credentials stay on host
- Runtime access only
- No copying to container

**Example:**
```json
{
  "mounts": [
    "source=${localEnv:HOME}/.aws,target=/home/node/.aws,type=bind,consistency=cached",
    "source=${localEnv:HOME}/.config/gcloud,target=/home/node/.config/gcloud,type=bind,consistency=cached",
    "source=${localEnv:HOME}/.azure,target=/home/node/.azure,type=bind,consistency=cached"
  ],
  "containerEnv": {
    "AWS_PROFILE": "default"
  }
}
```

**Advantages:**
- Credentials never copied
- Automatic updates
- Multi-cloud support
- Native CLI experience

**Limitations:**
- Requires credentials on host
- Not portable between machines
- Runtime only (not during build)

### 5. Docker Runtime Secrets (Production)

**Best for:** Production deployments, orchestration platforms

**How it works:**
- Mounted at `/run/secrets/<secret_name>`
- Available to running container
- Managed by orchestrator (Swarm, Kubernetes)

**docker-compose.yml:**
```yaml
services:
  app:
    secrets:
      - db_password
      - api_key

secrets:
  db_password:
    file: ./secrets/db_password.txt
  api_key:
    external: true  # Managed by orchestrator
```

**Application code:**
```python
# Read secret in application
def get_db_password():
    with open('/run/secrets/db_password', 'r') as f:
        return f.read().strip()
```

**Advantages:**
- Production-ready
- Orchestrator integration
- Centralized management
- Access control

**Limitations:**
- Requires orchestration platform
- More complex setup
- Not for local development

## Mode-Specific Approaches

### Basic Mode

**Philosophy:** Development defaults, no secret management

**Secret Count:** 0

**Approach:**
- Hardcoded development credentials
- No VS Code inputs
- No Docker secrets
- Relies on hypervisor isolation

**Example:**
```yaml
# docker-compose.yml
environment:
  POSTGRES_PASSWORD: devpassword  # Development default only
  REDIS_HOST: redis
```

**Security Notes:**
- Only for local development
- Change all defaults for production
- No network firewall

### Intermediate Mode

**Philosophy:** Basic secret management for Git and databases

**Secret Count:** 1-2 (Git auth, optional DB password)

**Approach:**
- VS Code inputs for Git tokens
- Optional DB password override
- No Docker secrets yet
- Permissive firewall

**Example:**
```json
{
  "inputs": {
    "githubToken": {
      "type": "promptString",
      "description": "GitHub personal access token (optional)",
      "password": true
    }
  },
  "containerEnv": {
    "GITHUB_TOKEN": "${input:githubToken}"
  }
}
```

**Security Notes:**
- Git authentication secured
- Database uses defaults or inputs
- Suitable for team development

### Advanced Mode

**Philosophy:** Comprehensive secret management with multiple methods

**Secret Count:** 5+ (Git, databases, APIs, cloud, SSL)

**Approach:**
- VS Code inputs for all API keys
- Docker build secrets for registries
- Host mounts for cloud credentials
- Docker secrets for SSL certificates
- Strict firewall with allowlist

**Example:**
```json
{
  "inputs": {
    "githubToken": {"type": "promptString", "password": true},
    "openaiKey": {"type": "promptString", "password": true},
    "anthropicKey": {"type": "promptString", "password": true},
    "dbPassword": {"type": "promptString", "password": true}
  },
  "mounts": [
    "source=${localEnv:HOME}/.aws,target=/home/node/.aws,type=bind"
  ]
}
```

**Dockerfile:**
```dockerfile
RUN --mount=type=secret,id=npm_token \
    --mount=type=secret,id=pypi_token \
    install_private_packages.sh
```

**Security Notes:**
- Production-ready credential handling
- Multiple secret methods
- Strict network controls
- Resource limits

### YOLO Mode

**Philosophy:** Full flexibility, all secret methods available

**Secret Count:** Custom (unlimited)

**Approach:**
- All VS Code input options
- All Docker secret types
- Custom secret handling
- User-defined security model

**Example:**
```json
{
  "inputs": {
    "githubToken": {...},
    "gitlabToken": {...},
    "openaiKey": {...},
    "anthropicKey": {...},
    "stripeKey": {...},
    "sendgridKey": {...}
    // ... unlimited custom inputs
  },
  "mounts": [
    // All cloud providers
    // Custom credential locations
  ]
}
```

## Common Use Cases

### GitHub Private Repositories

**Option 1: VS Code Input (Development)**
```json
{
  "inputs": {
    "githubToken": {
      "type": "promptString",
      "description": "GitHub PAT with repo scope",
      "password": true
    }
  },
  "containerEnv": {
    "GITHUB_TOKEN": "${input:githubToken}"
  }
}
```

**Option 2: SSH Key (Build)**
```dockerfile
RUN --mount=type=ssh git clone git@github.com:user/private-repo.git
```

```bash
ssh-add ~/.ssh/id_ed25519
docker build --ssh default .
```

**Option 3: Token in Build Secret**
```dockerfile
RUN --mount=type=secret,id=github_token \
    GITHUB_TOKEN=$(cat /run/secrets/github_token) && \
    git clone https://${GITHUB_TOKEN}@github.com/user/private-repo.git
```

### Private NPM Packages

```dockerfile
# .npmrc template (not committed)
//registry.npmjs.org/:_authToken=${NPM_TOKEN}

# Dockerfile
RUN --mount=type=secret,id=npm_token \
    NPM_TOKEN=$(cat /run/secrets/npm_token) && \
    envsubst < .npmrc.template > ~/.npmrc && \
    npm install && \
    rm ~/.npmrc
```

### Database Credentials

**Development:**
```json
{
  "inputs": {
    "dbPassword": {
      "type": "promptString",
      "description": "PostgreSQL password",
      "password": true,
      "default": "devpassword"
    }
  },
  "containerEnv": {
    "POSTGRES_PASSWORD": "${input:dbPassword}",
    "DATABASE_URL": "postgresql://user:${input:dbPassword}@postgres:5432/db"
  }
}
```

**Production:**
```yaml
services:
  app:
    secrets:
      - db_password
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
```

```python
# Application code
import os

def get_db_password():
    password_file = os.getenv('POSTGRES_PASSWORD_FILE')
    if password_file:
        with open(password_file) as f:
            return f.read().strip()
    return os.getenv('POSTGRES_PASSWORD', 'devpassword')
```

### AWS Credentials

**Best practice: Mount from host**
```json
{
  "mounts": [
    "source=${localEnv:HOME}/.aws,target=/home/node/.aws,type=bind"
  ],
  "containerEnv": {
    "AWS_PROFILE": "default"
  }
}
```

**Alternative: Input variables (NOT recommended for production)**
```json
{
  "inputs": {
    "awsAccessKeyId": {
      "type": "promptString",
      "description": "AWS Access Key ID",
      "password": true
    },
    "awsSecretAccessKey": {
      "type": "promptString",
      "description": "AWS Secret Access Key",
      "password": true
    }
  },
  "containerEnv": {
    "AWS_ACCESS_KEY_ID": "${input:awsAccessKeyId}",
    "AWS_SECRET_ACCESS_KEY": "${input:awsSecretAccessKey}",
    "AWS_REGION": "us-east-1"
  }
}
```

### API Keys (OpenAI, Anthropic, etc.)

```json
{
  "inputs": {
    "openaiKey": {
      "type": "promptString",
      "description": "OpenAI API key (starts with sk-)",
      "password": true
    },
    "anthropicKey": {
      "type": "promptString",
      "description": "Anthropic API key",
      "password": true
    }
  },
  "containerEnv": {
    "OPENAI_API_KEY": "${input:openaiKey}",
    "ANTHROPIC_API_KEY": "${input:anthropicKey}"
  }
}
```

## Best Practices

### 1. The Golden Rules

**NEVER:**
- ❌ Use ARG for secrets (persists in history)
- ❌ Use ENV for secrets (visible in inspect)
- ❌ Commit credentials to Git
- ❌ Share .env files with real credentials
- ❌ Use production secrets in development
- ❌ Hardcode API keys in source code

**ALWAYS:**
- ✅ Use VS Code inputs for development
- ✅ Use Docker secrets for production
- ✅ Add .env to .gitignore
- ✅ Create .env.example with placeholders
- ✅ Rotate secrets regularly
- ✅ Use different secrets per environment

### 2. Secret Lifecycle

```
Creation → Storage → Distribution → Usage → Rotation → Revocation
    ↓         ↓            ↓          ↓         ↓          ↓
Password   VS Code     devcontainer  App     Update    Delete
manager    settings    .json         code    values    old key
```

### 3. .gitignore Configuration

```gitignore
# Environment files with secrets
.env
.env.local
.env.*.local

# Credential files
**/*.key
**/*.pem
**/*.crt
**/*_credentials*
**/*_token*
secrets/

# Cloud provider credentials
.aws/
.config/gcloud/
.azure/

# Keep templates
!.env.example
!.env.template
```

### 4. Documentation Template

Create `SECRETS.md` in your project:

```markdown
# Project Secrets

## Required Secrets

1. **GITHUB_TOKEN**
   - Purpose: Access private repositories
   - How to obtain: GitHub Settings → Developer Settings → Personal Access Tokens
   - Scopes needed: repo
   - Where to set: VS Code will prompt on container start

2. **OPENAI_API_KEY**
   - Purpose: OpenAI API access
   - How to obtain: platform.openai.com → API Keys
   - Format: Starts with sk-
   - Where to set: VS Code input variable

## Optional Secrets

...
```

### 5. Team Onboarding Checklist

```markdown
# New Developer Setup

- [ ] Install required CLI tools (gh, aws, gcloud)
- [ ] Generate GitHub personal access token
- [ ] Obtain API keys from team lead
- [ ] Configure AWS credentials locally
- [ ] Copy .env.example to .env
- [ ] Start devcontainer (will prompt for secrets)
- [ ] Test all integrations
- [ ] Delete any test credentials
```

## Troubleshooting

### Issue: "Secret not found" during build

```bash
# Check secret file exists
ls -la ~/.npm_token

# Verify secret in docker-compose.yml
docker compose config | grep -A5 secrets

# Build with explicit secret
docker build --secret id=npm_token,src=$HOME/.npm_token .
```

### Issue: VS Code not prompting for input

```json
// Check inputs are defined correctly
{
  "inputs": {
    "mySecret": {  // ← Check spelling
      "type": "promptString",  // ← Correct type
      "password": true  // ← Boolean, not string
    }
  },
  "containerEnv": {
    "MY_SECRET": "${input:mySecret}"  // ← Must match input ID
  }
}
```

### Issue: Mounted credentials not working

```json
// Check path expansion
{
  "mounts": [
    // WRONG: Literal string
    "source=~/.aws,target=/home/node/.aws,type=bind",

    // CORRECT: Environment variable expansion
    "source=${localEnv:HOME}/.aws,target=/home/node/.aws,type=bind"
  ]
}
```

### Issue: Secret visible in docker history

```bash
# Check if secret is in history
docker history myimage | grep -i secret

# If found, rebuild with proper secret mount
# Never use ARG or ENV for secrets!
```

## Migration Guides

### From Hardcoded to VS Code Inputs

**Before:**
```dockerfile
ENV GITHUB_TOKEN=ghp_xxxxxxxxxxxx
```

**After:**
```json
{
  "inputs": {
    "githubToken": {"type": "promptString", "password": true}
  },
  "containerEnv": {
    "GITHUB_TOKEN": "${input:githubToken}"
  }
}
```

### From .env to Docker Secrets

**Before:**
```bash
# .env (committed - BAD!)
NPM_TOKEN=npm_xxxxxxxxxxxx
```

**After:**
```dockerfile
# Dockerfile
RUN --mount=type=secret,id=npm_token \
    NPM_TOKEN=$(cat /run/secrets/npm_token) npm install
```

```yaml
# docker-compose.yml
secrets:
  npm_token:
    file: ~/.npm_token
```

## Related Documentation

- [Variables Guide](./VARIABLES.md) - Variable types and usage
- [Modes Comparison](./MODES.md) - Secret counts per mode
- [Security Model](./security-model.md) - Overall security approach
- [Docker Build Secrets](https://docs.docker.com/build/building/secrets/)
- [VS Code Variables Reference](https://code.visualstudio.com/docs/reference/variables-reference)

## Reference Files

- `data/secrets.json` - Complete secrets catalog
- `templates/env/*.template` - Environment templates with secret placeholders
- `templates/variables/*.json` - Variable configurations per mode

---

**Last Updated:** 2025-12-16
**Version:** 2.2.1
