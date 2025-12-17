---
name: sandbox-setup-intermediate
description: Use when user wants standard sandbox with Dockerfile, permissive firewall for convenience, and common service options - good balance of flexibility and simplicity
---

# Sandbox Setup - Intermediate Mode

## Overview

Intermediate mode provides a standard Dockerfile-based development sandbox with a permissive firewall configuration and flexible service options. This mode offers a good balance between flexibility and simplicity, making it ideal for developers who want Docker customization capabilities without the complexity of fine-grained firewall rules.

**Key Features:**
- Standard Dockerfile template with common development tools
- Permissive firewall (no network restrictions)
- Full service selection (databases, caches, message queues)
- Official base images only
- 4-6 configuration questions for streamlined setup

## When to Use This Skill

**Use Intermediate Mode When:**
- User wants a standard sandbox with common service options
- User is comfortable with basic Docker concepts
- User needs database or cache services
- User wants convenience over security restrictions
- User is setting up a development environment (not production-like)
- User wants quick setup with some customization options

**Do NOT Use Intermediate Mode When:**
- User wants minimal setup with no Dockerfile → Use `sandbox-setup-basic` instead
- User needs custom firewall rules or specific network restrictions → Use `sandbox-setup-advanced` instead
- User wants complete control over all configuration → Use `sandbox-setup-yolo` instead
- User needs production-grade security → Use `sandbox-setup-advanced` with restricted firewall

## Key Characteristics

### Base Images
- **Source**: Official Docker images only (validated against `official-images.json`)
- **Examples**: `python:3.11`, `node:20`, `golang:1.21`
- **Validation**: All images must be from official Docker repositories

### Dockerfile
- **Template**: Standard language-specific templates from `templates/dockerfiles/Dockerfile.<language>`
- **Contents**:
  - Base image from official sources
  - Common development tools (git, curl, wget, vim, etc.)
  - Language-specific package managers
  - User setup with proper permissions
  - Health check configuration
- **Customization**: Limited to package additions

### Firewall Configuration
- **Mode**: PERMISSIVE (always)
- **Script**: `templates/firewall/intermediate-permissive.sh`
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
   - Location: `templates/dockerfiles/Dockerfile.<language>`
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
   - Source: `templates/firewall/intermediate-permissive.sh`
   - Copy as-is (no modifications needed)
   - Set permissions: `chmod +x .devcontainer/init-firewall.sh`

4. **Generate devcontainer.json**
   - Base template: `templates/base/devcontainer.json.template`
   - Key settings:
     ```json
     {
       "name": "[PROJECT_NAME]",
       "dockerComposeFile": "docker-compose.yml",
       "service": "app",
       "workspaceFolder": "/workspace",
       "customizations": {
         "vscode": {
           "settings": {
             "terminal.integrated.defaultProfile.linux": "bash"
           },
           "extensions": [
             // Language-specific extensions
           ]
         }
       },
       "features": {},
       "postCreateCommand": "bash .devcontainer/init-firewall.sh",
       "remoteEnv": {
         "FIREWALL_MODE": "permissive"
       }
     }
     ```

5. **Create docker-compose.yml**
   - Base structure from `templates/base/docker-compose.base.yml`
   - Add `app` service with Dockerfile build
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
           - ..:/workspace:cached
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
→ Use Advanced Mode: sandbox-setup-advanced

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
**Location**: `templates/dockerfiles/Dockerfile.<language>`

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
**Location**: `templates/firewall/intermediate-permissive.sh`

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

---

**Last Updated:** 2025-12-16
**Version:** 2.2.0
