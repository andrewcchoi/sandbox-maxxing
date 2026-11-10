#!/usr/bin/env bats
#
# Unit tests for hooks/sync-knowledge.sh
# Exercises the real hook against throwaway Docker volumes. A `docker` shim on
# PATH restricts `docker volume ls` to this test's volumes so real user volumes
# are never read, and HOME points at a temp dir so ~/.claude is never touched.

BATS_TEST_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
PLUGIN_ROOT="$(cd "$BATS_TEST_DIR/../../.." && pwd)"

load '../../helpers/test_helper'

HOOK_SCRIPT="${PLUGIN_ROOT}/hooks/sync-knowledge.sh"
# hooks/sync-knowledge.sh is the only copy in the repo (#368); scaffolding copies
# it into projects. See tests/unit/test_sync_knowledge_single_source.bats.

# Seed a volume as the current user so the hook (which runs as id -u) can read it.
seed_volume() {
  local vol="$1" script="$2"
  docker volume create "$vol" >/dev/null
  docker run --rm -v "${vol}:/v" alpine:3.19 sh -c \
    "${script}; chown -R $(id -u):$(id -g) /v; chmod 755 /v /v/* 2>/dev/null || true"
}

setup() {
  export TEST_TEMP_DIR="$(mktemp -d)"
  export ORIGINAL_DIR="$(pwd)"

  if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
    skip "Docker daemon not available"
  fi

  REAL_DOCKER="$(command -v docker)"
  export VOL_PREFIX="skt$$${RANDOM}"
  export FAKE_HOME="${TEST_TEMP_DIR}/home"
  mkdir -p "$FAKE_HOME" "${TEST_TEMP_DIR}/bin"

  cat > "${TEST_TEMP_DIR}/bin/docker" <<EOF
#!/usr/bin/env bash
if [ "\$1" = "volume" ] && [ "\$2" = "ls" ]; then
  "${REAL_DOCKER}" volume ls --format '{{.Name}}' | grep "^${VOL_PREFIX}" || true
  exit 0
fi
exec "${REAL_DOCKER}" "\$@"
EOF
  chmod +x "${TEST_TEMP_DIR}/bin/docker"

  seed_volume "${VOL_PREFIX}_claude-data" \
    'mkdir -p /v/projects/-workspace /v/plans && echo "{\"a\":1}" > /v/projects/-workspace/s1.jsonl && echo plan > /v/plans/p.md'
  seed_volume "${VOL_PREFIX}-agent-legacy" \
    'mkdir -p /v/projects/-workspace && echo "{\"b\":1}" > /v/projects/-workspace/s2.jsonl'
  seed_volume "${VOL_PREFIX}_claude-empty" 'true'
}

teardown() {
  if [ -n "${VOL_PREFIX:-}" ] && [ -n "${REAL_DOCKER:-}" ]; then
    "$REAL_DOCKER" volume ls --format '{{.Name}}' | grep "^${VOL_PREFIX}" \
      | xargs -r "$REAL_DOCKER" volume rm >/dev/null 2>&1 || true
  fi
  [ -n "${TEST_TEMP_DIR:-}" ] && rm -rf "${TEST_TEMP_DIR}"
  [ -n "${ORIGINAL_DIR:-}" ] && cd "${ORIGINAL_DIR}"
}

run_hook() {
  run env PATH="${TEST_TEMP_DIR}/bin:${PATH}" HOME="$FAKE_HOME" bash "$HOOK_SCRIPT"
}

@test "sync-knowledge: volume with only projects/ qualifies; empty volume is skipped" {
  run_hook
  assert_success
  assert_output_contains "Skipping (no plans/, state/, or projects/ directory)"
  assert_output_contains "Done syncing from 2 volume(s)"
}

@test "sync-knowledge: copies session transcripts from every volume" {
  run_hook
  assert_success
  [ -f "$FAKE_HOME/.claude/projects/-workspace/s1.jsonl" ]
  [ -f "$FAKE_HOME/.claude/projects/-workspace/s2.jsonl" ]
  [ -f "$FAKE_HOME/.claude/plans/p.md" ]
}

@test "sync-knowledge: host projects/ stays 0700 even though source dir is 755" {
  run_hook
  assert_success
  [ "$(stat -c '%a' "$FAKE_HOME/.claude/projects")" = "700" ]
}

@test "sync-knowledge: re-run picks up appended transcript lines" {
  run_hook
  assert_success
  sleep 1
  docker run --rm -v "${VOL_PREFIX}_claude-data:/v" alpine:3.19 \
    sh -c 'echo "{\"a\":2}" >> /v/projects/-workspace/s1.jsonl'
  run_hook
  assert_success
  run cat "$FAKE_HOME/.claude/projects/-workspace/s1.jsonl"
  assert_output_contains '{"a":2}'
}

@test "sync-knowledge: hook includes the 0700 reset and parses" {
  grep -q 'chmod 700 /dest/projects' "$HOOK_SCRIPT"
  run bash -n "$HOOK_SCRIPT"
  assert_success
}
