# Windows Hook Setup Guide

## Problem
Claude Code on Windows native cannot execute bash hooks directly because it uses `/bin/bash` internally, which doesn't exist on Windows.

## Solution
Use the `run-hook.cmd` wrapper that provides cross-platform hook execution on Windows.

## Setup Instructions

### 1. Hook Configuration

The Sandboxxer plugin includes hooks that work cross-platform through the `run-hook.cmd` wrapper. No manual copying is needed - hooks are automatically available when the plugin is installed.

### 2. Verify Git Bash is Installed

The PowerShell wrapper requires Git for Windows (which includes Git Bash):

```powershell
# Check if Git Bash is installed
Test-Path "$env:ProgramFiles\Git\bin\bash.exe"
```

If not installed, download from: https://git-scm.com/download/win

## Testing

1. Run Claude Code from any Windows terminal (PowerShell, cmd, etc.)
2. Hooks will execute automatically via `run-hook.cmd`
3. Check `%USERPROFILE%\.claude\state\hook.log` for debug output (if hooks create logs)

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

1. Claude Code executes `run-hook.cmd` (Windows batch script)
2. `run-hook.cmd` locates Git Bash
3. Git Bash executes the specified hook script (e.g., `sync-knowledge.sh`, `docker-safety-hook.sh`)
4. The bash script performs its hook logic

This approach avoids the `/bin/bash` error completely.


