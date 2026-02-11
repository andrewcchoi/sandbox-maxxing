#!/usr/bin/env bash
#
# Extracted sudo access check function from yolo-linux-maxxing.md
# This fixture is used for unit testing the sudo detection logic
#
# Source: commands/yolo-linux-maxxing.md
#
# NOTE: The main command's check_sudo_access() calls open_auth_window()
# which opens a popup terminal for password entry. This fixture provides
# a simplified version for unit testing that doesn't require the popup.

# Stub for open_auth_window - override in tests if needed
open_auth_window() {
  # Default stub returns failure (no popup available in test env)
  return 1
}

check_sudo_access() {
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

  # User needs to enter password - try popup window
  echo "  Sudo requires password authentication."
  echo ""
  echo "  Opening authentication window..."
  echo ""

  if open_auth_window; then
    # Verify sudo now works
    if sudo -n true 2>/dev/null; then
      return 0
    fi
  fi

  # Popup failed or unavailable - provide manual instructions
  echo ""
  echo "  ✗ Could not open authentication window."
  echo ""
  echo "  Please run this command in your terminal first:"
  echo "    sudo -v"
  echo ""
  echo "  Then re-run: /sandboxxer:yolo-linux-maxxing"
  return 1
}
