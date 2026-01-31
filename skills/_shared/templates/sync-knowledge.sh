#!/usr/bin/env bash
# Sync knowledge files from Docker volumes to host
# Scans for any volume with "claude" or "agent" in the name
set -euo pipefail

HOST_CLAUDE_DIR="${HOME}/.claude"

# Find all volumes with "claude" or "agent" in name
VOLUMES=$(docker volume ls --format '{{.Name}}' | grep -iE '(claude|agent)' || true)

if [ -z "$VOLUMES" ]; then
    echo "[sync-knowledge] No claude/agent volumes found, skipping" >&2
    exit 0
fi

# Ensure host directories exist
mkdir -p "$HOST_CLAUDE_DIR/plans" "$HOST_CLAUDE_DIR/state"

# Sync from each matching volume
echo "$VOLUMES" | while IFS= read -r VOLUME_NAME; do
    [ -z "$VOLUME_NAME" ] && continue
    echo "[sync-knowledge] Scanning volume: $VOLUME_NAME"

    # Check if volume has Claude-like structure (plans/ or state/ dir)
    HAS_CLAUDE_DATA=$(docker run --rm -v "${VOLUME_NAME}:/source:ro" alpine sh -c \
      '[ -d /source/plans ] || [ -d /source/state ] && echo "yes" || echo "no"' 2>/dev/null || echo "no")

    if [ "$HAS_CLAUDE_DATA" = "no" ]; then
        echo "  - Skipping (no plans/ or state/ directory)"
        continue
    fi

    # Sync via alpine container (works cross-platform)
    docker run --rm \
      -v "${VOLUME_NAME}:/source:ro" \
      -v "${HOST_CLAUDE_DIR}:/dest" \
      alpine sh -c '
        # Sync plans (only .md files)
        [ -d /source/plans ] && cp -r /source/plans/. /dest/plans/ 2>/dev/null || true

        # Sync state (logs only, not sensitive)
        [ -d /source/state ] && cp -r /source/state/. /dest/state/ 2>/dev/null || true

        # Sync projects.json
        [ -f /source/projects.json ] && cp /source/projects.json /dest/ 2>/dev/null || true
      '

    echo "  - Synced knowledge files"
done

echo "[sync-knowledge] Done syncing from $(echo "$VOLUMES" | wc -l) volume(s)"
