#!/bin/bash
# test-helpers.sh
# T1: Common test utilities for validation script tests

# Colors for test output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test suite name
TEST_SUITE=""

# Initialize test suite
init_test_suite() {
    TEST_SUITE="$1"
    TESTS_RUN=0
    TESTS_PASSED=0
    TESTS_FAILED=0
    echo -e "${CYAN}=== Test Suite: $TEST_SUITE ===${NC}"
    echo ""
}

# Assert functions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Values should be equal}"

    ((TESTS_RUN++))

    if [ "$expected" = "$actual" ]; then
        echo -e "  ${GREEN}✓ PASS${NC}: $message"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "  ${RED}✗ FAIL${NC}: $message"
        echo -e "    ${GRAY}Expected: '$expected'${NC}"
        echo -e "    ${GRAY}Actual:   '$actual'${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_not_equals() {
    local unexpected="$1"
    local actual="$2"
    local message="${3:-Values should not be equal}"

    ((TESTS_RUN++))

    if [ "$unexpected" != "$actual" ]; then
        echo -e "  ${GREEN}✓ PASS${NC}: $message"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "  ${RED}✗ FAIL${NC}: $message"
        echo -e "    ${GRAY}Should not equal: '$unexpected'${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_file_exists() {
    local file_path="$1"
    local message="${2:-File should exist: $file_path}"

    ((TESTS_RUN++))

    if [ -f "$file_path" ]; then
        echo -e "  ${GREEN}✓ PASS${NC}: $message"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "  ${RED}✗ FAIL${NC}: $message"
        echo -e "    ${GRAY}File not found: $file_path${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_file_not_exists() {
    local file_path="$1"
    local message="${2:-File should not exist: $file_path}"

    ((TESTS_RUN++))

    if [ ! -f "$file_path" ]; then
        echo -e "  ${GREEN}✓ PASS${NC}: $message"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "  ${RED}✗ FAIL${NC}: $message"
        echo -e "    ${GRAY}File found: $file_path${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-String should contain substring}"

    ((TESTS_RUN++))

    if [[ "$haystack" == *"$needle"* ]]; then
        echo -e "  ${GREEN}✓ PASS${NC}: $message"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "  ${RED}✗ FAIL${NC}: $message"
        echo -e "    ${GRAY}Expected to find: '$needle'${NC}"
        echo -e "    ${GRAY}In: '${haystack:0:60}...'${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_exit_code() {
    local expected_code="$1"
    local actual_code="$2"
    local message="${3:-Exit code should match}"

    ((TESTS_RUN++))

    if [ "$expected_code" -eq "$actual_code" ]; then
        echo -e "  ${GREEN}✓ PASS${NC}: $message"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "  ${RED}✗ FAIL${NC}: $message"
        echo -e "    ${GRAY}Expected exit code: $expected_code${NC}"
        echo -e "    ${GRAY}Actual exit code:   $actual_code${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Test suite summary
print_test_summary() {
    echo ""
    echo -e "${CYAN}=== Test Summary: $TEST_SUITE ===${NC}"
    echo "Tests run:    $TESTS_RUN"
    echo -e "${GREEN}Tests passed: $TESTS_PASSED${NC}"

    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}Tests failed: $TESTS_FAILED${NC}"
        echo ""
        echo -e "${GREEN}✓ All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}Tests failed: $TESTS_FAILED${NC}"
        echo ""
        echo -e "${RED}✗ Some tests failed!${NC}"
        return 1
    fi
}

# Create temporary test file
create_temp_file() {
    local content="$1"
    local temp_file=$(mktemp)
    echo "$content" > "$temp_file"
    echo "$temp_file"
}

# Clean up temporary files
cleanup_temp_files() {
    rm -f "$@"
}
