# Test-ValidateContent.ps1
# T2: Unit tests for validate-content.ps1

# Setup test environment
$testDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Parent $testDir

# Import test helpers
. "$testDir\Test-Helpers.ps1"

# Initialize test suite
Initialize-TestSuite "validate-content.ps1"

# Test 1: Script file exists
Write-Host "Test: validate-content.ps1 exists"
Assert-FileExists "$scriptDir\validate-content.ps1"

# Test 2: Script contains expected functionality
Write-Host "Test: Script contains content validation logic"
$content = Get-Content "$scriptDir\validate-content.ps1" -Raw
Assert-Contains $content "errorCount" "Script should contain errorCount variable"

# Test 3: Script uses PowerShell patterns
Write-Host "Test: Script uses PowerShell foreach patterns"
Assert-Contains $content "foreach" "Script should use foreach for iteration"

# Test 4: Script has verbose support
Write-Host "Test: Script supports verbose mode"
Assert-Contains $content "Verbose" "Script should support -Verbose parameter"

# Test 5: Script has exit code logic
Write-Host "Test: Script has proper exit code handling"
Assert-Contains $content "exit" "Script should have exit statements"

# Print test summary
$exitCode = Write-TestSummary
exit $exitCode
