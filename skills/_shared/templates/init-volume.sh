#!/bin/bash
# ============================================================================
# Volume Initialization Script
# ============================================================================
# NOTE: This script is kept for reference/manual use only.
# The devcontainer.json uses a Docker array command instead for Windows compatibility.
# See commands/quickstart.md for the cross-platform initializeCommand implementation.
# ============================================================================
# Copies host files into the Docker volume before container starts.
# Issue #79: Repository container option for Windows/macOS performance
# ============================================================================

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Sanitize project name for Docker compatibility
sanitize_project_name() {
  local name="$1"
  local sanitized
  sanitized=$(echo "$name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')
  sanitized=$(echo "$sanitized" | sed 's/^-*//;s/-*$//;s/--*/-/g')
  [ -z "$sanitized" ] && sanitized="sandbox-app"
  echo "$sanitized"
}

RAW_PROJECT_NAME="$(basename "$PROJECT_DIR")"
PROJECT_NAME="$(sanitize_project_name "$RAW_PROJECT_NAME")"
if [ "$PROJECT_NAME" != "$RAW_PROJECT_NAME" ]; then
  echo "Note: Project name sanitized: '$RAW_PROJECT_NAME' -> '$PROJECT_NAME'"
fi

VOLUME_NAME="${PROJECT_NAME}-workspace-volume"

echo "Initializing volume: $VOLUME_NAME"

# Create volume if it doesn't exist
docker volume create "$VOLUME_NAME" 2>/dev/null || true

# Copy files into volume using alpine container
# Uses a temporary container to mount both the source and destination
docker run --rm \
  -v "$PROJECT_DIR:/source:ro" \
  -v "$VOLUME_NAME:/dest" \
  alpine sh -c '
    echo "Copying project files to volume..."
    cp -a /source/. /dest/ 2>/dev/null || true
    FILE_COUNT=$(find /dest -type f | wc -l)
    echo "Done: $FILE_COUNT files copied"
  '

echo "Volume initialization complete"
