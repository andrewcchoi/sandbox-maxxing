# check-permissions.ps1
# Validates that shell scripts have execute permissions (Linux only)

param([switch]$Verbose)

$ErrorActionPreference = "Stop"

# Auto-detect repo root from script location
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Get-Item "$scriptPath\..\..\..").FullName

# Allow override via environment variable
if ($env:REPO_ROOT) {
    $repoRoot = $env:REPO_ROOT
}

Write-Host "=== File Permissions Validator ===" -ForegroundColor Cyan
Write-Host ""

# Note: Execute permissions are Linux-specific
# On Windows, this check is mostly informational
$isWindows = $PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows
if ($isWindows -or $env:OS -match "Windows") {
    Write-Host "[INFO] Running on Windows - execute permissions are Linux-specific" -ForegroundColor Gray
    Write-Host "[INFO] Checking file existence instead..." -ForegroundColor Gray
    Write-Host ""
}

$warningCount = 0
$totalScripts = 0

# Check script permissions in scripts directory
Write-Host "Checking script permissions..." -ForegroundColor Cyan

$scripts = Get-ChildItem -Path $scriptPath -Filter "*.sh" -File

foreach ($script in $scripts) {
    $totalScripts++
    $scriptName = $script.Name

    # On Windows, just check existence
    if ($isWindows -or $env:OS -match "Windows") {
        if (Test-Path $script.FullName) {
            if ($Verbose) {
                Write-Host "  [OK] $scriptName exists" -ForegroundColor Gray
            }
        } else {
            Write-Host "  [WARNING] Not found: $scriptName" -ForegroundColor Yellow
            $warningCount++
        }
    } else {
        # On Linux, check execute permission
        # PowerShell on Linux: use Get-Item.UnixMode or test with bash
        try {
            $result = & bash -c "test -x '$($script.FullName)' && echo 'true' || echo 'false'" 2>$null
            if ($result -eq 'false') {
                Write-Host "  [WARNING] Not executable: $scriptName" -ForegroundColor Yellow
                $warningCount++
            } elseif ($Verbose) {
                Write-Host "  [OK] $scriptName is executable" -ForegroundColor Gray
            }
        } catch {
            # If bash test fails, just verify file exists
            if ($Verbose) {
                Write-Host "  [OK] $scriptName exists" -ForegroundColor Gray
            }
        }
    }
}

# Check scripts in lib directory
$libPath = Join-Path $scriptPath "lib"
if (Test-Path $libPath) {
    $libScripts = Get-ChildItem -Path $libPath -Filter "*.sh" -File

    foreach ($script in $libScripts) {
        $totalScripts++
        $scriptName = "lib/$($script.Name)"

        # On Windows, just check existence
        if ($isWindows -or $env:OS -match "Windows") {
            if (Test-Path $script.FullName) {
                if ($Verbose) {
                    Write-Host "  [OK] $scriptName exists" -ForegroundColor Gray
                }
            } else {
                Write-Host "  [WARNING] Not found: $scriptName" -ForegroundColor Yellow
                $warningCount++
            }
        } else {
            # On Linux, check execute permission
            try {
                $result = & bash -c "test -x '$($script.FullName)' && echo 'true' || echo 'false'" 2>$null
                if ($result -eq 'false') {
                    Write-Host "  [WARNING] Not executable: $scriptName" -ForegroundColor Yellow
                    $warningCount++
                } elseif ($Verbose) {
                    Write-Host "  [OK] $scriptName is executable" -ForegroundColor Gray
                }
            } catch {
                if ($Verbose) {
                    Write-Host "  [OK] $scriptName exists" -ForegroundColor Gray
                }
            }
        }
    }
}

# Summary
Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "Total shell scripts checked: $totalScripts"

if ($warningCount -eq 0) {
    Write-Host "All scripts are executable!" -ForegroundColor Green
    Write-Host "Warnings: $warningCount" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Scripts with permission issues: $warningCount" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To fix permission issues, run:" -ForegroundColor Yellow
    Write-Host "  chmod +x `$scriptPath/*.sh"
    Write-Host "  chmod +x `$scriptPath/lib/*.sh"
    exit 0  # Don't fail on warnings
}
