---
name: sandbox-setup
description: Use when user wants to set up a Claude Code Docker sandbox, configure devcontainer environments, or needs help with Docker development environments - provides interactive setup wizard with three experience tiers (Basic/Advanced/Pro)
---

# Sandbox Setup Assistant

## Overview

Guides users through setting up Claude Code Docker sandbox environments with interactive wizards tailored to their experience level.

## When to Use This Skill

Use this skill when:
- User mentions "devcontainer", "docker sandbox", "Claude Code sandbox"
- User asks about setting up isolated development environments
- User wants to configure firewalls or network security for development
- User needs help with Docker Compose configurations for development
- User is starting a new project and needs containerized development setup

Do NOT use this skill when:
- User is troubleshooting an existing sandbox (use `sandbox-troubleshoot` instead)
- User wants to audit security of existing setup (use `sandbox-security` instead)
- User is asking general Docker questions unrelated to Claude Code

## Experience Tiers

### Basic Mode (Quick & Automatic)
**Best for**: Beginners, quick prototypes, standard setups

**Behavior**:
- Auto-detects project type from existing files
- Uses sensible defaults (strict firewall, recommended services)
- Generates all config files in one shot
- Uses flexible Dockerfile with build args
- Minimal user interaction (1-2 questions max)

### Advanced Mode (Semi-Autonomous)
**Best for**: Regular users who want some control

**Behavior**:
- Asks key decisions: language, database, cache, firewall mode
- Uses one configurable Dockerfile
- Explains trade-offs briefly for each choice
- Generates configs with configuration summaries
- 5-7 questions total

### Pro Mode (Step-by-Step with Guidance)
**Best for**: Learning, production setups, custom requirements

**Behavior**:
- Walks through each file creation step-by-step
- Uses separate optimized Dockerfiles per technology
- Explains why each setting matters
- Teaches security best practices at each step
- References documentation sections
- Full educational experience
- 10-15+ questions with detailed explanations

## Workflow

### 1. Mode Selection

Ask the user:

**"What setup experience would you prefer?"**
- **Basic** (Quick & automatic - recommended for beginners)
- **Advanced** (Some customization with guidance)
- **Pro** (Full control with detailed best practices)

If invoked via slash command with flag (`--basic`, `--advanced`, `--pro`), skip this question.

### 2. Project Detection

**All Modes**: Analyze the current workspace:
- Check for existing `.devcontainer/` directory (warn if exists)
- Detect project type from files:
  - Python: `requirements.txt`, `pyproject.toml`, `*.py`
  - Node.js: `package.json`, `*.js`, `*.ts`
  - Go: `go.mod`, `*.go`
  - Rust: `Cargo.toml`, `*.rs`
  - Fullstack: Multiple of the above

### 3. Configuration Wizard

#### Basic Mode Questions:
1. **Confirm detected project type**: "I detected a [Python/Node/etc] project. Is this correct?"
2. **Optional**: "Do you need a database?" (Yes/No - if yes, auto-select appropriate one)

Then generate everything with defaults.

#### Advanced Mode Questions:
1. **Project type**: "What's your primary programming language?" (Python/Node.js/Go/Rust/Other)
2. **Database**: "What database do you need?" (PostgreSQL/MySQL/MongoDB/Redis/None/Multiple)
3. **Cache**: "Need caching?" (Redis/None)
4. **AI Integration**: "Need local AI (Ollama)?" (Yes/No - warn about GPU requirement)
5. **Firewall mode**: "Firewall security level?" (Strict/Permissive)
6. **Network name**: "Network name?" (Default: `<project-name>-network`)

#### Pro Mode Questions:
Walk through each file with detailed explanations:

**Step 1: DevContainer Configuration**
- Container name
- Network name (explain why it must match docker-compose)
- Firewall mode (explain strict vs permissive with security implications)
- Environment variables (explain `${localEnv:VAR}` for secrets)
- VS Code extensions needed

**Step 2: Dockerfile Selection**
- Base image choice (explain trade-offs)
- Pre-install dependencies? (explain Docker layer caching)
- System packages needed
- User setup (explain non-root user security)

**Step 3: Docker Compose Services**
- Which services needed
- For each service:
  - Port mappings (explain when to expose vs not)
  - Volume strategy (explain data persistence)
  - Health checks (explain importance)
  - Resource limits (explain CPU/memory constraints)

**Step 4: Firewall Configuration**
- Review allowed domains list
- Explain each domain's purpose
- Add project-specific domains
- Explain threat model

### 4. Template Generation

Use templates from `${CLAUDE_PLUGIN_ROOT}/templates/`:

**Basic/Advanced Mode**:
- Use `templates/base/Dockerfile.flexible`
- Replace placeholders: `{{PROJECT_NAME}}`, `{{NETWORK_NAME}}`, `{{FIREWALL_MODE}}`

**Pro Mode**:
- Use technology-specific Dockerfiles from `templates/python/`, `templates/node/`, etc.
- Generate optimized configs for the specific stack

**Files to Generate**:
1. `.devcontainer/devcontainer.json`
2. `.devcontainer/Dockerfile`
3. `.devcontainer/init-firewall.sh`
4. `docker-compose.yml`
5. Language-specific configs (requirements.txt, package.json, etc.) as examples

### 5. Security Review

**All Modes**: After generation, perform security audit:
- ✓ Check firewall mode is set
- ✓ Verify no default passwords in committed files
- ✓ Check that secrets use environment variables
- ✓ Verify unnecessary ports aren't exposed
- ✓ Confirm non-root user in Dockerfile
- ⚠ Warn about any security concerns found

**Pro Mode**: Explain each security check and why it matters.

### 6. Next Steps

Provide verification commands:

```bash
# Start services
docker compose up -d

# Open in DevContainer
code .
# Ctrl+Shift+P → "Dev Containers: Reopen in Container"

# Test connectivity (inside container)
# For PostgreSQL:
psql postgresql://user:pass@postgres:5432/db

# For Redis:
redis-cli -h redis ping
```

Offer to run these commands if user wants.

## Reference Documentation

For detailed information, refer to embedded documentation in `references/`:
- `customization.md` - Full customization guide
- `security.md` - Security model and best practices
- `troubleshooting.md` - Common issues and solutions

## Integration with Other Skills

- After setup completes, suggest: "Would you like me to audit the security?" → Use `sandbox-security` skill
- If errors occur during setup, automatically invoke `sandbox-troubleshoot` skill
- For updating existing configs, use this skill with caution (warn about overwriting)

## Key Principles

- **One question at a time** - Don't overwhelm users
- **Multiple choice preferred** - Easier than open-ended when possible
- **Explain trade-offs** - Help users make informed decisions
- **Lead with recommendations** - Default to secure, best-practice configurations
- **Verify before overwriting** - Always check for existing files
- **Teach in Pro mode** - Education is a feature, not a bug

## Example Invocations

**Via slash command**:
```
/sandbox:setup
/sandbox:setup --basic
/sandbox:setup --pro
```

**Via natural language**:
- "Help me set up a Docker sandbox for my Python project"
- "I need a devcontainer with PostgreSQL"
- "Configure a Claude Code sandbox with strict firewall"
