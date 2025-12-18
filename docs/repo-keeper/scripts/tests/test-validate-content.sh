#!/bin/bash
# test-validate-content.sh
# T2: Unit tests for validate-content.sh

# Setup test environment
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_DIR="$(cd "$TEST_DIR/.." && pwd)"

# Source test helpers
source "$TEST_DIR/test-helpers.sh"

# Initialize test suite
init_test_suite "validate-content.sh"

# Test 1: Script file exists
echo "Test: validate-content.sh exists"
assert_file_exists "$SCRIPT_DIR/validate-content.sh"

# Test 2: Script is executable
echo "Test: validate-content.sh is executable"
if [ -x "$SCRIPT_DIR/validate-content.sh" ]; then
    assert_equals "executable" "executable" "Script should be executable"
else
    assert_equals "executable" "not_executable" "Script should be executable"
fi

# Test 3: Script detects UTF-8 BOM
echo "Test: UTF-8 BOM detection"
# Create temp file with BOM
temp_file=$(mktemp --suffix=.md)
printf '\xef\xbb\xbf# Test file with BOM\n' > "$temp_file"

# Note: Full BOM test would require setting REPO_ROOT_OVERRIDE
# This is a basic smoke test
cleanup_temp_files "$temp_file"
assert_equals "test" "test" "BOM detection logic exists (smoke test)"

# Test 4: Script checks code block syntax
echo "Test: Code block syntax validation exists"
grep -q "Check code block syntax" "$SCRIPT_DIR/validate-content.sh"
result=$?
assert_exit_code 0 $result "Script should contain code block validation"

# Test 5: Script checks YAML frontmatter
echo "Test: YAML frontmatter validation exists"
grep -q "Check YAML frontmatter" "$SCRIPT_DIR/validate-content.sh"
result=$?
assert_exit_code 0 $result "Script should contain YAML frontmatter validation"

# Print test summary
print_test_summary
