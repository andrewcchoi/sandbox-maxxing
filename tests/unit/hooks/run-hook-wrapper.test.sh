#!/usr/bin/env bats
#
# Unit tests for run-hook.cmd
# Tests the cross-platform polyglot hook wrapper

# Calculate plugin root from test file location
BATS_TEST_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
PLUGIN_ROOT="$(cd "$BATS_TEST_DIR/../../.." && pwd)"

load '../../helpers/test_helper'

# Path to the wrapper script
WRAPPER_SCRIPT="${PLUGIN_ROOT}/hooks/run-hook.cmd"

@test "run-hook.cmd: wrapper file exists and is executable" {
  [ -f "$WRAPPER_SCRIPT" ]
  [ -x "$WRAPPER_SCRIPT" ]
}

@test "run-hook.cmd: has LF line endings (not CRLF)" {
  # CRLF line endings break bash heredoc parsing
  run file "$WRAPPER_SCRIPT"
  assert_success

  # Should show "ASCII text" without "CRLF"
  assert_output_not_contains "CRLF"
  assert_output_contains "ASCII text"
}

@test "run-hook.cmd: has valid bash syntax" {
  run bash -n "$WRAPPER_SCRIPT"
  assert_success
}

@test "run-hook.cmd: fails gracefully without arguments" {
  run "$WRAPPER_SCRIPT"
  assert_failure
  assert_output_contains "missing script name"
}

@test "run-hook.cmd: executes target script successfully" {
  # Create a temporary test script
  local test_script="${PLUGIN_ROOT}/hooks/.test-hook-execution.sh"
  cat > "$test_script" <<'EOF'
#!/usr/bin/env bash
echo "TEST_HOOK_EXECUTED"
exit 0
EOF
  chmod +x "$test_script"

  # Execute via wrapper
  cd "${PLUGIN_ROOT}/hooks"
  run "$WRAPPER_SCRIPT" .test-hook-execution.sh

  # Cleanup
  rm -f "$test_script"

  assert_success
  assert_output_contains "TEST_HOOK_EXECUTED"
}

@test "run-hook.cmd: passes arguments to target script" {
  # Create a temporary test script that echoes its arguments
  local test_script="${PLUGIN_ROOT}/hooks/.test-hook-args.sh"
  cat > "$test_script" <<'EOF'
#!/usr/bin/env bash
echo "ARG1=$1"
echo "ARG2=$2"
exit 0
EOF
  chmod +x "$test_script"

  # Execute via wrapper with arguments
  cd "${PLUGIN_ROOT}/hooks"
  run "$WRAPPER_SCRIPT" .test-hook-args.sh "foo" "bar"

  # Cleanup
  rm -f "$test_script"

  assert_success
  assert_output_contains "ARG1=foo"
  assert_output_contains "ARG2=bar"
}

@test "run-hook.cmd: preserves exit codes from target script" {
  # Create a temporary test script that exits with specific code
  local test_script="${PLUGIN_ROOT}/hooks/.test-hook-exitcode.sh"
  cat > "$test_script" <<'EOF'
#!/usr/bin/env bash
exit 42
EOF
  chmod +x "$test_script"

  # Execute via wrapper
  cd "${PLUGIN_ROOT}/hooks"
  run "$WRAPPER_SCRIPT" .test-hook-exitcode.sh

  # Cleanup
  rm -f "$test_script"

  # Should preserve exit code 42
  [ "$status" -eq 42 ]
}

@test "run-hook.cmd: handles scripts with spaces in output" {
  # Create a temporary test script with complex output
  local test_script="${PLUGIN_ROOT}/hooks/.test-hook-spaces.sh"
  cat > "$test_script" <<'EOF'
#!/usr/bin/env bash
echo "Line with    multiple    spaces"
echo "  Indented line"
echo ""
echo "Final line"
exit 0
EOF
  chmod +x "$test_script"

  # Execute via wrapper
  cd "${PLUGIN_ROOT}/hooks"
  run "$WRAPPER_SCRIPT" .test-hook-spaces.sh

  # Cleanup
  rm -f "$test_script"

  assert_success
  assert_output_contains "multiple    spaces"
  assert_output_contains "  Indented line"
}

@test "run-hook.cmd: handles stderr from target script" {
  # Create a temporary test script that outputs to stderr
  local test_script="${PLUGIN_ROOT}/hooks/.test-hook-stderr.sh"
  cat > "$test_script" <<'EOF'
#!/usr/bin/env bash
echo "stdout output"
echo "stderr output" >&2
exit 0
EOF
  chmod +x "$test_script"

  # Execute via wrapper
  cd "${PLUGIN_ROOT}/hooks"
  run "$WRAPPER_SCRIPT" .test-hook-stderr.sh

  # Cleanup
  rm -f "$test_script"

  assert_success
  # Both stdout and stderr should be captured
  assert_output_contains "stdout output"
  assert_output_contains "stderr output"
}
