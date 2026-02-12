# Sandboxxer Plugin

![Plugin version 4.13.4](https://img.shields.io/badge/version-4.13.4-blue)
![Claude Code official plugin](https://img.shields.io/badge/claude--code-plugin-purple)
![MIT License](https://img.shields.io/badge/license-MIT-green)
![Supported platforms: Linux, macOS, Windows WSL2](https://img.shields.io/badge/platform-Linux%20%7C%20macOS%20%7C%20Windows%20WSL2-lightgrey)

> **Repository:** [andrewcchoi/sandbox-maxxing](https://github.com/andrewcchoi/sandbox-maxxing)
> **Plugin Name:** sandboxxer (used in commands: /sandboxxer:quickstart, /sandboxxer:yolo-docker-maxxing)

Interactive assistant for creating VS Code DevContainer configurations with Docker Compose support. Choose between interactive setup with project type selection and firewall customization, or quick one-command setup with defaults.

## What is Sandboxing?

**New to sandboxing?** A sandbox is a secure, isolated environment where code runs safely without accessing your personal files, passwords, or system settings. Think of it like a protective bubble - code can run inside, but can't escape to harm your computer.

**Visual guides for beginners:**
- 🔒 [Docker Sandbox Explained](docs/diagrams/svg/sandbox-explained.svg) - Simple visual showing what sandboxes can and cannot do
- 🛡️ [Bubblewrap Explained](docs/diagrams/svg/bubblewrap-explained.svg) - Comparison: Docker (maximum security) vs Bubblewrap (lightweight)

This plugin helps you set up sandboxed development environments using either Docker containers (full isolation with firewall) or bubblewrap (lightweight native Linux sandboxing).

## Important: Experimental Status

> **This plugin is experimental and provided as-is.** Most features have received minimal to no testing. Generated configurations may not work correctly on the first try and may require several iterations to get working.
>
> **Testing levels:**
> - `/sandboxxer:yolo-docker-maxxing` - **Moderate testing** (most reliable)
> - `/sandboxxer:quickstart` - **Very minimal testing**
> - Firewall features - **No testing** (highly experimental)
> - Azure deployment - **No testing** (highly experimental)
> - Agents and skills - **Not tested**
>
> If you encounter issues, expect to iterate on the generated configuration files.

## Features

- **🚀 Two-Path Setup System** - Interactive quickstart with project type selection, or non-interactive YOLO docker maxxing for instant defaults (Python+Node, container isolation)
- **🐧 Native Linux Support** - Run Claude Code directly on Linux/WSL2 without Docker overhead
- **☁️ Azure Cloud Deployment** - Deploy DevContainers to Azure Container Apps for cloud-based development environments
- **📊 Data-Driven Templates** - Configurations generated from curated registries of official Docker images and allowable domains
- **🔧 Troubleshooting Assistant** - Diagnose and fix common sandbox issues automatically
- **🔒 Security Auditor** - Review and harden sandbox configurations against best practices
- **🛡️ Smart Firewall Management** - Optional domain allowlist with 30-100+ curated domains
- **🎯 Intelligent Detection** - Auto-detects project type and suggests appropriate setup

![Plugin architecture diagram showing commands, skills, agents, and data templates organized in a component hierarchy](docs/diagrams/svg/plugin-architecture.svg)
*Plugin component overview - see [docs/diagrams/](docs/diagrams/) for detailed diagrams*

## Table of Contents

- [What is Sandboxing?](#what-is-sandboxing)
- [Important: Experimental Status](#important-experimental-status)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Setup Options](#setup-options)
- [Slash Commands](#slash-commands)
- [Auto-Detection](#auto-detection)
- [Security Features](#security-features)
- [Troubleshooting Features](#troubleshooting-features)
- [Cloud Deployment](#cloud-deployment)
- [Files Generated](#files-generated)
- [Configuration Placeholders](#configuration-placeholders)
- [Command Reference](#command-reference)
- [Reference Documentation](#reference-documentation)
- [Development](#development)
- [Example Applications](#example-applications)
- [Contributing](#contributing)
- [Changelog](#changelog)

## Prerequisites

Before using this plugin, ensure you have:

- **Anthropic Account** with Claude Code access (Pro/Team subscription or API key)
- **Docker Desktop** (v4.0+) or Docker Engine with Compose v2
- **VS Code** with Dev Containers extension (`ms-vscode-remote.remote-containers`)
- **Claude Code CLI** installed ([installation guide](https://claude.ai/code))
- **Git** for version control

**Platform-specific:**
- **Windows:** WSL 2 required; clone repos to WSL filesystem (`~/projects/`)
- **macOS/Linux:** Native Docker support

## Quick Start

### Installation

```bash
# Install the plugin
claude plugins add https://github.com/andrewcchoi/sandbox-maxxing

# Verify installation
claude plugins list
```

### Basic Usage

```bash
# Interactive quickstart - choose project type and firewall options
/sandboxxer:quickstart

# YOLO docker-maxxing - no questions, instant DevContainer (Python+Node, no firewall)
/sandboxxer:yolo-docker-maxxing

# Native Linux setup (no Docker)
/sandboxxer:yolo-linux-maxxing

# Troubleshoot existing DevContainer
/sandboxxer:troubleshoot

# Linux-specific troubleshooting
/sandboxxer:linux-troubleshoot

# Security audit
/sandboxxer:audit

# Deploy to Azure
/sandboxxer:deploy-to-azure
```

**Note:** v4.3.0 introduces project-type selection and interactive firewall customization. Use `/sandboxxer:yolo-docker-maxxing` (non-interactive YOLO docker maxxing) for the fastest path with sensible defaults.

### Claude Code Installation

> **Important:** Claude Code must be installed each time the devcontainer is rebuilt.

After opening the devcontainer:

```bash
# Install Claude Code CLI
curl -fsSL https://claude.ai/install.sh | sh

# Verify installation
claude --version
```

**Offline/Air-gapped Environments:**

If the installation script cannot be downloaded or the Anthropic servers are unreachable, pre-download the installation script on a connected machine and include it in your project or mount it as a volume.

See [TROUBLESHOOTING.md](docs/features/TROUBLESHOOTING.md#claude-code-installation) for details.

> **Windows Users:** For best performance, use WSL 2 with Docker Desktop and clone the repository to the WSL filesystem (`~/projects/`) rather than `/mnt/c/`. If you encounter line ending issues with shell scripts, the repository includes a `.gitattributes` file that enforces LF endings. For corporate environments with SSL/proxy, see [TROUBLESHOOTING.md](docs/features/TROUBLESHOOTING.md#corporate-proxy--ssl-certificate-issues). For detailed Windows setup, see [Windows Guide](docs/windows/README.md).

> **Security Note:** Generated configurations include default development passwords (e.g., `POSTGRES_PASSWORD: devpassword`). Change all passwords before deploying to production or when working with sensitive data.

## Setup Options

The plugin offers three setup paths:

> **Testing Status:** `/yolo-docker-maxxing` has moderate testing and is the most reliable option. `/quickstart` has very minimal testing - generated configurations may need manual adjustments.

1. **Interactive Quickstart** (`/sandboxxer:quickstart`) - Guided configuration with project type and firewall customization
2. **Non-Interactive YOLO Docker Maxxing** (`/sandboxxer:yolo-docker-maxxing`) - Instant defaults with no questions (Python+Node, container isolation)
3. **Native Linux/WSL2** (`/sandboxxer:yolo-linux-maxxing`) - No Docker required, faster startup with bubblewrap sandboxing

**New to sandboxing?** Visual guides:
- [Docker sandbox explained](docs/diagrams/svg/sandbox-explained.svg) - What is a sandbox and how does it protect you?
- [Bubblewrap explained](docs/diagrams/svg/bubblewrap-explained.svg) - Docker vs bubblewrap comparison

See [SETUP-OPTIONS.md](docs/features/SETUP-OPTIONS.md) for comprehensive guide.

### Interactive Quickstart

**Best for**: Projects needing specific languages or network restrictions

> **Testing:** Very minimal. Configuration files may require iteration to work correctly.

**Key Features**:
- Choose from 9 project types (Python/Node, Go, Ruby, Rust, C++ Clang, C++ GCC, PHP, PostgreSQL, Azure CLI)
- Optional firewall with domain allowlist
- Customizable security settings
- 2-3 questions for configuration
- Ready in 2-3 minutes

**Example**:
```
You: /sandboxxer:quickstart
Claude: What type of project are you setting up?
        • Python/Node (base only)
        • Go (adds Go toolchain)
        • Ruby (adds Ruby, bundler)
        • Rust (adds Cargo, rustfmt)
        • PHP (adds PHP, Composer)

You: Python/Node

Claude: Do you need network restrictions?
        • No - Container isolation only (fastest)
        • Yes - Domain allowlist (more secure)

You: Yes

Claude: Which domain categories should be allowed?
        [x] Package managers (npm, PyPI)
        [x] Version control (GitHub, GitLab)
        [ ] Cloud platforms (AWS, GCP, Azure)

        Generating configs... Done!
```

### Non-Interactive YOLO Docker Maxxing

**Best for**: Rapid prototyping, Python/Node projects, trusted code

**Key Features**:
- Zero questions asked
- Python 3.12 + Node 20 base
- Container isolation (no network firewall)
- PostgreSQL + Redis services
- Essential VS Code extensions
- Ready in < 1 minute

**Example**:
```
You: /sandboxxer:yolo-docker-maxxing

Claude: Creating DevContainer with defaults...
        - Base: Python 3.12 + Node 20
        - Firewall: Disabled (container isolation)
        - Services: PostgreSQL 16 + Redis 7
        ✓ Done in 18 seconds

        Next: Open in VS Code → 'Reopen in Container'
```

## Slash Commands

| Command                           | Description                                                       |
| --------------------------------- | ----------------------------------------------------------------- |
| `/sandboxxer:quickstart`          | Interactive quickstart - choose project type and firewall options |
| `/sandboxxer:yolo-docker-maxxing`   | YOLO docker-maxxing - no questions, sensible defaults (Python+Node) |
| `/sandboxxer:yolo-linux-maxxing`  | Native Linux/WSL2 setup (no Docker required)                      |
| `/sandboxxer:deploy-to-azure`     | Deploy DevContainer to Azure Container Apps for cloud development |
| `/sandboxxer:troubleshoot`        | Diagnose and fix sandbox issues                                   |
| `/sandboxxer:linux-troubleshoot`  | Diagnose and fix native Linux/WSL2 Claude Code setup issues       |
| `/sandboxxer:audit`               | Security audit and recommendations                                |
| `/sandboxxer:health`              | Comprehensive diagnostics and health checks                       |

**v4.6.0:** Added Azure deployment support for cloud-based development environments.
**v4.3.0:** Setup now offers interactive project-type selection or instant defaults with no questions.

![Quickstart workflow flowchart illustrating the interactive setup path with project type selection, network restrictions decision, and optional firewall configuration steps](docs/diagrams/svg/quickstart-flow.svg)

*Interactive quickstart workflow showing project type selection, network restrictions decision, and optional firewall configuration.*

## Auto-Detection

The plugin automatically activates when you:
- Mention "devcontainer", "docker sandbox", or "Claude Code sandbox"
- Ask about setting up isolated development environments
- Need help with Docker Compose configurations
- Want to configure firewalls for development

**Example**:
```
You: I need to set up a Docker development environment for my Python project
Claude: [Automatically uses /sandboxxer:quickstart command]
      What type of project are you setting up?
      • Python/Node (base only)
      • Go (adds Go toolchain)
      • Ruby (adds Ruby, bundler)
      ...
```

## Security Features

**New to sandboxing?** See the [beginner-friendly Docker sandbox explanation](docs/diagrams/svg/sandbox-explained.svg) for a simple visual guide showing how sandboxes protect your computer.

> **Testing:** Firewall features have received **no testing**. The `init-firewall.sh` script and domain allowlist configuration are highly experimental. Generated configurations may not correctly block/allow traffic and will likely require manual adjustment and iteration.

### Firewall Options

**Domain Allowlist** (Recommended):
- Default policy: DROP all outbound traffic
- Only whitelisted domains allowed
- Prevents accidental data leakage
- Protects against malicious dependencies

**Container Isolation**:
- No additional network firewall
- Relies on Docker container isolation
- Convenient for development
- Use only on trusted networks

### Security Audit Checks

The security auditor checks:
- ✅ Firewall configuration and allowed domains
- ✅ Default passwords in configs
- ✅ Exposed ports and services
- ✅ Container permissions (non-root user)
- ✅ Secrets management
- ✅ Network isolation
- ✅ Dependency vulnerabilities

## Troubleshooting Features

> **Testing:** Not tested. Diagnostic commands and suggestions may need verification.

### Automatic Issue Detection

The troubleshooter handles:
- Container startup failures
- Network connectivity issues
- Service connectivity (PostgreSQL, Redis, MongoDB)
- Firewall blocking legitimate traffic
- Permission errors
- VS Code DevContainer problems
- Claude Code CLI issues

### Example Troubleshooting Session

```
You: /sandboxxer:troubleshoot
Claude: What issue are you experiencing?
You: Can't connect to PostgreSQL
Claude: Let me diagnose...
      [Runs: docker compose ps, docker compose logs postgres]

      I found the issue: You're using 'localhost' in your connection string.

      ❌ DATABASE_URL=postgresql://user:pass@localhost:5432/db
      ✅ DATABASE_URL=postgresql://user:pass@postgres:5432/db

      In Docker networks, use the service name (postgres) not localhost.

      Would you like me to update your .env file?
```

## Cloud Deployment

### Deploy to Azure

Deploy your DevContainer to Azure Container Apps for cloud-based development:

> **Testing:** Azure deployment has received **no testing**. Generated Bicep templates, azure.yaml, and deployment scripts are highly experimental. Configurations may fail to deploy or create incorrect resources. Expect multiple iterations and manual debugging.

```bash
# Deploy to Azure
/sandboxxer:deploy-to-azure
```

**Use cases:**
- **Cloud Dev Environments** - Access from anywhere (like GitHub Codespaces)
- **CI/CD Runners** - Use exact DevContainer config for builds
- **Team Environments** - Shared, consistent dev environments
- **Remote Development** - VS Code Remote to cloud containers

**Features:**
- Azure Developer CLI (`azd`) integration
- Infrastructure-as-Code with Bicep
- Auto-scaling Container Apps
- Optional Azure Container Registry
- Service Principal support for CI/CD
- Complete monitoring with Log Analytics

**Documentation:** See [docs/features/AZURE-DEPLOYMENT.md](docs/features/AZURE-DEPLOYMENT.md) for:
- Prerequisites and setup
- Step-by-step wizard walkthrough
- Configuration options
- Post-deployment management
- CI/CD integration
- Troubleshooting
- Cost estimation

## Files Generated

Both setup commands create:
- `.devcontainer/devcontainer.json` - VS Code DevContainer config
- `.devcontainer/Dockerfile` - Container image with language tools
- `.devcontainer/init-firewall.sh` - Firewall configuration (if enabled)
- `.devcontainer/setup-claude-credentials.sh` - Credential persistence script
- `docker-compose.yml` - Services configuration (PostgreSQL, Redis)

Azure deployment additionally creates:
- `azure.yaml` - Azure Developer CLI manifest
- `infra/main.bicep` - Infrastructure-as-Code templates
- `infra/modules/` - Azure resource modules

## Configuration Placeholders

Templates use these placeholders:
- `{{PROJECT_NAME}}` - Your project name
- `{{NETWORK_NAME}}` - Docker network name
- `{{DATABASE_USER}}` - Database username
- `{{DATABASE_NAME}}` - Database name
- `{{FIREWALL_MODE}}` - strict or permissive
- `{{BASE_IMAGE}}` - Docker base image

## Command Reference

For detailed command documentation including workflows, triggers, and examples, see **[commands/README.md](commands/README.md)**.

**Quick Reference:**

| Command | Testing Status | Best For |
|---------|---------------|----------|
| `/sandboxxer:quickstart` | Very minimal | Projects needing specific languages or firewall |
| `/sandboxxer:yolo-docker-maxxing` | Moderate ✅ | Rapid prototyping, trusted code |
| `/sandboxxer:yolo-linux-maxxing` | No testing | Native Linux without Docker |
| `/sandboxxer:troubleshoot` | No testing | Diagnosing sandbox issues |
| `/sandboxxer:linux-troubleshoot` | No testing | WSL2/Linux-specific issues |
| `/sandboxxer:audit` | No testing | Security audits |
| `/sandboxxer:deploy-to-azure` | No testing | Cloud deployment |
| `/sandboxxer:health` | Moderate | Diagnostics and health checks |

## Reference Documentation

The plugin includes comprehensive documentation in the `docs/` directory:

### Feature Documentation (`docs/features/`)
- [AZURE-DEPLOYMENT.md](docs/features/AZURE-DEPLOYMENT.md) - Azure Container Apps deployment guide
- [CUSTOMIZATION.md](docs/features/CUSTOMIZATION.md) - Template and configuration customization
- [EXTENSIONS.md](docs/features/EXTENSIONS.md) - VS Code extensions configuration
- [MCP.md](docs/features/MCP.md) - Model Context Protocol server integration
- [NPM_PLATFORM_FIX.md](docs/features/NPM_PLATFORM_FIX.md) - npm platform compatibility fixes
- [OLLAMA_INTEGRATION.md](docs/features/OLLAMA_INTEGRATION.md) - Local AI with Ollama setup
- [SECRETS.md](docs/features/SECRETS.md) - Secrets management and security
- [SECURITY-MODEL.md](docs/features/SECURITY-MODEL.md) - Security architecture and best practices
- [SETTINGS.md](docs/features/SETTINGS.md) - Plugin configuration and per-project settings
- [SETUP-OPTIONS.md](docs/features/SETUP-OPTIONS.md) - Interactive vs non-interactive setup guide
- [KROKI_INTEGRATION.md](docs/features/KROKI_INTEGRATION.md) - Self-hosted diagram rendering
- [TROUBLESHOOTING.md](docs/features/TROUBLESHOOTING.md) - Common issues and solutions
- [VARIABLES.md](docs/features/VARIABLES.md) - Template variables reference

### Additional Documentation
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) - Plugin architecture overview
- [docs/CODESPACES.md](docs/CODESPACES.md) - GitHub Codespaces integration
- [docs/TESTING.md](docs/TESTING.md) - Testing guide for examples
- [docs/TEST-COVERAGE-REPORT.md](docs/TEST-COVERAGE-REPORT.md) - Test coverage analysis report
- [docs/windows/README.md](docs/windows/README.md) - Windows-specific setup guide

### Internal Development Documentation
- [docs/code-review/](docs/code-review/) - Code review process and prompt improvements

## Development

```bash
# Clone and install locally
git clone https://github.com/andrewcchoi/sandbox-maxxing
cd sandbox-maxxing
claude plugins add .
```

![Plugin Architecture](docs/diagrams/svg/plugin-architecture.svg)

For complete development guide, plugin structure, git worktrees support, and naming conventions, see **[DEVELOPMENT.md](DEVELOPMENT.md)**.

## Examples

### Example 1: Interactive Quickstart Python Setup

```
You: /sandboxxer:quickstart
Claude: I detected a Python FastAPI project. Setting up with:
        - Base: docker/sandbox-templates:claude-code
        - Database: PostgreSQL 16
        - Cache: Redis 7
        - Firewall: Strict (40 essential domains)

        Generating configurations...
        ✅ Created .devcontainer/devcontainer.json
        ✅ Created .devcontainer/Dockerfile  
        ✅ Created .devcontainer/init-firewall.sh
        ✅ Created docker-compose.yml

        Next steps:
        1. docker compose up -d
        2. Open in VS Code
        3. Reopen in Container
```

### Example 2: Node.js with Customization

```
Claude: Node.js version?
        • 22 (latest) • 20 (LTS, recommended) • 18 (maintenance)
You: 20
Claude: What database do you need?
You: MongoDB
Claude: MongoDB version? [7]
You: 7
Claude: Need Redis cache? [Y/n]
You: Yes
Claude: Do you need network restrictions?
        • No - Container isolation only
        • Yes - Domain allowlist (choose categories)
You: Expanded
Claude: Generating configuration for Node.js 20 + MongoDB 7 + Redis...
```

### Example 3: Security Audit

```
You: /sandboxxer:audit
Claude: Running security audit...

        # Security Audit Report

        ## Summary
        - Overall Risk Level: Medium
        - Warnings: 2

        ## Warnings ⚠
        1. Default password in docker-compose.yml
           - Found: POSTGRES_PASSWORD: devpassword
           - Recommendation: Change for production use

        2. Firewall disabled (container isolation only)
           - Current: FIREWALL_MODE=disabled
           - Recommendation: Enable domain allowlist for production

        ## Good Practices ✅
        1. Running as non-root user (node)
        2. No hardcoded secrets in configs
        3. Minimal Linux capabilities

        Would you like me to help fix these issues?
```

## Example Applications

The plugin includes working examples in `docs/examples/`:

| Example | Configuration | Best For |
|---------|--------------|----------|
| `streamlit-sandbox-basic/` | Minimal | 30-second environment validation |
| `demo-app-sandbox-basic/` | Minimal | Quick start, prototypes |
| `demo-app-sandbox-advanced/` | Domain allowlist | Team development |
| `demo-app-sandbox-yolo/` | Full | Production projects |

**Quick Start:**
```bash
cd docs/examples/streamlit-sandbox-basic
code .  # Open in VS Code → Reopen in Container
streamlit run app.py
```

For detailed examples, learning paths, and customization guides, see **[docs/examples/README.md](docs/examples/README.md)**.

## Contributing

**Note**: I am not actively accepting pull requests or feature requests for this project. However, you are more than welcome to fork this repository and make your own improvements! Feel free to adapt it to your needs.

This project was created with [Claude](https://claude.ai) using the [Superpowers](https://github.com/obra/superpowers) plugin.

## License

MIT License - See LICENSE file for details

## Support

- **Issues**: https://github.com/andrewcchoi/sandbox-maxxing/issues
- **Documentation**: See `docs/features/` directory
- **Claude Code Docs**: https://claude.ai/code

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for complete version history.

**Upgrading?** See [MIGRATION.md](MIGRATION.md) for breaking changes and migration guides between major versions.

