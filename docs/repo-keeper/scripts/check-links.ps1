# check-links.ps1
# Validates markdown links across the repository

param(
    [switch]$Verbose,
    [switch]$SkipExternal
)

$ErrorActionPreference = "Stop"

# Auto-detect repo root from script location
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Get-Item "$scriptPath\..\..\..").FullName

# Or allow override via environment variable
if ($env:REPO_ROOT) {
    $repoRoot = $env:REPO_ROOT
}

Write-Host "=== Repository Link Checker ===" -ForegroundColor Cyan
Write-Host ""

# Initialize counters
$totalLinks = 0
$brokenLinks = 0
$externalLinks = 0
$validLinks = 0
$errors = @()

# Find all markdown files
$mdFiles = Get-ChildItem -Path $repoRoot -Filter "*.md" -Recurse | Where-Object {
    $_.FullName -notmatch "node_modules" -and
    $_.FullName -notmatch "\.git"
}

Write-Host "Scanning $($mdFiles.Count) markdown files..." -ForegroundColor Cyan
Write-Host ""

foreach ($file in $mdFiles) {
    $relativePath = $file.FullName.Replace("$repoRoot\", "")
    $fileDir = $file.Directory.FullName
    $content = Get-Content $file.FullName -Raw
    $lineNumber = 0
    $lines = Get-Content $file.FullName

    # Find all markdown links: [text](url)
    $linkPattern = '\[([^\]]+)\]\(([^\)]+)\)'
    $matches = [regex]::Matches($content, $linkPattern)

    foreach ($match in $matches) {
        $totalLinks++
        $linkText = $match.Groups[1].Value
        $linkUrl = $match.Groups[2].Value

        # Find line number
        $matchIndex = $match.Index
        $textBeforeMatch = $content.Substring(0, $matchIndex)
        $lineNum = ($textBeforeMatch -split "`n").Count

        # Skip anchors (# links)
        if ($linkUrl -match '^#') {
            continue
        }

        # Check if external link
        if ($linkUrl -match '^https?://') {
            $externalLinks++
            if ($Verbose) {
                Write-Host "  [EXTERNAL] $relativePath:$lineNum - $linkUrl" -ForegroundColor Gray
            }
            continue
        }

        # Internal link - validate it exists
        # Remove fragment identifier if present
        $linkPath = $linkUrl -replace '#.*$', ''

        # Resolve relative path
        $resolvedPath = $null

        if ($linkPath -match '^/') {
            # Absolute path from repo root
            $resolvedPath = Join-Path $repoRoot $linkPath.TrimStart('/')
        } else {
            # Relative path from current file's directory
            $resolvedPath = Join-Path $fileDir $linkPath
        }

        # Normalize path
        $resolvedPath = [System.IO.Path]::GetFullPath($resolvedPath)

        # Check if target exists
        if (Test-Path $resolvedPath) {
            $validLinks++
            if ($Verbose) {
                Write-Host "  [OK] $relativePath:$lineNum - $linkUrl" -ForegroundColor Green
            }
        } else {
            $brokenLinks++
            $errors += [PSCustomObject]@{
                File = $relativePath
                Line = $lineNum
                LinkText = $linkText
                LinkUrl = $linkUrl
                ResolvedPath = $resolvedPath.Replace("$repoRoot\", "")
            }
            Write-Host "  [BROKEN] $relativePath:$lineNum" -ForegroundColor Red
            Write-Host "    Text: $linkText" -ForegroundColor Red
            Write-Host "    URL: $linkUrl" -ForegroundColor Red
            Write-Host "    Resolved to: $($resolvedPath.Replace("$repoRoot\", ""))" -ForegroundColor Red
            Write-Host ""
        }
    }
}

# Summary
Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "Total markdown files:  $($mdFiles.Count)"
Write-Host "Total links found:     $totalLinks"
Write-Host "Valid internal links:  $validLinks" -ForegroundColor Green
Write-Host "External links:        $externalLinks" -ForegroundColor Gray
Write-Host "Broken links:          $brokenLinks" -ForegroundColor $(if ($brokenLinks -eq 0) { "Green" } else { "Red" })

# Detailed error report
if ($errors.Count -gt 0) {
    Write-Host ""
    Write-Host "=== Broken Links Details ===" -ForegroundColor Red
    Write-Host ""

    # Group by file
    $groupedErrors = $errors | Group-Object -Property File

    foreach ($group in $groupedErrors) {
        Write-Host "$($group.Name) ($($group.Count) broken links):" -ForegroundColor Yellow
        foreach ($error in $group.Group) {
            Write-Host "  Line $($error.Line): [$($error.LinkText)]($($error.LinkUrl))"
            Write-Host "    -> Resolved to: $($error.ResolvedPath) (NOT FOUND)" -ForegroundColor Red
        }
        Write-Host ""
    }
}

Write-Host ""

# Exit with appropriate code for CI/CD
if ($brokenLinks -eq 0) {
    Write-Host "✓ All internal links are valid!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "✗ Link check failed!" -ForegroundColor Red
    Write-Host ""
    Write-Host "To fix broken links:"
    Write-Host "  1. Update relative paths to match actual file locations"
    Write-Host "  2. Use relative paths (../path) instead of absolute (/workspace/path)"
    Write-Host "  3. Ensure linked files exist in the repository"
    Write-Host "  4. Run this script again to verify"
    exit 1
}
