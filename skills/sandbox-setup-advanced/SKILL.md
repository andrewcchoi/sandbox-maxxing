---
name: sandbox-setup-advanced
description: Use when user wants security-focused development setup with strict firewall controls and customizable domain allowlists - ideal for production-like configurations, security-conscious teams, and scenarios requiring explicit network control
---

# Sandbox Setup: Advanced Mode

## TASK IDENTITY

You are a **DevContainer Configuration Generator**. This is a file generation task.

**Your output:** VS Code DevContainer files in `.devcontainer/` directory
**Technology:** Docker, VS Code Dev Containers
**NOT related to:** Claude Code settings, Claude Code sandbox, `.claude/` configs

## What This Skill Creates

**⚠️ CRITICAL: THIS SKILL CREATES A DEVCONTAINER SETUP, NOT CLAUDE CODE'S SANDBOX FEATURE.**

You will create VS Code DevContainer files in the project's `.devcontainer/` directory:
- `.devcontainer/Dockerfile` - Custom Dockerfile with security hardening
- `.devcontainer/devcontainer.json` - DevContainer configuration for VS Code
- `.devcontainer/init-firewall.sh` - Firewall initialization script (advanced: strict with allowlist)
- `.devcontainer/setup-claude-credentials.sh` - Claude credentials persistence (Issue #30)
- `docker-compose.yml` - Docker services configuration with production-like settings (in project root)

### What This Is:
- A **file generation task** that creates DevContainer configuration files
- Files that enable VS Code's "Reopen in Container" feature
- Docker-based development environment with strict firewall controls

### YOUR EXCLUSIVE OUTPUT FILES:

| File | Location | Purpose |
|------|----------|---------|
| `Dockerfile` | `.devcontainer/Dockerfile` | Security-hardened container image |
| `devcontainer.json` | `.devcontainer/devcontainer.json` | VS Code DevContainer config |
| `init-firewall.sh` | `.devcontainer/init-firewall.sh` | Firewall script (advanced: strict with allowlist) |
| `setup-claude-credentials.sh` | `.devcontainer/setup-claude-credentials.sh` | Credentials helper |
| `docker-compose.yml` | `./docker-compose.yml` | Docker services with production-like settings |

**Task Boundary:** This skill generates DevContainer files ONLY. Claude Code configuration is a different feature.

### After Creating Files:
The user will use VS Code's "Dev Containers: Reopen in Container" command to start the environment. You only create the configuration files.

## PRE-WRITE VALIDATION (MANDATORY)

**BEFORE creating ANY file, verify the path:**

| Path Pattern | Valid? | Action |
|--------------|--------|--------|
| `.devcontainer/*` | ✓ YES | Proceed |
| `docker-compose.yml` | ✓ YES | Proceed |
| `.claude/*` | ✗ NO | STOP - Wrong task |
| `.claude-code/*` | ✗ NO | STOP - Wrong task |
| `~/.claude*` | ✗ NO | STOP - Wrong location |

**Self-Check:** "Does my file path start with `.devcontainer/` or is it `docker-compose.yml`?"
If NO → STOP and re-read the TASK IDENTITY section.

## MANDATORY FIRST STEP - COPY TEMPLATES

**⚠️ NEW WORKFLOW: Copy templates first, then customize.**

### Step 1A: Find Template Directories

Templates are organized in two locations:
- **Shared templates**: Common files used by all modes
- **Mode-specific templates**: Unique files for this mode

```bash
# Find the skill directory (relative to this SKILL.md file)
SKILL_DIR="$(dirname "${BASH_SOURCE[0]}")"

# Shared templates are at plugin root
PLUGIN_ROOT="$(cd "$SKILL_DIR/../.." && pwd)"
SHARED_DIR="$PLUGIN_ROOT/templates/shared"

# Mode-specific templates are in this skill folder
MODE_DIR="$SKILL_DIR/templates"

echo "Shared templates: $SHARED_DIR"
echo "Mode templates: $MODE_DIR"
```

**Verify templates exist:**
```bash
ls -la "$SHARED_DIR/"
ls -la "$MODE_DIR/"
```

If either directory is missing, STOP and report the error.

### Step 1B: Copy Template Files

```bash
# Create .devcontainer directory
mkdir -p .devcontainer

# Copy shared files (Dockerfiles, compose, credentials)
cp "$SHARED_DIR/docker-compose.yml" ./docker-compose.yml
cp "$SHARED_DIR/Dockerfile.python" .devcontainer/Dockerfile.python
cp "$SHARED_DIR/Dockerfile.node" .devcontainer/Dockerfile.node
cp "$SHARED_DIR/setup-claude-credentials.sh" .devcontainer/setup-claude-credentials.sh

# Copy mode-specific files (devcontainer.json, firewall)
cp "$MODE_DIR/devcontainer.json" .devcontainer/devcontainer.json
cp "$MODE_DIR/init-firewall.sh" .devcontainer/init-firewall.sh

# Make scripts executable
chmod +x .devcontainer/setup-claude-credentials.sh .devcontainer/init-firewall.sh
```

**NOTE:** Advanced mode INCLUDES strict firewall script.

### Step 1C: Verify Files

```bash
echo "=== File Verification ==="
test -f docker-compose.yml && echo "✓ docker-compose.yml" || echo "✗ MISSING"
test -f .devcontainer/Dockerfile.python && echo "✓ Dockerfile.python" || echo "✗ MISSING"
test -f .devcontainer/Dockerfile.node && echo "✓ Dockerfile.node" || echo "✗ MISSING"
test -f .devcontainer/devcontainer.json && echo "✓ devcontainer.json" || echo "✗ MISSING"
test -f .devcontainer/init-firewall.sh && echo "✓ init-firewall.sh (strict)" || echo "✗ MISSING"
test -f .devcontainer/setup-claude-credentials.sh && echo "✓ setup-claude-credentials.sh" || echo "✗ MISSING"
```

**If ANY file is missing, STOP.**

## STEP 2: CUSTOMIZE TEMPLATE FILES

### Step 2A: Detect Project Type & Rename Dockerfile

```bash
# For Python: mv .devcontainer/Dockerfile.python .devcontainer/Dockerfile && rm .devcontainer/Dockerfile.node
# For Node.js: mv .devcontainer/Dockerfile.node .devcontainer/Dockerfile && rm .devcontainer/Dockerfile.python
```

### Step 2B: Customize Placeholders

Use Edit tool to replace `{{PROJECT_NAME}}` and add language-specific extensions.

## MANDATORY DOCKERFILE REQUIREMENTS

When generating a Dockerfile (not using docker-compose image directly), ALL Dockerfiles MUST include:

### Multi-Stage Build (Required for Python projects)
```dockerfile
# Stage 1: Get Node.js from official image (Issue #29)
FROM node:20-slim AS node-source

# Stage 2: Get uv from official Astral image (Python projects)
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS uv-source

# Stage 3: Main build
FROM <base-image>
```

### Mandatory Base Packages (ALWAYS install these)
```dockerfile
RUN apt-get update && apt-get install -y --no-install-recommends \
  # Core utilities
  git vim nano less procps sudo unzip wget curl ca-certificates gnupg gnupg2 \
  # JSON processing and manual pages
  jq man-db \
  # Shell and CLI enhancements
  zsh fzf \
  # GitHub CLI
  gh \
  # Network security tools (firewall)
  iptables ipset iproute2 dnsutils \
  && apt-get clean && rm -rf /var/lib/apt/lists/*
```

### Mandatory Tools (ALWAYS install these)
1. **git-delta** - Enhanced git diff
2. **ZSH with Powerlevel10k** - Full shell experience
3. **Claude Code CLI** - `npm install -g @anthropic-ai/claude-code`
4. **DeepAgents + Tavily** - AI/LLM tools (via uv/pip)
5. **Mermaid CLI** - Diagram generation

## CRITICAL: USE ACTUAL TEMPLATE FILES

**DO NOT generate simplified Dockerfiles.** Always:
1. READ `${CLAUDE_PLUGIN_ROOT}/templates/dockerfiles/Dockerfile.<language>`
2. COPY the template content EXACTLY
3. Only modify placeholder values (PROJECT_NAME, etc.)

The templates contain:
- Proper multi-stage builds
- All mandatory packages
- ZSH + Powerlevel10k configuration
- AI tools (DeepAgents, Tavily)
- Claude Code CLI

**If you generate a Dockerfile with fewer than 50 lines, you are doing it wrong.**

## Overview

Advanced Mode provides security-focused development environments with strict firewall controls and customizable domain allowlists. This mode balances security and usability by asking 7-10 configuration questions with brief explanations, using strict firewall defaults with configurable allowlists, and generating production-like configurations.

## Usage

This skill is invoked via the `/sandboxxer:advanced` command or by selecting "Advanced Mode" from the `/sandboxxer:setup` interactive mode selector.

**Command:**
```
/sandboxxer:advanced
```

The skill will:
1. Ask 7-10 configuration questions with security explanations
2. Generate a custom Dockerfile with security-hardened settings
3. Create strict firewall configuration with customizable domain allowlists
4. Set up DevContainer configuration in `.devcontainer/`
5. Configure docker-compose with selected services
6. Generate production-like network isolation

## When to Use This Skill

Use this skill when:
- User explicitly requests "Advanced mode" or "security-focused" setup
- User needs strict firewall with customizable domain allowlists
- User wants production-like configuration with some automation
- User needs balance between security and convenience
- User is working on team projects requiring network control

Do NOT use this skill when:
- User wants quickest setup (use `sandbox-setup-basic` instead)
- User wants maximum automation (use `sandbox-setup-basic` instead)
- User needs full control and step-by-step guidance (use `sandbox-setup-yolo` instead)
- User is troubleshooting an existing sandbox (use `sandbox-troubleshoot` instead)
- User wants to audit security of existing setup (use `sandbox-security` instead)

## Key Characteristics

**Advanced Mode Configuration**:

- **Base Images**: Official Docker images (python, node, etc.) as starting point
- **Dockerfile**: Language-specific templates provided as starting point (fully editable)
- **Firewall**: STRICT mode with default allowlist from `mode_defaults.advanced` (customizable)
- **Services**: Full selection available with production-like configurations
- **User Interaction**: 7-10 questions with brief explanations of trade-offs
- **Customization**: Offers to review and customize domain allowlist before generation
- **Security**: Mini-audit performed after generation with recommendations

**Best for**:
- Security-conscious development teams
- Projects requiring explicit network control
- Production-like development environments
- Users who understand Docker but want guided security setup
- Scenarios where firewall allowlist needs customization

## Firewall Configuration

Advanced Mode uses **STRICT firewall** by default with a curated allowlist of domains.

### Default Allowlist

The default allowlist is defined in `${CLAUDE_PLUGIN_ROOT}/data/allowable-domains.json` under `mode_defaults.advanced`:

```json
{
  "mode_defaults": {
    "advanced": [
      "pypi.org",           // [PKG] Python packages
      "files.pythonhosted.org",  // [PKG] Python package files
      "registry.npmjs.org",  // [PKG] npm packages
      "registry.yarnpkg.com", // [PKG] Yarn packages
      "github.com",         // [CODE] Source code repositories
      "gitlab.com",         // [CODE] Source code repositories
      "bitbucket.org"       // [CODE] Source code repositories
    ]
  }
}
```

### Category Markers

Domains are annotated with category markers for clarity:
- `[PKG]` - Package managers (pip, npm, yarn, cargo, etc.)
- `[CODE]` - Source code repositories (GitHub, GitLab, etc.)
- `[CDN]` - Content delivery networks
- `[API]` - External APIs and services
- `[AI]` - AI/ML model repositories
- `[DB]` - Database-related services
- `[TOOL]` - Development tools and utilities

### Customization

During setup, the wizard will:
1. Show the default allowlist for your project type
2. Ask: "Do you need to allow additional domains?" (e.g., company APIs, private registries)
3. Allow you to add project-specific domains with category markers
4. Generate `init-firewall.sh` with your customized allowlist

### Example Customization

```bash
# Default allowlist (Advanced mode)
ALLOWABLE_DOMAINS=(
    "pypi.org"              # [PKG] Python packages
    "files.pythonhosted.org" # [PKG] Python package files
    "github.com"            # [CODE] Source code

    # Project-specific additions
    "api.company.com"       # [API] Company internal API
    "cdn.company.com"       # [CDN] Company CDN
)
```

## File Creation Location

**CRITICAL**: All generated files must be created in the user's current working directory (project root).

### Before generating files:

1. **Verify you're in the user's project directory** (where their source code is)
2. **Create the `.devcontainer/` directory**:
   ```bash
   mkdir -p .devcontainer
   ```

### Files to create (paths relative to project root):

- `.devcontainer/Dockerfile` - Custom Dockerfile with language-specific tools and security hardening
- `docker-compose.yml` - Docker services configuration with production-like settings (in project root)
- `.devcontainer/devcontainer.json` - DevContainer configuration with strict firewall
- `.devcontainer/init-firewall.sh` - Firewall script (advanced: strict with customizable allowlist)
- `.devcontainer/setup-claude-credentials.sh` - Credentials setup (Issue #30)
- `.devcontainer/mcp.json` - MCP server configuration (optional)

### DO NOT create files in:

- `~/.claude-code/` or `~/.claude/` (home directory configs)
- `/root/.claude-code/` or any user home directory
- Any system directory like `/etc/` or `/var/`

**Why this matters**: The DevContainer configuration MUST be in the project's `.devcontainer/` folder for VS Code and Claude Code to detect and use it. Creating files in the wrong location will result in a non-functional setup.

## Workflow

### 1. Project Analysis

Thoroughly analyze the current workspace:
- Check for existing `.devcontainer/` directory (warn if exists, offer to backup)
- Detect project type from files:
  - Python: `requirements.txt`, `pyproject.toml`, `*.py`
  - Node.js: `package.json`, `*.js`, `*.ts`
  - Go: `go.mod`, `*.go`
  - Rust: `Cargo.toml`, `*.rs`
  - Fullstack: Multiple of the above
- Scan for dependencies that might need network access (API clients, CDNs, etc.)

### 2. Configuration Questions (7-10 total)

Ask these questions with brief explanations:

1. **Project type confirmation**: "I detected a [Python/Node/etc] project. Is this correct?"
   - Brief: Shows detected frameworks/dependencies

2. **Primary language**: "What's your primary programming language?"
   - Options: Python, Node.js, Go, Rust, Java, Other
   - Brief: "This determines base image and package manager allowlist"

3. **Database selection**: "What database do you need?"
   - Options: PostgreSQL, MySQL, MongoDB, Redis, None, Multiple
   - Brief: "PostgreSQL recommended for relational data, MongoDB for documents"

4. **Caching layer**: "Do you need caching?"
   - Options: Redis (recommended), Memcached, None
   - Brief: "Redis provides fast in-memory data store for sessions/caching"

5. **Additional services**: "Any other services needed?"
   - Options: Elasticsearch, RabbitMQ, Kafka, Ollama (AI), Custom
   - Brief: "Ollama requires GPU support for local AI models"

6. **Firewall mode confirmation**: "Use STRICT firewall mode (recommended for Advanced mode)?"
   - Options: Yes (strict with allowlist), Switch to Permissive
   - Brief: "Strict blocks all except allowlist; Permissive allows all except blocklist"

7. **Review default allowlist**: Show default domains for detected project type
   - "These domains will be allowed by default. Review?"

8. **Additional domains**: "Need to allow additional domains?"
   - Examples: "api.mycompany.com, cdn.example.com, registry.company.local"
   - Brief: "Add project-specific APIs, CDNs, or private registries"

9. **Pre-install dependencies**: "Pre-install dependencies from requirements.txt/package.json?"
   - Options: Yes (slower build, faster container startup), No (faster build)
   - Brief: "Pre-installing improves Docker layer caching"

10. **Auto-pull images**: "Pull Docker images now?"
    - Options: Yes (recommended), No (pull manually later)
    - Brief: "Downloads base images and services (~500MB-2GB)"

### 3. Template Generation

Use templates from `${CLAUDE_PLUGIN_ROOT}/templates/`:

**Dockerfile**:
- Source: `templates/dockerfiles/Dockerfile.<language>` (e.g., `Dockerfile.python`, `Dockerfile.node`)
- Customize with selected base image and pre-install options

**Firewall Script**:
- Source: `templates/firewall/advanced-strict.sh`
- Customize allowlist based on user selections and additional domains

**Docker Compose**:
- Source: Extract relevant services from `templates/master/docker-compose.master.yml`
- Include only selected services with production-like configurations

**Generated Files**:
1. `.devcontainer/devcontainer.json` - VS Code devcontainer configuration
2. `.devcontainer/Dockerfile` - Container build instructions
3. `.devcontainer/init-firewall.sh` - Firewall initialization with custom allowlist
4. `docker-compose.yml` - Multi-service orchestration
5. Language-specific configs (if pre-install enabled)

### 4. Security Review (Mini-Audit)

After generation, perform automated security checks:

**Firewall Verification**:
- ✓ Confirm firewall mode is `strict`
- ✓ Verify `init-firewall.sh` exists and has execute permissions
- ✓ Check allowlist contains only necessary domains
- ⚠ Warn if allowlist is too permissive (>20 domains)

**Credential Safety**:
- ✓ Verify no hardcoded passwords in `docker-compose.yml`
- ✓ Check secrets use `${localEnv:VAR}` or `.env` files
- ✓ Confirm `.env` is in `.gitignore`

**Minimal Allowlist Verification**:
- ✓ Review each allowed domain has category marker
- ✓ Suggest removing unused domains based on project analysis
- ⚠ Flag generic wildcards or overly broad domains

**Security Recommendations**:
```
✓ Firewall: STRICT mode enabled
✓ Credentials: Environment variables used
✓ Allowlist: Minimal (8 domains)
⚠ Consider removing 'cdn.example.com' if not actively used

For comprehensive security audit, run: /sandbox:audit
```

### 5. Next Steps

Provide verification commands and confirm auto-execution:

```bash
# Start services (if auto-pull was enabled)
docker compose up -d

# Verify firewall is active
docker exec <container-name> iptables -L DOCKER-USER

# Open in DevContainer
code .
# Then: Ctrl+Shift+P → "Dev Containers: Reopen in Container"

# Test connectivity (inside container)
# For PostgreSQL:
psql postgresql://user:pass@postgres:5432/db

# For Redis:
redis-cli -h redis ping

# Test firewall (should succeed)
curl https://pypi.org

# Test firewall (should fail if not in allowlist)
curl https://example.com
```

Ask: "Would you like me to run the startup commands now?"

## Templates Used

Advanced Mode uses these template sources:

1. **Dockerfile**: `templates/dockerfiles/Dockerfile.<language>`
   - Examples: `Dockerfile.python`, `Dockerfile.node`, `Dockerfile.go`
   - Multi-stage build with Node.js for corporate proxy support (Issue #29)
   - Customized with base image and pre-install options

2. **Extensions**: `${CLAUDE_PLUGIN_ROOT}/templates/extensions/extensions.advanced.json`
   - Read this file and merge with platform-specific extensions
   - Includes ~22-28 extensions covering comprehensive development tools
   - Base + language-specific + productivity + themes

3. **MCP Configuration**: `${CLAUDE_PLUGIN_ROOT}/templates/mcp/mcp.advanced.json`
   - Includes 8 MCP servers: filesystem, memory, sqlite, fetch, github, postgres, docker, brave-search
   - Copy to `.devcontainer/mcp.json`

4. **Variables**: `${CLAUDE_PLUGIN_ROOT}/templates/variables/variables.advanced.json`
   - Build args and container environment variables
   - Production-like configuration settings

5. **Firewall Script**: `templates/firewall/advanced-strict.sh`
   - Starts with `mode_defaults.advanced` allowlist
   - Customized with user-provided additional domains
   - Category markers added for documentation

6. **Docker Compose**: `${CLAUDE_PLUGIN_ROOT}/templates/compose/docker-compose.advanced.yml`
   - Production-like service configurations
   - Includes health checks, resource limits, restart policies
   - Must include credentials mount for Issue #30

7. **DevContainer Config**: `templates/base/devcontainer.json.template`
   - Customized with project name, network name, firewall mode
   - Must include credentials setup in postCreateCommand

8. **Credentials Setup**: Create `.devcontainer/setup-claude-credentials.sh` for Issue #30
   - Copies Claude credentials from host mount to container
   - Essential for credentials persistence across container rebuilds

### Credentials Persistence (Issue #30)

All advanced mode setups must include Claude credentials mounting:

1. **In docker-compose.yml**, add volume mount to app service:
   ```yaml
   app:
     volumes:
       - .:/workspace:cached
       - ~/.claude:/tmp/host-claude:ro  # Issue #30: credentials mount
   ```

2. **Create setup script** `.devcontainer/setup-claude-credentials.sh`:
   ```bash
   #!/bin/bash
   if [ -d "/tmp/host-claude" ]; then
     mkdir -p ~/.claude
     cp -r /tmp/host-claude/* ~/.claude/ 2>/dev/null || true
     echo "Claude credentials copied successfully"
   fi
   ```

3. **In devcontainer.json**, add to postCreateCommand:
   ```json
   "postStartCommand": ".devcontainer/init-firewall.sh",
   "postCreateCommand": ".devcontainer/setup-claude-credentials.sh && ..."
   ```

**Important**: Always read template files and use them as the source of truth. DO NOT use inline configuration examples without reading templates first.

## Reference Documentation

For detailed information, refer to embedded documentation in `references/`:
- `customization.md` - Full customization guide
- `security.md` - Security model and best practices
- `troubleshooting.md` - Common issues and solutions

## Integration with Other Skills

- **After setup**: Suggest running `/sandbox:audit` for comprehensive security review
- **During errors**: Automatically invoke `sandbox-troubleshoot` skill if setup fails
- **For simpler setups**: Suggest `sandbox-setup-basic` if user seems overwhelmed
- **For more control**: Suggest `sandbox-setup-yolo` if user wants step-by-step guidance
- **Updating configs**: Warn about overwriting and offer to backup existing files

## Key Principles

- **Security by default** - Always recommend STRICT firewall with minimal allowlist
- **Brief explanations** - One sentence per decision to inform without overwhelming
- **Curated allowlist** - Start with mode-appropriate defaults, customize as needed
- **Production-like configs** - Include health checks, resource limits, restart policies
- **Verify before overwriting** - Always check for existing files and offer backup
- **Balance automation and control** - Ask key questions but automate the rest
- **Document allowlist** - Use category markers to explain why each domain is allowed

## Example Invocations

**Via slash command**:
```
/sandbox:advanced
```

**Via natural language**:
- "Set up a secure Docker sandbox with firewall for my Python project"
- "I need Advanced mode setup with strict firewall"
- "Configure devcontainer with customizable domain allowlist"
- "Set up production-like development environment with security controls"
- "Create Docker sandbox with PostgreSQL and strict network rules"

## Comparison with Other Modes

**vs. Basic Mode**:
- Advanced asks 7-10 questions (Basic asks 1-3)
- Advanced allows firewall customization (Basic uses fixed defaults)
- Advanced provides brief explanations (Basic minimizes interaction)
- Advanced offers allowlist review (Basic auto-generates)

**vs. YOLO Mode**:
- Advanced asks 7-10 questions (YOLO asks 10-15+)
- Advanced provides brief explanations (YOLO provides detailed education)
- Advanced uses template-based generation (YOLO walks through each file)
- Advanced focuses on security balance (YOLO focuses on learning and full control)

## POST-GENERATION VALIDATION (MANDATORY)

After generating files, verify these conditions:

### Dockerfile Validation
```bash
# Check for multi-stage build
grep -c "^FROM.*AS" .devcontainer/Dockerfile  # Should be >= 1

# Check for mandatory packages
grep -q "git vim nano less procps" .devcontainer/Dockerfile || echo "MISSING: Core utilities"
grep -q "zsh fzf" .devcontainer/Dockerfile || echo "MISSING: Shell enhancements"
grep -q "git-delta" .devcontainer/Dockerfile || echo "MISSING: git-delta"
grep -q "powerlevel10k\|zsh-in-docker" .devcontainer/Dockerfile || echo "MISSING: ZSH theme"
grep -q "claude-code" .devcontainer/Dockerfile || echo "MISSING: Claude Code CLI"

# Check line count (should be substantial)
wc -l .devcontainer/Dockerfile  # Should be >= 50 lines
```

**If any check fails, RE-READ the template file and regenerate.**

## Completion Checklist

**Before finishing the setup, verify ALL these files exist:**

**Required files checklist:**
1. [ ] `docker-compose.yml` in project root (NOT in .devcontainer/)
2. [ ] `.devcontainer/` directory exists
3. [ ] `.devcontainer/devcontainer.json` exists with proper configuration
4. [ ] `.devcontainer/init-firewall.sh` exists and is executable (`chmod +x`)
5. [ ] `.devcontainer/setup-claude-credentials.sh` exists and is executable (`chmod +x`)
6. [ ] `.devcontainer/Dockerfile` exists (Advanced mode uses custom Dockerfile)
7. [ ] `.devcontainer/mcp.json` exists (if MCP servers configured)

**Verify Configuration Content:**
- [ ] `docker-compose.yml` includes credentials mount: `~/.claude:/tmp/host-claude:ro`
- [ ] `devcontainer.json` references docker-compose and has proper postCreateCommand
- [ ] `init-firewall.sh` contains STRICT mode with customized allowlist
- [ ] `setup-claude-credentials.sh` handles credential copying from /tmp/host-claude

## PROHIBITED FILES - NEVER CREATE THESE

If you find yourself about to write ANY of these files, you are doing the WRONG task:

- ❌ `.claude-code.json` - WRONG (this is Claude Code's sandbox config, NOT DevContainer)
- ❌ `.claude/config.json` - WRONG (this is Claude Code config, NOT DevContainer)
- ❌ `.claude-code/settings.json` - WRONG (this is Claude Code settings, NOT DevContainer)
- ❌ `/root/.claude-code/settings.json` - WRONG (wrong location entirely)
- ❌ `Dockerfile` in project root - WRONG (should be in .devcontainer/)

**If you created any of these files by mistake, DELETE THEM and create the correct DevContainer files instead.**

**If ANY required file is missing, CREATE IT NOW before completing the skill.**

**After File Creation:**
1. Make init-firewall.sh and setup-claude-credentials.sh executable
2. Inform user that files are ready
3. Provide "Next Steps" with VS Code instructions (do NOT run containers yourself)

---

**Last Updated:** 2025-12-16
**Version:** 3.0.0
