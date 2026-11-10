#!/usr/bin/env bats
# ============================================================================
# Guard: every test file is actually run (#380)
#
# `bats tests/` only picks up *.bats files in that one directory. Test files
# named *.test.sh, or *.bats in subdirectories without `-r`, were silently
# skipped: 316 of 337 tests never ran, locally or in CI.
# ============================================================================

ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"

@test "every file under tests/ that defines @test cases is a .bats file" {
  local stray
  stray=$(grep -rlE '^@test ' "$ROOT/tests" --exclude='*.md' | grep -v '\.bats$' || true)
  [ -z "$stray" ] || {
    echo "These files define @test cases but bats will not run them (rename to .bats):" >&2
    echo "$stray" >&2
    return 1
  }
}

@test "npm test scripts run bats recursively" {
  local script
  for script in test test:all test:ci test:integration test:hooks; do
    jq -r --arg s "$script" '.scripts[$s]' "$ROOT/package.json" | grep -q 'bats -r ' || {
      echo "package.json script '$script' must use 'bats -r'" >&2
      return 1
    }
  done
}

@test "CI runs bats recursively" {
  local workflow="$ROOT/.github/workflows/docs-validation.yml"
  [ -f "$workflow" ] || skip "no CI workflow"
  local invocations non_recursive
  invocations=$(grep -E '^[[:space:]]+run: bats ' "$workflow" || true)
  [ -n "$invocations" ] || { echo "CI has no bats invocation" >&2; return 1; }
  # every bats invocation in CI must be recursive
  non_recursive=$(printf '%s\n' "$invocations" | grep -v 'bats -r ' || true)
  [ -z "$non_recursive" ] || { echo "Non-recursive bats in CI: $non_recursive" >&2; return 1; }
}

@test "npm run test:all executes every @test case in the repo" {
  local expected listed
  expected=$(grep -rhcE '^@test ' "$ROOT/tests" --exclude='*.md' | awk '{ n += $1 } END { print n }')
  # --count lists the tests bats would run without running them
  listed=$(cd "$ROOT" && bats -r --count tests/)
  [ "$listed" -eq "$expected" ] || {
    echo "bats would run $listed tests, but $expected @test cases exist" >&2
    return 1
  }
}
