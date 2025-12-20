#!/bin/bash
# sync-templates.sh - Sync master templates to skill folders
#
# This script copies shared template files from templates/master-shared/
# to all skill mode folders, keeping them in sync with the source of truth.
#
# Usage: ./scripts/sync-templates.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Syncing shared templates to skill folders..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Shared files that are identical across all modes (from master-shared)
SHARED_FILES=(
    "docker-compose.yml"
    "Dockerfile.python"
    "Dockerfile.node"
    "setup-claude-credentials.sh"
)

# All skill modes
MODES=("basic" "intermediate" "advanced" "yolo")

# Verify master/shared directory exists
MASTER_SHARED="$REPO_ROOT/templates/master/shared"
if [ ! -d "$MASTER_SHARED" ]; then
    echo "✗ ERROR: Master shared directory not found: $MASTER_SHARED"
    exit 1
fi

echo ""
echo "Master source: $MASTER_SHARED"
echo ""

# Sync to each skill mode
for mode in "${MODES[@]}"; do
    DEST="$REPO_ROOT/skills/devcontainer-setup-$mode/templates"

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Mode: $mode"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Verify destination exists
    if [ ! -d "$DEST" ]; then
        echo "✗ ERROR: Destination directory not found: $DEST"
        exit 1
    fi

    # Copy each shared file
    for file in "${SHARED_FILES[@]}"; do
        SOURCE="$MASTER_SHARED/$file"
        TARGET="$DEST/$file"

        if [ ! -f "$SOURCE" ]; then
            echo "✗ WARNING: Source file not found: $SOURCE"
            continue
        fi

        # Copy the file
        cp "$SOURCE" "$TARGET"

        # Verify copy was successful
        if [ -f "$TARGET" ]; then
            SIZE=$(wc -l < "$TARGET" 2>/dev/null || echo "0")
            echo "  ✓ $file ($SIZE lines)"
        else
            echo "  ✗ FAILED to copy: $file"
        fi
    done

    echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Sync complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Summary:"
echo "  • Synced ${#SHARED_FILES[@]} files to ${#MODES[@]} skill modes"
echo "  • Source: templates/master/shared/"
echo "  • Targets: skills/devcontainer-setup-{basic,intermediate,advanced,yolo}/templates/"
echo ""
echo "Next steps:"
echo "  1. Review changes: git diff"
echo "  2. Test skill execution to verify templates work"
echo "  3. Commit changes: git add . && git commit -m 'Sync master templates to skills'"
echo ""
