# Claude Code Sandbox Plugin

Interactive assistant for setting up, troubleshooting, and securing Claude Code Docker sandbox environments.

## Features

- **🚀 Interactive Setup Wizard** - Set up Docker sandbox environments with tiered experience (Basic/Advanced/Pro)
- **🔧 Troubleshooting Assistant** - Diagnose and fix common sandbox issues automatically
- **🔒 Security Auditor** - Review and harden sandbox configurations against best practices
- **📦 Template Library** - Pre-configured templates for Python, Node.js, and full-stack projects
- **🛡️ Firewall Management** - Secure network configurations with strict/permissive modes

## Quick Start

### Installation

```bash
# Install the plugin
claude plugins add https://github.com/andrewcchoi/windows-sandbox

# Verify installation
claude plugins list
```

### Basic Usage

```bash
# Start interactive setup wizard
/windows-sandbox:setup

# Quick setup with auto-detection (Basic mode)
/windows-sandbox:setup --basic

# Step-by-step with detailed guidance (Pro mode)
/windows-sandbox:setup --pro

# Troubleshoot existing sandbox
/windows-sandbox:troubleshoot

# Security audit
/windows-sandbox:audit
```

## Experience Tiers

### Basic Mode (Quick & Automatic)
**Best for**: Beginners, rapid prototyping

- Auto-detects project type
- Uses sensible defaults
- Minimal questions (1-2)
- Generates all configs in one shot

**Example**:
```
You: /windows-sandbox:setup --basic
Claude: I detected a Python project with FastAPI. Setting up with PostgreSQL and Redis...
[Generates all files]
Claude: Done! Run 'docker compose up -d' to start.
```

### Advanced Mode (Semi-Autonomous)
**Best for**: Regular users who want control

- Asks key decisions (5-7 questions)
- Explains trade-offs briefly
- One flexible Dockerfile
- Configuration summaries

**Example**:
```
You: /windows-sandbox:setup --advanced
Claude: What database do you need?
  • PostgreSQL (recommended for relational data)
  • MySQL (alternative relational)
  • MongoDB (document store)
  • None
You: PostgreSQL
Claude: Firewall mode?
  • Strict (blocks all except whitelisted - recommended)
  • Permissive (allows all - convenient for development)
...
```

### Pro Mode (Step-by-Step with Guidance)
**Best for**: Learning, production setups

- Detailed 10-15+ questions
- Explains every choice
- Separate optimized Dockerfiles
- Security best practices
- Full educational experience

**Example**:
```
You: /windows-sandbox:setup --pro
Claude: Let's configure your DevContainer step by step.

**Step 1: Network Configuration**
The network name must match between devcontainer.json and docker-compose.yml.
This allows your container to communicate with services like PostgreSQL.

Recommended: <project>-network
What network name would you like? [my-project-network]
...
```

## Slash Commands

| Command | Description | Skill |
|---------|-------------|-------|
| `/windows-sandbox:setup` | Interactive setup wizard with mode selection | `sandbox-setup` |
| `/windows-sandbox:setup --basic` | Quick automatic setup | `sandbox-setup` |
| `/windows-sandbox:setup --advanced` | Semi-autonomous with key choices | `sandbox-setup` |
| `/windows-sandbox:setup --pro` | Step-by-step with detailed guidance | `sandbox-setup` |
| `/windows-sandbox:troubleshoot` | Diagnose and fix sandbox issues | `sandbox-troubleshoot` |
| `/windows-sandbox:audit` | Security audit and recommendations | `sandbox-security` |

## Auto-Detection

The plugin automatically activates when you:
- Mention "devcontainer", "docker sandbox", or "Claude Code sandbox"
- Ask about setting up isolated development environments
- Need help with Docker Compose configurations
- Want to configure firewalls for development

**Example**:
```
You: I need to set up a Docker development environment for my Python project
Claude: [Automatically uses sandbox-setup skill]
      What setup experience would you prefer?
      • Basic (Quick & automatic)
      • Advanced (Some customization)
      • Pro (Full control with guidance)
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
You: /windows-sandbox:troubleshoot
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

### Pro Mode
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

### sandbox-setup
Interactive setup wizard with three experience tiers.

**Triggers**:
- User mentions "devcontainer", "docker sandbox"
- User asks about isolated development environments
- User wants to configure firewalls for development

**Workflow**:
1. Mode selection (Basic/Advanced/Pro)
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
- `skills/sandbox-setup/references/customization.md` - Customization guide
- `skills/sandbox-setup/references/security.md` - Security model and best practices
- `skills/sandbox-setup/references/troubleshooting.md` - Detailed troubleshooting guide

## Development

### Local Installation

```bash
# Clone the repository
git clone https://github.com/andrewcchoi/windows-sandbox
cd windows-sandbox

# Install locally
claude plugins add .
```

### Plugin Structure

```
windows-sandbox/
├── .claude-plugin/
│   └── plugin.json              # Plugin manifest
├── skills/
│   ├── sandbox-setup/           # Interactive setup wizard
│   ├── sandbox-troubleshoot/    # Troubleshooting assistant
│   └── sandbox-security/        # Security auditor
├── commands/
│   ├── setup.md                 # /sandbox:setup command
│   ├── troubleshoot.md          # /sandbox:troubleshoot command
│   └── audit.md                 # /sandbox:audit command
└── templates/
    ├── base/                    # Flexible templates
    ├── python/                  # Python-specific
    ├── node/                    # Node.js-specific
    └── fullstack/               # Full-stack templates
```

## Examples

### Example 1: Quick Python Setup

```
You: /windows-sandbox:setup --basic
Claude: I detected a Python project. Setting up with:
        - Python 3.12 with uv
        - PostgreSQL database
        - Redis cache
        - Strict firewall mode

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
You: /windows-sandbox:setup --advanced
Claude: What's your primary language?
You: Node.js
Claude: What database do you need?
You: MongoDB
Claude: Need caching?
You: Yes, Redis
Claude: Firewall security level?
You: Strict
Claude: Generating optimized configuration for Node.js + MongoDB + Redis...
```

### Example 3: Security Audit

```
You: /windows-sandbox:audit
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

The plugin includes working example applications in the `examples/` directory that demonstrate real-world usage patterns and serve as validation tests.

### Basic Streamlit App (Quick Validation)

**Location**: `examples/basic-streamlit/`

A minimal Streamlit application for quickly validating that your devcontainer is working correctly.

**Features**:
- PostgreSQL connection test with visual feedback
- Redis connection test with visual feedback
- Simple one-button testing interface
- Perfect for quick environment validation

**Usage**:
```bash
cd examples/basic-streamlit
uv pip install -r requirements.txt
streamlit run app.py
```

**When to use**: After setting up a new devcontainer, run this app to verify that services are accessible.

### Demo Blog Application (Full-Stack Showcase)

**Location**: `examples/demo-app/`

A complete full-stack blogging platform demonstrating production-ready patterns and best practices.

**Tech Stack**:
- **Backend**: FastAPI + SQLAlchemy + Alembic migrations
- **Frontend**: React + Vite + Axios
- **Database**: PostgreSQL with proper indexing
- **Cache**: Redis with TTL-based caching and view counters
- **Testing**: Pytest (backend) + Jest + React Testing Library (frontend)

**Features Demonstrated**:
- Complete CRUD API with RESTful endpoints
- Database migrations with Alembic
- Redis caching patterns (content caching + counters)
- Async database operations
- Comprehensive test coverage (28+ tests)
- Error handling and validation
- Modern React patterns (hooks, component composition)

**Backend API**:
```bash
cd examples/demo-app/backend
uv pip install -r requirements.txt
alembic upgrade head
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Access API docs at http://localhost:8000/docs

**Frontend Application**:
```bash
cd examples/demo-app/frontend
npm install
npm run dev
```

Access app at http://localhost:5173

**Running Tests**:

From the `examples/demo-app` directory:

```bash
# All tests
./run-tests.sh             # Linux/Mac
.\run-tests.ps1            # Windows

# With coverage reports
./run-tests.sh --coverage
.\run-tests.ps1 -Coverage

# Backend only
./run-tests.sh --backend-only

# Frontend only
./run-tests.sh --frontend-only
```

**Test Coverage**:
- **Backend**: 8 tests covering API endpoints and Redis caching logic
- **Frontend**: 20+ tests covering all components, user interactions, and edge cases

**What You'll Learn**:
- How to structure a full-stack application in a devcontainer
- Redis caching patterns for performance optimization
- Database migration workflows with Alembic
- Testing strategies for both backend and frontend
- Service orchestration with Docker Compose

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
uv pip install -r requirements.txt
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

- **Issues**: https://github.com/andrewcchoi/windows-sandbox/issues
- **Documentation**: See `skills/*/references/` directories
- **Claude Code Docs**: https://claude.ai/code

## Changelog

### v1.0.0 (2025-01-XX)
- Initial release
- Interactive setup wizard with Basic/Advanced/Pro modes
- Troubleshooting assistant
- Security auditor
- Templates for Python, Node.js, and Full-stack projects
