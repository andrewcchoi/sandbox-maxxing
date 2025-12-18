# validate-relationships.ps1
# Validates INVENTORY.json relationships are accurate

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

$repoRoot = "/workspace"

if (-not $Quiet) {
    Write-Host "=== Relationship Validator ===" -ForegroundColor Cyan
    Write-Host ""
}

$inventoryPath = Join-Path $repoRoot "docs\repo-keeper\INVENTORY.json"
if (-not (Test-Path $inventoryPath)) {
    Write-Host "[ERROR] INVENTORY.json not found" -ForegroundColor Red
    if ($Log) { Stop-Transcript | Out-Null }
    exit 1
}

$inventory = Get-Content $inventoryPath -Raw | ConvertFrom-Json

$errorCount = 0
$totalChecks = 0

# Check skill → template relationships
if (-not $Quiet) {
    Write-Host "Checking skill → template relationships..." -ForegroundColor Cyan
}

foreach ($skill in $inventory.skills) {
    $totalChecks++

    # Check skill file exists
    $skillPath = Join-Path $repoRoot $skill.path
    if (-not (Test-Path $skillPath)) {
        Write-Host "  [ERROR] $($skill.name): Skill file not found: $($skill.path)" -ForegroundColor Red
        Write-Host "    How to fix: Create skill file at $($skill.path) or update path in INVENTORY.json" -ForegroundColor Yellow
        $errorCount++
    } elseif ($Verbose) {
        Write-Host "  [OK] $($skill.name): skill file exists" -ForegroundColor Gray
    }

    # Check related templates
    if ($skill.related_templates) {
        foreach ($template in $skill.related_templates) {
            $totalChecks++
            $templatePath = Join-Path $repoRoot $template

            if (-not (Test-Path $templatePath)) {
                Write-Host "  [ERROR] $($skill.name) → $template (NOT FOUND)" -ForegroundColor Red
                Write-Host "    How to fix: Create template file at $template or remove from related_templates in INVENTORY.json" -ForegroundColor Yellow
                $errorCount++
            } elseif ($Verbose) {
                Write-Host "  [OK] $($skill.name) → $template" -ForegroundColor Gray
            }
        }
    }
}

if ($errorCount -eq 0 -and -not $Quiet) {
    Write-Host "  [OK] All skill → template relationships valid" -ForegroundColor Green
}

# Check skill ↔ command relationships
if (-not $Quiet) {
    Write-Host ""
    Write-Host "Checking skill ↔ command relationships..." -ForegroundColor Cyan
}

foreach ($skill in $inventory.skills) {
    if ($skill.related_command) {
        $totalChecks++
        $commandPath = Join-Path $repoRoot $skill.related_command

        if (-not (Test-Path $commandPath)) {
            Write-Host "  [ERROR] $($skill.name) → $($skill.related_command) (NOT FOUND)" -ForegroundColor Red
            Write-Host "    How to fix: Create command file at $($skill.related_command) or update related_command in INVENTORY.json" -ForegroundColor Yellow
            $errorCount++
        } else {
            # Check bidirectional
            $commandContent = Get-Content $commandPath -Raw
            if ($commandContent -match $skill.name) {
                if ($Verbose) {
                    Write-Host "  [OK] $($skill.name) ↔ $($skill.related_command) (bidirectional)" -ForegroundColor Gray
                }
            } else {
                Write-Host "  [WARNING] $($skill.related_command) doesn't mention $($skill.name)" -ForegroundColor Yellow
            }
        }
    }
}

if ($errorCount -eq 0 -and -not $Quiet) {
    Write-Host "  [OK] All skill ↔ command relationships valid" -ForegroundColor Green
}

# Check command → skill relationships
if (-not $Quiet) {
    Write-Host ""
    Write-Host "Checking command → skill relationships..." -ForegroundColor Cyan
}

foreach ($command in $inventory.commands) {
    $totalChecks++

    # Check if invoked skill exists
    $skillExists = $inventory.skills | Where-Object { $_.name -eq $command.invokes_skill }

    if (-not $skillExists -and $command.invokes_skill -ne "interactive") {
        Write-Host "  [ERROR] $($command.name) invokes non-existent skill: $($command.invokes_skill)" -ForegroundColor Red
        Write-Host "    How to fix: Add skill '$($command.invokes_skill)' to INVENTORY.json or update invokes_skill field for command" -ForegroundColor Yellow
        $errorCount++
    } elseif ($Verbose) {
        Write-Host "  [OK] $($command.name) → $($command.invokes_skill)" -ForegroundColor Gray
    }
}

if ($errorCount -eq 0 -and -not $Quiet) {
    Write-Host "  [OK] All command → skill relationships valid" -ForegroundColor Green
}

# Check skill → example relationships
if (-not $Quiet) {
    Write-Host ""
    Write-Host "Checking skill → example relationships..." -ForegroundColor Cyan
}

foreach ($skill in $inventory.skills) {
    if ($skill.related_example -and $skill.related_example -ne $null) {
        $totalChecks++
        $examplePath = Join-Path $repoRoot $skill.related_example

        if (-not (Test-Path $examplePath)) {
            Write-Host "  [ERROR] $($skill.name) → $($skill.related_example) (NOT FOUND)" -ForegroundColor Red
            Write-Host "    How to fix: Create example at $($skill.related_example) or update related_example in INVENTORY.json" -ForegroundColor Yellow
            $errorCount++
        } elseif ($Verbose) {
            Write-Host "  [OK] $($skill.name) → $($skill.related_example)" -ForegroundColor Gray
        }
    }
}

if ($errorCount -eq 0 -and -not $Quiet) {
    Write-Host "  [OK] All skill → example relationships valid" -ForegroundColor Green
}

# Summary
if (-not $Quiet) {
    Write-Host ""
    Write-Host "=== Summary ===" -ForegroundColor Cyan
    Write-Host "Total relationships checked: $totalChecks"
}
if ($errorCount -eq 0) {
    if (-not $Quiet) {
        Write-Host "✓ All relationships valid!" -ForegroundColor Green
        Write-Host "Total errors: $errorCount" -ForegroundColor Green
    }
    if ($Log) { Stop-Transcript | Out-Null }
    exit 0
} else {
    Write-Host "✗ Relationship validation failed!" -ForegroundColor Red
    Write-Host "Total errors: $errorCount" -ForegroundColor Red
    if ($Log) { Stop-Transcript | Out-Null }
    exit 1
}
