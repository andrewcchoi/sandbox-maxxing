#!/bin/bash
# ============================================================================
# CLAUDE CODE SANDBOX - Basic Mode Firewall Configuration
# ============================================================================
# Basic mode relies on Windows Sandbox isolation for security rather than
# network-level restrictions. This approach minimizes complexity while
# leveraging the hypervisor-based isolation provided by Windows Sandbox.
#
# Security model:
# - Hypervisor-level container isolation (Windows Sandbox)
# - Ephemeral environment (automatic cleanup on exit)
# - No persistent state between sessions
# - No network firewall restrictions
# ============================================================================

echo "=========================================="
echo "FIREWALL: BASIC MODE"
echo "=========================================="
echo "No firewall configured (Basic mode - relies on sandbox isolation)"
echo ""
echo "Security model:"
echo "  - Windows Sandbox hypervisor isolation"
echo "  - Ephemeral container environment"
echo "  - No persistent state"
echo ""
echo "Firewall configuration complete (no restrictions applied)"
echo "=========================================="

exit 0
