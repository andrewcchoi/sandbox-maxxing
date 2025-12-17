---
name: sandbox-setup-advanced
description: Use when user wants security-focused development setup with strict firewall controls and customizable domain allowlists - ideal for production-like configurations, security-conscious teams, and scenarios requiring explicit network control
---

# Sandbox Setup: Advanced Mode

## Overview

Advanced Mode provides security-focused development environments with strict firewall controls and customizable domain allowlists. This mode balances security and usability by asking 7-10 configuration questions with brief explanations, using strict firewall defaults with configurable allowlists, and generating production-like configurations.

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
   - Customized with base image and pre-install options

2. **Firewall Script**: `templates/firewall/advanced-strict.sh`
   - Starts with `mode_defaults.advanced` allowlist
   - Customized with user-provided additional domains
   - Category markers added for documentation

3. **Docker Compose**: Extracted from `templates/master/docker-compose.master.yml`
   - Only includes selected services
   - Production-like configurations (health checks, resource limits, restart policies)

4. **DevContainer Config**: `templates/base/devcontainer.json.template`
   - Customized with project name, network name, firewall mode

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

---

**Last Updated:** 2025-12-16
**Version:** 2.2.1
