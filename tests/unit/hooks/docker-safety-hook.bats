#!/usr/bin/env bats
#
# Unit tests for docker-safety-hook.sh
# Tests the PreToolUse hook for Docker command safety checks

# Calculate plugin root from test file location
BATS_TEST_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
PLUGIN_ROOT="$(cd "$BATS_TEST_DIR/../../.." && pwd)"

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

# --- Regression: false positives fixed by token-based parsing ---

@test "docker-safety-hook: allows docker run --rm (the eval false positive)" {
  require_command jq

  input=$(create_hook_input "Bash" "docker run --rm img ffmpeg -version")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  [ -z "$output" ]
}

@test "docker-safety-hook: allows docker run --rm with container rm arg" {
  require_command jq

  input=$(create_hook_input "Bash" "docker run --rm -v /data:/data img rm -rf /data/tmp")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  [ -z "$output" ]
}

@test "docker-safety-hook: allows docker exec running rm inside container" {
  require_command jq

  input=$(create_hook_input "Bash" "docker exec c rm /tmp/f")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  [ -z "$output" ]
}

@test "docker-safety-hook: allows rm after docker in a separate command" {
  require_command jq

  input=$(create_hook_input "Bash" "docker logs x | tail -5; rm -f out.txt")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  [ -z "$output" ]
}

@test "docker-safety-hook: allows rm after docker with &&" {
  require_command jq

  input=$(create_hook_input "Bash" "docker build -t img . && rm -rf build/")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  [ -z "$output" ]
}

@test "docker-safety-hook: allows --stop-timeout is not stop" {
  require_command jq

  input=$(create_hook_input "Bash" "docker run -d --stop-timeout 30 nginx")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  [ -z "$output" ]
}

@test "docker-safety-hook: allows --restart policy is not restart" {
  require_command jq

  input=$(create_hook_input "Bash" "docker run -d --restart unless-stopped nginx")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  [ -z "$output" ]
}

@test "docker-safety-hook: allows host dir with trailing slash is not root mount" {
  require_command jq

  input=$(create_hook_input "Bash" "docker run -v /home/me/out/:/out img")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  [ -z "$output" ]
}

@test "docker-safety-hook: allows named volume mount" {
  require_command jq

  input=$(create_hook_input "Bash" "docker run --mount type=volume,src=data,dst=/data img")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  [ -z "$output" ]
}

@test "docker-safety-hook: allows --network none" {
  require_command jq

  input=$(create_hook_input "Bash" "docker run --network none img")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  [ -z "$output" ]
}

@test "docker-safety-hook: allows compose up" {
  require_command jq

  input=$(create_hook_input "Bash" "docker compose -f a.yml up -d")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  [ -z "$output" ]
}

@test "docker-safety-hook: allows mention of docker without docker binary" {
  require_command jq

  input=$(create_hook_input "Bash" "grep -rn dockerfile .")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  [ -z "$output" ]
}

# --- Regression: gaps in the old regex that must now prompt ---

@test "docker-safety-hook: prompts on global --context option before rm" {
  require_command jq

  input=$(create_hook_input "Bash" "docker --context foo rm x")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Destructive"
}

@test "docker-safety-hook: prompts on global -H option before kill" {
  require_command jq

  input=$(create_hook_input "Bash" "docker -H unix:///x kill y")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Destructive"
}

@test "docker-safety-hook: prompts on --context= form before container rm" {
  require_command jq

  input=$(create_hook_input "Bash" "docker --context=foo container rm x")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Destructive"
}

@test "docker-safety-hook: prompts on container rm" {
  require_command jq

  input=$(create_hook_input "Bash" "docker container rm abc")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Destructive"
}

@test "docker-safety-hook: prompts on image prune" {
  require_command jq

  input=$(create_hook_input "Bash" "docker image prune -af")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Destructive"
}

@test "docker-safety-hook: prompts on volume rm" {
  require_command jq

  input=$(create_hook_input "Bash" "docker volume rm data")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Destructive"
}

@test "docker-safety-hook: prompts on compose with options then down" {
  require_command jq

  input=$(create_hook_input "Bash" "docker compose -f a.yml -p proj down -v")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Destructive"
}

@test "docker-safety-hook: prompts on legacy docker-compose down" {
  require_command jq

  input=$(create_hook_input "Bash" "docker-compose down")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Destructive"
}

@test "docker-safety-hook: prompts on rm via command substitution" {
  require_command jq

  input=$(create_hook_input "Bash" "docker rm \$(docker ps -aq)")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Destructive"
}

@test "docker-safety-hook: prompts on rm via xargs" {
  require_command jq

  input=$(create_hook_input "Bash" "docker ps -aq | xargs docker rm")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Destructive"
}

@test "docker-safety-hook: prompts on rm via sh -c with quotes" {
  require_command jq

  input=$(create_hook_input "Bash" "sh -c 'docker rm x'")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Destructive"
}

@test "docker-safety-hook: prompts on sudo docker kill" {
  require_command jq

  input=$(create_hook_input "Bash" "sudo docker kill c")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Destructive"
}

@test "docker-safety-hook: prompts on full path binary" {
  require_command jq

  input=$(create_hook_input "Bash" "/usr/bin/docker rmi img")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Destructive"
}

@test "docker-safety-hook: prompts on --mount bind of host root" {
  require_command jq

  input=$(create_hook_input "Bash" "docker run --mount type=bind,src=/,dst=/h img")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Privileged"
}

@test "docker-safety-hook: prompts on -v root mount with space and quotes" {
  require_command jq

  input=$(create_hook_input "Bash" "docker run -v '/:/host' img")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Privileged"
}

@test "docker-safety-hook: prompts on --network host (space form)" {
  require_command jq

  input=$(create_hook_input "Bash" "docker run --network host img")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Privileged"
}

@test "docker-safety-hook: prompts on --cap-add SYS_ADMIN (space form)" {
  require_command jq

  input=$(create_hook_input "Bash" "docker run --cap-add SYS_ADMIN img")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Privileged"
}

@test "docker-safety-hook: prompts on container run --privileged" {
  require_command jq

  input=$(create_hook_input "Bash" "docker container run --privileged img")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Privileged"
}

@test "docker-safety-hook: prompts on container stop" {
  require_command jq

  input=$(create_hook_input "Bash" "docker container stop c")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "stop/restart/pause"
}

@test "docker-safety-hook: prompts on compose restart" {
  require_command jq

  input=$(create_hook_input "Bash" "docker compose restart web")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "stop/restart/pause"
}

# --- Hardening: escapes, continuations, aliases, path normalization ---
# Built with jq so backslashes/newlines/quotes are JSON-escaped correctly.
jq_hook_input() { printf '%b' "$1" | jq -Rs '{tool_name:"Bash",tool_input:{command:.}}'; }

@test "docker-safety-hook: prompts on attached -v value (-v/:/h)" {
  require_command jq

  input=$(jq_hook_input "docker run -v/:/h img")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Privileged"
}

@test "docker-safety-hook: prompts on bundled short flags ending in v" {
  require_command jq

  input=$(jq_hook_input "docker run -itv /:/h img")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Privileged"
}

@test "docker-safety-hook: prompts on non-canonical root mount (//)" {
  require_command jq

  input=$(jq_hook_input "docker run -v //:/h img")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Privileged"
}

@test "docker-safety-hook: prompts on non-canonical root mount (/x/..)" {
  require_command jq

  input=$(jq_hook_input "docker run -v /x/..:/h img")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Privileged"
}

@test "docker-safety-hook: prompts on --mount source=/. " {
  require_command jq

  input=$(jq_hook_input "docker run --mount type=bind,source=/.,dst=/h img")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Privileged"
}

@test "docker-safety-hook: prompts on --privileged=1" {
  require_command jq

  input=$(jq_hook_input "docker run --privileged=1 img")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Privileged"
}

@test "docker-safety-hook: prompts on image remove alias" {
  require_command jq

  input=$(jq_hook_input "docker image remove img")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Destructive"
}

@test "docker-safety-hook: prompts on container remove alias" {
  require_command jq

  input=$(jq_hook_input "docker container remove c")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Destructive"
}

@test "docker-safety-hook: prompts on backslash-newline continuation" {
  require_command jq

  input=$(jq_hook_input 'docker \\\n  rm x')
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Destructive"
}

@test "docker-safety-hook: prompts on backslash escapes (d\\ocker r\\m)" {
  require_command jq

  input=$(jq_hook_input "d\\ocker r\\m x")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Destructive"
}

@test "docker-safety-hook: prompts on quoted binary name (d\"o\"cker)" {
  require_command jq

  input=$(jq_hook_input "d\"o\"cker rm x")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Destructive"
}

@test "docker-safety-hook: allows --privileged=false" {
  require_command jq

  input=$(jq_hook_input "docker run --privileged=false img")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  [ -z "$output" ]
}

@test "docker-safety-hook: allows continuation that does not form rm (r\\<nl>m is rm, r<sp>m is not)" {
  require_command jq

  input=$(jq_hook_input "docker r m x")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  [ -z "$output" ]
}

# --- Hardening round 2: short-flag bundles, root aliases, sensitive host paths ---

@test "docker-safety-hook: prompts on bundle with attached value (-itv/:/h)" {
  require_command jq

  input=$(jq_hook_input 'docker run -itv/:/h img')
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Privileged"
}

@test "docker-safety-hook: prompts on /proc/self/root alias" {
  require_command jq

  input=$(jq_hook_input 'docker run -v /proc/self/root:/h img')
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Privileged"
}

@test "docker-safety-hook: prompts on --mount src=/proc/1/root" {
  require_command jq

  input=$(jq_hook_input 'docker run --mount type=bind,src=/proc/1/root,dst=/h img')
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Privileged"
}

@test "docker-safety-hook: prompts on /etc bind mount" {
  require_command jq

  input=$(jq_hook_input 'docker run -v /etc:/e img')
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Privileged"
}

@test "docker-safety-hook: prompts on /home parent bind mount" {
  require_command jq

  input=$(jq_hook_input 'docker run -v /home:/h img')
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Privileged"
}

@test "docker-safety-hook: allows project dir under /home read-only" {
  require_command jq

  input=$(jq_hook_input 'docker run --rm -v /home/me/proj:/repo:ro -v /tmp/claude-1000/x:/work img')
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  [ -z "$output" ]
}

@test "docker-safety-hook: allows attached non-sensitive -v value" {
  require_command jq

  input=$(jq_hook_input 'docker run -v/srv/data:/d img')
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  [ -z "$output" ]
}

@test "docker-safety-hook: prompts on symlink resolving to /" {
  require_command jq

  link="$BATS_TEST_TMPDIR/rootlink"; ln -sfn / "$link"
  input=$(jq_hook_input "docker run -v $link:/h img")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
}

# --- Hardening round 3: source expansion, socket case, -v= in bundles ---

@test "docker-safety-hook: prompts on bundle with = before value (-itv=/:/h)" {
  require_command jq

  input=$(jq_hook_input 'docker run -itv=/:/h img')
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Privileged"
}

@test "docker-safety-hook: prompts on docker socket in other case" {
  require_command jq

  input=$(jq_hook_input 'docker run -v /var/run/Docker.Sock:/s img')
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Privileged"
}

@test "docker-safety-hook: prompts on relative path escaping to /" {
  require_command jq

  input=$(jq_hook_input 'docker run -v ../../../../../../../../../..:/h img')
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Privileged"
}

@test "docker-safety-hook: prompts on unknown variable source" {
  require_command jq

  input=$(jq_hook_input 'docker run -v $X:/h img')
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Privileged"
}

@test "docker-safety-hook: prompts on command substitution source" {
  require_command jq

  input=$(jq_hook_input 'docker run -v $(pwd)/x:/h img')
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Privileged"
}

@test "docker-safety-hook: prompts on --mount src from command substitution" {
  require_command jq

  input=$(jq_hook_input 'docker run --mount type=bind,src=$(pwd),dst=/w img')
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Privileged"
}

@test "docker-safety-hook: allows $PWD source" {
  require_command jq

  input=$(jq_hook_input 'docker run -v $PWD:/work img')
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  [ -z "$output" ]
}

@test "docker-safety-hook: allows ~ subdir source" {
  require_command jq

  input=$(jq_hook_input 'docker run -v ~/proj:/p img')
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  [ -z "$output" ]
}

@test "docker-safety-hook: allows relative ./out source" {
  require_command jq

  input=$(jq_hook_input 'docker run -v ./out:/out img')
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  [ -z "$output" ]
}

# --- Hardening round 4: exact var names, ~user, cut substitutions, cd/env taint, globs ---

@test "docker-safety-hook: prompts on $HOMEX (not $HOME)" {
  require_command jq

  input=$(jq_hook_input 'docker run -v $HOMEX/y:/h img')
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Privileged"
}

@test "docker-safety-hook: prompts on ~user expansion" {
  require_command jq

  input=$(jq_hook_input 'docker run -v ~root:/h img')
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Privileged"
}

@test "docker-safety-hook: prompts on substitution in the middle of a path" {
  require_command jq

  input=$(jq_hook_input 'docker run -v /tmp/$(echo ../..)/:/h img')
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Privileged"
}

@test "docker-safety-hook: prompts on backtick in the middle of a path" {
  require_command jq

  input=$(jq_hook_input 'docker run -v /tmp/`echo ..`:/h img')
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Privileged"
}

@test "docker-safety-hook: prompts on relative source after cd" {
  require_command jq

  input=$(jq_hook_input 'cd / && docker run -v .:/h img')
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Privileged"
}

@test "docker-safety-hook: prompts on ~ after inline HOME= prefix" {
  require_command jq

  input=$(jq_hook_input 'HOME=/ docker run -v ~:/h img')
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Privileged"
}

@test "docker-safety-hook: prompts on $HOME after export" {
  require_command jq

  input=$(jq_hook_input 'export HOME=/; docker run -v $HOME:/h img')
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Privileged"
}

@test "docker-safety-hook: prompts on glob in source" {
  require_command jq

  input=$(jq_hook_input 'docker run -v /e*c:/h img')
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Privileged"
}

@test "docker-safety-hook: prompts on brace expansion in source" {
  require_command jq

  input=$(jq_hook_input 'docker run -v /{etc,x}:/h img')
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Privileged"
}

@test "docker-safety-hook: allows relative source after unrelated command" {
  require_command jq

  input=$(jq_hook_input 'ls foo.txt && docker run -v ./out:/o img')
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  [ -z "$output" ]
}

@test "docker-safety-hook: allows absolute source with -e VAR=" {
  require_command jq

  input=$(jq_hook_input 'docker run -e A=1 -v /srv/d:/d img')
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  [ -z "$output" ]
}

# --- Hardening round 5 ---

@test "docker-safety-hook: prompts on glob after ${HOME} prefix" {
  require_command jq

  input=$(jq_hook_input 'docker run -v ${HOME}/../../e*c:/h img')
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
}

@test "docker-safety-hook: allows plain ${HOME} subdir" {
  require_command jq

  input=$(jq_hook_input 'docker run -v ${HOME}/proj:/p img')
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  [ -z "$output" ]
}

@test "docker-safety-hook: prompts on relative source after /usr/bin/env cd" {
  require_command jq

  input=$(jq_hook_input '/usr/bin/env; docker run -v ./x:/h img')
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
}

@test "docker-safety-hook: prompts on $HOME source after printf -v HOME" {
  require_command jq

  input=$(jq_hook_input 'printf -v HOME /; docker run -v $HOME:/h img')
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
}

@test "docker-safety-hook: prompts on $HOME source inside for HOME loop" {
  require_command jq

  input=$(jq_hook_input 'for HOME in /; do docker run -v $HOME:/h img; done')
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
}

@test "docker-safety-hook: prompts when cd follows docker inside a loop" {
  require_command jq

  input=$(jq_hook_input 'while :; do docker run -v ./x:/h img; cd /; done')
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
}

@test "docker-safety-hook: docker -e VAR= does not taint a later relative source" {
  require_command jq

  input=$(jq_hook_input 'docker run -e A=1 img true && docker run -v ./o:/o img')
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  [ -z "$output" ]
}

# --- Data vs. shell: heredoc bodies, interpreter code, container command lines ---

@test "docker-safety-hook: allows container command -v after image (run)" {
  require_command jq

  input=$(jq_hook_input "docker run --rm img pytest -v")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  [ -z "$output" ]
}

@test "docker-safety-hook: allows container command -v after container (exec)" {
  require_command jq

  input=$(jq_hook_input "docker exec app python -m pytest -x -v")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  [ -z "$output" ]
}

@test "docker-safety-hook: allows container command -lv bundle after image" {
  require_command jq

  input=$(jq_hook_input "docker run --rm img ls -lv")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  [ -z "$output" ]
}

@test "docker-safety-hook: allows compose run service command -v" {
  require_command jq

  input=$(jq_hook_input "docker compose run --rm app pytest -v")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  [ -z "$output" ]
}

@test "docker-safety-hook: allows sh -c string inside exec after container" {
  require_command jq

  input=$(jq_hook_input "docker exec -it app sh -c \"pytest -v\"")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  [ -z "$output" ]
}

@test "docker-safety-hook: allows heredoc body that only mentions docker" {
  require_command jq

  input=$(jq_hook_input "python3 - <<'EOF'\ncases = [\"docker rm x\", \"docker run --privileged img\"]\nEOF")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  [ -z "$output" ]
}

@test "docker-safety-hook: allows unquoted heredoc data without substitution" {
  require_command jq

  input=$(jq_hook_input "cat > README.md <<EOF\nrun docker compose down to stop\nEOF")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  [ -z "$output" ]
}

@test "docker-safety-hook: allows quoted heredoc keeps \$( literal" {
  require_command jq

  input=$(jq_hook_input "cat > f <<'EOF'\n\$(docker rm x)\nEOF")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  [ -z "$output" ]
}

@test "docker-safety-hook: allows python -c code with for loop and \$PWD mount" {
  require_command jq

  input=$(jq_hook_input "docker run --rm -v \"\$PWD/src:/src:ro\" img python -c \"import x\nfor p in y: pass\"")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  [ -z "$output" ]
}

@test "docker-safety-hook: allows node -e code mentioning docker rm" {
  require_command jq

  input=$(jq_hook_input "node -e \"console.log('docker rm x')\"")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  [ -z "$output" ]
}

@test "docker-safety-hook: prompts on value flags before root mount" {
  require_command jq

  input=$(jq_hook_input "docker run --rm -it -e A=1 -p 80:80 -v /:/h img")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Privileged"
}

@test "docker-safety-hook: prompts on -P boolean before root mount" {
  require_command jq

  input=$(jq_hook_input "docker run -P -v /:/h img")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Privileged"
}

@test "docker-safety-hook: prompts on value flag before --privileged" {
  require_command jq

  input=$(jq_hook_input "docker run --name x --privileged img")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Privileged"
}

@test "docker-safety-hook: prompts on heredoc fed to bash" {
  require_command jq

  input=$(jq_hook_input "bash <<EOF\ndocker rm x\nEOF")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Destructive"
}

@test "docker-safety-hook: prompts on heredoc piped to sh" {
  require_command jq

  input=$(jq_hook_input "cat <<EOF | sh\ndocker rm x\nEOF")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Destructive"
}

@test "docker-safety-hook: prompts on heredoc sent over ssh" {
  require_command jq

  input=$(jq_hook_input "ssh host <<EOF\ndocker rm x\nEOF")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Destructive"
}

@test "docker-safety-hook: prompts on command after a heredoc ends" {
  require_command jq

  input=$(jq_hook_input "cat > f <<'EOF'\nhello\nEOF\ndocker rm x")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Destructive"
}

@test "docker-safety-hook: prompts on command substitution in unquoted heredoc" {
  require_command jq

  input=$(jq_hook_input "cat > f <<EOF\n\$(docker rm x)\nEOF")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Destructive"
}

@test "docker-safety-hook: prompts on quoted << is not a heredoc" {
  require_command jq

  input=$(jq_hook_input "echo \"a <<EOF\"\ndocker rm x")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Destructive"
}

@test "docker-safety-hook: prompts on <<< here-string is not a heredoc" {
  require_command jq

  input=$(jq_hook_input "grep x <<< \"y\"\ndocker rm x")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Destructive"
}

@test "docker-safety-hook: prompts on <<- heredoc with tab-indented delimiter" {
  require_command jq

  input=$(jq_hook_input "cat <<-EOF\n\thi\n\tEOF\ndocker rm x")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Destructive"
}

@test "docker-safety-hook: prompts on two heredocs on one line" {
  require_command jq

  input=$(jq_hook_input "cat <<A <<B\na\nA\nb\nB\ndocker kill c")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Destructive"
}

@test "docker-safety-hook: prompts on docker after python -c in next command" {
  require_command jq

  input=$(jq_hook_input "python3 -c \"print(1)\"; docker rm x")
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  assert_output_contains '"permissionDecision": "ask"'
  assert_output_contains "Destructive"
}

@test "docker-safety-hook: large heredoc mentioning docker is fast" {
  require_command jq

  local body i
  body='cat > README.md <<EOF'
  for i in $(seq 1 400); do body="$body"$'\n'"Line $i: run docker compose up and check the logs"; done
  body="$body"$'\n'EOF
  input=$(jq -n --arg c "$body" '{tool_input:{command:$c}}')
  local start=$SECONDS
  run bash "$HOOK_SCRIPT" <<< "$input"

  assert_success
  [ -z "$output" ]
  # Was ~18 s when every token forked; now well under a second.
  [ $((SECONDS - start)) -lt 3 ]
}
