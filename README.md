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
claude plugins add https://github.com/youruser/claude-code-sandbox

# Verify installation
claude plugins list
```

### Basic Usage

```bash
# Start interactive setup wizard
/sandbox:setup

# Quick setup with auto-detection (Basic mode)
/sandbox:setup --basic

# Step-by-step with detailed guidance (Pro mode)
/sandbox:setup --pro

# Troubleshoot existing sandbox
/sandbox:troubleshoot

# Security audit
/sandbox:audit
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
You: /sandbox:setup --basic
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
You: /sandbox:setup --advanced
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
You: /sandbox:setup --pro
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
| `/sandbox:setup` | Interactive setup wizard with mode selection | `sandbox-setup` |
| `/sandbox:setup --basic` | Quick automatic setup | `sandbox-setup` |
| `/sandbox:setup --advanced` | Semi-autonomous with key choices | `sandbox-setup` |
| `/sandbox:setup --pro` | Step-by-step with detailed guidance | `sandbox-setup` |
| `/sandbox:troubleshoot` | Diagnose and fix sandbox issues | `sandbox-troubleshoot` |
| `/sandbox:audit` | Security audit and recommendations | `sandbox-security` |

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
You: /sandbox:troubleshoot
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
git clone https://github.com/youruser/claude-code-sandbox
cd claude-code-sandbox

# Install locally
claude plugins add .
```

### Plugin Structure

```
claude-code-sandbox/
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
You: /sandbox:setup --basic
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
You: /sandbox:setup --advanced
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
You: /sandbox:audit
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

## Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Test your changes locally
4. Submit a pull request

## License

MIT License - See LICENSE file for details

## Support

- **Issues**: https://github.com/youruser/claude-code-sandbox/issues
- **Documentation**: See `skills/*/references/` directories
- **Claude Code Docs**: https://claude.ai/code

## Changelog

### v1.0.0 (2025-01-XX)
- Initial release
- Interactive setup wizard with Basic/Advanced/Pro modes
- Troubleshooting assistant
- Security auditor
- Templates for Python, Node.js, and Full-stack projects
