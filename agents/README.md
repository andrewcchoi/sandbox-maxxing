# Agents

This directory contains agent definitions for the sandboxxer plugin. Agents are specialized AI assistants that handle specific tasks within the plugin ecosystem.

## Available Agents

| Agent | Description |
|-------|-------------|
| [devcontainer-generator.md](devcontainer-generator.md) | Generates DevContainer configurations based on project requirements |
| [devcontainer-validator.md](devcontainer-validator.md) | Validates DevContainer configurations for correctness and security |

## How Agents Work

Agents are invoked automatically by the plugin when specific tasks need to be performed. They follow structured prompts to ensure consistent, high-quality output.

### Agent vs Command vs Skill

- **Commands** (`/sandboxxer:quickstart`): User-initiated actions
- **Skills** (`sandboxxer-troubleshoot`): Reusable capabilities Claude can invoke
- **Agents**: Specialized assistants for complex multi-step tasks

## See Also

- [Commands Documentation](../commands/README.md)
- [Skills Documentation](../skills/README.md)
