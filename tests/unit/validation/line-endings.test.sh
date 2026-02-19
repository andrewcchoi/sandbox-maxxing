#!/usr/bin/env bats
#
# Line Ending Validation Tests
# Ensures files have correct line endings per .gitattributes rules
# Critical for cross-platform compatibility (Windows CMD vs Unix bash)

BATS_TEST_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
PLUGIN_ROOT="$(cd "$BATS_TEST_DIR/../../.." && pwd)"

load '../../helpers/test_helper'

# ============================================================================
# Windows Batch Files - MUST be CRLF
# ============================================================================

@test "all .cmd files have CRLF line endings" {
  local cmd_files
  cmd_files=$(find "$PLUGIN_ROOT" -name "*.cmd" -type f 2>/dev/null)

  [ -n "$cmd_files" ] || skip "No .cmd files found"

  while IFS= read -r cmd_file; do
    # Skip run-hook.cmd - it's a polyglot requiring LF
    [[ "$(basename "$cmd_file")" == "run-hook.cmd" ]] && continue
    assert_crlf_line_endings "$cmd_file"
  done <<< "$cmd_files"
}

@test "hooks/run-hook.cmd has LF line endings (required for polyglot heredoc)" {
  local file="${PLUGIN_ROOT}/hooks/run-hook.cmd"
  [ -f "$file" ] || skip "run-hook.cmd not found"

  # LF is required - CRLF breaks bash heredoc parsing
  assert_lf_line_endings "$file"
}

# ============================================================================
# Shell Scripts - MUST be LF
# ============================================================================

@test "all .sh files have LF line endings" {
  while IFS= read -r sh_file; do
    assert_lf_line_endings "$sh_file"
  done < <(find "$PLUGIN_ROOT" -name "*.sh" -type f)
}

@test "hook shell scripts have LF line endings" {
  local hooks_dir="${PLUGIN_ROOT}/hooks"
  [ -d "$hooks_dir" ] || skip "hooks directory not found"

  while IFS= read -r hook_script; do
    assert_lf_line_endings "$hook_script"
  done < <(find "$hooks_dir" -name "*.sh" -type f)
}

# ============================================================================
# Docker Files - MUST be LF
# ============================================================================

@test "all Dockerfiles have LF line endings" {
  while IFS= read -r dockerfile; do
    assert_lf_line_endings "$dockerfile"
  done < <(find "$PLUGIN_ROOT" -name "Dockerfile*" -type f 2>/dev/null || true)
}

@test "docker-compose files have LF line endings" {
  while IFS= read -r compose_file; do
    assert_lf_line_endings "$compose_file"
  done < <(find "$PLUGIN_ROOT" -name "docker-compose*.yml" -o -name "docker-compose*.yaml" 2>/dev/null || true)
}

# ============================================================================
# Polyglot Script Validation
# ============================================================================

@test "run-hook.cmd polyglot works with LF on bash" {
  local wrapper="${PLUGIN_ROOT}/hooks/run-hook.cmd"
  [ -f "$wrapper" ] || skip "run-hook.cmd not found"

  # Verify it has LF (NOT CRLF)
  assert_lf_line_endings "$wrapper"

  # Verify bash can parse and execute it
  run bash -n "$wrapper"
  assert_success
}

@test "run-hook.cmd executes successfully with LF line endings" {
  local temp_hooks="${TEST_TEMP_DIR}/hooks"
  mkdir -p "$temp_hooks"

  # Copy the LF wrapper
  cp "${PLUGIN_ROOT}/hooks/run-hook.cmd" "$temp_hooks/"

  # Create a test script (with LF)
  printf '#!/usr/bin/env bash\necho "LF_TEST_PASSED"\nexit 0\n' > "$temp_hooks/test.sh"
  chmod +x "$temp_hooks/test.sh"

  # Execute via wrapper
  cd "$temp_hooks"
  run bash ./run-hook.cmd test.sh

  assert_success
  assert_output_contains "LF_TEST_PASSED"
}
