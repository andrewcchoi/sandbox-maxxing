# validate-inventory.ps1
# Validates INVENTORY.json against actual repository filesystem

param(
    [switch]$Verbose,
    [switch]$FindOrphans,
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
    Write-Host "=== Repository Inventory Validator ===" -ForegroundColor Cyan
    Write-Host ""
}

# Read INVENTORY.json
$inventoryPath = Join-Path $repoRoot "docs\repo-keeper\INVENTORY.json"
if (-not (Test-Path $inventoryPath)) {
    Write-Host "[ERROR] INVENTORY.json not found at $inventoryPath" -ForegroundColor Red
    if ($Log) { Stop-Transcript | Out-Null }
    exit 1
}

$inventory = Get-Content $inventoryPath -Raw | ConvertFrom-Json
if (-not $Quiet) {
    Write-Host "Inventory version: $($inventory.version)" -ForegroundColor Green
    Write-Host "Last updated: $($inventory.last_updated)" -ForegroundColor Green
    Write-Host ""
}

# Initialize counters
$totalPaths = 0
$validPaths = 0
$missingPaths = 0
$errors = @()

# Function to validate a path
function Test-InventoryPath {
    param(
        [string]$Path,
        [string]$Category
    )

    $script:totalPaths++
    $fullPath = Join-Path $repoRoot $Path

    if (Test-Path $fullPath) {
        $script:validPaths++
        if ($Verbose) {
            Write-Host "  [OK] $Path" -ForegroundColor Gray
        }
        return $true
    } else {
        $script:missingPaths++
        $script:errors += [PSCustomObject]@{
            Category = $Category
            Path = $Path
            Issue = "NOT FOUND"
        }
        Write-Host "  [MISSING] $Path" -ForegroundColor Red
        Write-Host "    How to fix: Create the file at $Path or remove it from INVENTORY.json" -ForegroundColor Yellow
        return $false
    }
}

# Validate Skills
if (-not $Quiet) {
    Write-Host "Validating skills..." -ForegroundColor Cyan
}
foreach ($skill in $inventory.skills) {
    Test-InventoryPath -Path $skill.path -Category "Skill" | Out-Null

    # Check references if they exist
    if ($skill.references) {
        foreach ($ref in $skill.references) {
            Test-InventoryPath -Path $ref -Category "Skill Reference" | Out-Null
        }
    }
}

# Validate Commands
if (-not $Quiet) {
    Write-Host "Validating commands..." -ForegroundColor Cyan
}
foreach ($command in $inventory.commands) {
    Test-InventoryPath -Path $command.path -Category "Command" | Out-Null
}

# Validate Templates
if (-not $Quiet) {
    Write-Host "Validating templates..." -ForegroundColor Cyan
}

# Master templates
foreach ($template in $inventory.templates.master) {
    Test-InventoryPath -Path $template.path -Category "Master Template" | Out-Null
}

# Dockerfiles
foreach ($template in $inventory.templates.dockerfiles) {
    Test-InventoryPath -Path $template.path -Category "Dockerfile" | Out-Null
}

# Compose
foreach ($template in $inventory.templates.compose) {
    Test-InventoryPath -Path $template.path -Category "Compose" | Out-Null
}

# Firewall
foreach ($template in $inventory.templates.firewall) {
    Test-InventoryPath -Path $template.path -Category "Firewall" | Out-Null
}

# Extensions
foreach ($template in $inventory.templates.extensions) {
    Test-InventoryPath -Path $template.path -Category "Extensions" | Out-Null
}

# MCP
foreach ($template in $inventory.templates.mcp) {
    Test-InventoryPath -Path $template.path -Category "MCP" | Out-Null
}

# Variables
foreach ($template in $inventory.templates.variables) {
    Test-InventoryPath -Path $template.path -Category "Variables" | Out-Null
}

# Env
foreach ($template in $inventory.templates.env) {
    Test-InventoryPath -Path $template.path -Category "Env" | Out-Null
}

# Validate Examples
if (-not $Quiet) {
    Write-Host "Validating examples..." -ForegroundColor Cyan
}
foreach ($example in $inventory.examples) {
    Test-InventoryPath -Path $example.path -Category "Example" | Out-Null

    # Check devcontainer path if it exists
    if ($example.devcontainer_path) {
        Test-InventoryPath -Path $example.devcontainer_path -Category "DevContainer" | Out-Null
    }

    # Check dockerfile path if it exists
    if ($example.dockerfile_path) {
        Test-InventoryPath -Path $example.dockerfile_path -Category "Dockerfile" | Out-Null
    }

    # Check compose path if it exists
    if ($example.compose_path) {
        Test-InventoryPath -Path $example.compose_path -Category "Compose" | Out-Null
    }
}

# Validate Data Files
if (-not $Quiet) {
    Write-Host "Validating data files..." -ForegroundColor Cyan
}
foreach ($dataFile in $inventory.data_files) {
    Test-InventoryPath -Path $dataFile.path -Category "Data File" | Out-Null
}

# Validate Documentation
if (-not $Quiet) {
    Write-Host "Validating documentation..." -ForegroundColor Cyan
}

foreach ($category in @("root", "docs", "commands", "skills", "templates", "examples", "data", "tests", "repo-keeper")) {
    if ($inventory.documentation.$category) {
        foreach ($doc in $inventory.documentation.$category) {
            Test-InventoryPath -Path $doc.path -Category "Documentation ($category)" | Out-Null
        }
    }
}

# Validate DevContainers
if (-not $Quiet) {
    Write-Host "Validating devcontainers..." -ForegroundColor Cyan
}
foreach ($devcontainer in $inventory.devcontainers) {
    Test-InventoryPath -Path $devcontainer.path -Category "DevContainer" | Out-Null

    if ($devcontainer.dockerfile_path) {
        Test-InventoryPath -Path $devcontainer.dockerfile_path -Category "DevContainer Dockerfile" | Out-Null
    }

    if ($devcontainer.firewall_path) {
        Test-InventoryPath -Path $devcontainer.firewall_path -Category "Firewall Script" | Out-Null
    }
}

# Validate Dependencies
if (-not $Quiet) {
    Write-Host "Validating dependencies..." -ForegroundColor Cyan
}
foreach ($req in $inventory.dependencies.python_requirements) {
    Test-InventoryPath -Path $req -Category "Python Requirements" | Out-Null
}

foreach ($pkg in $inventory.dependencies.node_packages) {
    Test-InventoryPath -Path $pkg -Category "Node Package" | Out-Null
}

# Validate Test Files
if (-not $Quiet) {
    Write-Host "Validating test files..." -ForegroundColor Cyan
}
foreach ($test in $inventory.test_files.manual_tests) {
    Test-InventoryPath -Path $test -Category "Manual Test" | Out-Null
}

# Find orphaned files (if requested)
$orphans = @()
if ($FindOrphans) {
    if (-not $Quiet) {
        Write-Host ""
        Write-Host "Searching for orphaned files..." -ForegroundColor Cyan
    }

    # Get all paths from inventory
    $inventoryPaths = @()

    # Skills
    $inventory.skills | ForEach-Object { $inventoryPaths += $_.path }

    # Commands
    $inventory.commands | ForEach-Object { $inventoryPaths += $_.path }

    # Templates (all categories)
    $inventory.templates.master | ForEach-Object { $inventoryPaths += $_.path }
    $inventory.templates.dockerfiles | ForEach-Object { $inventoryPaths += $_.path }
    $inventory.templates.compose | ForEach-Object { $inventoryPaths += $_.path }
    $inventory.templates.firewall | ForEach-Object { $inventoryPaths += $_.path }
    $inventory.templates.extensions | ForEach-Object { $inventoryPaths += $_.path }
    $inventory.templates.mcp | ForEach-Object { $inventoryPaths += $_.path }
    $inventory.templates.variables | ForEach-Object { $inventoryPaths += $_.path }
    $inventory.templates.env | ForEach-Object { $inventoryPaths += $_.path }

    # Examples
    $inventory.examples | ForEach-Object { $inventoryPaths += $_.path }

    # Data files
    $inventory.data_files | ForEach-Object { $inventoryPaths += $_.path }

    # Documentation
    foreach ($category in @("root", "docs", "commands", "skills", "templates", "examples", "data", "tests", "repo-keeper")) {
        if ($inventory.documentation.$category) {
            $inventory.documentation.$category | ForEach-Object { $inventoryPaths += $_.path }
        }
    }

    # Find critical files not in inventory
    $criticalPatterns = @(
        "commands/*.md",
        "skills/*/SKILL.md",
        "templates/master/*.*",
        "examples/*/README.md",
        "data/*.json"
    )

    foreach ($pattern in $criticalPatterns) {
        $files = Get-ChildItem -Path $repoRoot -Filter ($pattern -split '/')[0] -Recurse -File | Where-Object {
            $_.FullName -notmatch "node_modules" -and
            $_.FullName -notmatch "\.git"
        }

        foreach ($file in $files) {
            $relativePath = $file.FullName.Replace("$repoRoot\", "")
            if ($inventoryPaths -notcontains $relativePath) {
                $orphans += $relativePath
                Write-Host "  [ORPHAN] $relativePath" -ForegroundColor Yellow
            }
        }
    }
}

# Summary
if (-not $Quiet) {
    Write-Host ""
    Write-Host "=== Summary ===" -ForegroundColor Cyan
    Write-Host "Total paths in inventory: $totalPaths"
    Write-Host "Valid paths:              $validPaths" -ForegroundColor Green
    Write-Host "Missing paths:            $missingPaths" -ForegroundColor $(if ($missingPaths -eq 0) { "Green" } else { "Red" })

    if ($FindOrphans) {
        Write-Host "Orphaned files found:     $($orphans.Count)" -ForegroundColor $(if ($orphans.Count -eq 0) { "Green" } else { "Yellow" })
    }
}

# Detailed error report
if ($errors.Count -gt 0) {
    Write-Host ""
    Write-Host "=== Missing Paths Details ===" -ForegroundColor Red
    Write-Host ""

    # Group by category
    $groupedErrors = $errors | Group-Object -Property Category

    foreach ($group in $groupedErrors) {
        Write-Host "$($group.Name) ($($group.Count) missing):" -ForegroundColor Yellow
        foreach ($error in $group.Group) {
            Write-Host "  $($error.Path)"
        }
        Write-Host ""
    }
}

# Check version consistency
if (-not $Quiet) {
    Write-Host ""
    Write-Host "=== Version Checks ===" -ForegroundColor Cyan
}

$versionIssues = @()

# Check if inventory version matches known issues
$knownIssues = $inventory.known_issues
if ($knownIssues.outdated_versions) {
    if (-not $Quiet) {
        Write-Host "Known version issues:" -ForegroundColor Yellow
        $knownIssues.outdated_versions | ForEach-Object {
            Write-Host "  $_" -ForegroundColor Yellow
        }
    }
    $versionIssues += $knownIssues.outdated_versions
}

if (-not $Quiet) {
    Write-Host ""
}

# Exit with appropriate code for CI/CD
$exitCode = 0

if ($missingPaths -gt 0) {
    Write-Host "✗ Inventory validation failed! ($missingPaths missing paths)" -ForegroundColor Red
    $exitCode = 1
} elseif ($versionIssues.Count -gt 0) {
    if (-not $Quiet) {
        Write-Host "⚠ Inventory valid but version issues found" -ForegroundColor Yellow
        Write-Host "  Run version sync check to fix these issues" -ForegroundColor Yellow
    }
    $exitCode = 0  # Don't fail on version issues, just warn
} else {
    if (-not $Quiet) {
        Write-Host "✓ Inventory is valid and all paths exist!" -ForegroundColor Green
    }
    $exitCode = 0
}

if ($FindOrphans -and $orphans.Count -gt 0) {
    if (-not $Quiet) {
        Write-Host ""
        Write-Host "ℹ Found $($orphans.Count) orphaned files not in inventory" -ForegroundColor Cyan
        Write-Host "  Consider adding them to INVENTORY.json"
    }
}

if ($Log) { Stop-Transcript | Out-Null }
exit $exitCode
