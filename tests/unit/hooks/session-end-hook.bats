#!/usr/bin/env bats
#
# Unit tests for hooks/session-end-hook.sh (#369)
# SessionEnd must act on the current session only: write a clean-shutdown
# manifest, flush, and (volume mode) copy just that one volume. It must never
# scan or read other sandboxes' volumes, and its inner timeouts must fit inside
# the harness timeout in hooks.json.

BATS_TEST_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
PLUGIN_ROOT="$(cd "$BATS_TEST_DIR/../../.." && pwd)"

load '../../helpers/test_helper'

HOOK_SCRIPT="${PLUGIN_ROOT}/hooks/session-end-hook.sh"

setup() {
  export TEST_TEMP_DIR="$(mktemp -d)"
  export FAKE_HOME="${TEST_TEMP_DIR}/home"
  export DOCKER_LOG="${TEST_TEMP_DIR}/docker.log"
  mkdir -p "$FAKE_HOME" "${TEST_TEMP_DIR}/bin"
  : > "$DOCKER_LOG"
}

teardown() {
  if [ -n "${VOL_PREFIX:-}" ] && [ -n "${REAL_DOCKER:-}" ]; then
    "$REAL_DOCKER" volume ls --format '{{.Name}}' | grep "^${VOL_PREFIX}" \
      | xargs -r "$REAL_DOCKER" volume rm >/dev/null 2>&1 || true
  fi
  [ -n "${TEST_TEMP_DIR:-}" ] && rm -rf "${TEST_TEMP_DIR}"
}

# docker shim that records every invocation, then (optionally) forwards.
install_docker_shim() {
  local forward="${1:-}"
  cat > "${TEST_TEMP_DIR}/bin/docker" <<EOF
#!/usr/bin/env bash
echo "\$*" >> "${DOCKER_LOG}"
if [ -n "${forward}" ]; then exec "${forward}" "\$@"; fi
exit 0
EOF
  chmod +x "${TEST_TEMP_DIR}/bin/docker"
}

run_hook() {
  local input="$1"; shift
  run env PATH="${TEST_TEMP_DIR}/bin:${PATH}" HOME="$FAKE_HOME" "$@" \
    bash -c 'printf "%s" "$1" | bash "$2"' _ "$input" "$HOOK_SCRIPT"
}

# --- static checks -----------------------------------------------------------

@test "session-end: parses and never calls sync-knowledge without a volume scope" {
  run bash -n "$HOOK_SCRIPT"
  assert_success
  # Exactly one sync-knowledge invocation, and it is scoped to the session volume.
  [ "$(grep -c 'bash "${SCRIPT_DIR}/sync-knowledge.sh"' "$HOOK_SCRIPT")" -eq 1 ]
  grep -B1 'bash "${SCRIPT_DIR}/sync-knowledge.sh"' "$HOOK_SCRIPT" | grep -q 'SANDBOXXER_SYNC_VOLUMES="$SESSION_VOLUME"'
  ! grep -q 'docker volume ls' "$HOOK_SCRIPT"
}

@test "session-end: inner timeouts sum below the hooks.json SessionEnd timeout" {
  require_command jq
  local manifest copy outer_ms
  manifest=$(sed -n 's/^MANIFEST_TIMEOUT=\([0-9]*\)$/\1/p' "$HOOK_SCRIPT")
  copy=$(sed -n 's/^COPY_TIMEOUT=\([0-9]*\)$/\1/p' "$HOOK_SCRIPT")
  [ -n "$manifest" ]
  [ -n "$copy" ]
  # stdin read budget (2 s) + manifest/sync + copy
  for f in hooks.json hooks.example.json; do
    outer_ms=$(jq '.hooks.SessionEnd[0].hooks[0].timeout' "${PLUGIN_ROOT}/hooks/$f")
    [ $(( (2 + manifest + copy) * 1000 )) -lt "$outer_ms" ] || {
      echo "$f: inner budget $(( 2 + manifest + copy ))s >= outer ${outer_ms}ms" >&2
      return 1
    }
  done
}

# --- local mode (no Docker) --------------------------------------------------

@test "session-end local: writes manifest into CLAUDE_CONFIG_DIR and never touches docker" {
  install_docker_shim
  local cfg="${TEST_TEMP_DIR}/cfg"
  run_hook '{"session_id":"abc-123","reason":"logout","hook_event_name":"SessionEnd"}' \
    CLAUDE_CONFIG_DIR="$cfg"
  assert_success
  local m="$cfg/state/session-end/abc-123.json"
  [ -f "$m" ]
  if command -v jq >/dev/null 2>&1; then assert_valid_json "$m"; fi
  run cat "$m"
  assert_output_contains '"session_id":"abc-123"'
  assert_output_contains '"reason":"logout"'
  assert_output_contains '"mode":"local"'
  assert_output_contains '"hook_version"'
  [ ! -s "$DOCKER_LOG" ]
  run cat "$FAKE_HOME/.claude/state/hook.log"
  assert_output_contains "SessionEnd hook completed"
}

@test "session-end local: defaults to \$HOME/.claude and survives empty stdin" {
  install_docker_shim
  run_hook ''
  assert_success
  run ls "$FAKE_HOME/.claude/state/session-end/"
  assert_output_contains "unknown-"
  [ ! -s "$DOCKER_LOG" ]
}

@test "session-end local: hostile session_id cannot escape the manifest dir" {
  install_docker_shim
  local cfg="${TEST_TEMP_DIR}/cfg"
  run_hook '{"session_id":"../../evil\"x","reason":"other"}' CLAUDE_CONFIG_DIR="$cfg"
  assert_success
  [ -f "$cfg/state/session-end/evilx.json" ]
  [ ! -e "${TEST_TEMP_DIR}/evil" ]
}

@test "session-end volume: invalid volume name is rejected without calling docker" {
  install_docker_shim
  run_hook '{"session_id":"s1"}' SANDBOXXER_SESSION_VOLUME='bad;name'
  assert_success
  [ ! -s "$DOCKER_LOG" ]
  run cat "$FAKE_HOME/.claude/state/hook.log"
  assert_output_contains "invalid SANDBOXXER_SESSION_VOLUME"
}

# --- volume mode (real Docker) -----------------------------------------------

setup_volumes() {
  if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
    skip "Docker daemon not available"
  fi
  REAL_DOCKER="$(command -v docker)"
  export REAL_DOCKER
  export VOL_PREFIX="seh$$${RANDOM}"
  local v
  for v in A B; do
    "$REAL_DOCKER" volume create "${VOL_PREFIX}_claude-${v}" >/dev/null
    "$REAL_DOCKER" run --rm -v "${VOL_PREFIX}_claude-${v}:/v" alpine:3.19 sh -c \
      "mkdir -p /v/projects/-workspace /v/plans && echo '{\"s\":\"${v}\"}' > /v/projects/-workspace/${v}.jsonl \
       && echo ${v} > /v/plans/${v}.md && chown -R $(id -u):$(id -g) /v"
  done
  install_docker_shim "$REAL_DOCKER"
}

@test "session-end volume: concurrent session B is not touched by session A's SessionEnd" {
  setup_volumes
  run_hook '{"session_id":"sessA","reason":"exit"}' SANDBOXXER_SESSION_VOLUME="${VOL_PREFIX}_claude-A"
  assert_success

  # A's data copied to host; B's not.
  [ -f "$FAKE_HOME/.claude/projects/-workspace/A.jsonl" ]
  [ -f "$FAKE_HOME/.claude/plans/A.md" ]
  [ ! -e "$FAKE_HOME/.claude/projects/-workspace/B.jsonl" ]
  [ ! -e "$FAKE_HOME/.claude/plans/B.md" ]

  # No host-wide scan, and no docker call ever mentioned B.
  ! grep -q 'volume ls' "$DOCKER_LOG"
  ! grep -q "${VOL_PREFIX}_claude-B" "$DOCKER_LOG"

  # Manifest landed in A's volume (and was copied to host state/), not in B's.
  run "$REAL_DOCKER" run --rm -v "${VOL_PREFIX}_claude-A:/v:ro" alpine:3.19 cat /v/state/session-end/sessA.json
  assert_success
  assert_output_contains '"mode":"volume"'
  run "$REAL_DOCKER" run --rm -v "${VOL_PREFIX}_claude-B:/v:ro" alpine:3.19 ls /v/state/session-end
  assert_failure
  [ -f "$FAKE_HOME/.claude/state/session-end/sessA.json" ]
}
