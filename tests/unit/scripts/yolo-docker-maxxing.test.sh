#!/usr/bin/env bats
#
# Unit tests for scripts/yolo-docker-maxxing.sh
# Tests script validation logic and edge cases
#

# Calculate plugin root from test file location
BATS_TEST_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
PLUGIN_ROOT="$(cd "$BATS_TEST_DIR/../../.." && pwd)"

load '../../helpers/test_helper'

# ============================================================================
# Regression tests
# ============================================================================

@test "yolo-docker-maxxing: grep pipefail fix - no unreplaced placeholders succeeds" {
  # Regression test for bug where grep returning exit code 1 (no matches)
  # combined with set -o pipefail caused script to fail even when validation
  # should succeed (no unreplaced placeholders = correct outcome)
  #
  # Bug: UNREPLACED=$(grep -oh "{{[A-Z_]*}}" ... | sort -u) fails with pipefail
  # Fix: UNREPLACED=$(grep -oh "{{[A-Z_]*}}" ... | sort -u || true)

  cd "$TEST_TEMP_DIR"

  # Create files with NO unreplaced placeholders (the success case)
  mkdir -p .devcontainer
  cat > .devcontainer/devcontainer.json << 'EOF'
{
  "name": "my-project",
  "build": {
    "dockerfile": "Dockerfile"
  }
}
EOF
  cat > docker-compose.yml << 'EOF'
version: "3.8"
services:
  app:
    build: .devcontainer
EOF

  # Run the exact validation pattern from yolo-docker-maxxing.sh
  # This MUST succeed when no placeholders are found
  run bash -c 'set -euo pipefail; UNREPLACED=$(grep -oh "{{[A-Z_]*}}" .devcontainer/devcontainer.json docker-compose.yml 2>/dev/null | sort -u || true); [ -z "$UNREPLACED" ] && echo "PASS" || echo "FAIL: $UNREPLACED"'

  assert_success
  [ "$output" = "PASS" ]
}

@test "yolo-docker-maxxing: grep pipefail fix - unreplaced placeholders detected" {
  # Verify that the validation still correctly detects unreplaced placeholders

  cd "$TEST_TEMP_DIR"

  # Create files WITH unreplaced placeholders
  mkdir -p .devcontainer
  cat > .devcontainer/devcontainer.json << 'EOF'
{
  "name": "{{PROJECT_NAME}}",
  "forwardPorts": [{{APP_PORT}}]
}
EOF
  cat > docker-compose.yml << 'EOF'
version: "3.8"
services:
  app:
    ports:
      - "{{APP_PORT}}:8000"
EOF

  # Run the exact validation pattern from yolo-docker-maxxing.sh
  # This should find the unreplaced placeholders
  run bash -c 'set -euo pipefail; UNREPLACED=$(grep -oh "{{[A-Z_]*}}" .devcontainer/devcontainer.json docker-compose.yml 2>/dev/null | sort -u || true); [ -n "$UNREPLACED" ] && echo "FOUND: $UNREPLACED" || echo "NONE"'

  assert_success
  assert_output_contains "{{PROJECT_NAME}}"
  assert_output_contains "{{APP_PORT}}"
}

@test "yolo-docker-maxxing: script has valid bash syntax" {
  local script="${PLUGIN_ROOT}/scripts/yolo-docker-maxxing.sh"
  [ -f "$script" ] || skip "yolo-docker-maxxing.sh not found"

  assert_valid_shell "$script"
}

@test "yolo-docker-maxxing: script has shebang" {
  local script="${PLUGIN_ROOT}/scripts/yolo-docker-maxxing.sh"
  [ -f "$script" ] || skip "yolo-docker-maxxing.sh not found"

  local first_line
  first_line=$(head -n 1 "$script")

  [[ "$first_line" =~ ^#!/ ]]
}

@test "yolo-docker-maxxing: script uses set -euo pipefail" {
  local script="${PLUGIN_ROOT}/scripts/yolo-docker-maxxing.sh"
  [ -f "$script" ] || skip "yolo-docker-maxxing.sh not found"

  # Verify strict mode is enabled
  grep -q "set -euo pipefail" "$script"
}

@test "yolo-docker-maxxing: grep validation uses || true for pipefail safety" {
  local script="${PLUGIN_ROOT}/scripts/yolo-docker-maxxing.sh"
  [ -f "$script" ] || skip "yolo-docker-maxxing.sh not found"

  # Verify the fix is in place - grep command must end with || true
  grep -q 'sort -u || true' "$script"
}

# ============================================================================
# Script structure validation
# ============================================================================

@test "yolo-docker-maxxing: sources common.sh" {
  local script="${PLUGIN_ROOT}/scripts/yolo-docker-maxxing.sh"
  [ -f "$script" ] || skip "yolo-docker-maxxing.sh not found"

  grep -q 'source.*common\.sh' "$script"
}

@test "yolo-docker-maxxing: handles --portless argument" {
  local script="${PLUGIN_ROOT}/scripts/yolo-docker-maxxing.sh"
  [ -f "$script" ] || skip "yolo-docker-maxxing.sh not found"

  grep -q '\-\-portless' "$script"
}
