# validate-compose.ps1
# V15: Validate docker-compose YAML structure

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

# Allow override via environment variable
if ($env:REPO_ROOT) {
    $repoRoot = $env:REPO_ROOT
}

if (-not $Quiet) {
    Write-Host "=== Docker Compose Validator ===" -ForegroundColor Cyan
    Write-Host ""
}

$warningCount = 0
$errorCount = 0

# Find all docker-compose files
$composeFiles = Get-ChildItem -Path $repoRoot -Recurse -File | Where-Object {
    ($_.Name -like "docker-compose*.yml" -or $_.Name -like "docker-compose*.yaml" -or
     $_.Name -like "compose*.yml" -or $_.Name -like "compose*.yaml") -and
    $_.FullName -notmatch "node_modules" -and
    $_.FullName -notmatch "\.git"
}

$totalCompose = $composeFiles.Count
$invalidCompose = 0

if (-not $Quiet) {
    Write-Host "Validating docker-compose files..." -ForegroundColor Cyan
}

$knownKeys = @("version", "services", "networks", "volumes", "configs", "secrets", "name")

foreach ($composeFile in $composeFiles) {
    $relativePath = $composeFile.FullName.Replace("$repoRoot\", "").Replace("\", "/")
    $hasIssues = $false

    $content = Get-Content $composeFile.FullName -Raw

    # Check 1: Valid YAML syntax (check for tabs)
    $yamlValid = $true
    $lines = Get-Content $composeFile.FullName
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line -match '^\t') {
            Write-Host "  Line $($i+1): YAML does not allow tabs for indentation" -ForegroundColor Red
            $yamlValid = $false
        }
    }

    if (-not $yamlValid) {
        Write-Host "  [ERROR] $relativePath - Invalid YAML syntax" -ForegroundColor Red
        $errorCount++
        $invalidCompose++
        $hasIssues = $true
    }

    # Check 2: Has required services key
    $hasServices = $content -match '^\s*services:'
    if (-not $hasServices) {
        Write-Host "  [ERROR] $relativePath - Missing 'services:' key" -ForegroundColor Red
        $errorCount++
        $invalidCompose++
        $hasIssues = $true
    }

    # Check for version key (informational)
    $hasVersion = $content -match '^\s*version:'
    if (-not $hasVersion -and $Verbose) {
        Write-Host "  [INFO] $relativePath - No 'version:' key (compose v2 format)" -ForegroundColor Gray
    }

    # Check 3: Common docker-compose keys
    $topLevelKeys = [regex]::Matches($content, '(?m)^([a-z_]+):') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique

    foreach ($key in $topLevelKeys) {
        if ($key -notin $knownKeys) {
            Write-Host "  [WARNING] $relativePath - Unknown top-level key: '$key'" -ForegroundColor Yellow
            $warningCount++
            $hasIssues = $true
        }
    }

    # Check 4: Service count
    $serviceCount = ([regex]::Matches($content, '(?m)^  [a-z_-]+:')).Count
    if ($serviceCount -eq 0 -and $hasServices) {
        Write-Host "  [WARNING] $relativePath - 'services:' defined but no services found" -ForegroundColor Yellow
        $warningCount++
        $hasIssues = $true
    }

    # Check 5: Verify services have image or build
    if ($hasServices) {
        $serviceMatches = [regex]::Matches($content, '(?m)^  ([a-z_-]+):')
        foreach ($match in $serviceMatches) {
            $serviceName = $match.Groups[1].Value
            $servicePattern = "(?ms)^  $serviceName:.*?(?=^  [a-z]|\z)"
            $serviceBlock = [regex]::Match($content, $servicePattern).Value

            if ($serviceBlock -notmatch '(image:|build:)' -and $Verbose) {
                Write-Host "  [WARNING] $relativePath - Service '$serviceName' missing 'image' or 'build'" -ForegroundColor Yellow
                $warningCount++
            }
        }
    }

    if (-not $hasIssues -and $Verbose) {
        Write-Host "  [OK] $relativePath ($serviceCount services)" -ForegroundColor Gray
    }
}

# Summary
if (-not $Quiet) {
    Write-Host ""
    Write-Host "=== Summary ===" -ForegroundColor Cyan
    Write-Host "Total compose files checked: $totalCompose"
}

if ($errorCount -eq 0 -and $warningCount -eq 0) {
    if (-not $Quiet) {
        Write-Host "✓ All docker-compose files are valid!" -ForegroundColor Green
    }
    if ($Log) { Stop-Transcript | Out-Null }
    exit 0
} elseif ($errorCount -eq 0) {
    if (-not $Quiet) {
        Write-Host "⚠ Compose validation passed with warnings" -ForegroundColor Yellow
        Write-Host "Warnings: $warningCount" -ForegroundColor Yellow
    }
    if ($Log) { Stop-Transcript | Out-Null }
    exit 0
} else {
    Write-Host "✗ Compose validation failed!" -ForegroundColor Red
    if (-not $Quiet) {
        Write-Host "Errors: $errorCount" -ForegroundColor Red
        Write-Host "Warnings: $warningCount" -ForegroundColor Yellow
    }
    if ($Log) { Stop-Transcript | Out-Null }
    exit 1
}
