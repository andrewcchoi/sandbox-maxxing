#!/bin/bash
# ============================================================================
# CLAUDE CODE SANDBOX - Permissive Firewall
# ============================================================================
# Permissive mode allows all outbound traffic with no restrictions.
# Provides maximum compatibility while still maintaining container isolation.
#
# Security model:
# - Docker container isolation
# - All outbound connections allowed
# - No domain filtering
# - Suitable for development environments requiring broad network access
#
# This is an option for YOLO mode.
# ============================================================================

set -euo pipefail
IFS=$'\n\t'

echo "=========================================="
echo "FIREWALL: PERMISSIVE MODE"
echo "=========================================="
echo "All outbound traffic allowed (no restrictions)"
echo "Firewall configuration complete"
echo "=========================================="

exit 0
