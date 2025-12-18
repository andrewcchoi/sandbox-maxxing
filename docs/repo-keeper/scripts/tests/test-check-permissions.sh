#!/bin/bash
# test-check-permissions.sh
# T2: Unit tests for check-permissions.sh

# Setup test environment
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_DIR="$(cd "$TEST_DIR/.." && pwd)"

# Source test helpers
source "$TEST_DIR/test-helpers.sh"

# Initialize test suite
init_test_suite "check-permissions.sh"

# Test 1: Script file exists
echo "Test: check-permissions.sh exists"
assert_file_exists "$SCRIPT_DIR/check-permissions.sh"

# Test 2: Script is executable
echo "Test: check-permissions.sh is executable"
if [ -x "$SCRIPT_DIR/check-permissions.sh" ]; then
    assert_equals "executable" "executable" "Script should be executable"
else
    assert_equals "executable" "not_executable" "Script should be executable"
fi

# Test 3: Script contains expected functions
echo "Test: Script contains permission checking logic"
grep -q "TOTAL_SCRIPTS" "$SCRIPT_DIR/check-permissions.sh"
result=$?
assert_exit_code 0 $result "Script should contain TOTAL_SCRIPTS variable"

# Test 4: Script contains color definitions
echo "Test: Script defines color codes"
grep -q "^RED=" "$SCRIPT_DIR/check-permissions.sh"
result=$?
assert_exit_code 0 $result "Script should define color codes"

# Test 5: Script has shebang
echo "Test: Script has proper shebang"
first_line=$(head -n 1 "$SCRIPT_DIR/check-permissions.sh")
assert_contains "$first_line" "#!/bin/bash" "Script should start with #!/bin/bash"

# Print test summary
print_test_summary
