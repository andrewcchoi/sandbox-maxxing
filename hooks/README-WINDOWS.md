# Windows Setup for LangSmith Tracing Hooks

## Problem
Claude Code on Windows native cannot execute bash hooks directly because it uses `/bin/bash` internally, which doesn't exist on Windows.

## Solution
Use the PowerShell wrapper (`stop_hook.ps1`) that calls Git Bash to execute the actual bash hook script.

## Setup Instructions

### 1. Copy Hook Scripts to Windows

Copy both hook scripts to your Windows home directory:

```powershell
# In PowerShell on Windows
Copy-Item stop_hook.sh "$env:USERPROFILE\.claude\hooks\"
Copy-Item stop_hook.ps1 "$env:USERPROFILE\.claude\hooks\"
```

### 2. Update Claude Code Settings

Edit `~/.claude/settings.local.json` (or `%USERPROFILE%\.claude\settings.local.json` on Windows):

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "powershell -ExecutionPolicy Bypass -File \"%USERPROFILE%\\.claude\\hooks\\stop_hook.ps1\""
          }
        ]
      }
    ]
  }
}
```

### 3. Configure Environment Variables

Set the required environment variables in PowerShell:

```powershell
# Add to your PowerShell profile ($PROFILE) or set system-wide
$env:TRACE_TO_LANGSMITH = "true"
$env:CC_LANGSMITH_API_KEY = "lsv2_pt_your_key_here"
$env:CC_LANGSMITH_PROJECT = "your-project-name"
$env:CC_LANGSMITH_DEBUG = "true"
```

To make these permanent, add them to your PowerShell profile or set as system environment variables.

### 4. Verify Git Bash is Installed

The PowerShell wrapper requires Git for Windows (which includes Git Bash):

```powershell
# Check if Git Bash is installed
Test-Path "$env:ProgramFiles\Git\bin\bash.exe"
```

If not installed, download from: https://git-scm.com/download/win

## Testing

1. Run Claude Code from any Windows terminal (PowerShell, cmd, etc.)
2. Execute a command that triggers the stop hook
3. Check `%USERPROFILE%\.claude\state\hook.log` for debug output
4. Verify traces appear in LangSmith with `windows-native` environment label

## Cross-Platform Configuration

If you switch between Windows native and WSL/DevContainer:

**Windows native:**
```json
"command": "powershell -ExecutionPolicy Bypass -File \"%USERPROFILE%\\.claude\\hooks\\stop_hook.ps1\""
```

**Linux/macOS/WSL/DevContainer:**
```json
"command": "bash ~/.claude/hooks/stop_hook.sh"
```

## Troubleshooting

### PowerShell Execution Policy
If you get an execution policy error:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Git Bash Not Found
The wrapper searches these paths automatically:
- `C:\Program Files\Git\bin\bash.exe`
- `C:\Program Files (x86)\Git\bin\bash.exe`
- `%LOCALAPPDATA%\Programs\Git\bin\bash.exe`
- `bash` in PATH

If Git Bash is in a different location, add it to your PATH.

### Still Getting /bin/bash Error
This error comes from Claude Code trying to use `/bin/bash` before the hook runs. The PowerShell wrapper fixes this by being directly executable by Windows.

## How It Works

1. Claude Code executes `powershell.exe` (which exists on Windows)
2. PowerShell runs `stop_hook.ps1`
3. `stop_hook.ps1` finds Git Bash
4. Git Bash executes `stop_hook.sh`
5. The bash script sends traces to LangSmith

This chain avoids the `/bin/bash` error completely.


---

**Last Updated:** 2025-12-21
**Version:** 4.6.0
