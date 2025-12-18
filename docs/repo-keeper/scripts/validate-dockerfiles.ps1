# validate-dockerfiles.ps1
# V14: Basic Dockerfile syntax validation

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
    Write-Host "=== Dockerfile Validator ===" -ForegroundColor Cyan
    Write-Host ""
}

$warningCount = 0
$errorCount = 0

# Find all Dockerfiles
$dockerfiles = Get-ChildItem -Path $repoRoot -Recurse -File | Where-Object {
    ($_.Name -like "Dockerfile*" -or $_.Name -like "*.dockerfile") -and
    $_.FullName -notmatch "node_modules" -and
    $_.FullName -notmatch "\.git"
}

$totalDockerfiles = $dockerfiles.Count
$invalidDockerfiles = 0

if (-not $Quiet) {
    Write-Host "Validating Dockerfile syntax..." -ForegroundColor Cyan
}

$validInstructions = "FROM|RUN|CMD|LABEL|EXPOSE|ENV|ADD|COPY|ENTRYPOINT|VOLUME|USER|WORKDIR|ARG|ONBUILD|STOPSIGNAL|HEALTHCHECK|SHELL"

foreach ($dockerfile in $dockerfiles) {
    $relativePath = $dockerfile.FullName.Replace("$repoRoot\", "").Replace("\", "/")
    $hasIssues = $false

    $lines = Get-Content $dockerfile.FullName

    # Check 1: Must start with FROM (or ARG before FROM)
    $firstInstruction = $lines | Where-Object { $_ -notmatch '^\s*#' -and $_ -match '\S' } | Select-Object -First 1
    if ($firstInstruction -notmatch '^(FROM|ARG)') {
        Write-Host "  [ERROR] $relativePath - Must start with FROM or ARG" -ForegroundColor Red
        $errorCount++
        $invalidDockerfiles++
        $hasIssues = $true
    }

    # Check 2: Valid instruction keywords
    foreach ($line in $lines) {
        # Skip comments and empty lines
        if ($line -match '^\s*#' -or $line -notmatch '\S') { continue }

        # Extract instruction (first word)
        $instruction = ($line -split '\s+')[0]

        # Check if it's a known instruction
        if ($instruction -notmatch "^($validInstructions)$" -and $line -notmatch '^\s') {
            Write-Host "  [WARNING] $relativePath - Unknown instruction: $instruction" -ForegroundColor Yellow
            $warningCount++
            $hasIssues = $true
        }
    }

    # Check 3: No MAINTAINER (deprecated)
    if ($lines -match '^\s*MAINTAINER') {
        Write-Host "  [WARNING] $relativePath - MAINTAINER is deprecated, use LABEL instead" -ForegroundColor Yellow
        $warningCount++
        $hasIssues = $true
    }

    # Check 4: Warn about ADD when COPY should be used
    $addCount = ($lines | Where-Object { $_ -match '^\s*ADD\s' }).Count
    if ($addCount -gt 0 -and $Verbose) {
        Write-Host "  [INFO] $relativePath - Uses ADD ($addCount times). Consider COPY if not extracting archives." -ForegroundColor Gray
    }

    if (-not $hasIssues -and $Verbose) {
        Write-Host "  [OK] $relativePath" -ForegroundColor Gray
    }
}

# Summary
if (-not $Quiet) {
    Write-Host ""
    Write-Host "=== Summary ===" -ForegroundColor Cyan
    Write-Host "Total Dockerfiles checked: $totalDockerfiles"
}

if ($errorCount -eq 0 -and $warningCount -eq 0) {
    if (-not $Quiet) {
        Write-Host "✓ All Dockerfiles are valid!" -ForegroundColor Green
    }
    if ($Log) { Stop-Transcript | Out-Null }
    exit 0
} elseif ($errorCount -eq 0) {
    if (-not $Quiet) {
        Write-Host "⚠ Dockerfile validation passed with warnings" -ForegroundColor Yellow
        Write-Host "Warnings: $warningCount" -ForegroundColor Yellow
    }
    if ($Log) { Stop-Transcript | Out-Null }
    exit 0
} else {
    Write-Host "✗ Dockerfile validation failed!" -ForegroundColor Red
    Write-Host "Errors: $errorCount" -ForegroundColor Red
    Write-Host "Warnings: $warningCount" -ForegroundColor Yellow
    if ($Log) { Stop-Transcript | Out-Null }
    exit 1
}
