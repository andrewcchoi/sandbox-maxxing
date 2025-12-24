# Claude Code Sandbox Skills

This directory contains specialized skills for setting up, securing, and troubleshooting Claude Code sandbox environments. Each skill provides structured workflows and best practices for common sandbox operations.

## Overview

Skills are invoked through slash commands in Claude Code. When you use a command like `/devcontainer:quickstart`, Claude loads the corresponding skill and follows its structured workflow to ensure consistent, high-quality results.

## Available Skills

### Setup Skills

#### devcontainer-setup-basic
**Command:** `/devcontainer:quickstart` (Basic mode)
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

**Location:** `commands/quickstart.md`

---


#### devcontainer-setup-advanced
**Command:** `/devcontainer:quickstart` (Advanced mode)
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

**Location:** `commands/quickstart.md`

**Reference Documentation:**
- `docs/features/CUSTOMIZATION.md` - Customization guide
- `docs/features/security-model.md` - Security best practices
- `docs/features/TROUBLESHOOTING.md` - Common issues

---

#### devcontainer-setup-yolo
**Command:** `/devcontainer:quickstart` (YOLO mode)
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

**Location:** `commands/yolo-vibe-maxxing.md`

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

The skills directory uses a shared resources architecture for maintainability:

```
skills/
├── README.md                          # This file
├── _shared/                           # Shared resources
│   ├── templates/                     # Template files
│   │   ├── base.dockerfile            # Base multi-stage dockerfile
│   │   ├── devcontainer.json          # DevContainer config
│   │   ├── docker-compose.yml         # Compose template
│   │   ├── setup-claude-credentials.sh # Credential persistence
│   │   ├── init-firewall.sh           # Strict iptables firewall (v4.3.2)
│   │   ├── extensions.json            # VS Code extensions (minimal)
│   │   ├── mcp.json                   # MCP config
│   │   ├── variables.json             # Build/runtime vars
│   │   ├── .env.template              # Environment template
│   │   ├── README.md                  # Template docs (v4.3.1)
│   │   ├── partials/                  # Language partials (v4.3.1)
│   │   │   ├── go.dockerfile          # Go toolchain
│   │   │   ├── ruby.dockerfile        # Ruby toolchain
│   │   │   ├── rust.dockerfile        # Rust toolchain
│   │   │   ├── java.dockerfile        # Java toolchain
│   │   │   ├── cpp-clang.dockerfile   # C++ Clang
│   │   │   ├── cpp-gcc.dockerfile     # C++ GCC
│   │   │   ├── php.dockerfile         # PHP 8.3
│   │   │   └── postgres.dockerfile    # PostgreSQL tools
│   │   └── data/                      # Reference catalogs
│   │       ├── allowable-domains.json
│   │       ├── sandbox-templates.json
│   │       ├── official-images.json
│   │       ├── uv-images.json
│   │       ├── mcp-servers.json
│   │       ├── secrets.json
│   │       ├── variables.json
│   │       ├── vscode-extensions.json
│   │       └── README.md
├── sandbox-troubleshoot/
│   └── SKILL.md                       # Troubleshooting workflow
└── sandbox-security/
    └── SKILL.md                       # Security audit workflow
```

### File Descriptions

**SKILL.md**
- Skill metadata (name, description)
- Workflow instructions
- Validation and completion checklist

**_shared/templates/**
- Template files copied to user's devcontainer
- Base Dockerfile with language partial composition (v4.3.1)
- Firewall variants for different security modes
- All configuration files (devcontainer.json, docker-compose.yml, etc.)

**_shared/data/**
- Reference data shared across all skills
- Domain allowlists, image catalogs, extension lists

## How Skills Work

### Invocation via Commands

Skills are typically invoked through slash commands defined in `/commands/`:

```bash
# Setup commands (choose mode interactively)
/devcontainer:quickstart

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

**Current System (v4.3.0+): Command-Based Setup**

DevContainer setup is now command-based (not skill-based):

1. **User runs command**: `/devcontainer:quickstart` (interactive) or `/devcontainer:yolo-vibe-maxxing  (quick)
2. **Questions asked**: Command asks 2-3 questions (setup) or 0 questions (yolo)
3. **Templates copied**: Files copied from `skills/_shared/templates/`
4. **Placeholders replaced**: Customize with project-specific values
5. **Completion**: Report files created and next steps

**Remaining Skills:**

The two remaining skills are utilities invoked by commands:

| Skill | Command | Purpose |
|-------|---------|---------|
| sandbox-troubleshoot | `/devcontainer:troubleshoot` | Diagnose and fix issues |
| sandbox-security | `/devcontainer:audit` | Security audit and hardening |

## When to Use Each Command

### Use `/devcontainer:quickstart` (Interactive) When:
- You need specific language toolchains (Go, Ruby, Rust, Java, C++, PHP, PostgreSQL)
- You want firewall protection with domain allowlists
- You prefer guided setup with questions
- You want some customization

### Use `/devcontainer:yolo-vibe-maxxing  (Quick) When:
- You want instant setup with no questions
- Your project uses Python and/or Node.js only
- You don't need network restrictions
- You want the fastest possible setup
- You trust your development environment

### Use `/devcontainer:troubleshoot` When:
- Container fails to start
- Services won't connect (database, Redis, etc.)
- Firewall blocking legitimate traffic
- Permission errors
- Any sandbox-related problem

### Use `/devcontainer:audit` When:
- You want to review security configuration
- Before deploying to production
- Compliance audit needed
- Learning security best practices

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
- `docs/examples/demo-app-sandbox-advanced/` - Advanced mode result
- `docs/examples/demo-app-sandbox-yolo/` - YOLO mode result
- `docs/examples/streamlit-sandbox-basic/` - Basic mode (Python-only)


See [Examples README](../docs/examples/README.md) for detailed walkthroughs.

## Command Quick Reference

| Command | Skill Used | Purpose |
|---------|-----------|---------|
| `/devcontainer:quickstart` | devcontainer-setup-* | Create/update sandbox configuration |
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

**Last Updated:** 2025-12-24
**Version:** 4.5.0 (Remove obsolete planning-phase.md)
