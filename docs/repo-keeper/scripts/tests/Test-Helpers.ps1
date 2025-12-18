# Test-Helpers.ps1
# T1: Common test utilities for validation script tests

# Test counters (script scope for persistence across function calls)
$script:TestsRun = 0
$script:TestsPassed = 0
$script:TestsFailed = 0
$script:TestSuite = ""

# Initialize test suite
function Initialize-TestSuite {
    param([string]$Name)

    $script:TestSuite = $Name
    $script:TestsRun = 0
    $script:TestsPassed = 0
    $script:TestsFailed = 0

    Write-Host "=== Test Suite: $Name ===" -ForegroundColor Cyan
    Write-Host ""
}

# Assert functions
function Assert-Equals {
    param(
        $Expected,
        $Actual,
        [string]$Message = "Values should be equal"
    )

    $script:TestsRun++

    if ($Expected -eq $Actual) {
        Write-Host "  ✓ PASS: $Message" -ForegroundColor Green
        $script:TestsPassed++
        return $true
    } else {
        Write-Host "  ✗ FAIL: $Message" -ForegroundColor Red
        Write-Host "    Expected: '$Expected'" -ForegroundColor Gray
        Write-Host "    Actual:   '$Actual'" -ForegroundColor Gray
        $script:TestsFailed++
        return $false
    }
}

function Assert-NotEquals {
    param(
        $Unexpected,
        $Actual,
        [string]$Message = "Values should not be equal"
    )

    $script:TestsRun++

    if ($Unexpected -ne $Actual) {
        Write-Host "  ✓ PASS: $Message" -ForegroundColor Green
        $script:TestsPassed++
        return $true
    } else {
        Write-Host "  ✗ FAIL: $Message" -ForegroundColor Red
        Write-Host "    Should not equal: '$Unexpected'" -ForegroundColor Gray
        $script:TestsFailed++
        return $false
    }
}

function Assert-FileExists {
    param(
        [string]$Path,
        [string]$Message = "File should exist: $Path"
    )

    $script:TestsRun++

    if (Test-Path $Path) {
        Write-Host "  ✓ PASS: $Message" -ForegroundColor Green
        $script:TestsPassed++
        return $true
    } else {
        Write-Host "  ✗ FAIL: $Message" -ForegroundColor Red
        Write-Host "    File not found: $Path" -ForegroundColor Gray
        $script:TestsFailed++
        return $false
    }
}

function Assert-FileNotExists {
    param(
        [string]$Path,
        [string]$Message = "File should not exist: $Path"
    )

    $script:TestsRun++

    if (-not (Test-Path $Path)) {
        Write-Host "  ✓ PASS: $Message" -ForegroundColor Green
        $script:TestsPassed++
        return $true
    } else {
        Write-Host "  ✗ FAIL: $Message" -ForegroundColor Red
        Write-Host "    File found: $Path" -ForegroundColor Gray
        $script:TestsFailed++
        return $false
    }
}

function Assert-Contains {
    param(
        [string]$Haystack,
        [string]$Needle,
        [string]$Message = "String should contain substring"
    )

    $script:TestsRun++

    if ($Haystack -like "*$Needle*") {
        Write-Host "  ✓ PASS: $Message" -ForegroundColor Green
        $script:TestsPassed++
        return $true
    } else {
        Write-Host "  ✗ FAIL: $Message" -ForegroundColor Red
        Write-Host "    Expected to find: '$Needle'" -ForegroundColor Gray
        $preview = if ($Haystack.Length -gt 60) { $Haystack.Substring(0, 60) + "..." } else { $Haystack }
        Write-Host "    In: '$preview'" -ForegroundColor Gray
        $script:TestsFailed++
        return $false
    }
}

function Assert-ExitCode {
    param(
        [int]$Expected,
        [int]$Actual,
        [string]$Message = "Exit code should match"
    )

    $script:TestsRun++

    if ($Expected -eq $Actual) {
        Write-Host "  ✓ PASS: $Message" -ForegroundColor Green
        $script:TestsPassed++
        return $true
    } else {
        Write-Host "  ✗ FAIL: $Message" -ForegroundColor Red
        Write-Host "    Expected exit code: $Expected" -ForegroundColor Gray
        Write-Host "    Actual exit code:   $Actual" -ForegroundColor Gray
        $script:TestsFailed++
        return $false
    }
}

# Test suite summary
function Write-TestSummary {
    Write-Host ""
    Write-Host "=== Test Summary: $script:TestSuite ===" -ForegroundColor Cyan
    Write-Host "Tests run:    $script:TestsRun"
    Write-Host "Tests passed: $script:TestsPassed" -ForegroundColor Green

    if ($script:TestsFailed -eq 0) {
        Write-Host "Tests failed: $script:TestsFailed" -ForegroundColor Green
        Write-Host ""
        Write-Host "✓ All tests passed!" -ForegroundColor Green
        return 0
    } else {
        Write-Host "Tests failed: $script:TestsFailed" -ForegroundColor Red
        Write-Host ""
        Write-Host "✗ Some tests failed!" -ForegroundColor Red
        return 1
    }
}

# Create temporary test file
function New-TempTestFile {
    param([string]$Content)

    $tempFile = [System.IO.Path]::GetTempFileName()
    Set-Content -Path $tempFile -Value $Content
    return $tempFile
}

# Clean up temporary files
function Remove-TempTestFiles {
    param([string[]]$Paths)

    foreach ($path in $Paths) {
        if (Test-Path $path) {
            Remove-Item $path -Force
        }
    }
}

# Export functions
Export-ModuleMember -Function * -Variable *
