# Hooks

This directory contains Claude Code hooks for the sandboxxer plugin. Hooks extend Claude Code's behavior by executing code at specific lifecycle points.

## Available Hooks

### 1. Docker Safety Hook (ACTIVE)

Prompts for confirmation on potentially destructive Docker commands.

**Status:** ✅ **CONFIGURED AND ACTIVE** - This hook is enabled in hooks.json and will automatically protect your Docker operations.

**Trigger:** Before tool use (PreToolUse event)

**Protections:**
- **Prompted:** `docker prune`, `docker rm`, `docker rmi`, `docker kill`, `docker compose down` (destructive operations that can cause data loss)
- **Prompted:** `docker stop`, `docker restart`, `docker pause` (disruptive operations that can cause service interruption)
- **Prompted:** `docker --privileged`, `--cap-add=ALL`, `--pid=host`, `--net=host`, root volume mounts (security risks requiring elevated access)

**Timeout:** 5 seconds

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
- Set `SANDBOXXER_SYNC_VOLUMES="vol1 vol2"` to sync only those volumes instead of scanning

**Timeout:** 15 seconds

#### SessionEnd Hook (`session-end-hook.sh`)

Records a clean shutdown of the **current session** and flushes it to disk. It never scans or copies other sandboxes' volumes (#369); the host-wide recovery scan is the SessionStart hook's job.

**Trigger:** When a session ends (SessionEnd event)

**What it does:**
- Reads `session_id` and `reason` from the hook input
- **Local mode (default):** writes a manifest to `${CLAUDE_CONFIG_DIR:-~/.claude}/state/session-end/<session_id>.json` and runs `sync`. Inside a sandboxxer container this directory is the Claude data volume.
- **Volume mode:** if `SANDBOXXER_SESSION_VOLUME` names a Docker volume (Claude on the host driving one sandbox volume), writes the manifest into that volume, runs `sync`, then copies only that volume to `~/.claude` via `SANDBOXXER_SYNC_VOLUMES=<volume> sync-knowledge.sh`
- Logs to `~/.claude/state/hook.log`

**Manifest:** `{"session_id", "ended_at", "reason", "hook_version", "mode"}`. A session with no manifest ended dirty (crash, kill or timeout).

**Timeout:** 15 seconds. Internal steps are capped at 2 + 4 + 8 seconds so the harness never kills the hook mid-write.

### 3. LangSmith Hook (OPTIONAL - NOT CONFIGURED)

Automatically sends Claude Code traces to LangSmith for observability and debugging.

**Status:** ⚠️ **NOT CONFIGURED** - This hook exists but is not enabled in hooks.json. To enable it, uncomment the Stop hook configuration and set the required environment variables.

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

### Infinite loop or hooks hanging (Linux/WSL)

**Symptom:** Claude Code hangs or enters an infinite loop when executing hooks, particularly on Linux or WSL environments.

**Cause:** Windows path normalization pattern in hooks.json is incompatible with Linux shells. The pattern `${CLAUDE_PLUGIN_ROOT//\\\\//}` attempts to replace backslashes with forward slashes for Windows compatibility, but causes shell parsing issues on Unix-like systems.

**Solution:** Remove the path normalization pattern from hook commands in hooks.json:

```diff
- "command": "\"${CLAUDE_PLUGIN_ROOT//\\\\//}/hooks/run-hook.cmd\" script.sh"
+ "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd\" script.sh"
```

**Note:** This issue was fixed in commit 8636e07. If you're experiencing this problem, ensure you're using the latest hooks.json configuration without the `//\\\\//` pattern.

### Permission denied on WSL2/Linux

**Symptom:** Hook execution fails with "Permission denied" or "unexpected end of file" errors on WSL2 or native Linux.

**Cause:** The polyglot wrapper `run-hook.cmd` has CRLF line endings instead of LF. CRLF breaks bash heredoc parsing because the delimiter `CMDBLOCK\r` doesn't match `CMDBLOCK`.

**Solution:**

1. Check line endings:
   ```bash
   file hooks/run-hook.cmd
   # Should show: "ASCII text" (NOT "with CRLF line terminators")
   ```

2. Convert to LF if needed:
   ```bash
   git add --renormalize hooks/run-hook.cmd
   # or
   sed -i 's/\r$//' hooks/run-hook.cmd
   ```

3. Verify execute permission:
   ```bash
   chmod +x hooks/run-hook.cmd
   ```

4. Test execution:
   ```bash
   ./hooks/run-hook.cmd sync-knowledge.sh
   ```

**Prevention:** The `.gitattributes` file ensures `hooks/run-hook.cmd` uses LF endings. This issue only occurs if the file was checked out before the gitattributes rule was added.

See [docs/windows/polyglot-hooks.md](../docs/windows/polyglot-hooks.md) for detailed explanation of the polyglot technique and line ending requirements.

### Windows-specific issues

See [README-WINDOWS.md](README-WINDOWS.md) for:
- Git Bash installation
- PowerShell execution policy
- Path configuration

## See Also

- [Claude Code Hooks Documentation](https://docs.anthropic.com/claude-code/hooks)
- [README-WINDOWS.md](README-WINDOWS.md) - Windows setup

