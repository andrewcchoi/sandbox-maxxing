# Plugin Architecture

## Overview

The Claude Code DevContainer Setup plugin uses a skills-based architecture with shared resources supporting three experience modes (Basic, Advanced, YOLO) and mandatory planning mode.

**Version 4.0.0 Changes:**
- **Planning mode mandatory** - All skills start with planning phase before implementation
- **Shared resources architecture** - Templates and data consolidated to `skills/_shared/`
- **Intermediate mode deprecated** - Three-mode system (Basic, Advanced, YOLO)
- **69% reduction in skill file sizes** - Skills reference shared resources instead of duplicating

## Components

### 1. Skills

**Active Skills:**
- `devcontainer-setup-basic` - Basic mode setup (quick, minimal questions)
- `devcontainer-setup-advanced` - Advanced mode setup (security-focused)
- `devcontainer-setup-yolo` - YOLO mode setup (full control)
- `sandbox-troubleshoot` - Diagnostic assistant
- `sandbox-security` - Security auditor

**Deprecated Skills:**
- `devcontainer-setup-intermediate` - Removed in v4.0.0 (see migration guide in `commands/intermediate.md`)

### 2. Commands

**Primary Commands:**
- `/devcontainer:setup` - Interactive mode selection (or use `--basic`, `--advanced`, `--yolo`)
- `/devcontainer:troubleshoot` - Invokes troubleshoot skill
- `/devcontainer:audit` - Invokes security skill

**Mode-Specific Commands:**
- `/devcontainer:basic` - Invokes Basic mode setup directly
- `/devcontainer:advanced` - Invokes Advanced mode setup directly
- `/devcontainer:yolo` - Invokes YOLO mode setup directly
- `/devcontainer:intermediate` - DEPRECATED (returns migration notice)

### 3. Shared Resources Architecture (v4.0.0)

All templates and data files are now consolidated in `skills/_shared/` for easier maintenance and consistency.

#### Directory Structure

```
skills/
├── _shared/                           # Shared resources (v4.0.0)
│   ├── planning-phase.md              # Common planning workflow (349 lines)
│   ├── templates/                     # Template files (18 files)
│   │   ├── base.dockerfile            # Base Dockerfile with markers
│   │   ├── partial-*.dockerfile       # Language-specific partials (8 files)
│   │   ├── devcontainer.json          # DevContainer configuration
│   │   ├── docker-compose.yml         # Docker Compose template
│   │   ├── setup-claude-credentials.sh # Credential persistence
│   │   ├── extensions.json            # VS Code extensions
│   │   ├── mcp.json                   # MCP server configuration
│   │   ├── variables.json             # Build/runtime variables
│   │   ├── .env.template              # Environment variables
│   │   └── init-firewall/             # Firewall variants
│   │       ├── disabled.sh            # Basic mode (no firewall)
│   │       ├── permissive.sh          # YOLO option (allow all)
│   │       └── strict.sh              # Advanced mode (whitelist)
│   └── data/                          # Data files (9 files)
│       ├── allowable-domains.json     # Firewall domain whitelist
│       ├── sandbox-templates.json     # Docker template images
│       ├── official-images.json       # Official Docker images
│       ├── uv-images.json             # Python UV images
│       ├── mcp-servers.json           # MCP server catalog
│       ├── secrets.json               # Secret handling patterns
│       ├── variables.json             # Variable catalog
│       ├── vscode-extensions.json     # Extension catalog
│       └── README.md                  # Data file documentation
├── devcontainer-setup-basic/
│   └── SKILL.md                       # 234 lines (79% reduction from v3.0.0)
├── devcontainer-setup-advanced/
│   └── SKILL.md                       # 309 lines (60% reduction from v3.0.0)
└── devcontainer-setup-yolo/
    └── SKILL.md                       # 372 lines (66% reduction from v3.0.0)
```

#### Benefits of Shared Architecture

1. **Single source of truth** - Templates exist in one location only
2. **Easier maintenance** - Update once, applies to all modes
3. **Consistent behavior** - All skills use identical base templates
4. **Reduced duplication** - ~45 template files → ~18 files (60% reduction)
5. **Simpler skills** - Skills focus on mode-specific logic, not template management

### 4. Planning Phase (v4.0.0)

**Mandatory for all devcontainer skills.** Workflow defined in `skills/_shared/planning-phase.md`.

#### Planning Workflow

1. **Project Discovery**
   - Scan project directory for languages, frameworks, existing configs
   - Detect required services (databases, caches, message queues)
   - Check for proxy environment variables
   - Identify security requirements

2. **Plan Creation**
   - Write plan to `docs/plans/YYYY-MM-DD-devcontainer-setup.md`
   - Include:
     - Files to be created/modified
     - Detected project details
     - Proposed configuration
     - Firewall rules (if applicable)
     - Extensions and MCP servers

3. **User Approval**
   - Present plan to user
   - Wait for explicit approval
   - Allow modifications/questions

4. **Implementation**
   - Execute skill workflow only after approval
   - Follow plan exactly
   - Report completion status

#### Planning Phase Example

```markdown
## DevContainer Setup Plan - Advanced Mode

**Project:** my-python-api
**Detected:** Python 3.12, FastAPI, PostgreSQL
**Services:** PostgreSQL, Redis

### Files to Create:
1. `.devcontainer/Dockerfile` - Multi-stage Python 3.12 build
2. `.devcontainer/devcontainer.json` - VS Code configuration
3. `.devcontainer/setup-claude-credentials.sh` - Credential persistence
4. `docker-compose.yml` - PostgreSQL + Redis services
5. `.devcontainer/init-firewall.sh` - Strict whitelist firewall

### Configuration:
- Base image: python:3.12-bookworm-slim
- Firewall: Strict (anthropic, pypi, github, postgresql domains)
- Extensions: Python, Docker, PostgreSQL (15 total)
- MCP Servers: filesystem, postgres, github
```

### 5. Data Files

All data files are in `skills/_shared/data/`. See `skills/_shared/data/README.md` for details.

**Key files:**
- `sandbox-templates.json` - Docker template image registry
- `official-images.json` - Official Docker images (Python, Node, databases)
- `allowable-domains.json` - Firewall domain whitelist by category
- `uv-images.json` - Python UV images (fast package manager)
- `mcp-servers.json` - MCP server configurations
- `vscode-extensions.json` - VS Code extension catalog

Skills reference these using: `skills/_shared/data/<filename>`

## Three-Mode System (v4.0.0)

### Basic Mode

**Philosophy:** Quick start with sensible defaults

**Target:** Beginners, rapid prototyping, learning

**Workflow:**
1. Planning phase (1-2 minutes)
2. Minimal questions (1-3)
3. Auto-detect project type
4. Use template base image
5. No firewall (container isolation only)

**Features:**
- Base image: `docker/sandbox-templates:claude-code`
- Firewall: Disabled (relies on Docker isolation)
- Extensions: Minimal essential set (5-8)
- Questions: 1-3 total
- Time: 1-2 minutes planning + 1-2 minutes implementation

**Best for:**
- First-time DevContainer users
- Quick project setup
- Learning and experimentation

### Advanced Mode

**Philosophy:** Security-first with strict controls

**Target:** Security-conscious developers, production prep, team projects

**Workflow:**
1. Planning phase (5-7 minutes)
2. Security mini-audit during planning
3. Detailed questions (7-10)
4. Strict firewall configuration
5. Minimal attack surface

**Features:**
- Base image: Official security-hardened images
- Firewall: Strict whitelist (customizable allowlist)
- Extensions: Comprehensive curated set (15-20)
- Questions: 7-10 total
- Time: 5-7 minutes planning + 8-12 minutes implementation

**Best for:**
- Production-bound projects
- Security-conscious development
- Team environments
- Compliance requirements

### YOLO Mode

**Philosophy:** Maximum flexibility, expert control

**Target:** Experts, custom environments, experimental setups

**Workflow:**
1. Planning phase (10-15 minutes)
2. Extensive customization options
3. Detailed questions (15-20+)
4. Complete control over all settings
5. Optional safety nets

**Features:**
- Base image: Any (including nightly/experimental)
- Firewall: User choice (disabled/permissive/strict/custom)
- Extensions: Full control
- Questions: 15-20+ total
- Time: 10-15 minutes planning + 15-30 minutes implementation

**Best for:**
- Expert users
- Highly customized environments
- Experimental setups
- Testing edge cases

### Mode Comparison

| Aspect | Basic | Advanced | YOLO |
|--------|-------|----------|------|
| **Planning Time** | 1-2 min | 5-7 min | 10-15 min |
| **Questions** | 1-3 | 7-10 | 15-20+ |
| **Firewall** | None | Strict | User choice |
| **Base Images** | Template only | Official only | Any |
| **Extensions** | 5-8 | 15-20 | User control |
| **Security** | Low | High | User-controlled |
| **Customization** | Minimal | Moderate | Complete |

## Data Flow

### Setup Flow (with Planning Mode)

1. **User Invocation**
   - User runs `/devcontainer:setup` or mode-specific command
   - Command activates skill

2. **Planning Phase Start**
   - Skill follows `skills/_shared/planning-phase.md`
   - Scans project directory
   - Detects languages, services, existing configuration

3. **Plan Creation**
   - Query `skills/_shared/data/` files for mode-appropriate options
   - Generate plan document
   - Write to `docs/plans/YYYY-MM-DD-devcontainer-setup.md`

4. **User Approval**
   - Present plan to user
   - Wait for explicit "approve" or modifications
   - Update plan if needed

5. **Implementation Phase**
   - Load templates from `skills/_shared/templates/`
   - Select mode-specific firewall variant if applicable
   - Replace placeholders with user choices
   - Write output files to project

6. **Completion**
   - Report files created
   - Provide next steps
   - Suggest security audit (Advanced mode)

### Template Placeholder System

Templates use `{{PLACEHOLDER}}` syntax:

**Project placeholders:**
- `{{PROJECT_NAME}}` - Project name
- `{{NETWORK_NAME}}` - Docker network name

**Image placeholders:**
- `{{BASE_IMAGE}}` - Docker base image from data files
- `{{PYTHON_VERSION}}` - Python version from official-images.json
- `{{NODE_VERSION}}` - Node.js version from official-images.json

**Configuration placeholders:**
- `{{FIREWALL_MODE}}` - disabled/permissive/strict
- `{{DB_NAME}}`, `{{DB_USER}}`, `{{DB_PASSWORD}}` - Database config
- `{{REDIS_ENABLED}}` - true/false for Redis
- `{{EXTENSIONS_JSON}}` - VS Code extensions array

## Skill Integration

Skills can invoke each other for related tasks:

- **After setup** → Suggest `/devcontainer:audit` for security review
- **During errors** → Auto-invoke `/devcontainer:troubleshoot`
- **Before production** → Recommend Advanced mode review

## Version History

### Version 4.0.0 (2025-12-22)

**Major Breaking Changes:**
- **Mandatory planning mode** - All skills require planning phase
- **Intermediate mode deprecated** - Three-mode system only
- **Shared resources** - Templates consolidated to `skills/_shared/`

**Key Changes:**
- Templates: ~45 files → ~18 files (60% reduction)
- Skills: 2965 → 915 lines total (69% reduction)
- Deleted `templates/` and `data/` root directories (duplicates)
- Created `skills/_shared/planning-phase.md` (349 lines)
- Created explicit firewall variants (disabled/permissive/strict)

**Migration:**
- Intermediate mode users → Use Basic or Advanced mode
- Old template paths → Now `skills/_shared/templates/`
- Old data paths → Now `skills/_shared/data/`

### Version 3.0.0 (2025-12-19)

- Plugin renamed: `sandboxxer` → `devcontainer-setup`
- Copy-first workflow for templates
- Fixed template path discovery issues

### Version 2.0.0 (2025-12-16)

- Four-mode system (Basic, Intermediate, Advanced, YOLO)
- Data-driven configuration with JSON files
- Modular template system

### Version 1.0.0 (2025-12-12)

- Initial release with three modes
- Basic template system

## Related Documentation

### Core Docs
- [Skills README](../skills/README.md) - Detailed skill documentation
- [Commands README](../commands/README.md) - Command reference
- [Modes Guide](features/MODES.md) - Mode comparison and selection
- [Shared Data](../skills/_shared/data/README.md) - Data file reference

### Configuration
- [Planning Phase](../skills/_shared/planning-phase.md) - Planning workflow
- [Troubleshooting](features/TROUBLESHOOTING.md) - Common issues
- [Security Model](features/security-model.md) - Security architecture
- [Variables Guide](features/VARIABLES.md) - Environment configuration

### Examples
- [Examples README](examples/README.md) - Example projects
- [Basic Example](examples/demo-app-sandbox-basic/) - Basic mode result
- [Advanced Example](examples/demo-app-sandbox-advanced/) - Advanced mode result

---

**Last Updated:** 2025-12-22
**Version:** 4.0.0
