#!/usr/bin/env bash
#
# Extracted sudo access check function from yolo-linux-maxxing.md (lines 77-121)
# This fixture is used for unit testing the sudo detection logic
#
# Source: commands/yolo-linux-maxxing.md:77-121

check_sudo_access() {
  # Check if stdin is interactive
  if [ ! -t 0 ]; then
    echo "WARNING: Running in non-interactive mode."
    echo "Password prompts may not work correctly."
  fi

  # Test passwordless sudo first
  if sudo -n true 2>/dev/null; then
    echo "  ✓ Sudo access available (passwordless)"
    return 0
  fi

  # Check group membership
  if ! groups | grep -qE '\b(sudo|wheel|admin)\b'; then
    echo "  ✗ ERROR: User not in sudo/wheel group"
    echo ""
    echo "  To fix, ask an administrator to run:"
    echo "    sudo usermod -aG sudo $(whoami)"
    echo ""
    echo "  Then log out and back in, and retry."
    return 1
  fi

  echo "  Sudo access requires password authentication."
  echo "  You will be prompted for your password (30 second timeout)."
  echo ""

  # Attempt with timeout to prevent hang
  if ! timeout 30 sudo -v 2>/dev/null; then
    echo ""
    echo "  ✗ ERROR: Could not validate sudo access"
    echo ""
    echo "  Possible causes:"
    echo "    - Incorrect password"
    echo "    - Sudo timeout (30 seconds)"
    echo "    - Authentication backend issue"
    echo ""
    echo "  Fix: Run 'sudo -v' manually to verify access"
    return 1
  fi

  echo "  ✓ Sudo access verified"
  return 0
}
