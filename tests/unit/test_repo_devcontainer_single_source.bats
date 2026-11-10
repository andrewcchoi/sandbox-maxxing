#!/usr/bin/env bats
# ============================================================================
# This repo's dev container runs the template setup script (#389)
#
# A repo copy of setup-claude-credentials.sh drifted from the template (13 vs
# 15 steps, missing the worktree-path fix and AWS check), so the plugin's own
# container didn't exercise what users get. The repo now runs the template
# through .devcontainer/post-create.sh. These tests keep a copy from coming
# back. No Docker needed.
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

@test "repo dev container: no copy of setup-claude-credentials.sh in .devcontainer/" {
  [ ! -e "$ROOT/.devcontainer/setup-claude-credentials.sh" ] || {
    echo "Run the template from post-create.sh instead of keeping a copy (#389)." >&2
    return 1
  }
}

@test "repo dev container: postCreateCommand runs post-create.sh" {
  command -v jq >/dev/null || skip "jq not installed"
  run jq -r '.postCreateCommand' "$ROOT/.devcontainer/devcontainer.json"
  [ "$status" -eq 0 ]
  [ "$output" = "bash .devcontainer/post-create.sh" ]
}

@test "repo dev container: post-create.sh runs the template setup script" {
  local script="$ROOT/.devcontainer/post-create.sh"
  [ -x "$script" ]
  grep -qF 'exec bash "$TEMPLATES/setup-claude-credentials.sh"' "$script"
  grep -qF 'TEMPLATES="$REPO_ROOT/skills/_shared/templates"' "$script"
  bash -n "$script"
}

@test "repo dev container: post-create.sh stages the template's companion scripts" {
  # Copy the repo layout post-create.sh needs, with a stub template setup
  # script, and check it stages companions and passes WORKSPACE_DIR through.
  mkdir -p "$TEST_DIR/repo/.devcontainer" "$TEST_DIR/repo/hooks" "$TEST_DIR/repo/skills/_shared/templates"
  cp "$ROOT/.devcontainer/post-create.sh" "$TEST_DIR/repo/.devcontainer/"
  cp "$ROOT/hooks/sync-knowledge.sh" "$TEST_DIR/repo/hooks/"
  cp "$TEMPLATES/fix-worktree-paths.sh" "$TEST_DIR/repo/skills/_shared/templates/"
  printf '#!/usr/bin/env bash\necho "ran template WORKSPACE_DIR=$WORKSPACE_DIR"\n' \
    > "$TEST_DIR/repo/skills/_shared/templates/setup-claude-credentials.sh"

  run env -u WORKSPACE_DIR bash "$TEST_DIR/repo/.devcontainer/post-create.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"ran template WORKSPACE_DIR=$TEST_DIR/repo"* ]]
  cmp -s "$ROOT/hooks/sync-knowledge.sh" "$TEST_DIR/repo/.devcontainer/sync-knowledge.sh"
  cmp -s "$TEMPLATES/fix-worktree-paths.sh" "$TEST_DIR/repo/.devcontainer/fix-worktree-paths.sh"
  [ -x "$TEST_DIR/repo/.devcontainer/sync-knowledge.sh" ]
  [ -x "$TEST_DIR/repo/.devcontainer/fix-worktree-paths.sh" ]
}

@test "repo dev container: staged companion copies are gitignored" {
  git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1 || skip "not a git checkout"
  git -C "$ROOT" check-ignore -q .devcontainer/sync-knowledge.sh
  git -C "$ROOT" check-ignore -q .devcontainer/fix-worktree-paths.sh
}

@test "template setup-claude-credentials.sh looks for companions in .devcontainer/" {
  # post-create.sh stages them there; if the template moves, update both.
  grep -qF '"$WORKSPACE_DIR/.devcontainer/fix-worktree-paths.sh"' "$TEMPLATES/setup-claude-credentials.sh"
  grep -qF '"$WORKSPACE_DIR/.devcontainer/sync-knowledge.sh"' "$TEMPLATES/setup-claude-credentials.sh"
}
