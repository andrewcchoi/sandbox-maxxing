# Agents

This directory contains agent definitions for the sandboxxer plugin. Agents are specialized AI assistants that handle specific tasks within the plugin ecosystem.

## Available Agents

| Agent | Description | Model |
|-------|-------------|-------|
| [devcontainer-generator.md](devcontainer-generator.md) | Generates DevContainer configurations from templates | haiku |
| [devcontainer-validator.md](devcontainer-validator.md) | Comprehensive validation: file locations, JSON/YAML syntax, content structure | haiku |

## Agent Details

### devcontainer-generator

Generates DevContainer files using a **template-first workflow**. This agent intentionally has restricted tools (no Write/Edit) to enforce copying from templates rather than generating from memory.

**Triggers:**
- "generate devcontainer files"
- "create devcontainer setup from templates"
- "set up devcontainer configuration"

### devcontainer-validator

Performs **6-phase comprehensive validation**:

1. **File Location Validation** - Checks files exist in correct directories
2. **Wrong File Detection** - Catches misplaced `.claude/` or `.claude-code/` files
3. **JSON Syntax Validation** - Validates `devcontainer.json` syntax with jq/python
4. **YAML Syntax Validation** - Validates `docker-compose.yml` with docker compose/python
5. **Content Structure Validation** - Checks required fields, unreplaced placeholders
6. **Script Permission Validation** - Ensures shell scripts are executable

**Triggers:**
- "validate devcontainer"
- "check devcontainer files"
- "verify devcontainer setup"
- JSON/YAML parse errors during DevContainer build

## How Agents Work

Agents are invoked automatically by the plugin when specific tasks need to be performed. They follow structured prompts to ensure consistent, high-quality output.

### Agent vs Command vs Skill

- **Commands** (`/sandboxxer:quickstart`): User-initiated actions via slash commands
- **Skills** (`sandboxxer-troubleshoot`): Knowledge/workflow guidance Claude can invoke
- **Agents**: Specialized assistants for complex multi-step tasks with tool restrictions

### Tool Restrictions

Agents can have restricted tool access to enforce specific workflows:

| Agent | Tools | Reason |
|-------|-------|--------|
| devcontainer-generator | Bash, Read, Glob | Forces template copying (no Write/Edit) |
| devcontainer-validator | Bash, Glob, Read | Read-only validation |

## See Also

- [Commands Documentation](../commands/README.md)
- [Skills Documentation](../skills/README.md)
