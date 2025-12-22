# Claude Code Sandbox Commands

This directory contains slash commands for the Claude Code Sandbox Plugin. Commands provide user-friendly interfaces to the underlying skills, with smart routing and sensible defaults.

## Overview

Commands are invoked with the `/devcontainer:` prefix in Claude Code:

```
/devcontainer:setup         # Set up a new sandbox (interactive mode selection)
/devcontainer:troubleshoot  # Diagnose and fix issues
/devcontainer:audit         # Security audit
```

Each command loads and executes the corresponding skill with user-friendly prompts and guidance.

## Available Commands

### Primary Commands

#### `/devcontainer:setup`
**File:** `commands/setup.md`
**Skill:** Routes to mode-specific setup skill
**Description:** Set up a new Claude Code Docker sandbox environment

**Usage:**
```bash
# Interactive mode selection
/devcontainer:setup

# Quick setup with flags
/devcontainer:setup --basic          # Fastest setup
/devcontainer:setup --advanced       # Secure setup
/devcontainer:setup --yolo           # Full control
```

**What it does:**
1. Asks user to choose setup mode (or uses flag)
2. Routes to appropriate mode-specific skill:
   - `--basic` → devcontainer-setup-basic skill
   - `--advanced` → devcontainer-setup-advanced skill
   - `--yolo` → devcontainer-setup-yolo skill

**Note:** All modes now include a planning phase (v4.0.0) where Claude scans your project, creates a plan, and gets your approval before implementing.

**When to use:**
- Creating a new sandbox environment
- Updating existing sandbox configuration
- Switching between sandbox modes

---

#### `/devcontainer:troubleshoot`
**File:** `commands/troubleshoot.md`
**Skill:** sandbox-troubleshoot
**Description:** Diagnose and fix common Claude Code sandbox issues

**Usage:**
```bash
/devcontainer:troubleshoot
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

#### `/devcontainer:audit`
**File:** `commands/audit.md`
**Skill:** sandbox-security
**Description:** Audit sandbox configuration for security best practices

**Usage:**
```bash
/devcontainer:audit
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

See also: [Security Model](../docs/features/security-model.md)

---

### Mode-Specific Setup Commands

These commands directly invoke mode-specific setup skills. Most users should use `/devcontainer:setup` instead, which provides interactive mode selection.

#### `/devcontainer:basic`
**File:** `commands/basic.md`
**Skill:** devcontainer-setup-basic
**Description:** Quick sandbox setup using sandbox templates, no firewall

**Usage:**
```bash
/devcontainer:basic
```

**Equivalent to:**
```bash
/devcontainer:setup --basic
```

---

#### `/devcontainer:intermediate` [DEPRECATED]
**File:** `commands/intermediate.md`
**Status:** Deprecated in v4.0.0
**Description:** Intermediate mode has been removed. Use `/devcontainer:basic` or `/devcontainer:advanced` instead.

See `commands/intermediate.md` for migration guide.

---

#### `/devcontainer:advanced`
**File:** `commands/advanced.md`
**Skill:** devcontainer-setup-advanced
**Description:** Secure sandbox setup with strict firewall and customizable allowlist

**Usage:**
```bash
/devcontainer:advanced
```

**Equivalent to:**
```bash
/devcontainer:setup --advanced
```

---

#### `/devcontainer:yolo`
**File:** `commands/yolo.md`
**Skill:** devcontainer-setup-yolo
**Description:** Full control sandbox setup with no restrictions

**Usage:**
```bash
/devcontainer:yolo
```

**Equivalent to:**
```bash
/devcontainer:setup --yolo
```

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
- **Primary commands**: `setup`, `troubleshoot`, `audit`
- **Mode-specific**: `basic`, `advanced`, `yolo` (v4.0.0: intermediate deprecated)

All commands use the `/devcontainer:` namespace prefix when invoked.

## How Commands Invoke Skills

Commands serve as user-friendly entry points that delegate to skills:

```
User types: /devcontainer:setup --advanced
    ↓
Command file: commands/advanced.md loaded
    ↓
Command delegates to: devcontainer-setup-advanced skill
    ↓
Skill executes: skills/devcontainer-setup-advanced/SKILL.md
    ↓
Result: DevContainer configuration created
```

### Command vs Skill

| Aspect | Command | Skill |
|--------|---------|-------|
| **Purpose** | User interface | Implementation |
| **Location** | `commands/*.md` | `skills/*/SKILL.md` |
| **Invocation** | `/devcontainer:command` | Via command or directly |
| **Content** | Brief, delegates to skill | Detailed workflow |
| **User-facing** | Yes | Sometimes (expert users) |

## Command Quick Reference

| Command | Mode | Questions | Time | Security | Best For |
|---------|------|-----------|------|----------|----------|
| `/devcontainer:setup` | Interactive | Varies | Varies | Varies | Most users (choose mode) |
| `/devcontainer:basic` | Basic | 1-3 | 1-2 min | Low | Quick start, learning |
| `/devcontainer:advanced` | Advanced | 7-10 | 8-12 min | High | Security-conscious |
| `/devcontainer:yolo` | YOLO | 15-20+ | 15-30 min | User-controlled | Expert customization |
| `/devcontainer:troubleshoot` | N/A | Diagnostic | Varies | N/A | Problem solving |
| `/devcontainer:audit` | N/A | Audit | 5-10 min | N/A | Security review |

**Note:** All setup commands now include a planning phase (v4.0.0). Times include planning + implementation.

## Usage Examples

### Setting Up a New Sandbox

**Beginner (Interactive):**
```
User: /devcontainer:setup
Claude: Which setup mode do you prefer?
        [Shows mode comparison with planning phase info]
User: Basic
Claude: [Enters planning mode, scans project, creates plan]
Claude: [Presents plan for approval]
User: Approve
Claude: [Implements devcontainer configuration]
```

**Experienced (Direct):**
```
User: /devcontainer:setup --advanced
Claude: [Executes devcontainer-setup-advanced skill directly]
```

**Expert (Mode-Specific Command):**
```
User: /devcontainer:yolo
Claude: [Executes devcontainer-setup-yolo skill directly]
```

### Troubleshooting

```
User: /devcontainer:troubleshoot
Claude: What problem are you experiencing?
User: Container won't start
Claude: [Runs diagnostics, applies fixes]
```

### Security Audit

```
User: /devcontainer:audit
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
- Mode transitions (switching between modes)

## Related Documentation

### Core Documentation
- [Skills README](../skills/README.md) - Skill details and workflows
- [Modes Guide](../docs/features/MODES.md) - Mode comparison and selection
- [Troubleshooting](../docs/features/TROUBLESHOOTING.md) - Common issues

### Configuration
- [DevContainer Setup](../DEVELOPMENT.md) - DevContainer configuration
- [Variables Guide](../docs/features/VARIABLES.md) - Environment configuration
- [Secrets Management](../docs/features/SECRETS.md) - Credential handling

### Examples
- [Examples README](../docs/examples/README.md) - Example projects
- [demo-app-sandbox-basic](../docs/examples/demo-app-sandbox-basic/) - Basic mode result
- [demo-app-sandbox-advanced](../docs/examples/demo-app-sandbox-advanced/) - Advanced mode result

## Plugin Integration

### Claude Code Plugin System

Commands are defined in `.claude-plugin/plugin.json`:

```json
{
  "commands": {
    "setup": {
      "file": "commands/setup.md",
      "description": "Set up a new Claude Code Docker sandbox"
    },
    "troubleshoot": {
      "file": "commands/troubleshoot.md",
      "description": "Diagnose and fix sandbox issues"
    }
  }
}
```

### Auto-Discovery

Claude Code automatically discovers commands in the `commands/` directory when:
1. Files end with `.md`
2. Files contain valid frontmatter
3. Plugin is loaded

## Support

### Getting Help

1. **Command Issues**: Check command file for description and usage
2. **Skill Issues**: See [Skills README](../skills/README.md)
3. **General Problems**: Use `/devcontainer:troubleshoot`
4. **Security Questions**: Use `/devcontainer:audit`
5. **Documentation**: Review [Core Documentation](#related-documentation)

### Reporting Issues

When reporting command-related issues, include:
- Command used (e.g., `/devcontainer:setup --advanced`)
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

**Last Updated:** 2025-12-16
**Version:** 4.0.0
