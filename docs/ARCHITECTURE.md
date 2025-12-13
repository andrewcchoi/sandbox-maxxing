# Plugin Architecture

## Overview

The Claude Code Sandbox plugin uses a skills-based architecture with three main components.

## Components

### 1. Skills
- `windows-sandbox-setup` - Interactive setup wizard
- `windows-sandbox-troubleshoot` - Diagnostic assistant
- `windows-sandbox-security` - Security auditor

### 2. Commands
- `/windows-sandbox:setup` - Invokes setup skill
- `/windows-sandbox:troubleshoot` - Invokes troubleshoot skill
- `/windows-sandbox:audit` - Invokes security skill

### 3. Templates
- `base/` - Flexible templates for Basic/Advanced modes
- `python/` - Python-optimized templates
- `node/` - Node.js-optimized templates
- `fullstack/` - Fullstack templates

## Data Flow

1. User invokes command
2. Command activates skill
3. Skill uses AskUserQuestion for input
4. Skill reads template files
5. Skill replaces placeholders
6. Skill writes output files
7. Skill provides next steps

## Template System

Templates use `{{PLACEHOLDER}}` syntax:
- `{{PROJECT_NAME}}` - Project name
- `{{NETWORK_NAME}}` - Docker network
- `{{FIREWALL_MODE}}` - strict or permissive
- `{{DB_NAME}}`, `{{DB_USER}}` - Database config

## Skill Integration

Skills can invoke each other:
- After setup → suggest security audit
- During errors → auto-invoke troubleshoot
