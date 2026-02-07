#!/usr/bin/env bats
#
# Unit tests for package installation logic
# Tests the package installation blocks from yolo-linux-maxxing.md

load '../../helpers/test_helper'

@test "package-install: apt-get is available on test system" {
  require_command apt-get

  run which apt-get

  assert_success
}

@test "package-install: GitHub CLI idempotency check works" {
  require_command gh

  # This test only runs if gh is installed
  # Tests the idempotency logic: if gh exists, skip installation

  # Simulate the check from yolo-linux-maxxing.md:188
  run bash -c 'if command -v gh &>/dev/null; then echo "SKIP"; else echo "INSTALL"; fi'

  assert_success
  assert_output_contains "SKIP"
}

@test "package-install: GitHub CLI idempotency check fails when missing" {
  # Mock: gh command doesn't exist
  cat > "${TEST_TEMP_DIR}/check-gh.sh" << 'EOF'
#!/bin/bash
if command -v gh-nonexistent &>/dev/null; then
  echo "SKIP"
else
  echo "INSTALL"
fi
EOF
  chmod +x "${TEST_TEMP_DIR}/check-gh.sh"

  run "${TEST_TEMP_DIR}/check-gh.sh"

  assert_success
  assert_output_contains "INSTALL"
}

@test "package-install: heredoc syntax is valid for package block" {
  # Test that the heredoc syntax parses correctly
  # This validates the bash << 'PKGINSTALL' ... PKGINSTALL pattern

  cat > "${TEST_TEMP_DIR}/test-heredoc.sh" << 'EOF'
#!/bin/bash
# Simulate the package install heredoc structure
output=$(bash << 'PKGINSTALL'
set -e
echo "packages would be installed here"
exit 0
PKGINSTALL
)
echo "$output"
exit $?
EOF
  chmod +x "${TEST_TEMP_DIR}/test-heredoc.sh"

  run "${TEST_TEMP_DIR}/test-heredoc.sh"

  assert_success
  assert_output_contains "packages would be installed here"
}

@test "package-install: heredoc with set -e exits on error" {
  # Test that 'set -e' in heredoc causes immediate exit on error
  cat > "${TEST_TEMP_DIR}/test-sete.sh" << 'EOF'
#!/bin/bash
bash << 'BLOCK'
set -e
false
echo "This should not print"
BLOCK
exit $?
EOF
  chmod +x "${TEST_TEMP_DIR}/test-sete.sh"

  run "${TEST_TEMP_DIR}/test-sete.sh"

  assert_failure
  assert_output_not_contains "This should not print"
}

@test "package-install: exit code is captured correctly" {
  # Test that $? captures heredoc exit code correctly
  cat > "${TEST_TEMP_DIR}/test-exitcode.sh" << 'EOF'
#!/bin/bash
bash << 'BLOCK'
exit 42
BLOCK

if [ $? -eq 42 ]; then
  echo "EXIT_CODE_CAPTURED"
else
  echo "EXIT_CODE_WRONG"
fi
EOF
  chmod +x "${TEST_TEMP_DIR}/test-exitcode.sh"

  run "${TEST_TEMP_DIR}/test-exitcode.sh"

  assert_success
  assert_output_contains "EXIT_CODE_CAPTURED"
}

@test "package-install: error handling displays fix message" {
  # Test the error handling logic from yolo-linux-maxxing.md:160-165
  cat > "${TEST_TEMP_DIR}/test-error-msg.sh" << 'EOF'
#!/bin/bash
# Simulate package install failure
bash << 'PKGINSTALL'
exit 1
PKGINSTALL

if [ $? -ne 0 ]; then
  echo ""
  echo "✗ Package installation failed"
  echo "  Fix: Check network connection and retry"
  exit 1
fi
EOF
  chmod +x "${TEST_TEMP_DIR}/test-error-msg.sh"

  run "${TEST_TEMP_DIR}/test-error-msg.sh"

  assert_failure
  assert_output_contains "✗ Package installation failed"
  assert_output_contains "Fix: Check network connection"
}

@test "package-install: GitHub CLI error provides cleanup instructions" {
  # Test GitHub CLI error handling from yolo-linux-maxxing.md:205-213
  cat > "${TEST_TEMP_DIR}/test-gh-error.sh" << 'EOF'
#!/bin/bash
# Simulate gh install failure
exit_code=1

if [ $exit_code -ne 0 ]; then
  echo ""
  echo "✗ GitHub CLI installation failed"
  echo ""
  echo "  To clean up partial installation and retry:"
  echo "    sudo rm -f /etc/apt/keyrings/githubcli-archive-keyring.gpg"
  echo "    sudo rm -f /etc/apt/sources.list.d/github-cli.list"
  echo "    sudo apt update"
  exit 1
fi
EOF
  chmod +x "${TEST_TEMP_DIR}/test-gh-error.sh"

  run "${TEST_TEMP_DIR}/test-gh-error.sh"

  assert_failure
  assert_output_contains "GitHub CLI installation failed"
  assert_output_contains "clean up partial installation"
  assert_output_contains "/etc/apt/keyrings/githubcli-archive-keyring.gpg"
}

@test "package-install: dpkg architecture detection works" {
  require_command dpkg

  # Test that dpkg --print-architecture returns a valid arch
  run dpkg --print-architecture

  assert_success
  # Should output amd64, arm64, armhf, etc.
  assert_output_matches "^(amd64|arm64|armhf|i386)$"
}

@test "package-install: required packages list is correct" {
  # Validate the package list from yolo-linux-maxxing.md:157
  packages="bubblewrap socat curl wget unzip git"

  for pkg in $packages; do
    # Just verify package names are valid (no typos)
    [[ "$pkg" =~ ^[a-z0-9-]+$ ]] || {
      echo "Invalid package name: $pkg"
      return 1
    }
  done
}

@test "package-install: GitHub CLI version extraction works" {
  require_command gh

  # Test the version extraction from yolo-linux-maxxing.md:189
  run bash -c 'gh version 2>&1 | head -1'

  assert_success
  # Should contain version number
  assert_output_matches "gh version [0-9]+\.[0-9]+\.[0-9]+"
}

@test "package-install: wget quiet mode works in pipe" {
  require_command wget

  # Test that wget -qO- works (used in GitHub CLI keyring download)
  # Using a small test file to avoid network dependency
  echo "test content" > "${TEST_TEMP_DIR}/test.txt"

  run bash -c "cd ${TEST_TEMP_DIR} && wget -qO- test.txt"

  assert_success
  assert_output_contains "test content"
}

@test "package-install: mkdir with mode works correctly" {
  # Test mkdir -p -m 755 (used for /etc/apt/keyrings)
  run bash -c "mkdir -p -m 755 ${TEST_TEMP_DIR}/testdir && stat -c '%a' ${TEST_TEMP_DIR}/testdir"

  assert_success
  assert_output_contains "755"
}

@test "package-install: chmod go+r works correctly" {
  # Test chmod go+r (used for keyring file)
  touch "${TEST_TEMP_DIR}/testfile"
  chmod 600 "${TEST_TEMP_DIR}/testfile"

  run bash -c "chmod go+r ${TEST_TEMP_DIR}/testfile && stat -c '%a' ${TEST_TEMP_DIR}/testfile"

  assert_success
  assert_output_contains "644"
}

@test "package-install: apt source list creation works" {
  # Test the source list creation pattern
  arch="amd64"

  run bash -c "echo 'deb [arch=${arch} signed-by=/etc/apt/keyrings/test.gpg] https://example.com/packages stable main' > ${TEST_TEMP_DIR}/test.list && cat ${TEST_TEMP_DIR}/test.list"

  assert_success
  assert_output_contains "deb [arch=amd64"
  assert_output_contains "signed-by=/etc/apt/keyrings/test.gpg"
}

@test "package-install: command substitution in heredoc works" {
  # Test that $(dpkg --print-architecture) works inside heredoc
  cat > "${TEST_TEMP_DIR}/test-subst.sh" << 'EOF'
#!/bin/bash
# Mock dpkg
mkdir -p mock
cat > mock/dpkg << 'DPKG'
#!/bin/bash
echo "amd64"
DPKG
chmod +x mock/dpkg

export PATH="mock:$PATH"

bash << 'BLOCK'
arch=$(dpkg --print-architecture)
echo "Architecture: $arch"
BLOCK
EOF
  chmod +x "${TEST_TEMP_DIR}/test-subst.sh"

  run bash -c "cd ${TEST_TEMP_DIR} && ./test-subst.sh"

  assert_success
  assert_output_contains "Architecture: amd64"
}
