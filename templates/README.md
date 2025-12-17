# Template System

This directory contains template files used by the sandbox setup skills to generate DevContainer configurations. Templates are organized by purpose and support four sandbox modes: Basic, Intermediate, Advanced, and YOLO.

## Table of Contents

1. [Overview](#overview)
2. [Directory Structure](#directory-structure)
3. [Template Types](#template-types)
4. [Master Templates](#master-templates)
5. [Mode-Specific Templates](#mode-specific-templates)
6. [Template Usage](#template-usage)
7. [Customization](#customization)
8. [Legacy Templates](#legacy-templates)
9. [Templates vs Examples](#templates-vs-examples)
10. [Corporate Proxy Support](#corporate-proxy-support)
11. [Related Documentation](#related-documentation)

## Overview

The template system uses a hierarchical approach:

1. **Master Templates** - Comprehensive templates with ALL possible configurations
2. **Mode-Specific Templates** - Pre-configured templates for each sandbox mode
3. **Language-Specific Templates** - Dockerfiles for specific languages/runtimes
4. **Component Templates** - Modular pieces (firewall, compose, extensions, MCP, etc.)

Templates use placeholder substitution to generate final configuration files:

```
{{PROJECT_NAME}} → myapp
{{FIREWALL_MODE}} → strict
{{BASE_IMAGE}} → python:3.12-bookworm-slim
```

## Directory Structure

```
templates/
├── README.md                          # This file
├── master/                            # Master templates (all features)
│   ├── devcontainer.json.master      # Comprehensive devcontainer config
│   ├── Dockerfile.master             # Comprehensive Dockerfile
│   ├── docker-compose.master.yml     # Comprehensive compose config
│   ├── init-firewall.master.sh       # Comprehensive firewall script
│   ├── README.md                     # Master templates documentation
│   └── VALIDATION.txt                # Validation rules
├── dockerfiles/                       # Language-specific Dockerfiles
│   ├── Dockerfile.python
│   ├── Dockerfile.node
│   ├── Dockerfile.go
│   ├── Dockerfile.rust
│   ├── Dockerfile.java
│   ├── Dockerfile.ruby
│   ├── Dockerfile.php
│   ├── Dockerfile.cpp-gcc
│   ├── Dockerfile.cpp-clang
│   ├── Dockerfile.postgres
│   └── Dockerfile.redis
├── firewall/                          # Firewall scripts by mode
│   ├── basic-no-firewall.sh          # Basic: No firewall
│   ├── intermediate-permissive.sh    # Intermediate: Permissive
│   ├── advanced-strict.sh            # Advanced: Strict whitelist
│   └── yolo-configurable.sh          # YOLO: User-configurable
├── compose/                           # Docker Compose templates by mode
│   ├── docker-compose.basic.yml
│   ├── docker-compose.intermediate.yml
│   ├── docker-compose.advanced.yml
│   └── docker-compose.yolo.yml
├── extensions/                        # VS Code extensions by mode
│   ├── extensions.basic.json
│   ├── extensions.intermediate.json
│   ├── extensions.advanced.json
│   └── extensions.yolo.json
├── mcp/                              # MCP server configs by mode
│   ├── mcp.basic.json
│   ├── mcp.intermediate.json
│   ├── mcp.advanced.json
│   └── mcp.yolo.json
├── variables/                         # Variable configs by mode
│   ├── variables.basic.json
│   ├── variables.intermediate.json
│   ├── variables.advanced.json
│   └── variables.yolo.json
├── env/                              # Environment variable templates
│   └── [env templates]
└── legacy/                           # Legacy v1.x templates (deprecated)
    ├── base/
    ├── fullstack/
    ├── node/
    └── python/
```

## Template Types

### 1. Master Templates (`master/`)

Comprehensive templates containing ALL possible configurations. Used as source for generating mode-specific templates.

**Key Files:**
- `devcontainer.json.master` - All devcontainer options
- `Dockerfile.master` - All language toolchains and packages
- `docker-compose.master.yml` - All service configurations
- `init-firewall.master.sh` - All firewall modes and domain categories

**Features:**
- 37 sections in devcontainer.json (build, extensions, settings, ports, etc.)
- 14 sections in Dockerfile (Python, Go, Rust, Java, Ruby, PHP, etc.)
- 200+ domain categories in firewall script
- All VS Code extensions (35+)
- All MCP servers (11+)

See [master/README.md](master/README.md) for detailed documentation.

### 2. Language-Specific Dockerfiles (`dockerfiles/`)

Pre-configured Dockerfiles for specific programming languages and runtimes.

| File | Language/Runtime | Base Image | Use Case |
|------|-----------------|------------|----------|
| `Dockerfile.python` | Python 3.12 | python:3.12-bookworm-slim | Python development |
| `Dockerfile.node` | Node.js 20 | node:20-bookworm-slim | JavaScript/TypeScript |
| `Dockerfile.go` | Go 1.21 | golang:1.21-bookworm | Go development |
| `Dockerfile.rust` | Rust | rust:1.75-bookworm | Rust development |
| `Dockerfile.java` | Java 21 | eclipse-temurin:21-jdk | Java development |
| `Dockerfile.ruby` | Ruby 3.3 | ruby:3.3-bookworm | Ruby development |
| `Dockerfile.php` | PHP 8.3 | php:8.3-cli-bookworm | PHP development |
| `Dockerfile.cpp-gcc` | C++ (GCC) | gcc:13-bookworm | C++ with GCC |
| `Dockerfile.cpp-clang` | C++ (Clang) | silkeh/clang:17-bookworm | C++ with Clang |
| `Dockerfile.postgres` | PostgreSQL client | postgres:16-bookworm | Database work |
| `Dockerfile.redis` | Redis client | redis:7-bookworm | Cache work |

**Common Features:**
- Non-root user (node, UID 1000)
- Essential tools (git, vim, curl, etc.)
- Language-specific package managers
- Claude Code CLI installed
- Workspace at `/workspace`

### 3. Firewall Templates (`firewall/`)

Mode-specific firewall initialization scripts implementing different security policies.

#### basic-no-firewall.sh
- **Mode:** Basic
- **Policy:** No firewall (container isolation only)
- **Rules:** None
- **Use Case:** Trusted development, maximum convenience

```bash
# Clear any rules, set default ACCEPT
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
```

#### intermediate-permissive.sh
- **Mode:** Intermediate
- **Policy:** Permissive (allow all)
- **Rules:** Clear existing rules
- **Use Case:** Standard development, no network restrictions

```bash
# Clear rules, permissive policies
iptables -F && iptables -P INPUT ACCEPT
```

#### advanced-strict.sh
- **Mode:** Advanced
- **Policy:** Strict whitelist (deny by default)
- **Allowed Domains:** ~40 essential development domains
- **Categories:** Anthropic, GitHub, Docker Hub, npm, PyPI, Ubuntu
- **Use Case:** Security-conscious development

```bash
# Default DROP, whitelist-based
iptables -P OUTPUT DROP
# Allow only domains in allowed-domains ipset
```

#### yolo-configurable.sh
- **Mode:** YOLO
- **Policy:** User-configurable (disabled/permissive/strict)
- **Allowed Domains:** 200+ domains across 20+ categories
- **Configuration:** FIREWALL_MODE environment variable
- **Use Case:** Expert customization

```bash
# Supports three firewall modes:
# - disabled: No firewall
# - permissive: Allow all
# - strict: Whitelist-based (comprehensive categories)
```

See [Security Model](../docs/security-model.md) for detailed firewall documentation.

### 4. Docker Compose Templates (`compose/`)

Mode-specific service configurations for PostgreSQL, Redis, RabbitMQ, etc.

#### docker-compose.basic.yml
- **Services:** PostgreSQL, Redis
- **Configuration:** Minimal, development defaults
- **Networks:** Simple bridge network
- **Volumes:** Basic persistence

#### docker-compose.intermediate.yml
- **Services:** PostgreSQL, Redis, RabbitMQ
- **Configuration:** Standard with healthchecks
- **Networks:** Named network
- **Volumes:** Named volumes with persistence

#### docker-compose.advanced.yml
- **Services:** PostgreSQL, Redis, RabbitMQ, optional MongoDB
- **Configuration:** Production-like with security
- **Networks:** Isolated network
- **Volumes:** Named volumes with backup considerations
- **Secrets:** Docker secrets support

#### docker-compose.yolo.yml
- **Services:** User choice (all options available)
- **Configuration:** Fully customizable
- **Networks:** Custom configuration
- **Volumes:** User-defined
- **Advanced:** Support for all Docker Compose features

### 5. Extension Templates (`extensions/`)

VS Code extension lists for each sandbox mode.

| Mode | Extensions | Categories |
|------|-----------|------------|
| Basic | 6-8 | Essential only (Python, ESLint, Prettier) |
| Intermediate | 15-20 | Common languages + productivity |
| Advanced | 22-28 | Comprehensive + themes + tools |
| YOLO | 35+ | All categories including fun extensions |

**Extension Categories:**
- **Essential:** GitLens, EditorConfig, Markdown
- **Language:** Python, JavaScript, Go, Rust, Java, Ruby, PHP, C++
- **Themes:** GitHub, Dracula, Monokai, etc.
- **Productivity:** TODO Tree, Error Lens, Code Spell Checker
- **Fun:** Power Mode, Rainbow Brackets, Pets

See [Extensions Reference](../docs/EXTENSIONS.md) for full lists.

### 6. MCP Server Templates (`mcp/`)

MCP (Model Context Protocol) server configurations for each mode.

| Mode | Servers | Examples |
|------|---------|----------|
| Basic | 2 | filesystem, memory |
| Intermediate | 5 | +sqlite, fetch, github |
| Advanced | 8 | +postgres, docker, brave-search |
| YOLO | 11+ | +puppeteer, slack, google-drive, custom |

**Common MCP Servers:**
- **filesystem** - File system access
- **memory** - Conversation memory
- **sqlite** - SQLite database operations
- **fetch** - HTTP requests
- **github** - GitHub API integration
- **postgres** - PostgreSQL operations
- **docker** - Docker container management
- **brave-search** - Web search
- **puppeteer** - Browser automation
- **slack** - Slack integration
- **google-drive** - Google Drive access

See [MCP Configuration Guide](../docs/MCP.md) for details.

### 7. Variable Templates (`variables/`)

Environment variable and build argument configurations for each mode.

**Structure:**
```json
{
  "buildArgs": {
    "BASE_IMAGE": "python:3.12-slim",
    "TIMEZONE": "UTC",
    "PYTHON_VERSION": "3.12"
  },
  "containerEnv": {
    "NODE_ENV": "development",
    "PYTHONUNBUFFERED": "1"
  }
}
```

| Mode | Build Args | Container Env | Use Case |
|------|-----------|---------------|----------|
| Basic | 5 | 6 | Minimal configuration |
| Intermediate | 8 | 12 | Standard development |
| Advanced | 12+ | 20+ | Comprehensive configuration |
| YOLO | Custom | Custom | User-defined |

See [Variables Guide](../docs/VARIABLES.md) for detailed documentation.

## Master Templates

Master templates are comprehensive "kitchen sink" templates containing ALL possible configurations. Generator scripts strip unnecessary sections to create mode-specific templates.

### devcontainer.json.master

**37 Configuration Sections:**
```
[build] [base_image] [image] [ptrace] [lifecycle]
[extensions_git] [extensions_javascript] [extensions_python]
[extensions_go] [extensions_rust] [extensions_cpp] [extensions_java]
[extensions_ruby] [extensions_php] [extensions_docker] [extensions_yaml]
[settings_editor] [settings_git] [settings_javascript] [settings_python]
[settings_go] [settings_rust] [settings_cpp] [settings_java]
[features] [ports] [ports_backend] [ports_frontend] [ports_database]
[ports_cache] [ports_other] [ports_attributes_backend]
[ports_attributes_frontend] [ports_attributes_database]
[env_node] [env_python] [env_go] [env_rust] [env_docker]
```

**Usage:**
```python
# Generator strips unwanted sections
template = read_master("devcontainer.json.master")
filtered = strip_sections(template, keep=["build", "extensions_python", "env_python"])
output = substitute_placeholders(filtered, {"PROJECT_NAME": "myapp"})
```

### Dockerfile.master

**14 Package Sections:**
```
[packages_python] [packages_build] [packages_go] [packages_rust]
[packages_java] [packages_ruby] [packages_php] [packages_database]
[packages_docker] [npm_config] [claude_code] [python_packages]
[node_packages]
```

**Build Arguments:**
- `BASE_IMAGE` - Base Docker image
- `TIMEZONE` - Container timezone
- `PYTHON_VERSION` - Python version
- `NODE_VERSION` - Node.js version
- `GO_VERSION` - Go version

### docker-compose.master.yml

**Service Sections:**
```
[service_postgres] [service_redis] [service_rabbitmq] [service_mongodb]
[service_elasticsearch] [service_mailhog] [volume_postgres] [volume_redis]
[volume_rabbitmq] [volume_mongodb] [network]
```

### init-firewall.master.sh

**20+ Domain Categories:**
```
[anthropic_services] [version_control] [container_registries]
[cloud_platforms_google] [cloud_platforms_azure] [cloud_platforms_oracle]
[package_managers_npm] [package_managers_python] [package_managers_ruby]
[package_managers_rust] [package_managers_go] [package_managers_maven]
[package_managers_php] [package_managers_dotnet] [package_managers_dart]
[linux_distributions] [development_tools] [vscode] [analytics_telemetry]
[content_delivery] [schema_configuration] [project_specific]
```

See [master/README.md](master/README.md) for complete master template documentation.

## Mode-Specific Templates

Mode-specific templates are pre-configured for each sandbox mode's philosophy and use case.

### Basic Mode Templates

**Philosophy:** Simplicity and speed
**Features:** Minimal configuration, no firewall, essential services only
**Files Used:**
- `firewall/basic-no-firewall.sh`
- `compose/docker-compose.basic.yml`
- `extensions/extensions.basic.json`
- `mcp/mcp.basic.json`
- `variables/variables.basic.json`

### Intermediate Mode Templates

**Philosophy:** Balance of flexibility and convenience
**Features:** Standard Dockerfile, permissive firewall, common services
**Files Used:**
- `firewall/intermediate-permissive.sh`
- `compose/docker-compose.intermediate.yml`
- `extensions/extensions.intermediate.json`
- `mcp/mcp.intermediate.json`
- `variables/variables.intermediate.json`

### Advanced Mode Templates

**Philosophy:** Security and control
**Features:** Strict firewall, security-hardened, comprehensive configuration
**Files Used:**
- `firewall/advanced-strict.sh`
- `compose/docker-compose.advanced.yml`
- `extensions/extensions.advanced.json`
- `mcp/mcp.advanced.json`
- `variables/variables.advanced.json`

### YOLO Mode Templates

**Philosophy:** Complete control and flexibility
**Features:** User-configurable everything, all options available
**Files Used:**
- `firewall/yolo-configurable.sh`
- `compose/docker-compose.yolo.yml`
- `extensions/extensions.yolo.json`
- `mcp/mcp.yolo.json`
- `variables/variables.yolo.json`

## Template Usage

### How Skills Use Templates

Setup skills follow this workflow:

1. **Detect Project Type:** Language, framework, existing configuration
2. **Select Templates:** Choose appropriate templates for mode and language
3. **Gather Requirements:** Ask user questions for customization
4. **Generate Configuration:** Apply placeholders and strip unused sections
5. **Write Files:** Create `.devcontainer/` directory with generated files
6. **Verify:** Validate generated configuration

**Example Workflow (sandbox-setup-advanced):**

```python
# 1. Detect Python project
language = detect_language()  # → "python"

# 2. Select templates
dockerfile = "dockerfiles/Dockerfile.python"
firewall = "firewall/advanced-strict.sh"
compose = "compose/docker-compose.advanced.yml"
extensions = "extensions/extensions.advanced.json"

# 3. Gather requirements
project_name = ask_user("Project name?")
services = ask_user("Which services?")  # → ["postgres", "redis"]

# 4. Generate configuration
devcontainer = generate_from_master(
    "master/devcontainer.json.master",
    sections=["build", "extensions_python", "ports_backend"],
    placeholders={
        "PROJECT_NAME": project_name,
        "FIREWALL_MODE": "strict"
    }
)

# 5. Write files
write_file(".devcontainer/devcontainer.json", devcontainer)
write_file(".devcontainer/Dockerfile", dockerfile)
write_file(".devcontainer/init-firewall.sh", firewall)
write_file("docker-compose.yml", compose)

# 6. Verify
validate_configuration()
```

### Placeholder Substitution

Templates use `{{PLACEHOLDER}}` syntax for dynamic values:

**Common Placeholders:**
- `{{PROJECT_NAME}}` - Project/container name
- `{{BASE_IMAGE}}` - Docker base image
- `{{FIREWALL_MODE}}` - Firewall mode (strict/permissive/disabled)
- `{{NETWORK_NAME}}` - Docker network name
- `{{IMAGE_NAME}}` - Docker image name (for pre-built images)
- `{{POSTGRES_DB}}` - PostgreSQL database name
- `{{POSTGRES_USER}}` - PostgreSQL username
- `{{POSTGRES_PASSWORD}}` - PostgreSQL password
- `{{REDIS_PASSWORD}}` - Redis password
- `{{TIMEZONE}}` - Container timezone

**Example:**
```json
{
  "name": "{{PROJECT_NAME}}",
  "build": {
    "dockerfile": "Dockerfile",
    "args": {
      "BASE_IMAGE": "{{BASE_IMAGE}}"
    }
  }
}
```

After substitution:
```json
{
  "name": "myapp",
  "build": {
    "dockerfile": "Dockerfile",
    "args": {
      "BASE_IMAGE": "python:3.12-bookworm-slim"
    }
  }
}
```

## Customization

### Customizing Templates

Users can customize generated configurations after setup:

**1. Add VS Code Extensions:**
```json
// .devcontainer/devcontainer.json
{
  "customizations": {
    "vscode": {
      "extensions": [
        // ... existing extensions ...
        "usernamehw.errorlens",  // Add new extension
        "streetsidesoftware.code-spell-checker"
      ]
    }
  }
}
```

**2. Add Firewall Domains (Advanced/YOLO):**
```bash
# .devcontainer/init-firewall.sh
ALLOWED_DOMAINS=(
  # ... existing domains ...
  "api.myservice.com"
  "cdn.myservice.com"
)
```

**3. Add Services:**
```yaml
# docker-compose.yml
services:
  # ... existing services ...
  elasticsearch:
    image: elasticsearch:8.11
    ports:
      - "9200:9200"
```

**4. Configure Environment Variables:**
```json
// .devcontainer/devcontainer.json
{
  "containerEnv": {
    "NODE_ENV": "development",
    "DEBUG": "app:*",
    "MY_CUSTOM_VAR": "value"
  }
}
```

### Contributing Templates

To add new templates:

1. **Add to appropriate directory** (`dockerfiles/`, `firewall/`, etc.)
2. **Follow naming convention** (`Dockerfile.language`, `mode-description.sh`)
3. **Use placeholder syntax** (`{{PLACEHOLDER}}`)
4. **Document in this README** (add to relevant section)
5. **Update skills** if new template should be automatically used
6. **Test thoroughly** with example projects

See [Contributing Guide](../CONTRIBUTING.md) for details.

## Legacy Templates

The `legacy/` directory contains deprecated v1.x templates from the original three-tier system (Basic/Advanced/Pro). These are preserved for reference but should not be used in new projects.

**Legacy Structure:**
- `legacy/base/` - Base templates
- `legacy/fullstack/` - Full-stack app templates
- `legacy/node/` - Node.js templates
- `legacy/python/` - Python templates

**Migration:** Projects using legacy templates should migrate to the new mode-specific templates using `/sandbox:setup`.

## Templates vs Examples

### Relationship

- **Templates** (this directory): Source templates used to generate DevContainer configurations
- **Examples** (`../examples/`): Complete working projects generated from templates

When you run `/sandbox:setup`, the system:
1. Reads templates from this directory
2. Applies variable substitutions
3. Strips unused sections based on mode
4. Generates final files in your project (or example directory)

### Synchronization

All fixes and improvements are:
1. First applied to master templates
2. Then propagated to mode-specific templates
3. Finally applied to example projects

This ensures consistency across all deployment modes.

## Corporate Proxy Support

The template system includes built-in support for corporate proxy environments that intercept SSL certificates:

### Issue #29: Multi-Stage Node.js Build

**Problem:** Corporate proxies break NodeSource SSL verification when installing Node.js.

**Solution:** All language Dockerfiles use multi-stage builds to copy Node.js binaries from the official Docker image:

```dockerfile
# Stage 1: Get Node.js from official image
FROM node:20-slim AS node-source

# Stage 2: Your language base
FROM python:3.12-slim-bookworm

# Copy Node.js (avoids NodeSource SSL issues)
COPY --from=node-source /usr/local/bin/node /usr/local/bin/
COPY --from=node-source /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm && \
    ln -s /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx
```

### Issue #30: Claude Credentials Persistence

**Problem:** Claude credentials don't persist across container rebuilds.

**Solution:** Master templates include automatic credentials copying:

1. **Volume mount** in `docker-compose.master.yml`:
```yaml
app:
  volumes:
    - ~/.claude:/tmp/host-claude:ro  # Read-only mount from host
```

2. **Setup script** `setup-claude-credentials.master.sh`:
```bash
#!/bin/bash
# Copies credentials from host mount to container
cp /tmp/host-claude/.credentials.json ~/.claude/
```

3. **Automatic execution** in `devcontainer.json.master`:
```json
{
  "postCreateCommand": ".devcontainer/setup-claude-credentials.sh && echo 'Container ready'"
}
```

### Issue #32: npm Registry Access

**Problem:** Firewall blocks npm registry, preventing Claude Code installation and updates.

**Solution:** Firewall templates include npm registry in allowlist:

```bash
ALLOWED_DOMAINS=(
  # NPM package registry
  "registry.npmjs.org"
  "npmjs.org"
  "*.npmjs.org"
)
```

### Implementation Status

| Fix | Version | Master Templates | Language Dockerfiles | Examples |
|-----|---------|-----------------|---------------------|----------|
| #29 Multi-stage Node.js | 2.2.1 | ✅ | ✅ (11/11) | ✅ |
| #30 Credentials mount | 2.2.1 | ✅ | N/A | ✅ |
| #32 npm allowlist | 2.2.1 | ✅ | N/A | ✅ |

All fixes are included by default when using templates since version 2.2.1.

## Related Documentation

### Configuration Guides
- [Modes Guide](../docs/MODES.md) - Mode comparison and selection
- [Variables Guide](../docs/VARIABLES.md) - Environment variables and build args
- [Secrets Management](../docs/SECRETS.md) - Credential handling
- [MCP Configuration](../docs/MCP.md) - MCP server setup
- [Extensions Reference](../docs/EXTENSIONS.md) - VS Code extensions

### Security
- [Security Model](../docs/security-model.md) - Security architecture
- [Firewall Documentation](../docs/security-model.md#network-isolation--firewall-modes) - Firewall modes

### Skills and Commands
- [Skills README](../skills/README.md) - Setup skills that use templates
- [Commands README](../commands/README.md) - Commands that trigger setup

### Examples
- [Examples README](../examples/README.md) - Example projects
- [demo-app-sandbox-basic](../examples/demo-app-sandbox-basic/) - Basic mode result
- [demo-app-sandbox-advanced](../examples/demo-app-sandbox-advanced/) - Advanced mode result

---

**Last Updated:** 2025-12-16
**Version:** 2.2.1
