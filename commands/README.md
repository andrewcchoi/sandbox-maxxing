# Claude Code Sandbox Commands

This directory contains slash commands for the Claude Code Sandbox Plugin. Commands provide user-friendly interfaces to the underlying skills, with smart routing and sensible defaults.

## Overview

Commands are invoked with the `/sandboxxer:` prefix in Claude Code:

```
/sandboxxer:quickstart         # Set up a new sandbox (interactive mode selection)
/sandboxxer:troubleshoot  # Diagnose and fix issues
/sandboxxer:audit         # Security audit
```

Each command loads and executes the corresponding skill with user-friendly prompts and guidance.

## Available Commands

### Primary Commands

#### `/sandboxxer:quickstart`
**File:** `commands/quickstart.md`
**Description:** Interactive quickstart setup for Claude Code Docker sandbox environment

**Usage:**
```bash
# Interactive setup with project type and firewall questions
/sandboxxer:quickstart
```

**What it does:**
1. Asks about project type (9 language options)
2. Asks about network restrictions (optional domain allowlist)
3. Generates DevContainer configuration
4. Creates docker-compose.yml with services

**Features:**
- Choose from 9 project types (Python/Node, Go, Ruby, Rust, Java, C++ Clang/GCC, PHP, PostgreSQL)
- Optional firewall with domain allowlist
- 2-3 questions for configuration
- Ready in 2-3 minutes

**When to use:**
- Creating a new sandbox environment
- Updating existing sandbox configuration
- Need specific language toolchains or firewall protection

---

#### `/sandboxxer:yolo-vibe-maxxing`
**File:** `commands/yolo-vibe-maxxing.md`
**Description:** Non-interactive YOLO vibe maxxing setup with instant defaults

**Usage:**
```bash
# Quick setup with no questions
/sandboxxer:yolo-vibe-maxxing
```

**What it does:**
1. Copies templates with sensible defaults
2. Uses Python 3.12 + Node 20 base
3. Container isolation only (no firewall)
4. Creates PostgreSQL + Redis services

**Features:**
- Zero questions asked
- Python 3.12 + Node 20 base
- Container isolation (no network firewall)
- Essential VS Code extensions
- Ready in < 1 minute

**When to use:**
- Rapid prototyping
- Python/Node projects
- Quick experimentation
- Trusted code

---

#### `/sandboxxer:troubleshoot`
**File:** `commands/troubleshoot.md`
**Skill:** sandboxxer-troubleshoot
**Description:** Diagnose and fix common Claude Code sandbox issues

**Usage:**
```bash
/sandboxxer:troubleshoot
```

**What it does:**
1. Identifies problem category
2. Runs diagnostic commands
3. Applies systematic fixes
4. Verifies resolution

**Handles:**
- Container startup failures
- Network connectivity issues
- Service connectivity problems (database, Redis, etc.)
- Firewall blocking legitimate traffic
- Permission errors
- VS Code DevContainer issues

**When to use:**
- Container won't start
- Can't connect to services
- Network errors
- Any sandbox-related problem

See also: [Troubleshooting Guide](../docs/features/TROUBLESHOOTING.md)

---

#### `/sandboxxer:audit`
**File:** `commands/audit.md`
**Skill:** sandboxxer-security
**Description:** Audit sandbox configuration for security best practices

**Usage:**
```bash
/sandboxxer:audit
```

**What it does:**
1. Reviews security configuration
2. Audits firewall rules
3. Checks credential management
4. Validates best practices
5. Provides actionable recommendations

**When to use:**
- Pre-deployment security review
- Compliance audits
- Learning security best practices
- Hardening sandbox environment

See also: [Security Model](../docs/features/SECURITY-MODEL.md)

---

#### `/sandboxxer:deploy-to-azure`
**File:** `commands/deploy-to-azure.md`
**Description:** Deploy your DevContainer environment to Azure Container Apps for cloud-based development

**Usage:**
```bash
/sandboxxer:deploy-to-azure
```

**What it does:**
1. Validates Azure prerequisites
2. Builds container image from DevContainer
3. Pushes to Azure Container Registry
4. Deploys to Azure Container Apps
5. Provides connection instructions

**Use when:**
- You want to run your sandbox in the cloud
- You need to share your development environment
- You want persistent cloud-based development

**Skill:** None (direct implementation)

---

## Command Structure

### File Format

Each command file follows this structure:

```markdown
---
description: Brief description shown in command list
---

# Command Name

[Optional: Command-specific instructions]

Use and follow the [skill-name] skill exactly as written.

[Optional: Additional guidance, routing logic, or parameters]
```

### Naming Convention

Commands follow the pattern:
- **Primary commands**: `quickstart`, `yolo-vibe-maxxing`, `troubleshoot`, `audit`

All commands use the `/sandboxxer:` namespace prefix when invoked.

## How Commands Invoke Skills

Commands serve as user-friendly entry points that delegate to skills:

```
User types: /sandboxxer:quickstart
    ↓
Command file: commands/quickstart.md loaded
    ↓
Command executes bash script with template copying
    ↓
Templates copied from: skills/_shared/templates/
    ↓
Result: DevContainer configuration created
```

## Command Quick Reference

| Command | Questions | Time | Security | Best For |
|---------|-----------|------|----------|----------|
| `/sandboxxer:quickstart` | 2-3 | 2-3 min | Optional domain allowlist | Most users, specific languages |
| `/sandboxxer:yolo-vibe-maxxing` | 0 | < 1 min | Container isolation | Quick prototyping, Python/Node |
| `/sandboxxer:troubleshoot` | Diagnostic | Varies | N/A | Problem solving |
| `/sandboxxer:audit` | Audit | 5-10 min | N/A | Security review |
| `/sandboxxer:deploy-to-azure` | Azure config | 5-15 min | Azure security | Cloud deployment |

## Usage Examples

### Setting Up a New Sandbox

**Interactive Quickstart:**
```
User: /sandboxxer:quickstart
Claude: What type of project are you setting up?
        • Python/Node (base only)
        • Go (adds Go toolchain)
        • Ruby (adds Ruby, bundler)
        ...
User: Python/Node
Claude: Do you need network restrictions?
        • No - Container isolation only
        • Yes - Domain allowlist (choose categories)
User: Yes
Claude: [Asks about domain categories]
Claude: [Generates DevContainer configuration]
```

**Non-Interactive YOLO Vibe Maxxing:**
```
User: /sandboxxer:yolo-vibe-maxxing
Claude: Creating DevContainer with defaults...
        - Base: Python 3.12 + Node 20
        - Firewall: Disabled (container isolation)
        - Services: PostgreSQL 16 + Redis 7
        ✓ Done in 18 seconds
```

### Troubleshooting

```
User: /sandboxxer:troubleshoot
Claude: What problem are you experiencing?
User: Container won't start
Claude: [Runs diagnostics, applies fixes]
```

### Security Audit

```
User: /sandboxxer:audit
Claude: [Reviews configuration]
        Security Assessment:
        ✓ Firewall: Strict mode active
        ✓ Secrets: Using Docker secrets
        ⚠ Domain allowlist: Consider adding project-specific domains
        [Provides recommendations]
```

## Command Development

### Creating a New Command

1. **Create command file** in `commands/`
2. **Add frontmatter** with description
3. **Delegate to skill** or implement routing logic
4. **Test thoroughly** with various scenarios

**Example command file:**
```markdown
---
description: Brief description for command list
---

Use and follow the skill-name skill exactly as written.

[Optional: Additional parameters or routing logic]
```

### Best Practices

1. **Keep commands simple** - Delegate complex logic to skills
2. **Clear descriptions** - Help users choose the right command
3. **Consistent naming** - Follow established patterns
4. **User-friendly** - Provide guidance and defaults
5. **Document flags** - Explain available options

### Testing Commands

Test commands with:
- New users (should be intuitive)
- Experienced users (should be efficient)
- Edge cases (unusual inputs, errors)
- Different firewall configurations

## Related Documentation

### Core Documentation
- [Skills README](../skills/README.md) - Skill details and workflows
- [Setup Options Guide](../docs/features/SETUP-OPTIONS.md) - Mode comparison and selection
- [Troubleshooting](../docs/features/TROUBLESHOOTING.md) - Common issues

### Configuration
- [DevContainer Setup](../DEVELOPMENT.md) - DevContainer configuration
- [Variables Guide](../docs/features/VARIABLES.md) - Environment configuration
- [Secrets Management](../docs/features/SECRETS.md) - Credential handling

### Examples
- [Examples README](../docs/examples/README.md) - Example projects
- [demo-app-sandbox-basic](../docs/examples/demo-app-sandbox-basic/) - Minimal configuration
- [demo-app-sandbox-advanced](../docs/examples/demo-app-sandbox-advanced/) - Domain allowlist configuration

## Plugin Integration

Commands are auto-discovered from the `commands/` directory. No explicit registration
in `plugin.json` is required. Simply place command files in `commands/` with proper
YAML frontmatter.

### Auto-Discovery

Claude Code automatically discovers commands in the `commands/` directory when:
1. Files end with `.md`
2. Files contain valid frontmatter
3. Plugin is loaded

## Support

### Getting Help

1. **Command Issues**: Check command file for description and usage
2. **Skill Issues**: See [Skills README](../skills/README.md)
3. **General Problems**: Use `/sandboxxer:troubleshoot`
4. **Security Questions**: Use `/sandboxxer:audit`
5. **Documentation**: Review [Core Documentation](#related-documentation)

### Reporting Issues

When reporting command-related issues, include:
- Command used (e.g., `/sandboxxer:quickstart` or `/sandboxxer:yolo-vibe-maxxing`)
- Expected vs actual behavior
- Error messages or logs
- Project context (language, services, etc.)

### Contributing

See [Contributing Guide](../CONTRIBUTING.md) for:
- Adding new commands
- Improving existing commands
- Documentation updates
- Testing guidelines

---

**Last Updated:** 2025-12-25
**Version:** 4.6.0
