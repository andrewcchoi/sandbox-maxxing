# Plugin Architecture

## Overview

The Claude Code DevContainer Setup plugin uses a command-based architecture with shared resources supporting interactive and quick setup workflows.

**Version 4.3.0+ Changes:**
- **Command-based workflow** - Direct bash execution with template copying (not skill-based)
- **Interactive project selection** - 9 language options with modular dockerfile partials
- **Shared resources architecture** - Templates and data consolidated to `skills/_shared/`
- **Simplified firewall** - Single init-firewall.sh script (v4.3.2)

## Components

### 1. Skills

**Active Skills:**
- `sandboxxer-troubleshoot` - Diagnostic assistant
- `sandboxxer-security` - Security auditor

**Deprecated Skills:**
- `devcontainer-setup-basic`, `devcontainer-setup-advanced`, `devcontainer-setup-yolo` (v4.6.0)

### 2. Commands

**Primary Commands:**
- `/sandboxxer:quickstart` - Interactive quickstart with project type selection
- `/sandboxxer:troubleshoot` - Invokes troubleshoot skill
- `/sandboxxer:audit` - Invokes security skill

**Setup Commands:**
- `/sandboxxer:quickstart` - Interactive DevContainer setup with mode selection
- `/sandboxxer:yolo-vibe-maxxing` - Quick setup with no questions (Python+Node base, no firewall)

### 3. Shared Resources Architecture (v4.0.0)

All templates and data files are now consolidated in `skills/_shared/` for easier maintenance and consistency.

#### Directory Structure

```
skills/
├── _shared/                           # Shared resources
│   ├── templates/                     # Template files
│   │   ├── base.dockerfile            # Base Dockerfile with markers
│   │   ├── devcontainer.json          # DevContainer configuration
│   │   ├── docker-compose.yml         # Docker Compose template
│   │   ├── setup-claude-credentials.sh # Credential persistence
│   │   ├── init-firewall.sh           # Strict iptables firewall (v4.3.2)
│   │   ├── extensions.json            # VS Code extensions (minimal)
│   │   ├── mcp.json                   # MCP server configuration
│   │   ├── variables.json             # Build/runtime variables
│   │   ├── .env.template              # Environment variables
│   │   ├── README.md                  # Template documentation (v4.3.1)
│   │   ├── partials/                  # Language-specific partials (v4.3.1)
│   │   │   ├── go.dockerfile          # Go 1.22 toolchain
│   │   │   ├── ruby.dockerfile        # Ruby 3.3 and bundler
│   │   │   ├── rust.dockerfile        # Rust toolchain
│   │   │   ├── java.dockerfile        # OpenJDK 21, Maven, Gradle
│   │   │   ├── cpp-clang.dockerfile   # Clang 17, CMake, vcpkg
│   │   │   ├── cpp-gcc.dockerfile     # GCC, CMake, vcpkg
│   │   │   ├── php.dockerfile         # PHP 8.3, Composer
│   │   │   └── postgres.dockerfile    # PostgreSQL client tools
│   │   └── data/                      # Reference catalogs (v4.3.1)
│   │       ├── allowable-domains.json # Domain categories
│   │       ├── sandbox-templates.json # Docker template images
│   │       ├── official-images.json   # Official Docker images
│   │       ├── uv-images.json         # Python UV images
│   │       ├── mcp-servers.json       # MCP server catalog
│   │       ├── secrets.json           # Secret handling patterns
│   │       ├── variables.json         # Variable catalog
│   │       ├── vscode-extensions.json # Extension catalog (comprehensive)
│   │       └── README.md              # Data file documentation
├── sandboxxer-troubleshoot/
│   └── SKILL.md                       # Troubleshooting workflow
└── sandboxxer-security/
    └── SKILL.md                       # Security audit workflow
```

#### Benefits of Shared Architecture

1. **Single source of truth** - Templates exist in one location only
2. **Easier maintenance** - Update once, applies to all modes
3. **Consistent behavior** - All skills use identical base templates
4. **Reduced duplication** - ~45 template files → ~18 files (60% reduction)
5. **Simpler skills** - Skills focus on mode-specific logic, not template management

### 4. Data Files

All data files are in `skills/_shared/data/`. See `skills/_shared/data/README.md` for details.

**Key files:**
- `sandbox-templates.json` - Docker template image registry
- `official-images.json` - Official Docker images (Python, Node, databases)
- `allowable-domains.json` - Firewall domain whitelist by category
- `uv-images.json` - Python UV images (fast package manager)
- `mcp-servers.json` - MCP server configurations
- `vscode-extensions.json` - VS Code extension catalog

Skills reference these using: `skills/_shared/data/<filename>`

## Command-Based Setup (v4.3.0+)

### Interactive Setup (`/sandboxxer:quickstart`)

**Philosophy:** Flexible configuration through guided questions

**Workflow:**
1. Ask about project type (9 options: Python/Node, Go, Ruby, Rust, Java, C++ Clang/GCC, PHP, PostgreSQL)
2. Ask about network restrictions (yes/no)
3. If firewall enabled: Select domain categories and custom domains
4. Copy and compose templates
5. Replace placeholders

**Features:**
- Base image: `python:3.12-bookworm-slim` + `node:20-bookworm-slim` multi-stage
- Language support: Modular partials appended to base dockerfile
- Firewall: Optional (strict allowlist if enabled)
- Extensions: Curated minimal set
- Questions: 2-3 (or more if firewall enabled)

**Best for:**
- Projects needing specific language toolchains
- Users wanting firewall protection
- Customizable setups

### Quick Setup (`/sandboxxer:yolo-vibe-maxxing`)

**Philosophy:** Zero questions, instant setup

**Workflow:**
1. Copy all templates without asking
2. Use base Python+Node image
3. No firewall
4. Default configuration

**Features:**
- Base image: `python:3.12-bookworm-slim` + `node:20-bookworm-slim` multi-stage
- Language support: Python 3.12 + Node 20 only
- Firewall: Disabled
- Extensions: Curated minimal set
- Questions: 0

**Best for:**
- Rapid prototyping
- Python/Node projects
- Quick experimentation
- Users who want zero interaction

### Command Comparison

| Aspect            | /sandboxxer:quickstart | /sandboxxer:yolo-vibe-maxxing |
| ----------------- | ---------------------- | ----------------------------- |
| **Questions**     | 2-3+                   | 0                             |
| **Languages**     | 9 options              | Python + Node only            |
| **Firewall**      | Optional               | Disabled                      |
| **Time**          | 1-3 min                | < 30 sec                      |
| **Customization** | Moderate               | None                          |

## Data Flow

### Setup Flow (v4.3.0+)

1. **User Invocation**
   - User runs `/sandboxxer:quickstart` (interactive) or `/sandboxxer:yolo-vibe-maxxing` (non-interactive)
   - Command executes directly (bash-based, not skill-based)

2. **Interactive Questions** (setup command only)
   - Ask about project type (Python/Node, Go, Ruby, Rust, Java, C++, PHP, PostgreSQL)
   - Ask about network restrictions (yes/no)
   - If firewall enabled: Select domain categories and custom domains

3. **Template Composition**
   - Copy `base.dockerfile` to `.devcontainer/Dockerfile`
   - Append language partial if selected (from `partials/` directory)
   - Copy other templates: devcontainer.json, docker-compose.yml, setup-claude-credentials.sh
   - Copy `init-firewall.sh` if firewall enabled

4. **Placeholder Replacement**
   - Replace `{{PROJECT_NAME}}` with current directory name
   - Customize firewall allowlist if applicable

5. **Completion**
   - Report files created
   - Provide next steps (open in VS Code, reopen in container)

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

- **After setup** → Suggest `/sandboxxer:audit` for security review
- **During errors** → Auto-invoke `/sandboxxer:troubleshoot`
- **Before production** → Recommend domain allowlist configuration review

## Version History

### Version 4.0.0 (2025-12-22)

**Major Breaking Changes:**
- **Three-mode system** - Intermediate mode removed
- **Shared resources** - Templates consolidated to `skills/_shared/`
- **Skills to commands** - Setup modes converted from skills to bash commands

**Key Changes:**
- Templates: ~45 files → ~18 files (60% reduction)
- Skills: 2965 → 915 lines total (69% reduction)
- Deleted `templates/` and `data/` root directories (duplicates)
- Created explicit firewall variants (disabled/permissive/strict)

**Migration:**
- Old template paths → Now `skills/_shared/templates/`
- Old data paths → Now `skills/_shared/data/`

### Version 3.0.0 (2025-12-19)

- Plugin renamed: `sandboxxer` → `devcontainer-setup`
- Copy-first workflow for templates
- Fixed template path discovery issues

### Version 2.0.0 (2025-12-16)

- Four-mode system (Basic, Intermediate, Advanced, YOLO) - deprecated in v4.6.0
- Data-driven configuration with JSON files
- Modular template system

### Version 1.0.0 (2025-12-12)

- Initial release with three modes
- Basic template system

## Related Documentation

### Core Docs
- [Skills README](../skills/README.md) - Detailed skill documentation
- [Commands README](../commands/README.md) - Command reference
- [Setup Options Guide](features/SETUP-OPTIONS.md) - Mode comparison and selection
- [Shared Data](../skills/_shared/templates/data/README.md) - Data file reference

### Configuration
- [Troubleshooting](features/TROUBLESHOOTING.md) - Common issues
- [Security Model](features/SECURITY-MODEL.md) - Security architecture
- [Variables Guide](features/VARIABLES.md) - Environment configuration
- [GitHub Codespaces](CODESPACES.md) - Using sandboxxer in GitHub Codespaces

### Examples
- [Examples README](examples/README.md) - Example projects
- [Minimal Configuration](examples/demo-app-sandbox-basic/) - Minimal configuration result
- [Domain Allowlist](examples/demo-app-sandbox-advanced/) - Domain allowlist result

---

**Last Updated:** 2025-12-25
**Version:** 4.6.0
