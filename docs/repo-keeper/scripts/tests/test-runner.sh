#!/bin/bash
# test-runner.sh
# T1: Main test runner for validation scripts

set -e

# Auto-detect test directory
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_DIR="$(cd "$TEST_DIR/.." && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Counters
TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0

echo -e "${CYAN}=== Validation Script Test Runner ===${NC}"
echo "Test directory: $TEST_DIR"
echo "Repository root: $REPO_ROOT"
echo ""

# Find all test files
TEST_FILES=$(find "$TEST_DIR" -name "test-*.sh" -type f ! -name "test-helpers.sh" ! -name "test-runner.sh" 2>/dev/null | sort)

if [ -z "$TEST_FILES" ]; then
    echo -e "${YELLOW}No test files found${NC}"
    echo "Test files should be named: test-*.sh"
    exit 0
fi

# Run each test file
while IFS= read -r test_file; do
    [ -z "$test_file" ] && continue

    ((TOTAL_SUITES++))

    test_name=$(basename "$test_file" .sh)
    echo -e "${CYAN}Running: $test_name${NC}"
    echo ""

    # Run test in subshell to isolate environment
    if bash "$test_file"; then
        ((PASSED_SUITES++))
        echo ""
    else
        ((FAILED_SUITES++))
        echo ""
    fi
done <<< "$TEST_FILES"

# Overall summary
echo -e "${CYAN}=== Overall Test Summary ===${NC}"
echo "Test suites run:    $TOTAL_SUITES"
echo -e "${GREEN}Test suites passed: $PASSED_SUITES${NC}"

if [ $FAILED_SUITES -eq 0 ]; then
    echo -e "${GREEN}Test suites failed: $FAILED_SUITES${NC}"
    echo ""
    echo -e "${GREEN}✓ All test suites passed!${NC}"
    exit 0
else
    echo -e "${RED}Test suites failed: $FAILED_SUITES${NC}"
    echo ""
    echo -e "${RED}✗ Some test suites failed!${NC}"
    exit 1
fi
