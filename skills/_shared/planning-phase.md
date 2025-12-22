# DevContainer Setup: Planning Phase

## Overview

This document defines the common planning phase workflow used by all devcontainer setup skills (basic, advanced, yolo). Skills reference this workflow to ensure consistent planning before execution.

## When to Use

The planning phase is **MANDATORY** for all devcontainer setup skills. It must be executed before any implementation steps.

## Planning Phase Workflow

### Step 1: Project Discovery

Scan the project directory to understand what needs to be configured.

#### 1A: Check for Existing Configuration

```bash
# Check for existing devcontainer
if [ -d ".devcontainer" ]; then
    echo "⚠️  Existing .devcontainer/ directory found"
    echo "Contents:"
    ls -la .devcontainer/
fi

# Check for existing docker-compose
if [ -f "docker-compose.yml" ]; then
    echo "⚠️  Existing docker-compose.yml found"
fi
```

**If existing config found:**
- Ask user: "Existing devcontainer configuration detected. How should I proceed?"
  - **Backup and replace** - Move existing to `.devcontainer.backup-TIMESTAMP/`
  - **Cancel** - Stop setup
  - **Merge** - Attempt to merge configurations (advanced users only)

#### 1B: Detect Project Type

```bash
# Detect languages from project files
echo "=== Detecting Project Type ==="

# Python
[ -f "requirements.txt" ] || [ -f "pyproject.toml" ] || [ -f "setup.py" ] && echo "✓ Python detected"

# Node.js
[ -f "package.json" ] && echo "✓ Node.js detected"

# Go
[ -f "go.mod" ] || [ -f "go.sum" ] && echo "✓ Go detected"

# Rust
[ -f "Cargo.toml" ] && echo "✓ Rust detected"

# Java
[ -f "pom.xml" ] || [ -f "build.gradle" ] || [ -f "build.gradle.kts" ] && echo "✓ Java detected"

# Ruby
[ -f "Gemfile" ] && echo "✓ Ruby detected"

# PHP
[ -f "composer.json" ] && echo "✓ PHP detected"

# C++
[ -f "CMakeLists.txt" ] || [ -f "Makefile" ] && echo "✓ C++ detected"
```

#### 1C: Detect Required Services

```bash
# Scan dependency files for database/service usage
echo "=== Detecting Services ==="

# PostgreSQL
grep -qi "postgresql\|psycopg\|pg\|postgres" requirements.txt package.json Gemfile Cargo.toml 2>/dev/null && echo "✓ PostgreSQL usage detected"

# Redis
grep -qi "redis" requirements.txt package.json Gemfile Cargo.toml 2>/dev/null && echo "✓ Redis usage detected"

# MongoDB
grep -qi "mongodb\|mongoose\|pymongo" requirements.txt package.json 2>/dev/null && echo "✓ MongoDB usage detected"

# MySQL
grep -qi "mysql\|mariadb" requirements.txt package.json Gemfile 2>/dev/null && echo "✓ MySQL usage detected"
```

#### 1D: Detect Proxy Environment

```bash
# Check for proxy environment variables
if [ -n "$HTTP_PROXY" ] || [ -n "$HTTPS_PROXY" ] || [ -n "$http_proxy" ] || [ -n "$https_proxy" ]; then
    echo "✓ Proxy environment detected"
    echo "  - Recommend proxy-friendly build (skip GitHub downloads)"
fi
```

### Step 2: Create Planning Document

Write a plan file that summarizes what will be configured.

#### 2A: Determine Plan File Path

```bash
# Create plan in docs/plans/ with date prefix
PLAN_DATE=$(date +%Y-%m-%d)
PLAN_FILE="docs/plans/${PLAN_DATE}-devcontainer-setup.md"

# Ensure directory exists
mkdir -p docs/plans
```

#### 2B: Write Plan Content

Use this template for the plan file:

```markdown
# DevContainer Setup Plan - [MODE] Mode

**Date:** [YYYY-MM-DD]
**Mode:** [basic|advanced|yolo]
**Project:** [project-name]

## Detected Configuration

### Languages
- [list detected languages with file evidence]

### Services
- [list detected services with dependency evidence]

### Environment
- [proxy detected? existing config?]

## Proposed Files

### Files to Create:
1. `.devcontainer/Dockerfile` - [description based on mode]
2. `.devcontainer/devcontainer.json` - VS Code DevContainer configuration
3. `.devcontainer/setup-claude-credentials.sh` - Credentials persistence (Issue #30)
4. `.devcontainer/init-firewall.sh` - [firewall mode based on skill]
5. `docker-compose.yml` - Docker services orchestration

### Configuration Details:

**Firewall:** [none|permissive|strict]
- [mode-specific firewall description]

**Base Image:** [image selection logic]
- [why this image was chosen]

**Extensions:** [count]
- Base extensions (all modes)
- [Language-specific extensions]

**Services:** [list or "none"]
- [service configurations if detected]

**Build Args:**
- INSTALL_SHELL_EXTRAS: [true|false]
- INSTALL_DEV_TOOLS: [true|false]
- [other mode-specific args]

## Pending Questions

[List any questions that need user input before proceeding]

1. [Question 1]
2. [Question 2]
...

## Next Steps

After approval:
1. Copy templates from `skills/_shared/templates/`
2. Compose Dockerfile from base + language partials
3. Customize placeholders (project name, network name)
4. Make scripts executable
5. Verify all files created
```

### Step 3: Present Plan to User

After writing the plan file, present it to the user and wait for approval.

#### 3A: Display Plan Summary

Show user a concise summary:

```
Plan created: docs/plans/2025-12-22-devcontainer-setup.md

Summary:
- Mode: [mode]
- Languages: [list]
- Services: [list]
- Firewall: [mode]
- Files to create: 5

The plan includes [X] pending questions that need your input.
```

#### 3B: Ask Pending Questions

Use the `AskUserQuestion` tool for each pending question identified in the plan.

**Mode-specific questions:**
- **Basic mode:** 1-3 questions max (minimal interaction)
- **Advanced mode:** 7-10 questions (security-focused)
- **YOLO mode:** 15-20+ questions (complete control)

#### 3C: Request Final Approval

After all questions answered, ask for final approval:

```
Use AskUserQuestion tool:

Question: "Ready to proceed with devcontainer setup?"
Options:
- Yes - Create devcontainer configuration now
- Review plan - Show full plan file contents
- Modify - Make changes to the plan
- Cancel - Stop setup
```

If user selects "Review plan", use Read tool to show the full plan file, then ask again.

If user selects "Modify", ask what to change, update the plan file, then ask again.

### Step 4: Update Plan with User Responses

Once all questions are answered and user approves:

#### 4A: Update Plan File

Edit the plan file to record user's answers:

```markdown
## User Responses (Approved: [timestamp])

1. [Question 1]: [answer]
2. [Question 2]: [answer]
...

## Implementation Approved

User approved plan on [timestamp].
Proceeding to implementation phase.
```

### Step 5: Proceed to Implementation

After plan approval, the skill's implementation phase begins:

1. **Copy Templates** - Use `cp` commands to copy from `skills/_shared/templates/`
2. **Compose Dockerfile** - Combine base + language partials
3. **Customize Files** - Replace placeholders with actual values
4. **Verify Creation** - Confirm all files exist
5. **Post-validation** - Run verification commands

## Template Paths

All skills reference these shared template paths:

| Template | Path |
|----------|------|
| Base Dockerfile | `skills/_shared/templates/base.dockerfile` |
| Language Partials | `skills/_shared/templates/partial-*.dockerfile` |
| DevContainer Config | `skills/_shared/templates/devcontainer.json` |
| Docker Compose | `skills/_shared/templates/docker-compose.yml` |
| Credentials Script | `skills/_shared/templates/setup-claude-credentials.sh` |
| Firewall (disabled) | `skills/_shared/templates/init-firewall/disabled.sh` |
| Firewall (permissive) | `skills/_shared/templates/init-firewall/permissive.sh` |
| Firewall (strict) | `skills/_shared/templates/init-firewall/strict.sh` |
| Extensions | `skills/_shared/templates/extensions.json` |
| MCP Config | `skills/_shared/templates/mcp.json` |
| Variables | `skills/_shared/templates/variables.json` |
| Env Template | `skills/_shared/templates/.env.template` |

## Data Reference Paths

Skills can reference these shared data files:

| Data File | Path |
|-----------|------|
| Allowable Domains | `skills/_shared/data/allowable-domains.json` |
| Sandbox Templates | `skills/_shared/data/sandbox-templates.json` |
| Official Images | `skills/_shared/data/official-images.json` |

## Mode-Specific Planning Notes

### Basic Mode Planning
- **Goal:** Minimal questions, fast setup
- **Questions:** 1-3 maximum
- **Auto-detect:** Prefer automatic detection over asking
- **Defaults:** Use sensible defaults for everything
- **Firewall:** None (disabled)

### Advanced Mode Planning
- **Goal:** Security-focused with user control
- **Questions:** 7-10 with brief explanations
- **Firewall:** Strict (default), allow customization
- **Allowlist:** Show default allowlist, allow additions
- **Services:** Ask for each service with recommendations

### YOLO Mode Planning
- **Goal:** Complete control, no restrictions
- **Questions:** 15-20+ covering all options
- **Firewall:** User choice (disabled/permissive/strict/custom)
- **Images:** Allow unofficial images with warnings
- **Warnings:** Display security warnings for risky choices

## Error Handling

### Existing Configuration
If `.devcontainer/` exists:
1. Show contents to user
2. Offer to backup with timestamp
3. Get explicit approval before overwriting
4. Create backup: `mv .devcontainer .devcontainer.backup-$(date +%s)`

### Missing Tools
If required tools missing (docker, git, etc.):
1. List missing tools
2. Provide installation commands
3. Stop setup until tools available

### Permission Issues
If cannot create files/directories:
1. Check current user permissions
2. Suggest using sudo if appropriate
3. Verify write access to project directory

## Validation

After planning phase, verify:
- [ ] Plan file created in `docs/plans/`
- [ ] All questions answered
- [ ] User approved plan explicitly
- [ ] Plan file updated with approval timestamp
- [ ] Ready to proceed to skill's implementation phase

---

**Version:** 1.0.0
**Last Updated:** 2025-12-22
**Related:** Issue #49
