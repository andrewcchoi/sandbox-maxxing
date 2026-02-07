#!/usr/bin/env bats
#
# Unit tests for docker-safety-hook.sh
# Tests the PreToolUse hook for Docker command safety checks

load '../../helpers/test_helper'

# Path to the hook script
HOOK_SCRIPT="${PLUGIN_ROOT}/hooks/docker-safety-hook.sh"

@test "docker-safety-hook: safe command (docker ps) allows execution" {
  require_command jq

  # Create safe command input
  input=$(create_hook_input "Bash" "docker ps -a")

  # Run hook
  run bash "$HOOK_SCRIPT" <<< "$input"

  # Should allow (exit 0, no output)
  assert_success
  [ -z "$output" ]
}

@test "docker-safety-hook: safe command (docker images) allows execution" {
  require_command jq

  input=$(create_hook_input "Bash" "docker images --format json")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  [ -z "$output" ]
}

@test "docker-safety-hook: destructive command (docker rm) prompts user" {
  require_command jq

  input=$(create_hook_input "Bash" "docker rm my-container")
  run bash "$HOOK_SCRIPT" <<< "$input"

  # Should ask (exit 0 with JSON output)
  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Destructive Docker command detected"
}

@test "docker-safety-hook: destructive command (docker rmi) prompts user" {
  require_command jq

  input=$(create_hook_input "Bash" "docker rmi my-image:latest")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Destructive Docker command detected"
}

@test "docker-safety-hook: destructive command (docker prune) prompts user" {
  require_command jq

  input=$(create_hook_input "Bash" "docker system prune -af")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Destructive Docker command detected"
}

@test "docker-safety-hook: destructive command (docker compose down) prompts user" {
  require_command jq

  input=$(create_hook_input "Bash" "docker compose down -v")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Destructive Docker command detected"
}

@test "docker-safety-hook: destructive command (docker kill) prompts user" {
  require_command jq

  input=$(create_hook_input "Bash" "docker kill container-id")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Destructive Docker command detected"
}

@test "docker-safety-hook: privileged flag (--privileged) prompts user" {
  require_command jq

  input=$(create_hook_input "Bash" "docker run --privileged ubuntu bash")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Privileged container"
}

@test "docker-safety-hook: privileged flag (--cap-add=ALL) prompts user" {
  require_command jq

  input=$(create_hook_input "Bash" "docker run --cap-add=ALL ubuntu")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Privileged container"
}

@test "docker-safety-hook: host network flag (--net=host) prompts user" {
  require_command jq

  input=$(create_hook_input "Bash" "docker run --net=host nginx")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Privileged container"
}

@test "docker-safety-hook: host PID flag (--pid=host) prompts user" {
  require_command jq

  input=$(create_hook_input "Bash" "docker run --pid=host ubuntu")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Privileged container"
}

@test "docker-safety-hook: docker socket mount prompts user" {
  require_command jq

  input=$(create_hook_input "Bash" "docker run -v /var/run/docker.sock:/var/run/docker.sock ubuntu")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Privileged container"
}

@test "docker-safety-hook: root volume mount prompts user" {
  require_command jq

  input=$(create_hook_input "Bash" "docker run -v /:/host ubuntu")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Privileged container"
}

@test "docker-safety-hook: disruptive command (docker stop) prompts user" {
  require_command jq

  input=$(create_hook_input "Bash" "docker stop my-container")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "stop/restart/pause"
}

@test "docker-safety-hook: disruptive command (docker restart) prompts user" {
  require_command jq

  input=$(create_hook_input "Bash" "docker restart my-container")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "stop/restart/pause"
}

@test "docker-safety-hook: disruptive command (docker pause) prompts user" {
  require_command jq

  input=$(create_hook_input "Bash" "docker pause my-container")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "stop/restart/pause"
}

@test "docker-safety-hook: malformed JSON allows execution (fail-open)" {
  # Test fail-open security model: if jq fails, allow the command
  input='{"broken json here'
  run bash "$HOOK_SCRIPT" <<< "$input"

  # Should allow (exit 0, no output)
  assert_success
  [ -z "$output" ]
}

@test "docker-safety-hook: empty input allows execution" {
  run bash "$HOOK_SCRIPT" <<< ""

  assert_success
  [ -z "$output" ]
}

@test "docker-safety-hook: missing command field allows execution" {
  require_command jq

  input='{"tool_name":"Bash","tool_input":{}}'
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  [ -z "$output" ]
}

@test "docker-safety-hook: case insensitive matching (DOCKER RM)" {
  require_command jq

  input=$(create_hook_input "Bash" "DOCKER RM my-container")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
}

@test "docker-safety-hook: word boundary prevents false positive (thrm)" {
  require_command jq

  # "thrm" contains "rm" but shouldn't trigger
  input=$(create_hook_input "Bash" "docker run ubuntu thrm script.sh")
  run bash "$HOOK_SCRIPT" <<< "$input"

  # Should allow (no false positive)
  assert_success
  [ -z "$output" ]
}

@test "docker-safety-hook: multiple safe commands in pipeline" {
  require_command jq

  input=$(create_hook_input "Bash" "docker ps | grep nginx | wc -l")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  [ -z "$output" ]
}

@test "docker-safety-hook: JSON output is valid when prompting" {
  require_command jq

  input=$(create_hook_input "Bash" "docker rm test")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success

  # Validate JSON structure
  echo "$output" | jq -e '.hookSpecificOutput.hookEventName == "PreToolUse"' >/dev/null
  echo "$output" | jq -e '.hookSpecificOutput.permissionDecision == "ask"' >/dev/null
  echo "$output" | jq -e '.hookSpecificOutput.permissionDecisionReason' >/dev/null
}

@test "docker-safety-hook: large input handled (DoS protection)" {
  require_command jq

  # Create >1MB input (should be truncated)
  large_command=$(printf 'A%.0s' {1..2000000})
  input=$(create_hook_input "Bash" "$large_command")

  run bash "$HOOK_SCRIPT" <<< "$input"

  # Should still work (truncates to 1MB)
  assert_success
}
