#!/usr/bin/env bash
# Sync knowledge files from Docker volumes to host
# Scans for any volume with "claude" or "agent" in the name
set -euo pipefail

# Validate HOME is set and is a valid directory
if [ -z "${HOME:-}" ]; then
    echo "[sync-knowledge] ERROR: HOME environment variable not set" >&2
    exit 1
fi

if [ ! -d "$HOME" ]; then
    echo "[sync-knowledge] ERROR: HOME directory does not exist: $HOME" >&2
    exit 1
fi

HOST_CLAUDE_DIR="${HOME}/.claude"

# Find all volumes with "claude" or "agent" in name
VOLUMES=$(docker volume ls --format '{{.Name}}' | grep -iE '(claude|agent)' || true)

if [ -z "$VOLUMES" ]; then
    echo "[sync-knowledge] No claude/agent volumes found, skipping" >&2
    exit 0
fi

# Ensure host directories exist with restrictive permissions (700 = user only)
# Prevents other users on multi-user systems from reading sensitive Claude data
mkdir -p -m 0700 "$HOST_CLAUDE_DIR"
mkdir -p -m 0700 "$HOST_CLAUDE_DIR/plans"
mkdir -p -m 0700 "$HOST_CLAUDE_DIR/state"

# Track actual synced count
SYNCED_COUNT=0

# Sync from each matching volume
while IFS= read -r VOLUME_NAME; do
    [ -z "$VOLUME_NAME" ] && continue

    # Validate volume name format (alphanumeric, dash, underscore only - no dots for extra safety)
    # Docker volume names are opaque identifiers, not paths, but we restrict dots for defense in depth
    if ! [[ "$VOLUME_NAME" =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]*$ ]]; then
        echo "[sync-knowledge] Skipping invalid volume name: $VOLUME_NAME" >&2
        continue
    fi

    # Additional length check (Docker max is 242 chars, we limit to 200)
    if [ ${#VOLUME_NAME} -gt 200 ]; then
        echo "[sync-knowledge] Skipping volume name too long: $VOLUME_NAME" >&2
        continue
    fi

    echo "[sync-knowledge] Scanning volume: $VOLUME_NAME"

    # Check if volume has Claude-like structure (plans/ or state/ dir)
    # Run as current user to avoid permission issues
    # Use pinned Alpine version for security (3.19 is stable LTS)
    HAS_CLAUDE_DATA=$(docker run --rm --user "$(id -u):$(id -g)" \
      -v "${VOLUME_NAME}:/source:ro" alpine:3.19 sh -c \
      '[ -d /source/plans ] || [ -d /source/state ] && echo "yes" || echo "no"' 2>&1) || {
        echo "  - Skipping (docker error)" >&2
        continue
    }

    # Ensure we got valid output
    HAS_CLAUDE_DATA=$(echo "$HAS_CLAUDE_DATA" | tail -n1)

    if [ "$HAS_CLAUDE_DATA" = "no" ]; then
        echo "  - Skipping (no plans/ or state/ directory)"
        continue
    fi

    # Sync via alpine container (works cross-platform)
    # Run as current user to prevent root-owned files in user directory
    # Use pinned Alpine version for security (3.19 is stable LTS)
    if docker run --rm --user "$(id -u):$(id -g)" \
      -v "${VOLUME_NAME}:/source:ro" \
      -v "${HOST_CLAUDE_DIR}:/dest" \
      alpine:3.19 sh -c '
        # Sync plans (only .md files)
        [ -d /source/plans ] && cp -r /source/plans/. /dest/plans/ 2>/dev/null || true

        # Sync state (logs only, not sensitive)
        [ -d /source/state ] && cp -r /source/state/. /dest/state/ 2>/dev/null || true

        # Sync projects.json
        [ -f /source/projects.json ] && cp /source/projects.json /dest/ 2>/dev/null || true
      '; then
        echo "  - Synced knowledge files"
        SYNCED_COUNT=$((SYNCED_COUNT + 1))
    else
        echo "  - Error syncing from $VOLUME_NAME" >&2
        continue
    fi
done <<< "$VOLUMES"

echo "[sync-knowledge] Done syncing from $SYNCED_COUNT volume(s)"
