# stop_hook.ps1 - PowerShell wrapper for LangSmith tracing hook
# Calls Git Bash to execute the actual stop_hook.sh script
# This wrapper is needed because Claude Code on Windows uses /bin/bash
# which doesn't exist on Windows native systems.

# Find Git Bash
$gitBashPaths = @(
    "$env:ProgramFiles\Git\bin\bash.exe",
    "$env:ProgramFiles(x86)\Git\bin\bash.exe",
    "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe",
    "C:\Program Files\Git\bin\bash.exe"
)

$bashExe = $null
foreach ($path in $gitBashPaths) {
    if (Test-Path $path) {
        $bashExe = $path
        break
    }
}

if (-not $bashExe) {
    # Try to find bash in PATH
    $bashExe = (Get-Command bash -ErrorAction SilentlyContinue).Source
}

if (-not $bashExe) {
    Write-Error "Git Bash not found. Please install Git for Windows or add bash to PATH."
    exit 0  # Exit gracefully to not block Claude Code
}

# Get the script directory and construct path to stop_hook.sh
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$hookScript = Join-Path $scriptDir "stop_hook.sh"

# Verify the bash script exists
if (-not (Test-Path $hookScript)) {
    Write-Error "Hook script not found: $hookScript"
    exit 0
}

# Convert Windows path to Unix path for Git Bash
# C:\Users\Name\.claude\hooks\stop_hook.sh -> /c/Users/Name/.claude/hooks/stop_hook.sh
$unixHookScript = $hookScript -replace '\\', '/' -replace '^([A-Za-z]):', '/$1'

# Execute the bash script with Git Bash
# Use 'source' to run in same process and preserve environment variables
& $bashExe -c "source '$unixHookScript'"
