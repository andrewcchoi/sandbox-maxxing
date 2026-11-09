#!/usr/bin/env bash
# ============================================================================
# Git Worktree Path Fixer - Converts Windows paths to relative Unix paths
# ============================================================================
#
# This script automatically detects and fixes git worktrees opened from
# Windows hosts. Git worktrees have a .git file (not directory) containing
# an absolute Windows path that is invalid inside Linux containers.
#
# How it works:
# 1. Detects Windows path in .git file (C:/..., D:/..., etc.)
# 2. Extracts main repo name and worktree name from path
# 3. Verifies main repo is accessible as sibling (parent mount includes it)
# 4. Rewrites .git to relative Unix path: ../main-repo/.git/worktrees/worktree-name
#
# Assumptions:
# - Standard git worktree layout (worktrees are siblings of main repo)
# - Parent directory is mounted at /workspace (DevContainer default)
# - Script is idempotent and safe to run multiple times
#
# ============================================================================

set -euo pipefail

WORKSPACE_DIR="${WORKSPACE_DIR:-/workspace}"
GIT_FILE="$WORKSPACE_DIR/.git"

# Only proceed if .git is a file (indicates worktree)
if [ ! -f "$GIT_FILE" ]; then
    exit 0  # Normal repo, nothing to do
fi

# Read gitdir path
GITDIR_PATH=$(grep '^gitdir:' "$GIT_FILE" | cut -d' ' -f2-)

# Check for Windows path pattern (C:/, D:/, etc.)
if ! echo "$GITDIR_PATH" | grep -qE '^[A-Z]:/'; then
    exit 0  # Already Unix-style, nothing to do
fi

echo "Detected git worktree with Windows path: $GITDIR_PATH"

# Extract main repo name and worktree name from Windows path
# Pattern: .../main-repo/.git/worktrees/worktree-name
MAIN_REPO=$(echo "$GITDIR_PATH" | sed -E 's|.*/([^/]+)/\.git/worktrees/.*|\1|')
WORKTREE_NAME=$(basename "$GITDIR_PATH")

# Verify main repo is accessible as sibling
EXPECTED_PATH="$WORKSPACE_DIR/$MAIN_REPO/.git/worktrees/$WORKTREE_NAME"
if [ -d "$EXPECTED_PATH" ]; then
    echo "gitdir: ../$MAIN_REPO/.git/worktrees/$WORKTREE_NAME" > "$GIT_FILE"
    echo "✓ Fixed worktree path: ../$MAIN_REPO/.git/worktrees/$WORKTREE_NAME"
else
    echo "ERROR: Main repository not found at expected location." >&2
    echo "Expected: $EXPECTED_PATH" >&2
    echo "Ensure worktree is a sibling of the main repo (standard git worktree layout)." >&2
    exit 1
fi
