#!/usr/bin/env bats
# ============================================================================
# sync-knowledge.sh has one source: hooks/sync-knowledge.sh (#368)
#
# Two template copies had drifted from the hardened hook (no HOME guard, no
# volume-name validation, unpinned alpine, root-owned files, ...). They are
# gone; scaffolding copies the hook into the project instead. These tests keep
# a second copy from coming back and check that scaffolded projects get the
# hook's exact bytes. No Docker needed.
# ============================================================================

load '../helpers/test_helper.bash'

ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
HOOK="$ROOT/hooks/sync-knowledge.sh"

setup() {
  TEST_DIR="$(mktemp -d)"
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "single source: hooks/sync-knowledge.sh is the only sync-knowledge.sh in the repo" {
  [ -f "$HOOK" ]
  local copies
  if git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
    copies=$(git -C "$ROOT" ls-files '*sync-knowledge.sh')
  else
    copies=$(cd "$ROOT" && find . -name sync-knowledge.sh -not -path './.git/*' | sed 's#^\./##')
  fi
  [ "$copies" = "hooks/sync-knowledge.sh" ] || {
    echo "Expected only hooks/sync-knowledge.sh; found:" >&2
    echo "$copies" >&2
    echo "Copy it from hooks/ at scaffold time instead of adding a template copy (#368)." >&2
    return 1
  }
}

@test "yolo-docker-maxxing: scaffolds the hook's exact bytes as .devcontainer/sync-knowledge.sh (normal and portless)" {
  local mode dir
  for mode in normal portless; do
    dir="$TEST_DIR/$mode"
    mkdir -p "$dir"
    (cd "$dir" && git init -q)
    if [ "$mode" = portless ]; then
      run bash -c "cd '$dir' && CLAUDE_PLUGIN_ROOT='$ROOT' bash '$ROOT/scripts/yolo-docker-maxxing.sh' --portless sk-check"
    else
      run bash -c "cd '$dir' && CLAUDE_PLUGIN_ROOT='$ROOT' bash '$ROOT/scripts/yolo-docker-maxxing.sh' sk-check"
    fi
    [ "$status" -eq 0 ] || { echo "yolo ($mode) failed: $output" >&2; return 1; }
    [ -f "$dir/.devcontainer/sync-knowledge.sh" ] || { echo "missing in $mode" >&2; return 1; }
    cmp -s "$HOOK" "$dir/.devcontainer/sync-knowledge.sh" || { echo "differs from hook in $mode" >&2; return 1; }
    [ -x "$dir/.devcontainer/sync-knowledge.sh" ] || { echo "not executable in $mode" >&2; return 1; }
  done
}

@test "quickstart: copies hooks/sync-knowledge.sh into .devcontainer/" {
  grep -qxF 'cp "$PLUGIN_ROOT/hooks/sync-knowledge.sh" .devcontainer/sync-knowledge.sh' "$ROOT/commands/quickstart.md"
  run grep -n 'TEMPLATES/sync-knowledge.sh' "$ROOT/commands/quickstart.md" "$ROOT/scripts/yolo-docker-maxxing.sh"
  [ "$status" -eq 1 ]
}

@test "template setup-claude-credentials.sh installs the scaffolded .devcontainer/sync-knowledge.sh" {
  # The scaffold puts the hook at .devcontainer/sync-knowledge.sh; step 11 of the
  # template setup reads it from there and installs it on the host.
  grep -qF '"$WORKSPACE_DIR/.devcontainer/sync-knowledge.sh"' "$ROOT/skills/_shared/templates/setup-claude-credentials.sh"
}

@test "this repo's dev container stages hooks/sync-knowledge.sh for the template setup" {
  # The repo runs the template setup script (#389), so it stages the hook where
  # step 11 looks for it, the same way the scaffolders do.
  grep -qF '"$REPO_ROOT/hooks/sync-knowledge.sh" "$REPO_ROOT/.devcontainer/sync-knowledge.sh"' "$ROOT/.devcontainer/post-create.sh"
}
