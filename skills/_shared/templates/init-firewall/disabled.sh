#!/bin/bash
# ============================================================================
# CLAUDE CODE SANDBOX - Disabled Firewall (Basic Mode)
# ============================================================================
# Basic mode relies on Docker container isolation only. No firewall rules are
# applied, providing the simplest setup for rapid development and prototyping.
#
# Security model:
# - Docker container isolation (default sandbox)
# - No network restrictions
# - Suitable for trusted code and rapid prototyping
#
# This is the default for Basic mode.
# ============================================================================

echo "=========================================="
echo "FIREWALL: DISABLED (Basic Mode)"
echo "=========================================="
echo "No firewall configured - relies on Docker container isolation"
echo "Firewall configuration complete (no restrictions applied)"
echo "=========================================="

exit 0
