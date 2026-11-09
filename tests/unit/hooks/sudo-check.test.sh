#!/usr/bin/env bats
#
# Unit tests for sudo access check function
# Tests the check_sudo_access() function from yolo-linux-maxxing.md

# Calculate plugin root from test file location
BATS_TEST_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
PLUGIN_ROOT="$(cd "$BATS_TEST_DIR/../../.." && pwd)"

load '../../helpers/test_helper'

# Source the function under test
setup() {
  # Call test_helper's setup to create TEST_TEMP_DIR
  export TEST_TEMP_DIR="$(mktemp -d)"
  export ORIGINAL_DIR="$(pwd)"

  # Source the fixture
  source "${PLUGIN_ROOT}/tests/fixtures/sudo-check-function.sh"
}

teardown() {
  # Clean up temporary directory
  [ -n "${TEST_TEMP_DIR:-}" ] && rm -rf "${TEST_TEMP_DIR}"

  # Return to original directory
  [ -n "${ORIGINAL_DIR:-}" ] && cd "${ORIGINAL_DIR}" 2>/dev/null || true
}

@test "sudo-check: passwordless sudo is detected" {
  require_command sudo

  # Mock: Only test if user actually has passwordless sudo
  # (We can't easily mock sudo without elevated privileges)
  if ! sudo -n true 2>/dev/null; then
    skip "Passwordless sudo not configured for this user"
  fi

  run check_sudo_access

  assert_success
  assert_output_contains "✓ Sudo access available (passwordless)"
}

@test "sudo-check: detects non-interactive stdin" {
  require_command sudo

  # Mock: Test with non-interactive stdin (pipe)
  # Only proceed if we have passwordless sudo (to avoid hanging)
  if ! sudo -n true 2>/dev/null; then
    skip "Passwordless sudo not configured - cannot test non-interactive mode safely"
  fi

  # Run with piped stdin (non-interactive)
  run bash -c 'source tests/fixtures/sudo-check-function.sh && echo "" | check_sudo_access'

  assert_success
  assert_output_contains "WARNING: Running in non-interactive mode"
}

@test "sudo-check: user not in sudoers group returns error" {
  require_command sudo

  # This test requires mocking 'groups' command
  # Create a wrapper script that mocks groups without sudo
  cat > "${TEST_TEMP_DIR}/mock-groups.sh" << 'EOF'
#!/bin/bash
# Mock: user not in sudo/wheel/admin group
echo "users staff"
EOF
  chmod +x "${TEST_TEMP_DIR}/mock-groups.sh"

  # Override groups command in PATH
  export PATH="${TEST_TEMP_DIR}:${PATH}"

  # Create mock groups command
  ln -s "${TEST_TEMP_DIR}/mock-groups.sh" "${TEST_TEMP_DIR}/groups"

  # Source function and run
  run bash -c "source ${PLUGIN_ROOT}/tests/fixtures/sudo-check-function.sh && check_sudo_access"

  assert_failure
  assert_output_contains "ERROR: User not in sudo/wheel group"
  assert_output_contains "sudo usermod -aG sudo"
}

@test "sudo-check: timeout command is available" {
  require_command timeout

  # Verify timeout works as expected (basic sanity check)
  run timeout 1 sleep 0.5

  assert_success
}

@test "sudo-check: timeout prevents hang (mocked)" {
  require_command sudo
  require_command timeout

  # Create a mock sudo that hangs (simulates password prompt timeout)
  cat > "${TEST_TEMP_DIR}/sudo" << 'EOF'
#!/bin/bash
# Mock sudo that simulates hanging on password prompt
if [ "$1" = "-n" ]; then
  # Passwordless check fails
  exit 1
elif [ "$1" = "-v" ]; then
  # Simulate timeout by sleeping
  sleep 100
  exit 1
fi
exit 0
EOF
  chmod +x "${TEST_TEMP_DIR}/sudo"

  # Mock groups to pass group check
  cat > "${TEST_TEMP_DIR}/groups" << 'EOF'
#!/bin/bash
echo "sudo users"
EOF
  chmod +x "${TEST_TEMP_DIR}/groups"

  # Override PATH to use mocks
  export PATH="${TEST_TEMP_DIR}:${PATH}"

  # Run with timeout to prevent actual hang
  run timeout 35 bash -c "source ${PLUGIN_ROOT}/tests/fixtures/sudo-check-function.sh && check_sudo_access"

  # Should fail due to timeout
  assert_failure
  assert_output_contains "Could not validate sudo access"
}

@test "sudo-check: function exists and is callable" {
  # Verify the function loads without errors
  run bash -c "source ${PLUGIN_ROOT}/tests/fixtures/sudo-check-function.sh && type check_sudo_access"

  assert_success
  assert_output_contains "check_sudo_access is a function"
}

@test "sudo-check: error messages are informative" {
  # Test that error messages contain actionable information
  # Using mock to trigger error path
  cat > "${TEST_TEMP_DIR}/groups" << 'EOF'
#!/bin/bash
echo "users"
EOF
  chmod +x "${TEST_TEMP_DIR}/groups"

  export PATH="${TEST_TEMP_DIR}:${PATH}"

  run bash -c "source ${PLUGIN_ROOT}/tests/fixtures/sudo-check-function.sh && check_sudo_access"

  assert_failure
  # Should provide fix instructions
  assert_output_contains "To fix"
  assert_output_contains "usermod"
}

@test "sudo-check: handles wheel group (RHEL/Fedora)" {
  require_command sudo

  # Mock groups output with 'wheel' instead of 'sudo'
  cat > "${TEST_TEMP_DIR}/groups" << 'EOF'
#!/bin/bash
echo "users wheel"
EOF
  chmod +x "${TEST_TEMP_DIR}/groups"

  # Mock sudo to simulate passwordless
  cat > "${TEST_TEMP_DIR}/sudo" << 'EOF'
#!/bin/bash
if [ "$1" = "-n" ]; then
  exit 0
fi
exit 0
EOF
  chmod +x "${TEST_TEMP_DIR}/sudo"

  export PATH="${TEST_TEMP_DIR}:${PATH}"

  run bash -c "source ${PLUGIN_ROOT}/tests/fixtures/sudo-check-function.sh && check_sudo_access"

  assert_success
  assert_output_contains "✓ Sudo access available"
}

@test "sudo-check: handles admin group (macOS)" {
  require_command sudo

  # Mock groups output with 'admin' instead of 'sudo'
  cat > "${TEST_TEMP_DIR}/groups" << 'EOF'
#!/bin/bash
echo "staff admin"
EOF
  chmod +x "${TEST_TEMP_DIR}/groups"

  # Mock sudo to simulate passwordless
  cat > "${TEST_TEMP_DIR}/sudo" << 'EOF'
#!/bin/bash
if [ "$1" = "-n" ]; then
  exit 0
fi
exit 0
EOF
  chmod +x "${TEST_TEMP_DIR}/sudo"

  export PATH="${TEST_TEMP_DIR}:${PATH}"

  run bash -c "source ${PLUGIN_ROOT}/tests/fixtures/sudo-check-function.sh && check_sudo_access"

  assert_success
  assert_output_contains "✓ Sudo access available"
}

@test "sudo-check: regex prevents partial group matches" {
  # Ensure 'sudoers' doesn't match '\bsudo\b' pattern
  cat > "${TEST_TEMP_DIR}/groups" << 'EOF'
#!/bin/bash
echo "users sudoers-fake"
EOF
  chmod +x "${TEST_TEMP_DIR}/groups"

  export PATH="${TEST_TEMP_DIR}:${PATH}"

  run bash -c "source ${PLUGIN_ROOT}/tests/fixtures/sudo-check-function.sh && check_sudo_access"

  assert_failure
  assert_output_contains "User not in sudo/wheel group"
}
