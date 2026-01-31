# Hooks

This directory contains Claude Code hooks for the sandboxxer plugin. Hooks extend Claude Code's behavior by executing code at specific lifecycle points.

## Available Hooks

### 1. Docker Safety Hook

Blocks or prompts for confirmation on potentially destructive Docker commands.

**Trigger:** Before tool use (PreToolUse event)

**Protections:**
- **Blocked:** `docker prune`, `docker rm -f`, `docker rmi -f`
- **Prompted:** `docker --privileged` (requires explicit approval)

### 2. Knowledge Sync Hooks

Automatically sync knowledge files between Docker volumes and the host filesystem.

#### SessionStart Hook (`sync-knowledge.sh`)

Syncs knowledge files from Docker volumes to the host when a Claude session begins.

**Trigger:** When a session starts (SessionStart event)

**What it does:**
- Finds Docker volumes with "claude" or "agent" in their names
- Syncs `plans/`, `state/`, and `projects.json` to `~/.claude/`
- Ensures knowledge persists across sessions
- Logs sync activity to `~/.claude/state/hook.log`

**Timeout:** 15 seconds

#### SessionEnd Hook (`session-end-hook.sh`)

Performs final sync and cleanup when a Claude session ends.

**Trigger:** When a session ends (SessionEnd event)

**What it does:**
- Runs final sync to capture any changes made during the session
- Logs session completion for debugging
- Provides extensibility point for future cleanup tasks

**Timeout:** 15 seconds

### 3. LangSmith Hook

Automatically sends Claude Code traces to LangSmith for observability and debugging.

**Trigger:** After each Claude response (Stop event)

**What it does:**
- Processes conversation transcripts and sends traces to LangSmith
- Tracks user messages, assistant responses, tool calls, and results
- Provides environment metadata (OS, container status, git branch)
- Enables visualization of Claude Code sessions in the LangSmith dashboard

**Required environment variables:**
- `TRACE_TO_LANGSMITH=true` - Enable/disable tracing
- `CC_LANGSMITH_API_KEY` or `LANGSMITH_API_KEY` - Your LangSmith API key
- `CC_LANGSMITH_PROJECT` - Project name for traces

**Optional environment variables:**
- `CC_LANGSMITH_DEBUG=true` - Enable debug logging
- `CC_LANGSMITH_ENVIRONMENT` - Custom environment label (defaults to `{os}-{container|native}`)

**Setup:**
```bash
export TRACE_TO_LANGSMITH=true
export CC_LANGSMITH_API_KEY=your-api-key
export CC_LANGSMITH_PROJECT=my-project
export CC_LANGSMITH_DEBUG=true  # Optional
```

**Timeout:** 30 seconds

### 4. Windows Support

For Windows native Claude Code (not WSL):
- `run-hook.cmd` - Command prompt wrapper that provides cross-platform hook execution

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

### Windows-specific issues

See [README-WINDOWS.md](README-WINDOWS.md) for:
- Git Bash installation
- PowerShell execution policy
- Path configuration

## See Also

- [Claude Code Hooks Documentation](https://docs.anthropic.com/claude-code/hooks)
- [README-WINDOWS.md](README-WINDOWS.md) - Windows setup

