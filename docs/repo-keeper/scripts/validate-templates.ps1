# validate-templates.ps1
# V13: Validates template variable syntax

param([switch]$Verbose)

$ErrorActionPreference = "Stop"

# Auto-detect repo root from script location
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Get-Item "$scriptPath\..\..\..").FullName

# Allow override via environment variable
if ($env:REPO_ROOT) {
    $repoRoot = $env:REPO_ROOT
}

Write-Host "=== Template Variable Validator ===" -ForegroundColor Cyan
Write-Host ""

$warningCount = 0
$errorCount = 0

# V13: Check variable syntax in templates
Write-Host "Checking variable syntax in template files..." -ForegroundColor Cyan

# Find all template files
$templatePath = Join-Path $repoRoot "templates"
if (Test-Path $templatePath) {
    $templateFiles = Get-ChildItem -Path $templatePath -Recurse -File | Where-Object {
        $_.FullName -notmatch "node_modules" -and $_.FullName -notmatch "\.git"
    }
} else {
    $templateFiles = @()
}

$invalidSyntax = 0
$totalTemplates = $templateFiles.Count

foreach ($template in $templateFiles) {
    $relativePath = $template.FullName.Replace("$repoRoot\", "").Replace("\", "/")

    $content = Get-Content $template.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }

    # Check for bare $ not followed by {
    if ($content -match '\$[A-Za-z_]' -and $content -notmatch '\$\{') {
        if ($Verbose) {
            Write-Host "  [WARNING] $relativePath - Bare `$ variable (should use `${VAR})" -ForegroundColor Yellow
            $lines = Get-Content $template.FullName
            for ($i = 0; $i -lt [Math]::Min($lines.Count, 3); $i++) {
                if ($lines[$i] -match '\$[A-Za-z_]' -and $lines[$i] -notmatch '\$\{') {
                    $lineNum = $i + 1
                    $lineContent = $lines[$i].Substring(0, [Math]::Min($lines[$i].Length, 60))
                    Write-Host "    Line ${lineNum}: $lineContent" -ForegroundColor Gray
                }
            }
        }
        $invalidSyntax++
        $warningCount++
    }

    # Check for unclosed variable references
    if ($content -match '\$\{[A-Za-z_][A-Za-z0-9_]*[^}]') {
        $matches = [regex]::Matches($content, '\$\{[A-Za-z_][A-Za-z0-9_]*')
        if ($matches.Count -gt 0 -and $Verbose) {
            $unclosed = $matches[0].Value
            Write-Host "  [WARNING] $relativePath - Potentially unclosed variable: $unclosed" -ForegroundColor Yellow
            $invalidSyntax++
            $warningCount++
        }
    }
}

if ($invalidSyntax -eq 0) {
    Write-Host "  [OK] All template variable syntax is valid" -ForegroundColor Green
} else {
    Write-Host "  Templates with syntax issues: $invalidSyntax" -ForegroundColor Yellow
}

# Check variables.*.json files for consistency
Write-Host ""
Write-Host "Checking variables JSON files..." -ForegroundColor Cyan

$varPath = Join-Path $repoRoot "templates\variables"
if (Test-Path $varPath) {
    $varFiles = Get-ChildItem -Path $varPath -Filter "variables.*.json" -ErrorAction SilentlyContinue
} else {
    $varFiles = @()
}

$varFileCount = $varFiles.Count

foreach ($varFile in $varFiles) {
    $relativePath = $varFile.FullName.Replace("$repoRoot\", "").Replace("\", "/")

    # Validate JSON syntax using PowerShell native ConvertFrom-Json
    try {
        $jsonData = Get-Content $varFile.FullName -Raw | ConvertFrom-Json

        if ($Verbose) {
            $mode = if ($jsonData.mode) { $jsonData.mode } else { "unknown" }
            Write-Host "  [OK] $relativePath (mode: $mode)" -ForegroundColor Gray
        }

        # Check for ${VAR} references in the file
        $content = Get-Content $varFile.FullName -Raw
        $varRefs = [regex]::Matches($content, '\$\{([A-Za-z_][A-Za-z0-9_]*)\}')

        foreach ($match in $varRefs) {
            $varName = $match.Groups[1].Value
            # Check if variable is defined in the file
            if ($content -notmatch "`"$varName`"") {
                Write-Host "  [WARNING] $relativePath - References undefined variable: $varName" -ForegroundColor Yellow
                $warningCount++
            }
        }
    } catch {
        Write-Host "  [ERROR] $relativePath - Invalid JSON syntax" -ForegroundColor Red
        $errorCount++
    }
}

Write-Host "  Checked $varFileCount variables files" -ForegroundColor Green

# Summary
Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "Total template files checked: $totalTemplates"
Write-Host "Variables files checked: $varFileCount"

if ($errorCount -eq 0 -and $warningCount -eq 0) {
    Write-Host "✓ All template validation checks passed!" -ForegroundColor Green
    exit 0
} elseif ($errorCount -eq 0) {
    Write-Host "⚠ Template validation passed with warnings" -ForegroundColor Yellow
    Write-Host "Warnings: $warningCount" -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "✗ Template validation failed!" -ForegroundColor Red
    Write-Host "Errors: $errorCount" -ForegroundColor Red
    Write-Host "Warnings: $warningCount" -ForegroundColor Yellow
    exit 1
}
