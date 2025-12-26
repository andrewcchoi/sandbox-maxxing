# Windows Troubleshooting Guide

Common issues when using the sandbox-maxxing plugin on Windows and how to fix them.

## Table of Contents
- [Installation Issues](#installation-issues)
- [Hook Execution Issues](#hook-execution-issues)
- [Path and Environment Issues](#path-and-environment-issues)
- [DevContainer Issues](#devcontainer-issues)
- [Line Ending Issues](#line-ending-issues)

---

## Installation Issues

### Git for Windows Not Found

**Symptoms:**
```
'bash' is not recognized as an internal or external command
bash.exe not found at C:\Program Files\Git\bin\bash.exe
```

**Solution:**

1. **Install Git for Windows**: https://git-scm.com/download/win
2. **Verify installation**:
   ```powershell
   Test-Path "C:\Program Files\Git\bin\bash.exe"
   # Should return: True
   ```
3. **Alternative locations** (if installed elsewhere):
   - `C:\Program Files (x86)\Git\bin\bash.exe`
   - `%LOCALAPPDATA%\Programs\Git\bin\bash.exe`

4. **Update run-hook.cmd** if Git is in a custom location:
   ```cmd
   REM Change this line in run-hook.cmd:
   "C:\Program Files\Git\bin\bash.exe" -l -c "..."
   REM To your actual Git Bash path
   ```

---

## Hook Execution Issues

### Hooks Open in Text Editor Instead of Running

**Symptoms:**
- `.sh` file opens in Notepad or default text editor
- Hook doesn't execute

**Cause:** `hooks.json` references `.sh` file directly instead of using wrapper.

**Solution:**

Check `hooks/hooks.json` - it should reference `run-hook.cmd`:
```json
// ❌ Wrong
"command": "${CLAUDE_PLUGIN_ROOT}/hooks/my-script.sh"

// ✅ Correct
"command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd\" my-script.sh"
```

### "cygpath: command not found"

**Symptoms:**
```
hooks/run-hook.cmd: line X: cygpath: command not found
```

**Cause:** Bash not running as login shell (missing `-l` flag).

**Solution:**

Verify `run-hook.cmd` has the `-l` flag:
```cmd
"C:\Program Files\Git\bin\bash.exe" -l -c "..."
                                    ^^^ Must be present
```

### "jq: command not found" or "stat: command not found"

**Symptoms:**
Hook script fails with missing command errors.

**Cause:** PATH not set up in Git Bash.

**Solutions:**

1. **Ensure `-l` flag** is used (login shell sets up PATH)
2. **Manually add to PATH** in PowerShell:
   ```powershell
   $env:PATH += ";C:\Program Files\Git\usr\bin"
   ```
3. **Check Git Bash installation** is complete (not portable version)

---

## Path and Environment Issues

### ${CLAUDE_PLUGIN_ROOT} Contains Spaces

**Symptoms:**
```
No such file or directory: C:\Program
(Path gets truncated at space)
```

**Solution:**

Ensure paths are **quoted** in `hooks.json`:
```json
// ❌ Wrong
"command": "${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd verify.sh"

// ✅ Correct
"command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd\" verify.sh"
```

### Backslash vs Forward Slash Issues

**Symptoms:**
```
Path error: C:\path/to/file (mixed separators)
```

**Solution:**

The polyglot wrapper handles this via `cygpath -u`:
```cmd
"C:\Program Files\Git\bin\bash.exe" -l -c "cd \"$(cygpath -u \"%SCRIPT_DIR%\")\" && \"./%SCRIPT_NAME%\""
                                                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^
                                                  Converts C:\foo to /c/foo
```

### %USERPROFILE% vs $HOME

**Symptoms:**
Paths work on Linux but not Windows.

**Windows Equivalents:**
| Windows | Unix | Path |
|---------|------|------|
| `%USERPROFILE%` | `$HOME` | `C:\Users\Name` |
| `%APPDATA%` | `~/.config` | `C:\Users\Name\AppData\Roaming` |
| `%LOCALAPPDATA%` | `~/.local` | `C:\Users\Name\AppData\Local` |

**Solution:**

In bash scripts, use `$HOME` (works on both):
```bash
# ✅ Cross-platform
"$HOME/.claude/hooks/stop_hook.sh"

# ❌ Windows-only
"%USERPROFILE%\.claude\hooks\stop_hook.sh"
```

---

## DevContainer Issues

### Docker Desktop Not Running

**Symptoms:**
```
Cannot connect to Docker daemon
Docker Desktop not started
```

**Solution:**

1. **Start Docker Desktop**
2. **Check WSL 2 backend** is enabled:
   - Docker Desktop → Settings → General
   - Enable "Use the WSL 2 based engine"
3. **Verify Docker is running**:
   ```powershell
   docker ps
   ```

### DevContainer Stuck on "Starting Dev Container"

**Symptoms:**
VS Code shows "Starting..." indefinitely.

**Solutions:**

1. **Check Docker logs**:
   ```powershell
   docker-compose logs
   ```
2. **Rebuild container**:
   - VS Code: Command Palette → "Dev Containers: Rebuild Container"
3. **Check Dockerfile syntax** (Windows line endings can cause issues)

### Volume Mounts Don't Work

**Symptoms:**
Files not syncing between host and container.

**Cause:** Windows path format in docker-compose.yml.

**Solution:**

Use forward slashes even on Windows:
```yaml
# ✅ Works on Windows and Linux
volumes:
  - ./:/workspace

# ❌ May fail on Windows
volumes:
  - .\:\workspace
```

---

## Line Ending Issues

### "Bad interpreter: /bin/bash^M"

**Symptoms:**
```
bash: ./script.sh: /bin/bash^M: bad interpreter: No such file or directory
```

**Cause:** Script has Windows CRLF line endings instead of Unix LF.

**Solutions:**

1. **Convert line endings** (Git Bash):
   ```bash
   dos2unix script.sh
   # Or
   sed -i 's/\r$//' script.sh
   ```

2. **Configure Git** to prevent CRLF conversion:
   ```bash
   git config core.autocrlf input
   ```

3. **EditorConfig** (if using VS Code):
   ```ini
   # .editorconfig
   [*.sh]
   end_of_line = lf

   [*.cmd]
   end_of_line = crlf
   ```

4. **Git attributes**:
   ```gitattributes
   # .gitattributes
   *.sh text eol=lf
   *.cmd text eol=crlf
   ```

### Git Auto-Converts Line Endings

**Symptoms:**
Committed files work on Windows but fail on Linux.

**Solution:**

Set core.autocrlf to `input`:
```bash
git config --global core.autocrlf input
```

Options:
- `input` - Convert CRLF → LF on commit, no conversion on checkout (recommended)
- `false` - Never convert (use with .gitattributes)
- `true` - Convert to CRLF on checkout (causes issues for scripts)

---

## PowerShell Execution Policy

### "Running scripts is disabled"

**Symptoms:**
```
.\script.ps1 : File cannot be loaded because running scripts is disabled
```

**Solution:**

Allow script execution:
```powershell
# For current user only (recommended)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# To run a single script
powershell -ExecutionPolicy Bypass -File script.ps1
```

---

## Testing Hooks on Windows

### Quick Hook Test

**PowerShell:**
```powershell
cd hooks
.\run-hook.cmd verify-template-match.sh
```

**CMD:**
```cmd
cd hooks
run-hook.cmd verify-template-match.sh
```

**Git Bash:**
```bash
cd hooks
./run-hook.cmd verify-template-match.sh
```

### Test with Environment Variables

```powershell
$env:CLAUDE_PLUGIN_ROOT = "D:\path\to\sandbox-maxxing"
cmd /c "D:\path\to\sandbox-maxxing\hooks\run-hook.cmd verify-template-match.sh"
```

### Enable Debug Output

Add to hook scripts:
```bash
#!/bin/bash
set -x  # Print each command before executing
# ... rest of script
```

---

## Getting Help

If you're still stuck after trying these solutions:

1. **Check Git Bash installation**:
   ```powershell
   & "C:\Program Files\Git\bin\bash.exe" --version
   ```

2. **Verify hook wrapper syntax** in `run-hook.cmd`

3. **Test bash script directly**:
   ```bash
   bash hooks/verify-template-match.sh
   ```

4. **Check Claude Code logs** for error messages

5. **Open an issue** with:
   - Windows version
   - Git for Windows version
   - Full error message
   - Output of `echo %CLAUDE_PLUGIN_ROOT%`

---

**Last Updated:** 2025-12-25
**Version:** 4.6.0
**Platform**: Windows 10/11
