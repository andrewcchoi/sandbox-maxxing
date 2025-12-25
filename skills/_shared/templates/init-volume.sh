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
PROJECT_NAME="$(basename "$PROJECT_DIR")"
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
