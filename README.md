# DevContainer Setup Plugin

> **Repository:** [andrewcchoi/sandbox-maxxing](https://github.com/andrewcchoi/sandbox-maxxing)
> **Plugin Name:** devcontainer-setup (used in commands: /devcontainer:quickstart, /devcontainer:yolo-vibe-maxxing)

Interactive assistant for creating VS Code DevContainer configurations with Docker Compose support. Choose between interactive setup with project type selection and firewall customization, or quick one-command setup with defaults.

## Features

- **🚀 Two-Path Setup System** - Interactive setup with project type selection, or YOLO mode for instant defaults (Python+Node, no firewall)
- **📊 Data-Driven Templates** - Configurations generated from curated registries of official Docker images and allowable domains
- **🔧 Troubleshooting Assistant** - Diagnose and fix common sandbox issues automatically
- **🔒 Security Auditor** - Review and harden sandbox configurations against best practices
- **🛡️ Smart Firewall Management** - Mode-specific domain whitelists with 30-100+ curated domains
- **🎯 Intelligent Detection** - Auto-detects project type and suggests appropriate mode

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
/devcontainer:quickstart

# YOLO vibe-maxxing - no questions, instant DevContainer (Python+Node, no firewall)
/devcontainer:yolo-vibe-maxxing

# Troubleshoot existing DevContainer
/devcontainer:troubleshoot

# Security audit
/devcontainer:audit
```

**Note:** v4.3.0 introduces project-type selection and interactive firewall customization. Use `/devcontainer:yolo-vibe-maxxing` for the fastest path with sensible defaults.

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

## Three-Mode System

See [MODES.md](docs/features/MODES.md) for comprehensive comparison guide.

### Basic Mode - Zero Configuration

**Best for**: Beginners, rapid prototyping, learning projects

**Key Features**:
- Auto-detects project type (2-3 questions max)
- Sensible defaults (PostgreSQL + Redis)
- Base images: `docker/sandbox-templates:latest` or `claude-code`
- Firewall: None (relies on container isolation)
- VS Code: 5-8 essential extensions
- Ready in 1-2 minutes

**Example**:
```
You: /devcontainer:quickstart
Claude: I detected a Python FastAPI project. Setting up with:
        - Base: docker/sandbox-templates:claude-code
        - Database: PostgreSQL 16
        - Cache: Redis 7
        - Firewall: Strict (essential domains only)
        Generating configs... Done!
```

### Advanced Mode - Security-First Minimal

**Best for**: Security-conscious development, production prep, compliance

**Key Features**:
- Detailed configuration (10-15 questions)
- Multi-stage optimized Dockerfiles
- Base images: Security-hardened official images
- Firewall: Strict (customizable allowlist, explicit additions)
- VS Code: 20+ comprehensive extensions (including security scanners)
- Ready in 8-12 minutes

**Example**:
```
You: /devcontainer:quickstart
Claude: This mode creates security-hardened configurations.

        **Step 1: Base Configuration**
        Project name? [my-project]

        **Step 2: Base Image Selection**
        For security, we'll use hardened official images with:
        - Minimal system packages
        - Security updates
        - Non-root user
        - Small attack surface
...
```

### YOLO Mode - Maximum Flexibility

**Best for**: Experts, experimental setups, custom requirements

**Key Features**:
- Full customization (15-20+ questions)
- Any base image (including nightly/experimental)
- Base images: Any including `docker/sandbox-templates:nightly`, custom registries
- Firewall: Optional (can disable entirely) or fully custom
- VS Code: Complete control
- Ready in 15-30 minutes (depends on choices)

**Example**:
```
You: /devcontainer:yolo-vibe-maxxing
Claude: YOLO vibe-maxxing mode - You're in control!

        ⚠️  Warning: Maximum flexibility, minimal safety rails.

        Base image source?
        • Official Docker (python, node, etc.)
        • Docker sandbox-templates (latest, claude-code, nightly)
        • Custom registry (specify full path)

You: sandbox-templates
Claude: sandbox-templates tag?
        • latest • claude-code • nightly • cagent • Custom
...
```

## Slash Commands

| Command                            | Description                                                           |
| ---------------------------------- | --------------------------------------------------------------------- |
| `/devcontainer:quickstart`        | Interactive quickstart - choose project type and firewall options          |
| `/devcontainer:yolo-vibe-maxxing`         | YOLO vibe-maxxing - no questions, sensible defaults (Python+Node)           |
| `/devcontainer:troubleshoot` | Diagnose and fix sandbox issues                                       |
| `/devcontainer:audit`        | Security audit and recommendations                                    |

**v4.3.0:** Setup now offers interactive project-type selection or instant YOLO defaults.

## Auto-Detection

The plugin automatically activates when you:
- Mention "devcontainer", "docker sandbox", or "Claude Code sandbox"
- Ask about setting up isolated development environments
- Need help with Docker Compose configurations
- Want to configure firewalls for development

**Example**:
```
You: I need to set up a Docker development environment for my Python project
Claude: [Automatically uses /devcontainer:quickstart command]
      What mode would you like?
      • Basic (Zero config, 1-2 min)
      • Advanced (Secure minimal, 8-12 min)
      • YOLO (Full control, 15-30 min)
```

## Project Templates

### Python (FastAPI + PostgreSQL + Redis)
- Optimized Python 3.12 with uv
- FastAPI web framework
- PostgreSQL database
- Redis cache
- Async SQLAlchemy
- Alembic migrations

### Node.js (Express + MongoDB + Redis)
- Node.js 20 with TypeScript
- Express web framework
- MongoDB database
- Redis cache
- ESLint + Prettier

### Full-Stack (React + FastAPI + PostgreSQL + AI)
- Python FastAPI backend
- React + TypeScript frontend
- PostgreSQL database
- Redis cache
- Ollama (optional local AI)

## Security Features

### Firewall Modes

**Strict Mode** (Recommended):
- Default policy: DROP all outbound traffic
- Only whitelisted domains allowed
- Prevents accidental data leakage
- Protects against malicious dependencies

**Permissive Mode**:
- Default policy: ACCEPT all traffic
- No restrictions
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
You: /devcontainer:troubleshoot
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

## Files Generated

### Basic/Advanced Mode
- `.devcontainer/devcontainer.json` - VS Code DevContainer config
- `.devcontainer/Dockerfile` - Flexible container image
- `.devcontainer/init-firewall.sh` - Firewall configuration
- `docker-compose.yml` - Services configuration

### YOLO Mode
- `.devcontainer/devcontainer.json` - Optimized for your stack
- `.devcontainer/Dockerfile` - Technology-specific optimizations
- `.devcontainer/init-firewall.sh` - Customized allowed domains
- `docker-compose.yml` - Production-ready service configs
- Language-specific files (requirements.txt, package.json, etc.)

## Configuration Placeholders

Templates use these placeholders:
- `{{PROJECT_NAME}}` - Your project name
- `{{NETWORK_NAME}}` - Docker network name
- `{{DATABASE_USER}}` - Database username
- `{{DATABASE_NAME}}` - Database name
- `{{FIREWALL_MODE}}` - strict or permissive
- `{{BASE_IMAGE}}` - Docker base image

## Skills Reference

### /devcontainer:quickstart (Interactive Router)
Interactive setup wizard with four experience modes.

**Note:** This is a router command that delegates to mode-specific skills:
- `devcontainer-setup-basic` - Basic mode setup
- `devcontainer-setup-advanced` - Advanced mode setup
- `devcontainer-setup-yolo` - YOLO mode setup

**Triggers**:
- User mentions "devcontainer", "docker sandbox"
- User asks about isolated development environments
- User wants to configure firewalls for development

**Workflow**:
1. Mode selection (Basic/Advanced/YOLO)
2. Project detection
3. Configuration wizard
4. Template generation
5. Security review
6. Verification steps

### sandbox-troubleshoot
Diagnoses and resolves common sandbox issues.

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

### sandbox-security
Performs comprehensive security audits.

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

## Reference Documentation

The plugin includes comprehensive reference documentation:
- `docs/features/CUSTOMIZATION.md` - Customization guide
- `docs/features/security-model.md` - Security model and best practices
- `docs/features/TROUBLESHOOTING.md` - Detailed troubleshooting guide

## Naming Convention

This plugin uses consistent naming across different contexts:

| Context           | Name                      | Example                                             |
| ----------------- | ------------------------- | --------------------------------------------------- |
| Plugin name       | devcontainer-setup        | Plugin installation and management                  |
| GitHub repository | sandbox-maxxing           | github.com/andrewcchoi/sandbox-maxxing              |
| Slash commands    | /devcontainer:*           | /devcontainer:quickstart, /devcontainer:yolo-vibe-maxxing |
| Skills            | sandbox-*                 | devcontainer-setup-basic                            |
| User-facing title | DevContainer Setup Plugin | In documentation headers                            |

**Why different names?**
- **devcontainer-setup**: Official plugin name used for installation and management
- **sandbox-maxxing**: Repository and marketplace name (reflects Windows WSL 2 compatibility)
- **sandbox**: Shorthand used in internal skills for brevity (skill files remain unchanged for backwards compatibility)
- **DevContainer Setup Plugin**: Full descriptive name for user-facing documentation

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

```
sandbox-maxxing/
├── .claude-plugin/
│   ├── plugin.json              # Plugin manifest
│   └── marketplace.json         # Marketplace configuration
├── data/                        # Data-driven configuration
│   ├── sandbox-templates.json   # Official Docker sandbox images
│   ├── official-images.json     # Docker Hub official images registry
│   └── allowable-domains.json   # Firewall domain whitelists
├── skills/
│   ├── _shared/                 # Shared templates and data
│   │   ├── templates/           # DevContainer templates
│   │   │   ├── base.dockerfile
│   │   │   ├── devcontainer.json
│   │   │   ├── docker-compose.yml
│   │   │   ├── init-firewall.sh
│   │   │   ├── setup-claude-credentials.sh
│   │   │   └── partials/        # Language-specific Dockerfile sections
│   │   │       ├── go.dockerfile
│   │   │       ├── rust.dockerfile
│   │   │       ├── java.dockerfile
│   │   │       ├── ruby.dockerfile
│   │   │       ├── php.dockerfile
│   │   │       ├── cpp-clang.dockerfile
│   │   │       ├── cpp-gcc.dockerfile
│   │   │       └── postgres.dockerfile
│   │   └── templates/data/      # Configuration data
│   │       ├── allowable-domains.json
│   │       ├── mcp-servers.json
│   │       ├── secrets.json
│   │       └── variables.json
│   ├── sandbox-troubleshoot/    # Troubleshooting assistant
│   └── sandbox-security/        # Security auditor
├── commands/
│   ├── quickstart.md            # /devcontainer:quickstart (interactive mode selection)
│   ├── yolo-vibe-maxxing.md     # /devcontainer:yolo-vibe-maxxing (quick no-questions setup)
│   ├── troubleshoot.md          # /devcontainer:troubleshoot
│   └── audit.md                 # /devcontainer:audit
└── docs/examples/                    # Working example applications
    ├── streamlit-sandbox-basic/
    ├── demo-app-sandbox-basic/
    ├── demo-app-sandbox-advanced/
    └── demo-app-sandbox-yolo/
```

## Examples

### Example 1: Quick Python Setup (Basic Mode)

```
You: /devcontainer:quickstart
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
Claude: Firewall mode?
        • Strict (essential domains)
        • Expanded (includes cloud platforms)
You: Expanded
Claude: Generating configuration for Node.js 20 + MongoDB 7 + Redis...
```

### Example 3: Security Audit

```
You: /devcontainer:audit
Claude: Running security audit...

        # Security Audit Report

        ## Summary
        - Overall Risk Level: Medium
        - Warnings: 2

        ## Warnings ⚠
        1. Default password in docker-compose.yml
           - Found: POSTGRES_PASSWORD: devpassword
           - Recommendation: Change for production use

        2. Firewall in permissive mode
           - Current: FIREWALL_MODE=permissive
           - Recommendation: Switch to strict mode

        ## Good Practices ✅
        1. Running as non-root user (node)
        2. No hardcoded secrets in configs
        3. Minimal Linux capabilities

        Would you like me to help fix these issues?
```

## Example Applications

The plugin includes comprehensive working examples in the `docs/examples/` directory, demonstrating all three experience modes (Basic, Advanced, YOLO) with real applications.

### Example Structure

```
docs/examples/
├── README.md                        # Comprehensive examples guide
├── docker-compose.yml               # Shared PostgreSQL + Redis services
│
├── streamlit-shared/                # Shared: Streamlit connection validator
├── streamlit-sandbox-basic/         # Self-contained with Basic mode DevContainer
│
├── demo-app-shared/                 # Shared: Full-stack blog application
├── demo-app-sandbox-basic/          # Demo app with Basic mode DevContainer
├── demo-app-sandbox-advanced/       # Demo app with Advanced mode DevContainer
└── demo-app-sandbox-yolo/            # Demo app with YOLO mode DevContainer
```

### Quick Validation: Streamlit App

**Shared Code**: `docs/examples/streamlit-shared/`
**Sandbox Example**: `docs/examples/streamlit-sandbox-basic/` (Basic mode)

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

**Four Example Sandbox Modes Available**:

#### 1. Basic Mode - Quick Start
**Location**: `docs/examples/demo-app-sandbox-basic/`

**What's included**:
- Auto-detected Python + Node.js stack
- Minimal configuration (4 files)
- Essential VS Code extensions (2)
- Strict firewall by default
- Ready in < 3 minutes

**Best for**: Prototypes, solo developers, quick start

#### 2. Advanced Mode - Balanced
**Location**: `docs/examples/demo-app-sandbox-advanced/`

**What's included**:
- Configurable Python/Node.js versions (build args)
- Curated VS Code extensions (10+)
- User-controlled firewall (strict/permissive/disabled)
- Enhanced developer experience (formatting on save, SQLTools)
- Development tools (Black, Pylint, IPython)

**Best for**: Team development, active projects, customization needs

#### 3. YOLO Mode - Full Control
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

**Full-stack demo** (any mode):
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

This plugin uses itself for development! The `.devcontainer/` configuration was generated using the plugin's **Basic mode**, which correctly detected this as a documentation/template repository and created a minimal development environment.

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
cd examples
docker compose up -d                    # Start PostgreSQL + Redis
cd basic-streamlit
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

### v2.0.0 (2025-12-16)
- **Major Release**: Three-mode system (Basic, Advanced, YOLO)
- Data-driven configuration with JSON registries
  - `sandbox-templates.json`: Official Docker sandbox images
  - `official-images.json`: Docker Hub official images
  - `allowable-domains.json`: Mode-specific firewall whitelists
- Modular template system with section markers
- Enhanced firewall with mode-specific domain sets (30-100+ domains)
- Updated slash commands: `/devcontainer:quickstart`, `/devcontainer:quickstart`, `/devcontainer:yolo-vibe-maxxing`, `/devcontainer:quickstart`
- Comprehensive mode comparison guide (MODES.md)
- Migration from Basic/Advanced/YOLO to new three-mode system

### v1.0.0 (2025-01-XX)
- Initial release
- Interactive setup wizard with Basic/Advanced/YOLO modes
- Troubleshooting assistant
- Security auditor
- Templates for Python, Node.js, and Full-stack projects

---

**Last Updated:** 2025-12-24
**Version:** 4.5.0
