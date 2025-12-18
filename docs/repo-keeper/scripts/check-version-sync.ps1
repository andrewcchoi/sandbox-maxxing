# check-version-sync.ps1
# Validates version consistency across the repository

param(
    [switch]$Verbose,
    [switch]$Quiet,
    [string]$Log
)

$ErrorActionPreference = "Stop"

# Start logging if requested
if ($Log) {
    Start-Transcript -Path $Log -Append | Out-Null
}

# Auto-detect repo root from script location
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Get-Item "$scriptPath\..\..\..").FullName

# Or allow override via environment variable
if ($env:REPO_ROOT) {
    $repoRoot = $env:REPO_ROOT
}

if (-not $Quiet) {
    Write-Host "=== Repository Version Sync Checker ===" -ForegroundColor Cyan
    Write-Host ""
}

# Read version from plugin.json
$pluginJsonPath = Join-Path $repoRoot ".claude-plugin\plugin.json"
$pluginJson = Get-Content $pluginJsonPath -Raw | ConvertFrom-Json
$expectedVersion = $pluginJson.version
if (-not $Quiet) {
    Write-Host "Expected version (from plugin.json): $expectedVersion" -ForegroundColor Green
    Write-Host ""
}

# Read version from marketplace.json
$marketplaceJsonPath = Join-Path $repoRoot ".claude-plugin\marketplace.json"
$marketplaceJson = Get-Content $marketplaceJsonPath -Raw | ConvertFrom-Json
$marketplaceVersion = $marketplaceJson.version

# Read version from INVENTORY.json
$inventoryPath = Join-Path $repoRoot "docs\repo-keeper\INVENTORY.json"
$inventoryVersion = "unknown"
if (Test-Path $inventoryPath) {
    $inventoryJson = Get-Content $inventoryPath -Raw | ConvertFrom-Json
    $inventoryVersion = $inventoryJson.version
}

# Initialize counters
$totalFiles = 0
$matchingFiles = 0
$missingFooters = 0
$wrongVersions = 0
$errors = @()

# Check marketplace.json
if ($marketplaceVersion -ne $expectedVersion) {
    $errors += [PSCustomObject]@{
        File = ".claude-plugin\marketplace.json"
        Expected = $expectedVersion
        Found = $marketplaceVersion
        Type = "Config"
    }
    Write-Host "[ERROR] marketplace.json version mismatch: $marketplaceVersion" -ForegroundColor Red
    Write-Host "  How to fix: Update version field in .claude-plugin\marketplace.json to $expectedVersion" -ForegroundColor Yellow
} else {
    Write-Host "[OK] marketplace.json version matches: $marketplaceVersion" -ForegroundColor Green
}

# Check INVENTORY.json
if ($inventoryVersion -ne $expectedVersion) {
    $errors += [PSCustomObject]@{
        File = "docs\repo-keeper\INVENTORY.json"
        Expected = $expectedVersion
        Found = $inventoryVersion
        Type = "Inventory"
    }
    Write-Host "[ERROR] INVENTORY.json version mismatch: $inventoryVersion" -ForegroundColor Red
    Write-Host "  How to fix: Update version field in docs\repo-keeper\INVENTORY.json to $expectedVersion" -ForegroundColor Yellow
} else {
    Write-Host "[OK] INVENTORY.json version matches: $inventoryVersion" -ForegroundColor Green
}

if (-not $Quiet) {
    Write-Host ""
    Write-Host "Checking documentation footers..." -ForegroundColor Cyan
}

# Find all markdown files
$mdFiles = Get-ChildItem -Path $repoRoot -Filter "*.md" -Recurse | Where-Object {
    # Exclude node_modules and .git
    $_.FullName -notmatch "node_modules" -and
    $_.FullName -notmatch "\.git" -and
    $_.FullName -notmatch "CHANGELOG\.md"  # CHANGELOG doesn't need footer
}

foreach ($file in $mdFiles) {
    $totalFiles++
    $relativePath = $file.FullName.Replace("$repoRoot\", "")

    $content = Get-Content $file.FullName -Raw

    # Check for version footer pattern: **Version:** X.Y.Z
    if ($content -match '\*\*Version:\*\*\s+([\d\.]+)') {
        $foundVersion = $matches[1]

        if ($foundVersion -eq $expectedVersion) {
            $matchingFiles++
            if ($Verbose) {
                Write-Host "  [OK] $relativePath" -ForegroundColor Gray
            }
        } else {
            $wrongVersions++
            $errors += [PSCustomObject]@{
                File = $relativePath
                Expected = $expectedVersion
                Found = $foundVersion
                Type = "Footer"
            }
            Write-Host "  [MISMATCH] $relativePath - Found: $foundVersion" -ForegroundColor Yellow
            Write-Host "    How to fix: Update **Version:** footer in $relativePath to $expectedVersion" -ForegroundColor Yellow
        }
    } else {
        $missingFooters++
        if ($Verbose) {
            Write-Host "  [NO FOOTER] $relativePath" -ForegroundColor DarkGray
        }
    }
}

# Check data files with version fields
if (-not $Quiet) {
    Write-Host ""
    Write-Host "Checking data files..." -ForegroundColor Cyan
}

$dataFiles = @(
    @{ Path = "data\secrets.json"; Field = "version" },
    @{ Path = "data\variables.json"; Field = "version" }
)

foreach ($dataFile in $dataFiles) {
    $fullPath = Join-Path $repoRoot $dataFile.Path
    if (Test-Path $fullPath) {
        $json = Get-Content $fullPath -Raw | ConvertFrom-Json
        $dataVersion = $json.($dataFile.Field)

        if ($dataVersion -ne $expectedVersion) {
            $errors += [PSCustomObject]@{
                File = $dataFile.Path
                Expected = $expectedVersion
                Found = $dataVersion
                Type = "Data"
            }
            Write-Host "  [ERROR] $($dataFile.Path) version mismatch: $dataVersion" -ForegroundColor Red
            Write-Host "    How to fix: Update version field in $($dataFile.Path) to $expectedVersion" -ForegroundColor Yellow
        } else {
            Write-Host "  [OK] $($dataFile.Path) version matches: $dataVersion" -ForegroundColor Green
        }
    }
}

# Summary
if (-not $Quiet) {
    Write-Host ""
    Write-Host "=== Summary ===" -ForegroundColor Cyan
    Write-Host "Total markdown files checked: $totalFiles"
    Write-Host "Files with matching footers:  $matchingFiles" -ForegroundColor Green
    Write-Host "Files with wrong versions:    $wrongVersions" -ForegroundColor Yellow
    Write-Host "Files missing footers:        $missingFooters" -ForegroundColor DarkGray
    Write-Host "Total errors found:           $($errors.Count)" -ForegroundColor $(if ($errors.Count -eq 0) { "Green" } else { "Red" })
}

# Detailed error report
if ($errors.Count -gt 0) {
    Write-Host ""
    Write-Host "=== Error Details ===" -ForegroundColor Red
    Write-Host ""

    # Group by type
    $configErrors = $errors | Where-Object { $_.Type -eq "Config" }
    $inventoryErrors = $errors | Where-Object { $_.Type -eq "Inventory" }
    $footerErrors = $errors | Where-Object { $_.Type -eq "Footer" }
    $dataErrors = $errors | Where-Object { $_.Type -eq "Data" }

    if ($configErrors) {
        Write-Host "Configuration Files:" -ForegroundColor Yellow
        $configErrors | ForEach-Object {
            Write-Host "  $($_.File): $($_.Found) -> $($_.Expected)"
        }
        Write-Host ""
    }

    if ($inventoryErrors) {
        Write-Host "Inventory:" -ForegroundColor Yellow
        $inventoryErrors | ForEach-Object {
            Write-Host "  $($_.File): $($_.Found) -> $($_.Expected)"
        }
        Write-Host ""
    }

    if ($dataErrors) {
        Write-Host "Data Files:" -ForegroundColor Yellow
        $dataErrors | ForEach-Object {
            Write-Host "  $($_.File): $($_.Found) -> $($_.Expected)"
        }
        Write-Host ""
    }

    if ($footerErrors) {
        Write-Host "Documentation Footers ($($footerErrors.Count) files):" -ForegroundColor Yellow
        $footerErrors | ForEach-Object {
            Write-Host "  $($_.File): $($_.Found) -> $($_.Expected)"
        }
    }
}

# Missing footers report (only if verbose)
if ($Verbose -and $missingFooters -gt 0) {
    Write-Host ""
    Write-Host "=== Files Missing Footers ===" -ForegroundColor DarkGray
    $mdFiles | ForEach-Object {
        $content = Get-Content $_.FullName -Raw
        if ($content -notmatch '\*\*Version:\*\*') {
            $relativePath = $_.FullName.Replace("$repoRoot\", "")
            Write-Host "  $relativePath"
        }
    }
}

if (-not $Quiet) {
    Write-Host ""
}

# Exit with appropriate code for CI/CD
if ($errors.Count -eq 0) {
    if (-not $Quiet) {
        Write-Host "✓ All versions are in sync!" -ForegroundColor Green
    }
    if ($Log) { Stop-Transcript | Out-Null }
    exit 0
} else {
    Write-Host "✗ Version sync check failed!" -ForegroundColor Red
    if (-not $Quiet) {
        Write-Host ""
        Write-Host "To fix version mismatches:"
        Write-Host "  1. Update all files to version $expectedVersion"
        Write-Host "  2. Use search/replace across the repository"
        Write-Host "  3. Run this script again to verify"
    }
    if ($Log) { Stop-Transcript | Out-Null }
    exit 1
}
