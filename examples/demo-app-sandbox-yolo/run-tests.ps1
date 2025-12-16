# Test Runner for Demo Blog Application (PowerShell)
# Runs both backend (pytest) and frontend (Jest) tests

param(
    [switch]$BackendOnly,
    [switch]$FrontendOnly,
    [switch]$Coverage,
    [switch]$Help
)

# Show help message
if ($Help) {
    Write-Host "Usage: .\run-tests.ps1 [OPTIONS]" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Cyan
    Write-Host "  -BackendOnly   Run only backend tests (pytest)"
    Write-Host "  -FrontendOnly  Run only frontend tests (Jest)"
    Write-Host "  -Coverage      Generate coverage reports"
    Write-Host "  -Help          Show this help message"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Cyan
    Write-Host "  .\run-tests.ps1                    # Run all tests"
    Write-Host "  .\run-tests.ps1 -BackendOnly       # Run only backend tests"
    Write-Host "  .\run-tests.ps1 -Coverage          # Run all tests with coverage"
    exit 0
}

# Function to print section headers
function Print-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Blue
    Write-Host $Message -ForegroundColor Blue
    Write-Host "========================================" -ForegroundColor Blue
    Write-Host ""
}

# Function to print success message
function Print-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

# Function to print error message
function Print-Error {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

# Track overall test status
$BackendPassed = $true
$FrontendPassed = $true

# Run backend tests
if (-not $FrontendOnly) {
    Print-Header "Running Backend Tests (pytest)"

    Push-Location backend

    try {
        if ($Coverage) {
            pytest --cov=app --cov-report=term-missing --cov-report=html
            if ($LASTEXITCODE -eq 0) {
                Print-Success "Backend tests passed"
                Write-Host "Coverage report generated at: backend\htmlcov\index.html" -ForegroundColor Yellow
            } else {
                Print-Error "Backend tests failed"
                $BackendPassed = $false
            }
        } else {
            pytest
            if ($LASTEXITCODE -eq 0) {
                Print-Success "Backend tests passed"
            } else {
                Print-Error "Backend tests failed"
                $BackendPassed = $false
            }
        }
    } finally {
        Pop-Location
    }
}

# Run frontend tests
if (-not $BackendOnly) {
    Print-Header "Running Frontend Tests (Jest)"

    Push-Location frontend

    try {
        if ($Coverage) {
            npm test -- --coverage --run
            if ($LASTEXITCODE -eq 0) {
                Print-Success "Frontend tests passed"
                Write-Host "Coverage report generated at: frontend\coverage\index.html" -ForegroundColor Yellow
            } else {
                Print-Error "Frontend tests failed"
                $FrontendPassed = $false
            }
        } else {
            npm test -- --run
            if ($LASTEXITCODE -eq 0) {
                Print-Success "Frontend tests passed"
            } else {
                Print-Error "Frontend tests failed"
                $FrontendPassed = $false
            }
        }
    } finally {
        Pop-Location
    }
}

# Print summary
Print-Header "Test Summary"

if (-not $FrontendOnly) {
    if ($BackendPassed) {
        Print-Success "Backend: All tests passed"
    } else {
        Print-Error "Backend: Some tests failed"
    }
}

if (-not $BackendOnly) {
    if ($FrontendPassed) {
        Print-Success "Frontend: All tests passed"
    } else {
        Print-Error "Frontend: Some tests failed"
    }
}

# Exit with appropriate status
if ($BackendPassed -and $FrontendPassed) {
    Write-Host ""
    Print-Success "All tests passed!"
    exit 0
} else {
    Write-Host ""
    Print-Error "Some tests failed"
    exit 1
}
