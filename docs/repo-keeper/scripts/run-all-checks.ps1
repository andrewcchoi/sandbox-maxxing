# run-all-checks.ps1
# Orchestrates all validation scripts in tiers

param(
    [switch]$Quick,
    [switch]$Full,
    [switch]$Verbose,
    [switch]$FixCrlf
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = "/workspace"

# Determine tier
$tier = "standard"
if ($Quick) { $tier = "quick" }
if ($Full) { $tier = "full" }

# Get version from plugin.json
$pluginJsonPath = Join-Path $repoRoot ".claude-plugin/plugin.json"
if (Test-Path $pluginJsonPath) {
    $pluginJson = Get-Content $pluginJsonPath -Raw | ConvertFrom-Json
    $version = $pluginJson.version
} else {
    $version = "unknown"
}

Write-Host "=== Repository Validation Suite ===" -ForegroundColor Cyan
Write-Host "Version: $version"
Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd')"
Write-Host "Tier: $tier"
Write-Host ""

# Fix CRLF if requested
if ($FixCrlf) {
    Write-Host "Fixing line endings..." -ForegroundColor Cyan
    $shellScripts = Get-ChildItem -Path $scriptDir -Filter "*.sh" -File
    foreach ($script in $shellScripts) {
        $content = Get-Content $script.FullName -Raw
        $content = $content -replace "`r`n", "`n"
        Set-Content -Path $script.FullName -Value $content -NoNewline
    }
    Write-Host "✓ Line endings fixed" -ForegroundColor Green
    Write-Host ""
}

# Counters
$totalChecks = 0
$passedChecks = 0
$failedChecks = 0
$warnings = 0
$errors = 0

# Function to run a check
function Run-Check {
    param(
        [int]$CheckNum,
        [int]$TotalInTier,
        [string]$CheckName,
        [string]$ScriptName,
        [string[]]$Args = @()
    )

    $script:totalChecks++

    # Build verbose flag if needed
    if ($script:Verbose) {
        $Args = @("-Verbose") + $Args
    }

    # Prepare display name with padding
    $displayName = $CheckName.PadRight(30)
    Write-Host "  [$CheckNum/$TotalInTier] $displayName" -NoNewline

    # Determine if PowerShell or Bash script
    $scriptPath = Join-Path $scriptDir $ScriptName
    $isPowerShell = $ScriptName -match '\.ps1$'

    # Capture output and exit code
    $output = ""
    $exitCode = 0

    try {
        if ($isPowerShell) {
            # Run PowerShell script
            if ($Args.Count -gt 0) {
                $output = & $scriptPath @Args 2>&1 | Out-String
            } else {
                $output = & $scriptPath 2>&1 | Out-String
            }
            if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
                $exitCode = $LASTEXITCODE
            }
        } else {
            # Run Bash script
            $bashArgs = @($scriptPath) + $Args
            $output = bash @bashArgs 2>&1 | Out-String
            $exitCode = $LASTEXITCODE
        }
    } catch {
        $output = $_.Exception.Message
        $exitCode = 1
    }

    # Parse output for warnings/errors
    $checkWarnings = ([regex]::Matches($output, "warning", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).Count
    $checkErrors = ([regex]::Matches($output, "error", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)).Count

    # Override error count if script exited with non-zero
    if ($exitCode -ne 0 -and $checkErrors -eq 0) {
        $checkErrors = 1
    }

    $script:warnings += $checkWarnings
    $script:errors += $checkErrors

    # Display result
    if ($exitCode -eq 0) {
        if ($checkWarnings -gt 0) {
            Write-Host " " -NoNewline
            Write-Host "✓ PASS" -ForegroundColor Green -NoNewline
            Write-Host " " -NoNewline
            Write-Host "($checkWarnings warnings)" -ForegroundColor Yellow
        } else {
            Write-Host " " -NoNewline
            Write-Host "✓ PASS" -ForegroundColor Green
        }
        $script:passedChecks++
    } else {
        Write-Host " " -NoNewline
        Write-Host "✗ FAIL" -ForegroundColor Red -NoNewline
        Write-Host " " -NoNewline
        Write-Host "($checkErrors errors)" -ForegroundColor Red
        $script:failedChecks++

        # Show error details if not verbose
        if (-not $script:Verbose) {
            Write-Host ""
            $errorLines = $output -split "`n" | Where-Object { $_ -match "\[ERROR\]|✗" } | Select-Object -First 10
            foreach ($line in $errorLines) {
                Write-Host "    $line" -ForegroundColor Red
            }
        }
    }

    # Always show full output in verbose mode
    if ($script:Verbose) {
        Write-Host ""
        $output -split "`n" | ForEach-Object { Write-Host "    $_" }
        Write-Host ""
    }
}

# Tier 1: Structural Validation
Write-Host "Running Tier 1: Structural Validation..." -ForegroundColor Cyan

Run-Check 1 5 "Version sync" "check-version-sync.sh"
Run-Check 2 5 "Link integrity" "check-links.sh"
Run-Check 3 5 "Inventory accuracy" "validate-inventory.sh"
Run-Check 4 5 "Relationship validation" "validate-relationships.sh"
Run-Check 5 5 "Schema validation" "validate-schemas.sh"

# Exit early if quick mode
if ($tier -eq "quick") {
    Write-Host ""
    Write-Host "=== Summary (Quick Mode) ===" -ForegroundColor Cyan

    if ($failedChecks -eq 0) {
        Write-Host "Status: PASSED" -ForegroundColor Green
    } else {
        Write-Host "Status: FAILED" -ForegroundColor Red
    }

    Write-Host "Checks run: $totalChecks"
    Write-Host "Passed: $passedChecks" -ForegroundColor Green
    Write-Host "Failed: $failedChecks" -ForegroundColor Red
    Write-Host "Warnings: $warnings" -ForegroundColor Yellow
    Write-Host "Errors: $errors" -ForegroundColor Red
    Write-Host ""

    exit $failedChecks
}

# Tier 2: Completeness Validation
Write-Host ""
Write-Host "Running Tier 2: Completeness Validation..." -ForegroundColor Cyan

Run-Check 6 6 "Feature coverage" "validate-completeness.sh"

# Exit if standard mode (not full)
if ($tier -eq "standard") {
    Write-Host ""
    Write-Host "=== Summary (Standard Mode) ===" -ForegroundColor Cyan

    if ($failedChecks -eq 0) {
        Write-Host "Status: PASSED" -ForegroundColor Green
    } else {
        Write-Host "Status: FAILED" -ForegroundColor Red
    }

    Write-Host "Checks run: $totalChecks"
    Write-Host "Passed: $passedChecks" -ForegroundColor Green
    Write-Host "Failed: $failedChecks" -ForegroundColor Red
    Write-Host "Warnings: $warnings" -ForegroundColor Yellow
    Write-Host "Errors: $errors" -ForegroundColor Red
    Write-Host ""

    exit $failedChecks
}

# Tier 3: Content Validation (full mode only)
Write-Host ""
Write-Host "Running Tier 3: Content Validation..." -ForegroundColor Cyan

Run-Check 7 8 "Required sections" "validate-content.sh"
Run-Check 8 8 "External links (slow)" "validate-content.sh" @("--check-external")

# Final Summary
Write-Host ""
Write-Host "=== Summary (Full Mode) ===" -ForegroundColor Cyan

if ($failedChecks -eq 0) {
    Write-Host "Status: PASSED" -ForegroundColor Green
} else {
    Write-Host "Status: FAILED" -ForegroundColor Red
}

Write-Host "Checks run: $totalChecks"
Write-Host "Passed: $passedChecks" -ForegroundColor Green
Write-Host "Failed: $failedChecks" -ForegroundColor Red
Write-Host "Warnings: $warnings" -ForegroundColor Yellow
Write-Host "Errors: $errors" -ForegroundColor Red
Write-Host ""

if ($failedChecks -gt 0) {
    Write-Host "Some checks failed. Review the output above for details." -ForegroundColor Red
    Write-Host ""
    Write-Host "To fix issues:"
    Write-Host "  1. Review error messages above"
    Write-Host "  2. Run individual scripts with -Verbose for more details"
    Write-Host "  3. Fix reported issues"
    Write-Host "  4. Re-run this script"
    Write-Host ""
}

exit $failedChecks
