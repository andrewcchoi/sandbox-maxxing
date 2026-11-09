#!/usr/bin/env bats
#
# Manifest Validation Tests
# Validates plugin.json, marketplace.json, and hooks.json structure and consistency
#

# Calculate plugin root from test file location
BATS_TEST_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
PLUGIN_ROOT="$(cd "$BATS_TEST_DIR/../../.." && pwd)"

load '../../helpers/test_helper'

# Test-specific constants
PLUGIN_JSON="${PLUGIN_ROOT}/.claude-plugin/plugin.json"
MARKETPLACE_JSON="${PLUGIN_ROOT}/.claude-plugin/marketplace.json"
HOOKS_JSON="${PLUGIN_ROOT}/hooks/hooks.json"

# ============================================================================
# plugin.json validation tests
# ============================================================================

@test "plugin.json exists" {
  [ -f "$PLUGIN_JSON" ]
}

@test "plugin.json is valid JSON" {
  assert_valid_json "$PLUGIN_JSON"
}

@test "plugin.json has required field: name" {
  run jq -r '.name' "$PLUGIN_JSON"
  assert_success
  [ -n "$output" ]
  [ "$output" != "null" ]
}

@test "plugin.json has required field: version" {
  run jq -r '.version' "$PLUGIN_JSON"
  assert_success
  [ -n "$output" ]
  [ "$output" != "null" ]
}

@test "plugin.json has required field: description" {
  run jq -r '.description' "$PLUGIN_JSON"
  assert_success
  [ -n "$output" ]
  [ "$output" != "null" ]
}

@test "plugin.json has required field: author" {
  run jq -r '.author' "$PLUGIN_JSON"
  assert_success
  [ "$output" != "null" ]
}

@test "plugin.json version follows semver format" {
  run jq -r '.version' "$PLUGIN_JSON"
  assert_success
  # Check semver format: X.Y.Z
  [[ "$output" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

# ============================================================================
# marketplace.json validation tests
# ============================================================================

@test "marketplace.json exists" {
  [ -f "$MARKETPLACE_JSON" ]
}

@test "marketplace.json is valid JSON" {
  assert_valid_json "$MARKETPLACE_JSON"
}

@test "marketplace.json version matches plugin.json version" {
  local plugin_version
  local marketplace_version

  plugin_version=$(jq -r '.version' "$PLUGIN_JSON")
  marketplace_version=$(jq -r '.version' "$MARKETPLACE_JSON")

  [ "$plugin_version" = "$marketplace_version" ]
}

@test "marketplace.json has required field: name" {
  run jq -r '.name' "$MARKETPLACE_JSON"
  assert_success
  [ -n "$output" ]
  [ "$output" != "null" ]
}

@test "marketplace.json has required field: plugins array" {
  run jq -r '.plugins | type' "$MARKETPLACE_JSON"
  assert_success
  [ "$output" = "array" ]
}

# ============================================================================
# hooks.json validation tests
# ============================================================================

@test "hooks.json exists" {
  [ -f "$HOOKS_JSON" ]
}

@test "hooks.json is valid JSON" {
  assert_valid_json "$HOOKS_JSON"
}

@test "hooks.json has hooks object" {
  run jq -r '.hooks | type' "$HOOKS_JSON"
  assert_success
  [ "$output" = "object" ]
}

@test "hooks.json references only existing script files" {
  # Extract all command values from hooks.json
  local commands
  commands=$(jq -r '.. | .command? | select(. != null)' "$HOOKS_JSON")

  # Check each command references an existing file
  while IFS= read -r cmd; do
    # Extract script filename from command (handles run-hook.cmd wrapper pattern)
    local script
    script=$(echo "$cmd" | grep -oE '[a-zA-Z0-9_-]+\.sh' | head -1)

    if [ -n "$script" ]; then
      local script_path="${PLUGIN_ROOT}/hooks/${script}"
      [ -f "$script_path" ] || {
        echo "Script not found: $script_path (from command: $cmd)" >&2
        return 1
      }
    fi
  done <<< "$commands"
}

@test "hooks.json commands have valid timeout values" {
  # Extract all timeout values
  local timeouts
  timeouts=$(jq -r '.. | .timeout? | select(. != null)' "$HOOKS_JSON")

  # Check each timeout is a positive integer
  while IFS= read -r timeout; do
    [[ "$timeout" =~ ^[0-9]+$ ]] || {
      echo "Invalid timeout value: $timeout" >&2
      return 1
    }

    [ "$timeout" -gt 0 ] || {
      echo "Timeout must be positive: $timeout" >&2
      return 1
    }
  done <<< "$timeouts"
}

@test "hooks.json uses valid hook event types" {
  local valid_events="SessionStart SessionEnd PreToolUse PostToolUse Stop SubagentStop UserPromptSubmit PreCompact Notification"

  # Get all hook event names
  local events
  events=$(jq -r '.hooks | keys[]' "$HOOKS_JSON")

  # Check each event is valid
  while IFS= read -r event; do
    if ! echo "$valid_events" | grep -qw "$event"; then
      echo "Invalid hook event: $event" >&2
      return 1
    fi
  done <<< "$events"
}
