# Sandboxxer Plugin

![Version](https://img.shields.io/badge/version-4.6.0-blue)
![Claude Code](https://img.shields.io/badge/claude--code-plugin-purple)
![License](https://img.shields.io/badge/license-MIT-green)
![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS%20%7C%20Windows%20WSL2-lightgrey)

> **Repository:** [andrewcchoi/sandbox-maxxing](https://github.com/andrewcchoi/sandbox-maxxing)
> **Plugin Name:** sandboxxer (used in commands: /sandboxxer:quickstart, /sandboxxer:yolo-vibe-maxxing)

Interactive assistant for creating VS Code DevContainer configurations with Docker Compose support. Choose between interactive setup with project type selection and firewall customization, or quick one-command setup with defaults.

## Features

- **🚀 Two-Path Setup System** - Interactive quickstart with project type selection, or non-interactive YOLO vibe maxxing for instant defaults (Python+Node, container isolation)
- **☁️ Azure Cloud Deployment** - Deploy DevContainers to Azure Container Apps for cloud-based development environments
- **📊 Data-Driven Templates** - Configurations generated from curated registries of official Docker images and allowable domains
- **🔧 Troubleshooting Assistant** - Diagnose and fix common sandbox issues automatically
- **🔒 Security Auditor** - Review and harden sandbox configurations against best practices
- **🛡️ Smart Firewall Management** - Optional domain allowlist with 30-100+ curated domains
- **🎯 Intelligent Detection** - Auto-detects project type and suggests appropriate setup

## Important: Experimental Status

> **This plugin is experimental and provided as-is.** Most features have received minimal to no testing. Generated configurations may not work correctly on the first try and may require several iterations to get working.
>
> **Testing levels:**
> - `/sandboxxer:yolo-vibe-maxxing` - **Moderate testing** (most reliable)
> - `/sandboxxer:quickstart` - **Very minimal testing**
> - Firewall features - **No testing** (highly experimental)
> - Azure deployment - **No testing** (highly experimental)
> - Agents and skills - **Not tested**
>
> If you encounter issues, expect to iterate on the generated configuration files.

![Plugin Architecture](docs/diagrams/svg/plugin-architecture.svg)
*Plugin component overview - see [docs/diagrams/](docs/diagrams/) for detailed diagrams*

## Table of Contents

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
- [Skills Reference](#skills-reference)
- [Reference Documentation](#reference-documentation)
- [Naming Convention](#naming-convention)
- [Development](#development)
- [Examples](#examples)
- [Example Applications](#example-applications)
- [Contributing](#contributing)
- [License](#license)
- [Support](#support)
- [Repository Maintenance](#repository-maintenance)
- [Changelog](#changelog)

## Prerequisites

Before using this plugin, ensure you have:

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

# YOLO vibe-maxxing - no questions, instant DevContainer (Python+Node, no firewall)
/sandboxxer:yolo-vibe-maxxing

# Troubleshoot existing DevContainer
/sandboxxer:troubleshoot

# Security audit
/sandboxxer:audit

# Deploy to Azure
/sandboxxer:deploy-to-azure
```

**Note:** v4.3.0 introduces project-type selection and interactive firewall customization. Use `/sandboxxer:yolo-vibe-maxxing` (non-interactive YOLO vibe maxxing) for the fastest path with sensible defaults.

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

## Setup Options

The plugin offers two setup paths:

> **Testing Status:** `/yolo-vibe-maxxing` has moderate testing and is the most reliable option. `/quickstart` has very minimal testing - generated configurations may need manual adjustments.

1. **Interactive Quickstart** (`/sandboxxer:quickstart`) - Guided configuration with project type and firewall customization
2. **Non-Interactive YOLO Vibe Maxxing** (`/sandboxxer:yolo-vibe-maxxing`) - Instant defaults with no questions (Python+Node, container isolation)

See [SETUP-OPTIONS.md](docs/features/SETUP-OPTIONS.md) for comprehensive guide.

### Interactive Quickstart

**Best for**: Projects needing specific languages or network restrictions

> **Testing:** Very minimal. Configuration files may require iteration to work correctly.

**Key Features**:
- Choose from 8 project types (Python/Node, Go, Ruby, Rust, C++ Clang, C++ GCC, PHP, PostgreSQL)
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

### Non-Interactive YOLO Vibe Maxxing

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
You: /sandboxxer:yolo-vibe-maxxing

Claude: Creating DevContainer with defaults...
        - Base: Python 3.12 + Node 20
        - Firewall: Disabled (container isolation)
        - Services: PostgreSQL 16 + Redis 7
        ✓ Done in 18 seconds

        Next: Open in VS Code → 'Reopen in Container'
```

## Slash Commands

| Command                         | Description                                                       |
| ------------------------------- | ----------------------------------------------------------------- |
| `/sandboxxer:quickstart`        | Interactive quickstart - choose project type and firewall options |
| `/sandboxxer:yolo-vibe-maxxing` | YOLO vibe-maxxing - no questions, sensible defaults (Python+Node) |
| `/sandboxxer:deploy-to-azure`   | Deploy DevContainer to Azure Container Apps for cloud development |
| `/sandboxxer:troubleshoot`      | Diagnose and fix sandbox issues                                   |
| `/sandboxxer:audit`             | Security audit and recommendations                                |

**v4.6.0:** Added Azure deployment support for cloud-based development environments.
**v4.3.0:** Setup now offers interactive project-type selection or instant defaults with no questions.

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

## Skills Reference

### /sandboxxer:quickstart (Interactive Quickstart)
Interactive quickstart wizard with project type and firewall customization.

**Testing:** Very minimal

**Triggers**:
- User mentions "devcontainer", "docker sandbox"
- User asks about isolated development environments
- User wants to configure firewalls for development

**Workflow**:
1. Project type selection (8 languages)
2. Network restrictions question
3. Domain allowlist configuration (if enabled)
4. Template generation
5. Verification steps

### /sandboxxer:troubleshoot
Diagnoses and resolves common sandbox issues.

**Testing:** Not tested

**Triggers**:
- Container won't start
- Network connectivity problems
- Service connectivity failures
- Firewall blocking issues
- Permission errors

**Workflow**:
1. Identify problem category
2. Gather diagnostic information
3. Apply systematic fixes
4. Verify the fix

### /sandboxxer:audit
Performs comprehensive security audits.

**Testing:** Not tested

**Triggers**:
- User wants security audit
- User asks about security best practices
- User preparing for production
- User working with sensitive data

**Workflow**:
1. Scan configuration files
2. Firewall audit
3. Credentials and secrets check
4. Port exposure review
5. Container permissions audit
6. Generate security report

### /sandboxxer:yolo-vibe-maxxing
Non-interactive instant DevContainer setup with sensible defaults.

**Testing:** Moderate (most reliable)

**Triggers**:
- User wants fastest path to sandbox
- User mentions "yolo", "quick setup", "no questions"
- User needs rapid prototyping environment

**Workflow**:
1. Apply default configuration (Python 3.12 + Node 20)
2. Set container isolation (no firewall)
3. Add PostgreSQL 16 + Redis 7 services
4. Generate all configuration files
5. Display next steps

### /sandboxxer:deploy-to-azure
Deploy DevContainer configurations to Azure Container Apps.

**Testing:** No testing

**Triggers**:
- User wants cloud-based development
- User mentions "Azure", "cloud deployment", "remote container"
- User needs team/shared environments

**Workflow**:
1. Verify Azure CLI and subscription
2. Configure deployment options
3. Generate Azure Developer CLI manifest
4. Generate Bicep infrastructure templates
5. Execute deployment
6. Provide connection instructions

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
- [SETUP-OPTIONS.md](docs/features/SETUP-OPTIONS.md) - Interactive vs non-interactive setup guide
- [TROUBLESHOOTING.md](docs/features/TROUBLESHOOTING.md) - Common issues and solutions
- [VARIABLES.md](docs/features/VARIABLES.md) - Template variables reference

### Additional Documentation
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) - Plugin architecture overview
- [docs/CODESPACES.md](docs/CODESPACES.md) - GitHub Codespaces integration
- [docs/TESTING.md](docs/TESTING.md) - Testing guide for examples
- [docs/windows/README.md](docs/windows/README.md) - Windows-specific setup guide

## Naming Convention

This plugin uses consistent naming across different contexts:

| Context           | Name              | Example                                               |
| ----------------- | ----------------- | ----------------------------------------------------- |
| Plugin name       | sandboxxer        | Plugin installation and management                    |
| Marketplace name  | sandbox-maxxing   | Marketplace listing name                              |
| GitHub repository | sandbox-maxxing   | github.com/andrewcchoi/sandbox-maxxing                |
| Slash commands    | /sandboxxer:*     | /sandboxxer:quickstart, /sandboxxer:yolo-vibe-maxxing |
| Skills            | sandboxxer-*      | Internal skill naming                                 |
| User-facing title | Sandboxxer Plugin | In documentation headers                              |

**Why different names?**
- **sandboxxer**: Official plugin name used for installation and management
- **sandbox-maxxing**: Repository and marketplace name (reflects Windows WSL 2 compatibility)
- **Sandboxxer Plugin**: Full descriptive name for user-facing documentation

## Development

### Local Installation

```bash
# Clone the repository
git clone https://github.com/andrewcchoi/sandbox-maxxing
cd sandbox-maxxing

# Install locally
claude plugins add .
```

### Plugin Structure

![Plugin Architecture](docs/diagrams/svg/plugin-architecture.svg)

*Visual overview of the sandboxxer plugin components and their relationships. See [docs/diagrams/](docs/diagrams/) for more diagrams.*

```
sandbox-maxxing/
├── .claude-plugin/
│   ├── plugin.json              # Plugin manifest
│   └── marketplace.json         # Marketplace configuration
├── agents/                      # Subagent definitions
│   ├── devcontainer-generator.md   # File generation subagent
│   └── devcontainer-validator.md   # Post-setup validation subagent
├── commands/                    # Slash commands
│   ├── quickstart.md            # /sandboxxer:quickstart (interactive setup)
│   ├── yolo-vibe-maxxing.md     # /sandboxxer:yolo-vibe-maxxing (instant setup)
│   ├── deploy-to-azure.md       # /sandboxxer:deploy-to-azure (Azure deployment)
│   ├── troubleshoot.md          # /sandboxxer:troubleshoot
│   └── audit.md                 # /sandboxxer:audit
├── hooks/                       # Event hooks
│   ├── hooks.json               # Hook configuration
│   ├── stop_hook.sh             # Linux stop hook
│   ├── stop_hook.ps1            # Windows stop hook
│   └── run-hook.cmd             # Windows wrapper
├── skills/                      # Skills and shared resources
│   ├── _shared/                 # Shared templates and data
│   │   └── templates/           # DevContainer templates
│   │       ├── base.dockerfile
│   │       ├── devcontainer.json
│   │       ├── docker-compose.yml
│   │       ├── docker-compose.volume.yml
│   │       ├── docker-compose.prebuilt.yml
│   │       ├── docker-compose-profiles.yml
│   │       ├── init-firewall.sh
│   │       ├── init-volume.sh
│   │       ├── setup-claude-credentials.sh
│   │       ├── azure/           # Azure deployment templates
│   │       │   ├── azure.yaml
│   │       │   └── infra/
│   │       ├── partials/        # Language-specific Dockerfile sections
│   │       │   ├── azure-cli.dockerfile
│   │       │   ├── cpp-clang.dockerfile
│   │       │   ├── cpp-gcc.dockerfile
│   │       │   ├── go.dockerfile
│   │       │   ├── php.dockerfile
│   │       │   ├── postgres.dockerfile
│   │       │   ├── ruby.dockerfile
│   │       │   └── rust.dockerfile
│   │       └── data/            # Configuration data
│   │           ├── allowable-domains.json
│   │           ├── azure-regions.json
│   │           ├── mcp-servers.json
│   │           ├── official-images.json
│   │           ├── ollama-models.json
│   │           └── vscode-extensions.json
│   ├── sandboxxer-troubleshoot/ # Troubleshooting assistant
│   │   └── SKILL.md
│   └── sandboxxer-audit/     # Security auditor
│       └── SKILL.md
└── docs/                        # Documentation
    ├── examples/                # Working example applications
    │   ├── streamlit-sandbox-basic/
    │   ├── demo-app-sandbox-basic/
    │   ├── demo-app-sandbox-advanced/
    │   └── demo-app-sandbox-yolo/
    └── features/                # Feature documentation
```

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

The plugin includes comprehensive working examples in the `docs/examples/` directory, demonstrating different configuration approaches (minimal, domain allowlist, full) with real applications.

### Example Structure

```
docs/examples/
├── README.md                        # Comprehensive examples guide
├── docker-compose.yml               # Shared PostgreSQL + Redis services
│
├── streamlit-shared/                # Shared: Streamlit connection validator
├── streamlit-sandbox-basic/         # Self-contained with minimal configuration
│
├── demo-app-shared/                 # Shared: Full-stack blog application
├── demo-app-sandbox-basic/          # Demo app with minimal configuration
├── demo-app-sandbox-advanced/       # Demo app with domain allowlist
└── demo-app-sandbox-yolo/            # Demo app with full configuration
```

### Quick Validation: Streamlit App

**Shared Code**: `docs/examples/streamlit-shared/`
**Sandbox Example**: `docs/examples/streamlit-sandbox-basic/` (minimal configuration)

Minimal Python Streamlit app for 30-second environment validation:
- PostgreSQL connection test with visual feedback
- Redis connection test with visual feedback
- Perfect first step to verify sandbox setup

```bash
# Option 1: Use shared services
cd examples && docker compose up -d
cd streamlit-shared && uv add -r requirements.txt && streamlit run app.py

# Option 2: Self-contained DevContainer
code docs/examples/streamlit-sandbox-basic  # Open in VS Code
# Reopen in Container → Auto-starts all services
```

### Production Demo: Blog Application

**Shared Code**: `docs/examples/demo-app-shared/`

A complete full-stack blogging platform with:
- **Backend**: FastAPI + SQLAlchemy + PostgreSQL + Redis
- **Frontend**: React + Vite
- **Testing**: Pytest (backend) + Jest + React Testing Library (frontend)
- **Features**: CRUD operations, caching, view counters, comprehensive tests

**Example Configurations Available**:

#### 1. Minimal Configuration
**Location**: `docs/examples/demo-app-sandbox-basic/`

**What's included**:
- Auto-detected Python + Node.js stack
- Minimal configuration (4 files)
- Essential VS Code extensions (2)
- Domain allowlist by default
- Ready in < 3 minutes

**Best for**: Prototypes, solo developers, quick start

#### 2. Domain Allowlist
**Location**: `docs/examples/demo-app-sandbox-advanced/`

**What's included**:
- Configurable Python/Node.js versions (build args)
- Curated VS Code extensions (10+)
- User-controlled firewall (domain allowlist/container isolation)
- Enhanced developer experience (formatting on save, SQLTools)
- Development tools (Black, Pylint, IPython)

**Best for**: Team development, active projects, customization needs

#### 3. Full Configuration
**Location**: `docs/examples/demo-app-sandbox-yolo/`

**What's included**:
- Multi-stage optimized Dockerfile (7 stages)
- Comprehensive VS Code extensions (20+)
- Complete development tooling (linters, formatters, profilers, security scanners)
- Production patterns (resource limits, health checks, security hardening)
- Database initialization scripts
- Optional admin tools (pgAdmin, Redis Commander)
- Full observability and debugging

**Best for**: Large teams, production projects, comprehensive needs

### Running the Examples

**Quick validation** (Streamlit):
```bash
cd docs/examples/streamlit-sandbox-basic
# Open in VS Code → Reopen in Container
streamlit run app.py
```

**Full-stack demo** (any configuration):
```bash
cd docs/examples/demo-app-sandbox-basic  # or -advanced or -yolo
# Open in VS Code → Reopen in Container

# Terminal 1: Backend
cd backend && uvicorn app.api:app --reload

# Terminal 2: Frontend
cd frontend && npm run dev

# Visit: http://localhost:5173
```

**Run tests**:
```bash
./run-tests.sh           # Linux/Mac/Git Bash
.\run-tests.ps1          # Windows PowerShell
./run-tests.sh --coverage  # With coverage reports
```

### Learning Path

1. **Start here**: `streamlit-sandbox-basic/` - 30-second validation
2. **Learn basics**: `demo-app-sandbox-basic/` - Understand minimal setup
3. **Explore features**: `demo-app-sandbox-advanced/` - See customization options
4. **Study production**: `demo-app-sandbox-yolo/` - Learn best practices

See `docs/examples/README.md` for detailed comparison and customization guides

### Dogfooding Approach

This plugin uses itself for development! The `.devcontainer/` configuration was generated using the plugin's **interactive quickstart**, which correctly detected this as a documentation/template repository and created a minimal development environment.

**What the plugin detected:**
- Primary content: Markdown files (skills, documentation, commands)
- Languages: Python 3.12 + Node.js 20 (for examples and templates)
- Services needed: None (no database/cache in plugin code itself)

**What was generated:**
- Lightweight devcontainer with Python + Node.js runtimes
- VS Code extensions for markdown and code editing
- No PostgreSQL or Redis (not needed for plugin development)
- Examples have separate `docker-compose.yml` for optional testing

**Quick Start:**
```bash
# Open in VS Code
code .

# Reopen in container (F1 → Dev Containers: Reopen in Container)
# Container builds in ~2 minutes, ready to edit plugin files immediately

# Optional: Test examples (requires services)
cd docs/examples
docker compose up -d                    # Start PostgreSQL + Redis
cd streamlit-sandbox-basic
uv add -r requirements.txt
streamlit run app.py
```

This demonstrates the plugin's intelligent detection - it generates **only what you need**, not a one-size-fits-all template.

See [DEVELOPMENT.md](DEVELOPMENT.md) for complete development guide.

## Contributing

**Note**: I am not actively accepting pull requests or feature requests for this project. However, you are more than welcome to fork this repository and make your own improvements! Feel free to adapt it to your needs.

This project was created with [Claude](https://claude.ai) using the [Superpowers](https://github.com/obra/superpowers) plugin.

## License

MIT License - See LICENSE file for details

## Support

- **Issues**: https://github.com/andrewcchoi/sandbox-maxxing/issues
- **Documentation**: See `docs/features/` directory
- **Claude Code Docs**: https://claude.ai/code

## Repository Maintenance

For contributors and maintainers, see [`.internal/repo-keeper/`](.internal/repo-keeper/):

- **Organization Checklist**: [`ORGANIZATION_CHECKLIST.md`](.internal/repo-keeper/ORGANIZATION_CHECKLIST.md) - 18-category maintenance checklist
- **Inventory**: [`INVENTORY.json`](.internal/repo-keeper/INVENTORY.json) - Entity inventory for auditing
- **Automation Scripts**: [`scripts/`](.internal/repo-keeper/scripts/) - Version sync, link checking, inventory validation
- **GitHub Workflows**: [`workflows/`](.internal/repo-keeper/workflows/) - CI/CD templates for automated validation
- **Issue/PR Templates**: [`templates/`](.internal/repo-keeper/templates/) - Standardized templates for contributors

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for complete version history.

---

**Last Updated:** 2026-01-02
**Version:** 4.6.0
