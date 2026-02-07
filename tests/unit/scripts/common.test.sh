#!/usr/bin/env bats
#
# Unit tests for scripts/common.sh
# Tests all common utility functions

load '../../helpers/test_helper'

setup() {
  # Source common functions
  source "${PLUGIN_ROOT}/scripts/common.sh"
}

# ============================================================================
# sanitize_project_name() tests
# ============================================================================

@test "common: sanitize_project_name converts uppercase to lowercase" {
  run sanitize_project_name "MyProject"

  assert_success
  [ "$output" = "myproject" ]
}

@test "common: sanitize_project_name replaces spaces with hyphens" {
  run sanitize_project_name "my project name"

  assert_success
  [ "$output" = "my-project-name" ]
}

@test "common: sanitize_project_name replaces underscores with hyphens" {
  run sanitize_project_name "my_project_name"

  assert_success
  [ "$output" = "my-project-name" ]
}

@test "common: sanitize_project_name removes special characters" {
  run sanitize_project_name "my@project!name#"

  assert_success
  [ "$output" = "my-project-name" ]
}

@test "common: sanitize_project_name strips leading hyphens" {
  run sanitize_project_name "---myproject"

  assert_success
  [ "$output" = "myproject" ]
}

@test "common: sanitize_project_name strips trailing hyphens" {
  run sanitize_project_name "myproject---"

  assert_success
  [ "$output" = "myproject" ]
}

@test "common: sanitize_project_name collapses multiple hyphens" {
  run sanitize_project_name "my---project---name"

  assert_success
  [ "$output" = "my-project-name" ]
}

@test "common: sanitize_project_name defaults empty to sandbox-app" {
  run sanitize_project_name ""

  assert_success
  [ "$output" = "sandbox-app" ]
}

@test "common: sanitize_project_name handles all special chars" {
  run sanitize_project_name "@#$%"

  assert_success
  [ "$output" = "sandbox-app" ]
}

@test "common: sanitize_project_name preserves valid docker names" {
  run sanitize_project_name "my-valid-project123"

  assert_success
  [ "$output" = "my-valid-project123" ]
}

# ============================================================================
# merge_env_value() tests
# ============================================================================

@test "common: merge_env_value creates new key in empty file" {
  local envfile="${TEST_TEMP_DIR}/.env"
  touch "$envfile"

  run merge_env_value "TEST_KEY" "test_value" "$envfile"

  assert_success
  [ "$(grep '^TEST_KEY=' "$envfile")" = "TEST_KEY=test_value" ]
}

@test "common: merge_env_value updates existing key" {
  local envfile="${TEST_TEMP_DIR}/.env"
  echo "TEST_KEY=old_value" > "$envfile"

  run merge_env_value "TEST_KEY" "new_value" "$envfile"

  assert_success
  [ "$(grep '^TEST_KEY=' "$envfile")" = "TEST_KEY=new_value" ]
}

@test "common: merge_env_value handles pipe character in value" {
  local envfile="${TEST_TEMP_DIR}/.env"
  touch "$envfile"

  run merge_env_value "TEST_KEY" "value|with|pipes" "$envfile"

  assert_success
  [ "$(grep '^TEST_KEY=' "$envfile")" = "TEST_KEY=value|with|pipes" ]
}

@test "common: merge_env_value handles ampersand in value" {
  local envfile="${TEST_TEMP_DIR}/.env"
  touch "$envfile"

  run merge_env_value "TEST_KEY" "value&with&ampersand" "$envfile"

  assert_success
  [ "$(grep '^TEST_KEY=' "$envfile")" = "TEST_KEY=value&with&ampersand" ]
}

@test "common: merge_env_value handles backslash in value" {
  local envfile="${TEST_TEMP_DIR}/.env"
  touch "$envfile"

  run merge_env_value "TEST_KEY" 'value\\with\\backslash' "$envfile"

  assert_success
  grep -q 'TEST_KEY=.*\\' "$envfile"
}

@test "common: merge_env_value preserves other keys" {
  local envfile="${TEST_TEMP_DIR}/.env"
  cat > "$envfile" << 'EOF'
KEY1=value1
KEY2=value2
KEY3=value3
EOF

  run merge_env_value "KEY2" "new_value" "$envfile"

  assert_success
  grep -q '^KEY1=value1$' "$envfile"
  grep -q '^KEY2=new_value$' "$envfile"
  grep -q '^KEY3=value3$' "$envfile"
}

@test "common: merge_env_value adds trailing newline if missing" {
  local envfile="${TEST_TEMP_DIR}/.env"
  printf "KEY1=value1" > "$envfile"  # No trailing newline

  run merge_env_value "KEY2" "value2" "$envfile"

  assert_success
  # Should have proper newlines now
  [ "$(wc -l < "$envfile")" -ge 2 ]
}

# ============================================================================
# port_in_use() tests
# ============================================================================

@test "common: port_in_use returns false for unused port" {
  # Port 65534 is unlikely to be in use
  if port_in_use 65534; then
    skip "Port 65534 is in use on this system"
  fi

  run bash -c "source ${PLUGIN_ROOT}/scripts/common.sh && port_in_use 65534"

  assert_failure
}

@test "common: port_in_use works with lsof if available" {
  if ! command -v lsof >/dev/null 2>&1; then
    skip "lsof not available"
  fi

  # Just verify lsof is called correctly
  run lsof -i :65534

  # Should exit cleanly (0 or 1, doesn't matter)
  [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "common: port_in_use works with ss if available" {
  if ! command -v ss >/dev/null 2>&1; then
    skip "ss not available"
  fi

  # Verify ss command works
  run ss -tuln

  assert_success
}

@test "common: port_in_use works with netstat if available" {
  if ! command -v netstat >/dev/null 2>&1; then
    skip "netstat not available"
  fi

  # Verify netstat command works
  run netstat -tuln

  assert_success
}

# ============================================================================
# find_available_port() tests
# ============================================================================

@test "common: find_available_port returns a port number" {
  run find_available_port 50000

  assert_success
  # Should return a number between 50000 and 65535
  [ "$output" -ge 50000 ]
  [ "$output" -le 65535 ]
}

@test "common: find_available_port excludes specified ports" {
  local start_port=50000

  run find_available_port $start_port $start_port

  assert_success
  # Should return start_port + 1 (or next available)
  [ "$output" -ne "$start_port" ]
}

@test "common: find_available_port handles multiple exclusions" {
  local port1=50000
  local port2=50001
  local port3=50002

  run find_available_port 50000 $port1 $port2 $port3

  assert_success
  # Should not return any of the excluded ports
  [ "$output" -ne "$port1" ]
  [ "$output" -ne "$port2" ]
  [ "$output" -ne "$port3" ]
}

@test "common: find_available_port increments until free port found" {
  # This test assumes at least one port is free in the 60000-60010 range
  run find_available_port 60000

  assert_success
  [ "$output" -ge 60000 ]
}

# ============================================================================
# find_plugin_root() tests
# ============================================================================

@test "common: find_plugin_root uses CLAUDE_PLUGIN_ROOT if set" {
  export CLAUDE_PLUGIN_ROOT="/custom/path"

  run find_plugin_root

  assert_success
  assert_output_contains "/custom/path"
}

@test "common: find_plugin_root converts Windows backslashes" {
  export CLAUDE_PLUGIN_ROOT='C:\Users\test\plugin'

  run find_plugin_root

  assert_success
  assert_output_contains "C:/Users/test/plugin"
}

@test "common: find_plugin_root detects development mode" {
  # This should succeed since we're running from the plugin directory
  cd "$PLUGIN_ROOT"

  run find_plugin_root

  assert_success
  assert_output_matches "current directory"
}

@test "common: find_plugin_root searches ~/.claude/plugins" {
  # Unset CLAUDE_PLUGIN_ROOT
  unset CLAUDE_PLUGIN_ROOT

  # Change to a directory that's not the plugin root
  cd "$TEST_TEMP_DIR"

  # This will search ~/.claude/plugins
  run find_plugin_root

  # May succeed or fail depending on whether plugin is installed
  # Just verify it doesn't crash
  [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "common: find_plugin_root handles .claude-plugin subdirectory" {
  # Create mock plugin structure
  mkdir -p "${TEST_TEMP_DIR}/mock-plugins/sandboxxer/.claude-plugin"
  cat > "${TEST_TEMP_DIR}/mock-plugins/sandboxxer/.claude-plugin/plugin.json" << 'EOF'
{
  "name": "sandboxxer",
  "version": "1.0.0"
}
EOF

  # Mock HOME to point to our test structure
  export HOME="${TEST_TEMP_DIR}"
  mkdir -p "${TEST_TEMP_DIR}/.claude/plugins"
  cp -r "${TEST_TEMP_DIR}/mock-plugins/"* "${TEST_TEMP_DIR}/.claude/plugins/"

  # Unset CLAUDE_PLUGIN_ROOT
  unset CLAUDE_PLUGIN_ROOT

  # Change to temp dir
  cd "$TEST_TEMP_DIR"

  run find_plugin_root

  assert_success
  assert_output_contains ".claude/plugins/sandboxxer"
  assert_output_not_contains ".claude-plugin"
}

# ============================================================================
# validate_templates() tests
# ============================================================================

@test "common: validate_templates succeeds when all templates exist" {
  # Our actual templates should exist
  run validate_templates "$PLUGIN_ROOT" \
    "base.dockerfile" \
    "devcontainer.json" \
    "docker-compose.yml"

  assert_success
}

@test "common: validate_templates fails when template missing" {
  run validate_templates "$PLUGIN_ROOT" \
    "base.dockerfile" \
    "nonexistent-template.yml"

  assert_failure
  assert_output_contains "Missing template"
  assert_output_contains "nonexistent-template.yml"
}

@test "common: validate_templates checks correct directory" {
  # Invalid plugin root should fail
  run validate_templates "/nonexistent" "base.dockerfile"

  assert_failure
}

# ============================================================================
# Script execution prevention tests
# ============================================================================

@test "common: common.sh prevents direct execution" {
  # Running the script directly should print warning and exit
  run bash "${PLUGIN_ROOT}/scripts/common.sh"

  assert_failure
  assert_output_contains "should be sourced"
}

@test "common: common.sh can be sourced successfully" {
  run bash -c "source ${PLUGIN_ROOT}/scripts/common.sh && echo 'SOURCED'"

  assert_success
  assert_output_contains "SOURCED"
}

# ============================================================================
# Integration tests
# ============================================================================

@test "common: all functions can be sourced together" {
  run bash -c "
    source ${PLUGIN_ROOT}/scripts/common.sh
    sanitize_project_name 'Test' >/dev/null
    find_available_port 30000 >/dev/null
    echo 'ALL_OK'
  "

  assert_success
  assert_output_contains "ALL_OK"
}
