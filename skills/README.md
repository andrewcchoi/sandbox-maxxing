# Claude Code Sandbox Skills

This directory contains specialized skills for setting up, securing, and troubleshooting Claude Code sandbox environments. Each skill provides structured workflows and best practices for common sandbox operations.

## Overview

Skills are invoked through slash commands in Claude Code. When you use a command like `/devcontainer:setup`, Claude loads the corresponding skill and follows its structured workflow to ensure consistent, high-quality results.

## Available Skills

### Setup Skills

#### devcontainer-setup-basic
**Command:** `/devcontainer:setup` (Basic mode)
**When to use:** You want the simplest sandbox setup with minimal configuration.

**Features:**
- Uses sandbox templates or official images
- Docker Compose when appropriate
- No firewall (relies on container isolation only)
- Minimal questions (2-3)
- Fast setup (1-2 minutes)

**Best for:**
- First-time users
- Rapid prototyping
- Learning and tutorials
- Solo developers

**Location:** `skills/devcontainer-setup-basic/SKILL.md`

---

#### devcontainer-setup-intermediate
**Command:** `/devcontainer:setup` (Intermediate mode)
**When to use:** You want a standard sandbox with good balance of flexibility and simplicity.

**Features:**
- Custom Dockerfile for flexibility
- Permissive firewall for convenience
- Common service options (PostgreSQL, Redis, RabbitMQ)
- Moderate questions (5-8)
- Standard setup (3-5 minutes)

**Best for:**
- Regular developers
- Team projects
- Projects requiring authentication
- Moderate customization needs

**Location:** `skills/devcontainer-setup-intermediate/SKILL.md`

---

#### devcontainer-setup-advanced
**Command:** `/devcontainer:setup` (Advanced mode)
**When to use:** You need security-focused development with strict controls.

**Features:**
- Security-hardened official images
- Strict whitelist-based firewall
- Customizable domain allowlists
- Comprehensive questions (10-15)
- Detailed setup (8-12 minutes)

**Best for:**
- Security-conscious developers
- Production-like environments
- Evaluating untrusted packages
- Compliance requirements

**Location:** `skills/devcontainer-setup-advanced/SKILL.md`

**Reference Documentation:**
- `docs/features/CUSTOMIZATION.md` - Customization guide
- `docs/features/security-model.md` - Security best practices
- `docs/features/TROUBLESHOOTING.md` - Common issues

---

#### devcontainer-setup-yolo
**Command:** `/devcontainer:setup` (YOLO mode)
**When to use:** You want complete control with no restrictions.

**Features:**
- Unofficial images allowed
- Optional or custom firewall configuration
- Full access to all domain categories
- Extensive questions (15-20+)
- Custom setup (15-30 minutes)

**Best for:**
- Expert users
- Highly specialized requirements
- Custom security policies
- Experimental configurations

**Location:** `skills/devcontainer-setup-yolo/SKILL.md`

---

### Maintenance Skills

#### sandbox-troubleshoot
**Command:** `/devcontainer:troubleshoot`
**When to use:** You're experiencing problems with your sandbox environment.

**Handles:**
- Container startup failures
- Network connectivity issues
- Service connectivity problems (database, Redis, etc.)
- Firewall blocking legitimate traffic
- Permission errors
- VS Code DevContainer issues
- Claude Code CLI problems

**Features:**
- Systematic diagnostic workflow
- Problem categorization
- Step-by-step fixes
- Verification commands
- Nuclear reset option

**Best for:**
- Any sandbox-related problem
- Build failures
- Connection issues
- Configuration problems

**Location:** `skills/sandbox-troubleshoot/SKILL.md`

See also: [Troubleshooting Guide](../docs/features/TROUBLESHOOTING.md)

---

#### sandbox-security
**Command:** `/devcontainer:audit` (or manually invoked)
**When to use:** You want to audit or harden your sandbox security.

**Handles:**
- Security configuration review
- Firewall audit and recommendations
- Credential management review
- Best practices validation
- Security hardening suggestions
- Vulnerability assessment

**Features:**
- Comprehensive security checklist
- Mode-appropriate recommendations
- Actionable improvement suggestions
- Risk assessment

**Best for:**
- Pre-deployment security review
- Compliance audits
- Security-conscious development
- Learning security best practices

**Location:** `skills/sandbox-security/SKILL.md`

See also: [Security Model](../docs/features/security-model.md)

---

## Skill Directory Structure

Each skill follows a consistent structure:

```
skills/
├── README.md                          # This file
├── devcontainer-setup-basic/
│   └── SKILL.md                       # Skill definition and workflow
├── devcontainer-setup-intermediate/
│   └── SKILL.md
├── devcontainer-setup-advanced/
│   ├── SKILL.md
│   └── templates/                     # Mode-specific templates
│       ├── customization.md
│       ├── security.md
│       └── troubleshooting.md
├── devcontainer-setup-yolo/
│   └── SKILL.md
├── sandbox-troubleshoot/
│   └── SKILL.md
└── sandbox-security/
    └── SKILL.md
```

### File Descriptions

**SKILL.md**
- Skill metadata (name, description)
- When to use the skill
- Step-by-step workflow
- Decision trees and conditionals
- Verification steps
- Error handling

**templates/** (required)
- Mode-specific template files
- Dockerfile templates, configuration files
- Extensions, MCP, variables, compose files

## How Skills Work

### Invocation via Commands

Skills are typically invoked through slash commands defined in `/commands/`:

```bash
# Setup commands (choose mode interactively)
/devcontainer:setup

# Troubleshooting
/devcontainer:troubleshoot

# Security audit
/devcontainer:audit
```

See [Commands README](../commands/README.md) for full command list.

### Direct Skill Usage

Claude can also invoke skills directly when appropriate:

```
User: "I'm getting a connection refused error from PostgreSQL"
Claude: [Automatically uses sandbox-troubleshoot skill]

User: "Set up a secure development environment"
Claude: [Automatically uses devcontainer-setup-advanced skill]
```

### Skill Workflow

1. **Skill Loaded**: Claude reads SKILL.md and reference documentation
2. **Context Gathered**: Claude asks questions or examines project
3. **Workflow Executed**: Claude follows structured steps in SKILL.md
4. **Validation**: Claude verifies successful completion
5. **Documentation**: Claude provides next steps and references

## Skill Comparison

| Skill | Complexity | Questions | Time | Security | Customization |
|-------|-----------|-----------|------|----------|---------------|
| devcontainer-setup-basic | Low | 2-3 | 1-2 min | Low | Minimal |
| devcontainer-setup-intermediate | Medium | 5-8 | 3-5 min | Medium | Moderate |
| devcontainer-setup-advanced | High | 10-15 | 8-12 min | High | High |
| devcontainer-setup-yolo | Expert | 15-20+ | 15-30 min | User-controlled | Complete |
| sandbox-troubleshoot | Varies | Diagnostic | Varies | N/A | N/A |
| sandbox-security | Medium | Audit-based | 5-10 min | N/A | N/A |

## When to Use Each Setup Skill

### Choose Basic Mode When:
- First time using DevContainers
- Quick prototyping or proof-of-concept
- Learning projects
- Solo development
- Working with trusted code only

### Choose Intermediate Mode When:
- Regular team development
- Need Git/GitHub authentication
- Require common services (DB, cache, queue)
- Want flexibility without complexity
- Moderate customization needed

### Choose Advanced Mode When:
- Security is a priority
- Production-like environment needed
- Evaluating unknown/untrusted packages
- Compliance requirements
- Handling sensitive data
- Need explicit network control

### Choose YOLO Mode When:
- Expert with Docker/security knowledge
- Need unofficial/experimental images
- Custom firewall configuration required
- Building specialized environments
- Want complete control over all settings

## Skill Development

### Structure Requirements

All skills must follow this frontmatter format:

```yaml
---
name: skill-name
description: When to use this skill (shown in skill list)
---
```

### Best Practices

1. **Clear Conditionals**: Use explicit decision trees
2. **Verification Steps**: Always verify successful completion
3. **Error Handling**: Provide clear error messages and recovery steps
4. **Documentation**: Link to relevant documentation
5. **User Feedback**: Keep user informed of progress

### Testing Skills

Test skills with various scenarios:
- New projects (no existing configuration)
- Existing projects (with configuration)
- Edge cases (unusual project structures)
- Error conditions (failures, missing tools)

## Related Documentation

### Core Documentation
- [Modes Comparison](../docs/features/MODES.md) - Detailed mode comparison
- [Security Model](../docs/features/security-model.md) - Security architecture
- [Troubleshooting Guide](../docs/features/TROUBLESHOOTING.md) - Common issues and fixes

### Configuration Guides
- [Variables Guide](../docs/features/VARIABLES.md) - Environment variables and build args
- [Secrets Management](../docs/features/SECRETS.md) - Credential handling
- [MCP Configuration](../docs/features/MCP.md) - MCP server setup

### Reference
- [Development Guide](../DEVELOPMENT.md) - Plugin development
- [Contributing Guide](../CONTRIBUTING.md) - Contribution guidelines

## Examples

Each skill is demonstrated in example projects:

### Setup Skill Examples
- `docs/examples/demo-app-sandbox-basic/` - Basic mode result
- `docs/examples/demo-app-sandbox-intermediate/` - Intermediate mode result
- `docs/examples/demo-app-sandbox-advanced/` - Advanced mode result
- `docs/examples/demo-app-sandbox-yolo/` - YOLO mode result
- `docs/examples/streamlit-sandbox-basic/` - Basic mode (Python-only)

See [Examples README](../docs/examples/README.md) for detailed walkthroughs.

## Command Quick Reference

| Command | Skill Used | Purpose |
|---------|-----------|---------|
| `/devcontainer:setup` | devcontainer-setup-* | Create/update sandbox configuration |
| `/devcontainer:troubleshoot` | sandbox-troubleshoot | Diagnose and fix issues |
| `/devcontainer:audit` | sandbox-security | Security audit and hardening |

See [Commands README](../commands/README.md) for full command documentation.

## Support

### Getting Help

1. **Interactive Commands**: Use `/devcontainer:troubleshoot` for problems
2. **Documentation**: Check relevant guides in `docs/`
3. **Examples**: Review example projects in `docs/examples/`
4. **GitHub Issues**: Report bugs or request features
5. **GitHub Discussions**: Ask questions and share knowledge

### Reporting Issues

When reporting skill-related issues, include:
- Skill name and mode (if setup skill)
- Error messages or unexpected behavior
- Project structure and configuration
- Relevant logs (Docker, VS Code, Claude)
- Steps to reproduce

---

**Last Updated:** 2025-12-16
**Version:** 3.0.0
