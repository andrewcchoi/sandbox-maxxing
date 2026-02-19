#!/usr/bin/env bats
# ============================================================================
# Git Worktree Path Fixer Tests
# Tests for fix-worktree-paths.sh script (Issue #314)
# ============================================================================

load '../helpers/test_helper.bash'

# Test fixture setup
setup() {
    # Create temporary test directory
    TEST_DIR=$(mktemp -d)
    WORKSPACE_DIR="$TEST_DIR/workspace"
    mkdir -p "$WORKSPACE_DIR"

    # Copy script to test location
    SCRIPT_PATH="$BATS_TEST_DIRNAME/../../skills/_shared/templates/fix-worktree-paths.sh"
    cp "$SCRIPT_PATH" "$TEST_DIR/fix-worktree-paths.sh"
    chmod +x "$TEST_DIR/fix-worktree-paths.sh"
}

# Cleanup after each test
teardown() {
    rm -rf "$TEST_DIR"
}

# ============================================================================
# Test 1: Normal repo (not worktree) - should skip silently
# ============================================================================
@test "fix-worktree-paths: skips normal git repos" {
    # Create normal .git directory
    mkdir -p "$WORKSPACE_DIR/.git/refs"

    # Run script
    cd "$WORKSPACE_DIR"
    WORKSPACE_DIR="$WORKSPACE_DIR" run "$TEST_DIR/fix-worktree-paths.sh"

    # Should exit with success (0) and do nothing
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

# ============================================================================
# Test 2: Worktree with Unix path - should skip silently
# ============================================================================
@test "fix-worktree-paths: skips worktrees with valid Unix paths" {
    # Create .git file with Unix path
    echo "gitdir: ../main-repo/.git/worktrees/feature-branch" > "$WORKSPACE_DIR/.git"

    # Run script
    cd "$WORKSPACE_DIR"
    WORKSPACE_DIR="$WORKSPACE_DIR" run "$TEST_DIR/fix-worktree-paths.sh"

    # Should exit with success and skip
    [ "$status" -eq 0 ]
    [ "$output" = "" ]

    # Path should remain unchanged
    grep -q "gitdir: ../main-repo/.git/worktrees/feature-branch" "$WORKSPACE_DIR/.git"
}

# ============================================================================
# Test 3: Worktree with Windows path (sibling layout) - should fix
# ============================================================================
@test "fix-worktree-paths: fixes Windows paths in standard sibling layout" {
    # Create .git file with Windows path
    echo "gitdir: C:/Users/TestUser/repos/my-project/.git/worktrees/feature-branch" > "$WORKSPACE_DIR/.git"

    # Create main repo structure (sibling)
    mkdir -p "$TEST_DIR/workspace/my-project/.git/worktrees/feature-branch"

    # Run script
    cd "$WORKSPACE_DIR"
    WORKSPACE_DIR="$WORKSPACE_DIR" run "$TEST_DIR/fix-worktree-paths.sh"

    # Should succeed and fix the path
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Detected git worktree with Windows path" ]]
    [[ "$output" =~ "Fixed worktree path" ]]

    # Path should be rewritten to relative Unix path
    grep -q "gitdir: ../my-project/.git/worktrees/feature-branch" "$WORKSPACE_DIR/.git"
}

# ============================================================================
# Test 4: Worktree with Windows path (D: drive)
# ============================================================================
@test "fix-worktree-paths: handles D: drive paths" {
    # Create .git file with D: drive Windows path
    echo "gitdir: D:/Projects/main-repo/.git/worktrees/hotfix" > "$WORKSPACE_DIR/.git"

    # Create main repo structure
    mkdir -p "$TEST_DIR/workspace/main-repo/.git/worktrees/hotfix"

    # Run script
    cd "$WORKSPACE_DIR"
    WORKSPACE_DIR="$WORKSPACE_DIR" run "$TEST_DIR/fix-worktree-paths.sh"

    # Should succeed
    [ "$status" -eq 0 ]
    grep -q "gitdir: ../main-repo/.git/worktrees/hotfix" "$WORKSPACE_DIR/.git"
}

# ============================================================================
# Test 5: Non-sibling layout - should fail with helpful error
# ============================================================================
@test "fix-worktree-paths: fails gracefully for non-sibling layout" {
    # Create .git file with Windows path
    echo "gitdir: C:/Different/Location/my-project/.git/worktrees/feature" > "$WORKSPACE_DIR/.git"

    # Don't create main repo (simulate non-sibling layout)

    # Run script
    cd "$WORKSPACE_DIR"
    WORKSPACE_DIR="$WORKSPACE_DIR" run "$TEST_DIR/fix-worktree-paths.sh"

    # Should fail with helpful error
    [ "$status" -eq 1 ]
    [[ "$output" =~ "ERROR: Main repository not found" ]]
    [[ "$output" =~ "Ensure worktree is a sibling" ]]
}

# ============================================================================
# Test 6: Idempotency - running twice should be safe
# ============================================================================
@test "fix-worktree-paths: is idempotent (safe to run multiple times)" {
    # Create .git file with Windows path
    echo "gitdir: C:/Users/TestUser/repos/project/.git/worktrees/branch" > "$WORKSPACE_DIR/.git"

    # Create main repo structure
    mkdir -p "$TEST_DIR/workspace/project/.git/worktrees/branch"

    # Run script first time
    cd "$WORKSPACE_DIR"
    WORKSPACE_DIR="$WORKSPACE_DIR" run "$TEST_DIR/fix-worktree-paths.sh"
    [ "$status" -eq 0 ]

    # Save fixed content
    FIRST_RUN=$(cat "$WORKSPACE_DIR/.git")

    # Run script second time
    WORKSPACE_DIR="$WORKSPACE_DIR" run "$TEST_DIR/fix-worktree-paths.sh"
    [ "$status" -eq 0 ]
    [ "$output" = "" ]  # Should skip silently

    # Content should be unchanged
    SECOND_RUN=$(cat "$WORKSPACE_DIR/.git")
    [ "$FIRST_RUN" = "$SECOND_RUN" ]
}

# ============================================================================
# Test 7: Complex path with spaces and special characters
# ============================================================================
@test "fix-worktree-paths: handles paths with spaces" {
    # Create .git file with Windows path containing spaces
    echo "gitdir: C:/Users/Test User/My Repos/main-repo/.git/worktrees/feature-branch" > "$WORKSPACE_DIR/.git"

    # Create main repo structure
    mkdir -p "$TEST_DIR/workspace/main-repo/.git/worktrees/feature-branch"

    # Run script
    cd "$WORKSPACE_DIR"
    WORKSPACE_DIR="$WORKSPACE_DIR" run "$TEST_DIR/fix-worktree-paths.sh"

    # Should succeed
    [ "$status" -eq 0 ]
    grep -q "gitdir: ../main-repo/.git/worktrees/feature-branch" "$WORKSPACE_DIR/.git"
}
