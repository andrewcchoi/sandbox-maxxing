#!/usr/bin/env bats
# ============================================================================
# WORKSPACE_DIR defaults to the project root, not /workspace
#
# In the default layout compose mounts ..:/workspace, so the project is
# /workspace/<name> and /workspace is the parent folder. Nothing sets
# WORKSPACE_DIR, so a /workspace default sent the worktree fix, SSH pubkey,
# sync-knowledge install and .gitignore edit to the parent folder. The
# scripts live in <project>/.devcontainer/, so they derive the root from that.
# ============================================================================

load '../helpers/test_helper.bash'

ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
TEMPLATES="$ROOT/skills/_shared/templates"

setup() {
  TEST_DIR="$(mktemp -d)"
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "no template script defaults WORKSPACE_DIR to /workspace" {
  run grep -nE 'WORKSPACE_DIR:-/workspace' "$TEMPLATES"/*.sh
  [ "$status" -eq 1 ] || { echo "$output" >&2; return 1; }
}

@test "setup-claude-credentials.sh: WORKSPACE_DIR defaults to the project root and is exported" {
  # Run the script's own WORKSPACE_DIR lines from <parent>/proj/.devcontainer/
  mkdir -p "$TEST_DIR/parent/proj/.devcontainer"
  local snippet="$TEST_DIR/parent/proj/.devcontainer/setup-claude-credentials.sh"
  grep -E '^(export )?WORKSPACE_DIR' "$TEMPLATES/setup-claude-credentials.sh" > "$snippet"
  [ -s "$snippet" ]
  printf 'bash -c '"'"'echo "child=$WORKSPACE_DIR"'"'"'\n' >> "$snippet"

  cd "$TEST_DIR"
  run env -u WORKSPACE_DIR bash "$snippet"
  [ "$status" -eq 0 ]
  [ "$output" = "child=$TEST_DIR/parent/proj" ]
}

@test "setup-claude-credentials.sh: an explicit WORKSPACE_DIR still wins" {
  mkdir -p "$TEST_DIR/proj/.devcontainer"
  local snippet="$TEST_DIR/proj/.devcontainer/setup-claude-credentials.sh"
  grep -E '^(export )?WORKSPACE_DIR' "$TEMPLATES/setup-claude-credentials.sh" > "$snippet"
  printf 'echo "$WORKSPACE_DIR"\n' >> "$snippet"

  run env WORKSPACE_DIR=/custom bash "$snippet"
  [ "$output" = "/custom" ]
}

@test "this repo's compose no longer hardcodes WORKSPACE_DIR (post-create.sh derives it)" {
  run grep -n 'WORKSPACE_DIR' "$ROOT/.devcontainer/docker-compose.yml"
  [ "$status" -eq 1 ]
}
