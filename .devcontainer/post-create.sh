#!/usr/bin/env bash
# ============================================================================
# postCreateCommand for this repo's own dev container (#389)
#
# Runs the same setup-claude-credentials.sh that scaffolded projects get, so
# working in this container exercises the shipped template and the two can't
# drift. The template expects its companion scripts in .devcontainer/, where
# yolo-docker-maxxing and quickstart put them; stage them from their single
# sources first. The staged copies are gitignored.
# ============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATES="$REPO_ROOT/skills/_shared/templates"

# Same companions the scaffolders copy (scripts/yolo-docker-maxxing.sh)
cp "$REPO_ROOT/hooks/sync-knowledge.sh" "$REPO_ROOT/.devcontainer/sync-knowledge.sh"
cp "$TEMPLATES/fix-worktree-paths.sh" "$REPO_ROOT/.devcontainer/fix-worktree-paths.sh"
chmod +x "$REPO_ROOT/.devcontainer/sync-knowledge.sh" "$REPO_ROOT/.devcontainer/fix-worktree-paths.sh"

export WORKSPACE_DIR="${WORKSPACE_DIR:-$REPO_ROOT}"
exec bash "$TEMPLATES/setup-claude-credentials.sh"
