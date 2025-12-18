# Validation Script Test Framework

## Overview

This directory contains the test framework and unit tests for the repo-keeper validation scripts.

## Structure

```
tests/
├── test-runner.sh          # Main test runner - discovers and runs all tests
├── test-helpers.sh         # Common test utilities and assertions
├── test-*.sh               # Individual test suites
├── fixtures/               # Test data and fixtures
└── README.md               # This file
```

## Running Tests

Run all tests:
```bash
./test-runner.sh
```

Run a specific test suite:
```bash
./test-check-permissions.sh
```

## Writing Tests

### Test File Structure

Test files should:
1. Be named `test-*.sh`
2. Be executable (`chmod +x`)
3. Source `test-helpers.sh`
4. Initialize with `init_test_suite "Suite Name"`
5. End with `print_test_summary`

### Example Test

```bash
#!/bin/bash
# test-example.sh

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_DIR="$(cd "$TEST_DIR/.." && pwd)"

source "$TEST_DIR/test-helpers.sh"

init_test_suite "Example Tests"

# Test case 1
echo "Test: File exists"
assert_file_exists "$SCRIPT_DIR/some-script.sh"

# Test case 2
echo "Test: String comparison"
assert_equals "expected" "actual" "Values should match"

# Test case 3
echo "Test: Exit code"
output=$(some-command 2>&1)
exit_code=$?
assert_exit_code 0 $exit_code "Command should succeed"

print_test_summary
```

## Available Assertions

### `assert_equals expected actual [message]`
Assert two values are equal

### `assert_not_equals unexpected actual [message]`
Assert two values are not equal

### `assert_file_exists path [message]`
Assert a file exists

### `assert_file_not_exists path [message]`
Assert a file does not exist

### `assert_contains haystack needle [message]`
Assert a string contains a substring

### `assert_exit_code expected actual [message]`
Assert an exit code matches expected value

## Test Helpers

### `create_temp_file content`
Create a temporary file with content, returns file path

### `cleanup_temp_files file1 file2 ...`
Remove temporary files

## Current Test Coverage

- `test-check-permissions.sh` - Tests for check-permissions.sh
- `test-validate-content.sh` - Tests for validate-content.sh

## Adding New Tests

To add tests for a new validation script:

1. Create `test-<script-name>.sh`
2. Make it executable: `chmod +x test-<script-name>.sh`
3. Follow the test file structure above
4. Run `./test-runner.sh` to verify

## Exit Codes

- `0` - All tests passed
- `1` - Some tests failed

## Notes

- Tests run in isolated subshells
- Test framework uses bash built-ins and common utilities
- Tests should be fast (< 1 second per test suite)
- Tests should clean up temporary files
