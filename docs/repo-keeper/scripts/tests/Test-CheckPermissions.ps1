# Test-CheckPermissions.ps1
# T2: Unit tests for check-permissions.ps1

# Setup test environment
$testDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Parent $testDir

# Import test helpers
. "$testDir\Test-Helpers.ps1"

# Initialize test suite
Initialize-TestSuite "check-permissions.ps1"

# Test 1: Script file exists
Write-Host "Test: check-permissions.ps1 exists"
Assert-FileExists "$scriptDir\check-permissions.ps1"

# Test 2: Script contains expected patterns
Write-Host "Test: Script contains permission checking logic"
$content = Get-Content "$scriptDir\check-permissions.ps1" -Raw
Assert-Contains $content "totalScripts" "Script should contain totalScripts variable"

# Test 3: Script contains color definitions
Write-Host "Test: Script defines color output"
Assert-Contains $content "Write-Host" "Script should use Write-Host for colored output"

# Test 4: Script has param block
Write-Host "Test: Script has proper param block"
Assert-Contains $content "param" "Script should have param block"

# Test 5: Script handles Windows vs Linux
Write-Host "Test: Script detects Windows vs Linux"
Assert-Contains $content "isWindows" "Script should detect Windows platform"

# Print test summary
$exitCode = Write-TestSummary
exit $exitCode
