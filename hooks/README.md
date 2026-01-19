# Hooks

This directory contains Claude Code hooks for the sandboxxer plugin. Hooks extend Claude Code's behavior by executing code at specific lifecycle points.

## Available Hooks

### 1. LangSmith Tracing Hook (`stop_hook.sh`)

Sends Claude Code conversation traces to LangSmith for observability and debugging.

**Trigger:** After each Claude response (Stop event)

**Configuration:**

| Variable | Required | Description |
|----------|----------|-------------|
| `TRACE_TO_LANGSMITH` | Yes | Set to `true` to enable tracing |
| `CC_LANGSMITH_API_KEY` | Yes | Your LangSmith API key (falls back to `LANGSMITH_API_KEY`) |
| `CC_LANGSMITH_PROJECT` | Yes | LangSmith project name |
| `CC_LANGSMITH_ENVIRONMENT` | No | Custom environment label (auto-detected if not set) |
| `CLAUDE_CODE_TEAM` | No | Team identifier prefix for trace names (default: `acdc`) |
| `CC_LANGSMITH_DEBUG` | No | Set to `true` for debug logging |

For detailed information about these variables, including environment detection, trace naming, security best practices, and configuration examples, see the [Hook Environment Variables](../docs/features/VARIABLES.md#hook-environment-variables) section in the Variables Configuration Guide.

### 2. Docker Safety Hook (`hooks.json`)

Blocks or prompts for confirmation on potentially destructive Docker commands.

**Trigger:** Before tool use (PreToolUse event)

**Protections:**
- **Blocked:** `docker prune`, `docker rm -f`, `docker rmi -f`
- **Prompted:** `docker --privileged` (requires explicit approval)

### 3. Windows Support

For Windows native Claude Code (not WSL):
- `stop_hook.ps1` - PowerShell wrapper for the bash hook
- `run-hook.cmd` - Command prompt wrapper

See [README-WINDOWS.md](README-WINDOWS.md) for detailed Windows setup instructions.

## Hook Types

Claude Code supports these hook events:

| Event | Description | Use Cases |
|-------|-------------|-----------|
| `PreToolUse` | Before a tool executes | Validation, safety checks |
| `PostToolUse` | After a tool executes | Logging, cleanup |
| `Stop` | After Claude's response completes | Tracing, metrics |
| `SessionStart` | When a session begins | Initialization |
| `SessionEnd` | When a session ends | Cleanup, reporting |

## Troubleshooting

### Hook not executing

1. Verify settings.local.json syntax is valid JSON
2. Check script has execute permissions: `chmod +x script.sh`
3. Enable debug logging: `CC_LANGSMITH_DEBUG=true`
4. Check log file: `~/.claude/state/hook.log`

### LangSmith traces not appearing

1. Verify `TRACE_TO_LANGSMITH=true`
2. Check API key is valid
3. Verify project exists in LangSmith
4. Check network connectivity to api.smith.langchain.com

### Windows-specific issues

See [README-WINDOWS.md](README-WINDOWS.md) for:
- Git Bash installation
- PowerShell execution policy
- Path configuration

## See Also

- [Claude Code Hooks Documentation](https://docs.anthropic.com/claude-code/hooks)
- [LangSmith Documentation](https://docs.langchain.com/langsmith)
- [README-WINDOWS.md](README-WINDOWS.md) - Windows setup

---

**Last Updated:** 2026-01-02
**Version:** 4.6.0
