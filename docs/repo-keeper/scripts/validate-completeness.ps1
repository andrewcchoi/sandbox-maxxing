# validate-completeness.ps1
# Ensures every feature has documentation and all modes have full coverage

param(
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"
$repoRoot = "/workspace"

Write-Host "=== Completeness Validator ===" -ForegroundColor Cyan
Write-Host ""

$inventoryPath = Join-Path $repoRoot "docs/repo-keeper/INVENTORY.json"
if (-not (Test-Path $inventoryPath)) {
    Write-Host "Error: INVENTORY.json not found" -ForegroundColor Red
    exit 1
}

$inventory = Get-Content $inventoryPath -Raw | ConvertFrom-Json

$errorCount = 0

# Feature Documentation Check
Write-Host "Checking feature documentation..." -ForegroundColor Cyan

# Check skills have SKILL.md
$skillsWithDocs = 0
foreach ($skill in $inventory.skills) {
    $skillPath = Join-Path $repoRoot $skill.path
    if (Test-Path $skillPath) {
        $skillsWithDocs++
    } else {
        Write-Host "  [ERROR] Missing SKILL.md for: $($skill.name)" -ForegroundColor Red
        $errorCount++
    }
}
Write-Host "  [OK] $skillsWithDocs/$($inventory.skills.Count) skills have SKILL.md" -ForegroundColor Green

# Check commands documented in README
$commandsReadme = Join-Path $repoRoot "commands/README.md"
$commandsDocumented = 0

if (Test-Path $commandsReadme) {
    $readmeContent = Get-Content $commandsReadme -Raw
    foreach ($command in $inventory.commands) {
        if ($readmeContent -match $command.name) {
            $commandsDocumented++
        } else {
            Write-Host "  [ERROR] Command not in README: $($command.name)" -ForegroundColor Red
            $errorCount++
        }
    }
    Write-Host "  [OK] $commandsDocumented/$($inventory.commands.Count) commands documented in README" -ForegroundColor Green
} else {
    Write-Host "  [ERROR] commands/README.md not found" -ForegroundColor Red
    $errorCount++
}

# Check data files in README
$dataReadme = Join-Path $repoRoot "data/README.md"
if (Test-Path $dataReadme) {
    $dataContent = Get-Content $dataReadme -Raw
    $dataDocumented = 0

    foreach ($dataFile in $inventory.data_files) {
        if ($dataContent -match $dataFile.name) {
            $dataDocumented++
        } else {
            Write-Host "  [ERROR] Data file not in README: $($dataFile.name)" -ForegroundColor Red
            $errorCount++
        }
    }
    Write-Host "  [OK] $dataDocumented/$($inventory.data_files.Count) data files documented" -ForegroundColor Green
} else {
    Write-Host "  [WARNING] data/README.md not found" -ForegroundColor Yellow
}

# Mode Coverage Check
Write-Host ""
Write-Host "Checking mode coverage..." -ForegroundColor Cyan

$modes = @("basic", "intermediate", "advanced", "yolo")
foreach ($mode in $modes) {
    $missingCount = 0

    # Check for skill
    $skillExists = $inventory.skills | Where-Object { $_.mode -eq $mode }
    if (-not $skillExists) {
        Write-Host "  [ERROR] $mode`: No skill found" -ForegroundColor Red
        $errorCount++
        $missingCount++
    }

    # Check for command
    $commandFile = Join-Path $repoRoot "commands/$mode.md"
    if (-not (Test-Path $commandFile)) {
        Write-Host "  [ERROR] $mode`: Command file missing" -ForegroundColor Red
        $errorCount++
        $missingCount++
    }

    # Check for templates
    $templateTypes = @("compose/docker-compose", "firewall", "extensions/extensions", "mcp/mcp", "variables/variables", "env/.env")
    foreach ($type in $templateTypes) {
        if ($type -eq "firewall") {
            $templateFile = Get-ChildItem -Path (Join-Path $repoRoot "templates/firewall") -Filter "*$mode*" -ErrorAction SilentlyContinue | Select-Object -First 1
        } elseif ($type -eq "env/.env") {
            $templateFile = Get-Item (Join-Path $repoRoot "templates/env/.env.$mode.template") -ErrorAction SilentlyContinue
        } else {
            $templateFile = Get-Item (Join-Path $repoRoot "templates/$type.$mode.*") -ErrorAction SilentlyContinue | Select-Object -First 1
        }

        if (-not $templateFile) {
            $missingCount++
        }
    }

    # Check for example
    $exampleDir = Join-Path $repoRoot "examples/demo-app-sandbox-$mode"
    if (-not (Test-Path $exampleDir)) {
        Write-Host "  [ERROR] $mode`: Example directory missing" -ForegroundColor Red
        $errorCount++
        $missingCount++
    }

    if ($missingCount -eq 0) {
        Write-Host "  [OK] $mode`: 9/9 components" -ForegroundColor Green
    } else {
        Write-Host "  [ERROR] $mode`: Missing $missingCount components" -ForegroundColor Red
    }
}

# Summary
Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
if ($errorCount -eq 0) {
    Write-Host "✓ All completeness checks passed!" -ForegroundColor Green
    Write-Host "Total errors: $errorCount" -ForegroundColor Green
    exit 0
} else {
    Write-Host "✗ Completeness validation failed!" -ForegroundColor Red
    Write-Host "Total errors: $errorCount" -ForegroundColor Red
    exit 1
}
