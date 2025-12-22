# validate-schemas.ps1
# Validates JSON files against their schemas

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
    Write-Host "=== JSON Schema Validator ===" -ForegroundColor Cyan
    Write-Host ""
}

$errorCount = 0

# Function to validate version pattern
function Test-VersionFormat {
    param([string]$Version)
    return $Version -match '^\d+\.\d+\.\d+$'
}

# Validate INVENTORY.json
if (-not $Quiet) {
    Write-Host "Validating INVENTORY.json..." -ForegroundColor Cyan
}
$inventoryPath = Join-Path $repoRoot "docs/repo-keeper/INVENTORY.json"

if (Test-Path $inventoryPath) {
    try {
        $inventory = Get-Content $inventoryPath -Raw | ConvertFrom-Json

        # Check required fields
        if (-not $inventory.version) {
            Write-Host "  [ERROR] Missing required field: version" -ForegroundColor Red
            Write-Host "    How to fix: Add version field to INVENTORY.json (e.g., ""version"": ""1.0.0"")" -ForegroundColor Yellow
            $errorCount++
        } elseif (-not (Test-VersionFormat $inventory.version)) {
            Write-Host "  [ERROR] Invalid version format: $($inventory.version)" -ForegroundColor Red
            Write-Host "    How to fix: Update version field in INVENTORY.json to semver format (e.g., 1.0.0)" -ForegroundColor Yellow
            $errorCount++
        } elseif (-not $Quiet) {
            Write-Host "  [OK] version: $($inventory.version)" -ForegroundColor Green
        }

        if (-not $inventory.last_updated) {
            Write-Host "  [ERROR] Missing required field: last_updated" -ForegroundColor Red
            Write-Host "    How to fix: Add last_updated field to INVENTORY.json (e.g., ""last_updated"": ""2025-01-15"")" -ForegroundColor Yellow
            $errorCount++
        } elseif ($inventory.last_updated -notmatch '^\d{4}-\d{2}-\d{2}$') {
            Write-Host "  [ERROR] Invalid date format: $($inventory.last_updated) (expected YYYY-MM-DD)" -ForegroundColor Red
            Write-Host "    How to fix: Update last_updated field in INVENTORY.json to YYYY-MM-DD format (e.g., 2025-01-15)" -ForegroundColor Yellow
            $errorCount++
        } elseif (-not $Quiet) {
            Write-Host "  [OK] last_updated: $($inventory.last_updated)" -ForegroundColor Green
        }

        if (-not $inventory.repository) {
            Write-Host "  [ERROR] Missing required field: repository" -ForegroundColor Red
            Write-Host "    How to fix: Add repository field to INVENTORY.json (e.g., ""repository"": ""owner/repo"")" -ForegroundColor Yellow
            $errorCount++
        } elseif (-not $Quiet) {
            Write-Host "  [OK] repository: $($inventory.repository)" -ForegroundColor Green
        }

        # Check arrays
        if ($inventory.skills) {
            if (-not $Quiet) {
                Write-Host "  [OK] skills: $($inventory.skills.Count) entries" -ForegroundColor Green
            }
        } elseif (-not $Quiet) {
            Write-Host "  [WARNING] No skills defined" -ForegroundColor Yellow
        }

        if ($inventory.commands) {
            if (-not $Quiet) {
                Write-Host "  [OK] commands: $($inventory.commands.Count) entries" -ForegroundColor Green
            }
        } elseif (-not $Quiet) {
            Write-Host "  [WARNING] No commands defined" -ForegroundColor Yellow
        }

    } catch {
        Write-Host "  [ERROR] Invalid JSON syntax: $_" -ForegroundColor Red
        Write-Host "    How to fix: Check JSON syntax in INVENTORY.json, ensure all brackets/braces match and commas are correct" -ForegroundColor Yellow
        $errorCount++
    }
} else {
    Write-Host "  [ERROR] INVENTORY.json not found" -ForegroundColor Red
    Write-Host "    How to fix: Create INVENTORY.json in docs/repo-keeper/ directory" -ForegroundColor Yellow
    $errorCount++
}

# Validate data files
if (-not $Quiet) {
    Write-Host ""
    Write-Host "Validating data files..." -ForegroundColor Cyan
}

$dataPath = Join-Path $repoRoot "data"
$dataFiles = @()

if (Test-Path $dataPath) {
    $dataFiles = Get-ChildItem -Path $dataPath -Filter "*.json" -ErrorAction SilentlyContinue
}

foreach ($file in $dataFiles) {
    try {
        $data = Get-Content $file.FullName -Raw | ConvertFrom-Json

        if ($data.version) {
            if (Test-VersionFormat $data.version) {
                if (-not $Quiet) {
                    Write-Host "  [OK] $($file.Name): version $($data.version)" -ForegroundColor Green
                }
            } else {
                Write-Host "  [ERROR] $($file.Name): Invalid version format: $($data.version)" -ForegroundColor Red
                Write-Host "    How to fix: Update version in $($file.Name) to semver format (e.g., 1.0.0)" -ForegroundColor Yellow
                $errorCount++
            }
        } else {
            if ($Verbose -and -not $Quiet) {
                Write-Host "  [INFO] $($file.Name): no version field" -ForegroundColor Gray
            }
        }
    } catch {
        Write-Host "  [ERROR] $($file.Name): Invalid JSON syntax" -ForegroundColor Red
        Write-Host "    How to fix: Check JSON syntax in $($file.Name), ensure all brackets/braces match and commas are correct" -ForegroundColor Yellow
        $errorCount++
    }
}

# Summary
if (-not $Quiet) {
    Write-Host ""
    Write-Host "=== Summary ===" -ForegroundColor Cyan
}
if ($errorCount -eq 0) {
    if (-not $Quiet) {
        Write-Host "✓ All schemas valid!" -ForegroundColor Green
        Write-Host "Total errors: $errorCount" -ForegroundColor Green
    }
    if ($Log) { Stop-Transcript | Out-Null }
    exit 0
} else {
    Write-Host "✗ Schema validation failed!" -ForegroundColor Red
    if (-not $Quiet) {
        Write-Host "Total errors: $errorCount" -ForegroundColor Red
    }
    if ($Log) { Stop-Transcript | Out-Null }
    exit 1
}
