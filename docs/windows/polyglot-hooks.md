# Cross-Platform Polyglot Hooks for Windows and Linux

## Overview

The sandbox-maxxing plugin uses **polyglot wrapper scripts** to ensure hooks work seamlessly on both Windows and Unix-based systems (Linux/macOS/WSL).

This technique is adapted from the [superpowers plugin](https://github.com/obra/superpowers) and allows a single hook configuration to work across all platforms.

## The Problem

Claude Code plugins execute hooks through the system's default shell:
- **Windows**: CMD.exe (Command Prompt)
- **Linux/macOS**: bash or sh
- **WSL**: bash

This creates challenges:
1. **Script execution**: Windows CMD cannot execute `.sh` (bash) files directly
2. **Path format**: Windows uses backslashes (`C:\path`), Unix uses forward slashes (`/path`)
3. **Environment variables**: `$VAR` syntax doesn't work in CMD
4. **Bash not in PATH**: Even with Git Bash installed, `bash` isn't available when CMD runs

## The Solution: Polyglot `.cmd` Wrapper

A **polyglot script** is valid syntax in multiple languages simultaneously. Our `run-hook.cmd` wrapper is valid in both CMD and bash.

### How It Works

The key is this structure at the start of the file:

```cmd
: << 'CMDBLOCK'
@echo off
REM Windows batch commands here
exit /b
CMDBLOCK

# Unix shell commands here
```

#### On Windows (CMD.exe)

1. `:` is interpreted as a **label** (like `:label`), CMD ignores `<< 'CMDBLOCK'`
2. `@echo off` suppresses command echoing
3. Batch commands execute normally
4. `exit /b` terminates CMD execution before reaching Unix code
5. Everything after `CMDBLOCK` is never seen by CMD

#### On Unix (bash/sh)

1. `:` is a **no-op command** (does nothing)
2. `<< 'CMDBLOCK'` starts a **heredoc** that consumes all text until `CMDBLOCK`
3. All batch commands are consumed by the heredoc (ignored)
4. `# Unix shell commands here` executes normally

## File Structure

```
hooks/
├── hooks.json                      # Hook configuration (platform-agnostic)
├── run-hook.cmd                    # Polyglot wrapper (works everywhere)
├── verify-template-match.sh        # Actual hook logic (bash)
└── verify-devcontainer-complete.sh # Actual hook logic (bash)
```

### hooks.json

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd\" verify-template-match.sh"
          }
        ]
      }
    ]
  }
}
```

**Key points:**
- Path is **quoted** because `${CLAUDE_PLUGIN_ROOT}` may contain spaces
- References the **`.cmd` wrapper**, not the `.sh` file directly
- Passes the `.sh` script name as an argument
- Same config works on **all platforms**

## The run-hook.cmd Polyglot Wrapper

```cmd
: << 'CMDBLOCK'
@echo off
REM ============================================================================
REM Cross-Platform Polyglot Hook Runner
REM ============================================================================
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_NAME=%~1"
if "%SCRIPT_NAME%"=="" (
    echo run-hook.cmd: missing script name >&2
    exit /b 1
)
"C:\Program Files\Git\bin\bash.exe" -l -c "cd \"$(cygpath -u \"%SCRIPT_DIR%\")\" && \"./%SCRIPT_NAME%\""
exit /b
CMDBLOCK

# ============================================================================
# Unix shell execution starts here
# ============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
SCRIPT_NAME="$1"
if [ -z "$SCRIPT_NAME" ]; then
    echo "run-hook.cmd: missing script name" >&2
    exit 1
fi
shift
"${SCRIPT_DIR}/${SCRIPT_NAME}" "$@"
```

### Windows Section Explained

- `%~dp0` - Gets directory where the wrapper is located
- `%~1` - Gets first argument (script name)
- `"C:\Program Files\Git\bin\bash.exe"` - Full path to Git Bash
- `-l` - Login shell flag (sets up proper PATH with Unix utilities)
- `cygpath -u` - Converts Windows path to Unix format (`C:\foo` → `/c/foo`)

### Unix Section Explained

- `${BASH_SOURCE[0]:-$0}` - Gets script path (works in sourced scripts too)
- `dirname` - Extracts directory path
- `shift` - Removes first argument, passes remaining args to script

## Requirements

### Windows
- **Git for Windows** must be installed
  - Download: https://git-scm.com/download/win
  - Provides `bash.exe` and `cygpath` utilities
  - Default installation path: `C:\Program Files\Git\bin\bash.exe`

### Linux/macOS/WSL
- Standard bash or sh shell (already installed)
- Execute permission on `.cmd` file: `chmod +x run-hook.cmd`

## Writing Cross-Platform Hook Scripts

Your actual hook logic goes in `.sh` files. To ensure they work when called via Git Bash on Windows:

### ✅ Best Practices

1. **Use pure bash builtins** when possible
2. **Use `$(command)` syntax** instead of backticks
3. **Quote all variable expansions**: `"$VAR"`
4. **Use `printf`** or here-docs for output
5. **Test commands are available**: `command -v jq >/dev/null 2>&1`

### ⚠️ Be Careful With

- **External utilities** (sed, awk, grep) - they work but require `-l` flag on bash
- **stat command** - different options on BSD vs GNU (use fallback)
- **Hardcoded paths** - use relative paths or `$HOME`

### Example: Cross-Platform stat Usage

```bash
# Cross-platform file size check
SIZE=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
```

This tries:
1. BSD stat format (macOS): `-f%z`
2. GNU stat format (Linux): `-c%s`
3. Fallback: `0` if both fail

## Troubleshooting

### "bash is not recognized" or "bash.exe not found"

**Cause**: Git for Windows not installed, or installed in non-standard location.

**Solution 1**: Install Git for Windows from https://git-scm.com/download/win

**Solution 2**: If installed elsewhere, update the path in `run-hook.cmd`:
```cmd
"C:\Program Files\Git\bin\bash.exe"  ← Change this line
```

Common alternative locations:
- `C:\Program Files (x86)\Git\bin\bash.exe`
- `%LOCALAPPDATA%\Programs\Git\bin\bash.exe`

### "cygpath: command not found"

**Cause**: Bash isn't running as a login shell.

**Solution**: Ensure the `-l` flag is present in the wrapper:
```cmd
"C:\Program Files\Git\bin\bash.exe" -l -c "..."
                                    ^^^ Must have this
```

### "dirname: command not found" or "jq: command not found"

**Cause**: PATH not set up properly in Git Bash.

**Solution**: The `-l` (login) flag should fix this. If not, verify Git Bash installation.

### Script opens in text editor instead of running

**Cause**: `hooks.json` is pointing directly to the `.sh` file.

**Solution**: Update `hooks.json` to reference the `.cmd` wrapper:
```json
// Wrong
"command": "${CLAUDE_PLUGIN_ROOT}/hooks/my-script.sh"

// Correct
"command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd\" my-script.sh"
```

### Hook works in terminal but not from Claude Code

**Cause**: Different environment when Claude Code runs hooks.

**Solution**: Test by simulating Claude Code's environment:

**PowerShell:**
```powershell
$env:CLAUDE_PLUGIN_ROOT = "D:\path\to\plugin"
cmd /c "D:\path\to\plugin\hooks\run-hook.cmd verify-template-match.sh"
```

**CMD:**
```cmd
set CLAUDE_PLUGIN_ROOT=D:\path\to\plugin
D:\path\to\plugin\hooks\run-hook.cmd verify-template-match.sh
```

### Paths have weird `\/` or `\\` issues

**Cause**: Mixing Windows and Unix path separators.

**Solution**: Use `cygpath -u` to convert entire paths:
```cmd
"C:\Program Files\Git\bin\bash.exe" -l -c "cd \"$(cygpath -u \"%SCRIPT_DIR%\")\" && \"./%SCRIPT_NAME%\""
```

## Testing Your Hooks

### On Linux/macOS/WSL

```bash
cd hooks/
./run-hook.cmd verify-template-match.sh
```

### On Windows (PowerShell)

```powershell
cd hooks
.\run-hook.cmd verify-template-match.sh
```

### On Windows (CMD)

```cmd
cd hooks
run-hook.cmd verify-template-match.sh
```

All three should work if the wrapper is correctly implemented!

## Comparison with Other Approaches

| Approach | Files | Maintenance | Dependencies |
|----------|-------|-------------|--------------|
| **Polyglot wrapper** | 1 wrapper + N scripts | Low | Git Bash |
| Separate .ps1 + .sh | 2 wrappers + N scripts | Medium | PowerShell, Bash |
| Pure rewrite | 2N scripts (both languages) | High | None |
| Node.js wrapper | 1 wrapper + N scripts | Low | Node.js |

**Polyglot is recommended** because:
- ✅ Single `hooks.json` for all platforms
- ✅ No code duplication
- ✅ Git Bash is common on Windows dev machines
- ✅ Proven pattern from superpowers plugin

## References

- **Original technique**: [superpowers plugin](https://github.com/obra/superpowers/blob/main/docs/windows/polyglot-hooks.md)
- **Claude Code hooks**: See Claude Code documentation
- **Git for Windows**: https://git-scm.com/download/win
- **Polyglot programming**: https://en.wikipedia.org/wiki/Polyglot_(computing)

---

**Last Updated**: 2025-12-22
**Version**: 1.0.0
**Adapted from**: superpowers plugin by Jesse Vincent (obra)
