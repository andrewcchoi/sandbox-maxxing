# validate-content.ps1
# Checks that documents contain expected sections and correct references

param(
    [switch]$Verbose,
    [switch]$CheckExternal,
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
    Write-Host "=== Content Validator ===" -ForegroundColor Cyan
    Write-Host ""
}

$errorCount = 0

# Check SKILL.md files for required sections
if (-not $Quiet) {
    Write-Host "Checking required sections in SKILL.md files..." -ForegroundColor Cyan
}

$skillFiles = Get-ChildItem -Path (Join-Path $repoRoot "skills") -Filter "SKILL.md" -Recurse -File -ErrorAction SilentlyContinue

foreach ($skillFile in $skillFiles) {
    $skillName = Split-Path -Leaf (Split-Path -Parent $skillFile.FullName)
    $content = Get-Content $skillFile.FullName -Raw

    # Check for required sections
    $hasOverview = $content -match '(?i)overview'
    $hasUsage = $content -match '(?i)usage'
    $hasExamples = $content -match '(?i)example'
    $hasFooter = $content -match '\*\*Version:\*\*'

    $missingSections = @()
    if (-not $hasOverview) { $missingSections += "Overview" }
    if (-not $hasUsage) { $missingSections += "Usage" }
    if (-not $hasExamples) { $missingSections += "Examples" }
    if (-not $hasFooter) { $missingSections += "Footer" }

    if ($missingSections.Count -gt 0) {
        Write-Host "  [ERROR] $skillName missing: $($missingSections -join ', ')" -ForegroundColor Red
        $errorCount++
    } elseif ($Verbose) {
        Write-Host "  [OK] $skillName has all sections" -ForegroundColor Gray
    }
}

# Check mode consistency
if (-not $Quiet) {
    Write-Host ""
    Write-Host "Checking mode consistency..." -ForegroundColor Cyan
}

$modeFiles = Get-ChildItem -Path $repoRoot -Include @("*basic*", "*intermediate*", "*advanced*", "*yolo*") -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Extension -eq ".md" -or $_.Name -eq "SKILL.md" }

$modeConsistent = 0
$modeChecked = 0

foreach ($file in $modeFiles) {
    $modeChecked++
    $content = Get-Content $file.FullName -Raw

    # Determine expected mode from filename
    $expectedMode = $null
    if ($file.Name -match 'basic') {
        $expectedMode = 'basic'
    } elseif ($file.Name -match 'intermediate') {
        $expectedMode = 'intermediate'
    } elseif ($file.Name -match 'advanced') {
        $expectedMode = 'advanced'
    } elseif ($file.Name -match 'yolo') {
        $expectedMode = 'yolo'
    } else {
        continue
    }

    # Check if file content mentions the mode
    if ($content -match "(?i)$expectedMode") {
        $modeConsistent++
        if ($Verbose) {
            Write-Host "  [OK] $($file.Name) references $expectedMode" -ForegroundColor Gray
        }
    } else {
        Write-Host "  [WARNING] $($file.Name) doesn't mention '$expectedMode'" -ForegroundColor Yellow
    }
}

if (-not $Quiet) {
    Write-Host "  [OK] $modeConsistent/$modeChecked files reference correct mode" -ForegroundColor Green
}

# Check step sequences
if (-not $Quiet) {
    Write-Host ""
    Write-Host "Checking step sequences..." -ForegroundColor Cyan
}

$mdFiles = Get-ChildItem -Path $repoRoot -Filter "*.md" -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch 'node_modules' -and $_.FullName -notmatch '\.git' } |
    Select-Object -First 50

$brokenSequences = 0

foreach ($mdFile in $mdFiles) {
    $content = Get-Content $mdFile.FullName

    # Extract numbered steps (1., 2., 3., etc.)
    $steps = @()
    foreach ($line in $content) {
        if ($line -match '^\s*(\d+)\.') {
            $steps += [int]$matches[1]
        }
    }

    if ($steps.Count -gt 0) {
        $steps = $steps | Sort-Object -Unique

        # Check for gaps in sequence
        $prev = 0
        foreach ($step in $steps) {
            if ($prev -ne 0 -and ($step - $prev) -gt 1) {
                Write-Host "  [WARNING] $($mdFile.Name): Gap in steps ($prev -> $step)" -ForegroundColor Yellow
                $brokenSequences++
                break
            }
            $prev = $step
        }
    }
}

if (-not $Quiet) {
    if ($brokenSequences -eq 0) {
        Write-Host "  [OK] No broken step sequences found" -ForegroundColor Green
    } else {
        Write-Host "  [WARNING] Found $brokenSequences files with step gaps" -ForegroundColor Yellow
    }
}

# External link checking (optional)
if ($CheckExternal) {
    if (-not $Quiet) {
        Write-Host ""
        Write-Host "Checking external links (slow)..." -ForegroundColor Cyan
    }

    # Extract all external links from markdown files
    $externalLinks = @()
    $mdAllFiles = Get-ChildItem -Path $repoRoot -Filter "*.md" -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch 'node_modules' -and $_.FullName -notmatch '\.git' } |
        Select-Object -First 20

    foreach ($mdFile in $mdAllFiles) {
        $content = Get-Content $mdFile.FullName -Raw
        $matches = [regex]::Matches($content, 'https?://[^)]+')
        foreach ($match in $matches) {
            $externalLinks += $match.Value
        }
    }

    $externalLinks = $externalLinks | Select-Object -Unique | Select-Object -First 20

    $checked = 0
    $failed = 0

    foreach ($link in $externalLinks) {
        $checked++

        try {
            $response = Invoke-WebRequest -Uri $link -Method Head -TimeoutSec 5 -ErrorAction Stop
            if ($Verbose) {
                Write-Host "  [OK] $link" -ForegroundColor Gray
            }
        } catch {
            Write-Host "  [ERROR] $link (unreachable)" -ForegroundColor Red
            $failed++
            $errorCount++
        }
    }

    if (-not $Quiet) {
        Write-Host "  Checked $checked external links, $failed failed" -ForegroundColor Green
    }
}

# Summary
if (-not $Quiet) {
    Write-Host ""
    Write-Host "=== Summary ===" -ForegroundColor Cyan
}
if ($errorCount -eq 0) {
    if (-not $Quiet) {
        Write-Host "✓ All content checks passed!" -ForegroundColor Green
        Write-Host "Total errors: $errorCount" -ForegroundColor Green
    }
    if ($Log) { Stop-Transcript | Out-Null }
    exit 0
} else {
    Write-Host "✗ Content validation failed!" -ForegroundColor Red
    Write-Host "Total errors: $errorCount" -ForegroundColor Red
    if ($Log) { Stop-Transcript | Out-Null }
    exit 1
}
