# Test-Runner.ps1
# T1: Main test runner for validation scripts

$ErrorActionPreference = "Stop"

# Auto-detect test directory
$testDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Parent $testDir
$repoRoot = (Get-Item "$scriptDir\..\..\..").FullName

# Counters
$totalSuites = 0
$passedSuites = 0
$failedSuites = 0

Write-Host "=== Validation Script Test Runner ===" -ForegroundColor Cyan
Write-Host "Test directory: $testDir"
Write-Host "Repository root: $repoRoot"
Write-Host ""

# Find all test files (Test-*.ps1 pattern)
$testFiles = Get-ChildItem -Path $testDir -Filter "Test-*.ps1" | Where-Object {
    $_.Name -ne "Test-Helpers.ps1" -and $_.Name -ne "Test-Runner.ps1"
} | Sort-Object Name

if ($testFiles.Count -eq 0) {
    Write-Host "No test files found" -ForegroundColor Yellow
    Write-Host "Test files should be named: Test-*.ps1"
    exit 0
}

# Run each test file
foreach ($testFile in $testFiles) {
    $totalSuites++

    $testName = $testFile.BaseName
    Write-Host "Running: $testName" -ForegroundColor Cyan
    Write-Host ""

    # Run test in isolated scope
    try {
        # Execute test file and capture exit code
        $output = & $testFile.FullName
        $exitCode = $LASTEXITCODE

        if ($exitCode -eq 0 -or $null -eq $exitCode) {
            $passedSuites++
        } else {
            $failedSuites++
        }
    } catch {
        Write-Host "Test execution error: $_" -ForegroundColor Red
        $failedSuites++
    }

    Write-Host ""
}

# Overall summary
Write-Host "=== Overall Test Summary ===" -ForegroundColor Cyan
Write-Host "Test suites run:    $totalSuites"
Write-Host "Test suites passed: $passedSuites" -ForegroundColor Green

if ($failedSuites -eq 0) {
    Write-Host "Test suites failed: $failedSuites" -ForegroundColor Green
    Write-Host ""
    Write-Host "✓ All test suites passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Test suites failed: $failedSuites" -ForegroundColor Red
    Write-Host ""
    Write-Host "✗ Some test suites failed!" -ForegroundColor Red
    exit 1
}
