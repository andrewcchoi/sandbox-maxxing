#!/usr/bin/env bash
#
# BATS Test Helper Functions
# Provides common utilities for testing sandbox-maxxing plugin

# Setup function called before each test
setup() {
  # Create temporary directory for test isolation
  export TEST_TEMP_DIR="$(mktemp -d)"

  # Store original directory
  export ORIGINAL_DIR="$(pwd)"

  # Set up common test variables
  export PLUGIN_ROOT="${ORIGINAL_DIR}"
}

# Teardown function called after each test
teardown() {
  # Clean up temporary directory
  [ -n "${TEST_TEMP_DIR:-}" ] && rm -rf "${TEST_TEMP_DIR}"

  # Return to original directory
  [ -n "${ORIGINAL_DIR:-}" ] && cd "${ORIGINAL_DIR}"
}

# Assert a command succeeds (exit code 0)
assert_success() {
  if [ "$status" -ne 0 ]; then
    echo "Expected success (exit 0), got: $status" >&2
    echo "Output: $output" >&2
    return 1
  fi
}

# Assert a command fails (non-zero exit code)
assert_failure() {
  if [ "$status" -eq 0 ]; then
    echo "Expected failure (non-zero exit), got: $status" >&2
    echo "Output: $output" >&2
    return 1
  fi
}

# Assert output contains a string
assert_output_contains() {
  local expected="$1"
  if ! echo "$output" | grep -qF "$expected"; then
    echo "Expected output to contain: $expected" >&2
    echo "Actual output: $output" >&2
    return 1
  fi
}

# Assert output matches a regex pattern
assert_output_matches() {
  local pattern="$1"
  if ! echo "$output" | grep -qE "$pattern"; then
    echo "Expected output to match: $pattern" >&2
    echo "Actual output: $output" >&2
    return 1
  fi
}

# Assert output does NOT contain a string
assert_output_not_contains() {
  local unexpected="$1"
  if echo "$output" | grep -qF "$unexpected"; then
    echo "Expected output NOT to contain: $unexpected" >&2
    echo "Actual output: $output" >&2
    return 1
  fi
}

# Assert JSON contains a specific key-value pair
assert_json_contains() {
  local key="$1"
  local expected="$2"

  if ! command -v jq >/dev/null 2>&1; then
    echo "ERROR: jq is required for JSON assertions" >&2
    return 1
  fi

  local actual
  actual=$(echo "$output" | jq -r "$key" 2>/dev/null)

  if [ "$actual" != "$expected" ]; then
    echo "Expected JSON $key = '$expected', got: '$actual'" >&2
    echo "Full output: $output" >&2
    return 1
  fi
}

# Create a mock stdin JSON payload for hooks
create_hook_input() {
  local tool_name="${1:-Bash}"
  local command="${2:-echo hello}"

  cat <<EOF
{
  "tool_name": "$tool_name",
  "tool_input": {
    "command": "$command"
  }
}
EOF
}

# Skip test if command is not available
require_command() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    skip "$cmd is not installed"
  fi
}

# Skip test on specific platform
skip_on_platform() {
  local platform="$1"
  local current_platform
  current_platform="$(uname -s)"

  if [ "$current_platform" = "$platform" ]; then
    skip "Test not applicable on $platform"
  fi
}

# Load bats-support and bats-assert if available (optional)
if [ -f "/usr/lib/bats-support/load.bash" ]; then
  load '/usr/lib/bats-support/load.bash'
fi
if [ -f "/usr/lib/bats-assert/load.bash" ]; then
  load '/usr/lib/bats-assert/load.bash'
fi
