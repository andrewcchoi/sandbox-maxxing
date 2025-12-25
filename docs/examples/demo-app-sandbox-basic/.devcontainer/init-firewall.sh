#!/bin/bash
# ============================================================================
# CLAUDE CODE SANDBOX - Minimal Configuration (No Firewall)
# ============================================================================
# Minimal configuration relies on container isolation for security rather than
# network-level restrictions. This approach minimizes complexity while
# leveraging the container isolation provided by Docker.
#
# Security model:
# - Container-level isolation (Docker)
# - Ephemeral environment (automatic cleanup on exit)
# - No persistent state between sessions
# - No network firewall restrictions
# ============================================================================

echo "=========================================="
echo "FIREWALL: MINIMAL CONFIGURATION"
echo "=========================================="
echo "No firewall configured (minimal configuration - relies on container isolation)"
echo ""
echo "Security model:"
echo "  - Windows Sandbox hypervisor isolation"
echo "  - Ephemeral container environment"
echo "  - No persistent state"
echo ""
echo "Firewall configuration complete (no restrictions applied)"
echo "=========================================="

exit 0
