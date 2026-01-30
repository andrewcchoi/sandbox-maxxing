#!/bin/bash
# ============================================================================
# CLAUDE CODE SANDBOX - Permissive Firewall Configuration
# ============================================================================
# This configuration uses permissive mode with no network restrictions.
# This provides maximum flexibility for development while still maintaining
# container-level isolation.
#
# Security model:
# - Container isolation only (no network restrictions)
# - All outbound traffic allowed
# - User responsible for security considerations
#
# WARNING: This configuration allows unrestricted network access from the
# container. Only use in trusted development environments where you control
# the code being executed. Do NOT use when running untrusted or unknown code.
# ============================================================================

set -euo pipefail  # Exit on error, undefined vars, and pipeline failures
IFS=$'\n\t'       # Stricter word splitting

echo "============================================================================"
echo "FIREWALL MODE: PERMISSIVE"
echo "============================================================================"
echo "All outbound traffic will be allowed."
echo ""
echo "WARNING: No network restrictions applied."
echo "This mode provides maximum flexibility but"
echo "relies solely on container isolation for security."
echo ""

# Validate iptables is available
if ! command -v iptables &>/dev/null; then
    echo "ERROR: iptables command not found or not executable"
    echo "Firewall configuration cannot proceed without iptables"
    exit 1
fi

# Clear any existing rules
echo "Clearing any existing firewall rules..."
iptables -F 2>/dev/null || true
iptables -X 2>/dev/null || true
# Don't flush NAT table - Docker needs these rules for DNS and routing
# iptables -t nat -F 2>/dev/null || true
# iptables -t nat -X 2>/dev/null || true
iptables -t mangle -F 2>/dev/null || true
iptables -t mangle -X 2>/dev/null || true
# Clean up ipset from any previous restrictive mode configuration (if present)
if command -v ipset &>/dev/null; then
    ipset destroy allowed-domains 2>/dev/null || true
fi

# Set default policies to ACCEPT (critical - must not fail silently)
echo "Setting permissive policies..."
if ! iptables -P INPUT ACCEPT 2>/dev/null; then
    echo "ERROR: Failed to set INPUT policy to ACCEPT"
    echo "Insufficient permissions or iptables configuration issue"
    exit 1
fi
if ! iptables -P FORWARD ACCEPT 2>/dev/null; then
    echo "ERROR: Failed to set FORWARD policy to ACCEPT"
    echo "Insufficient permissions or iptables configuration issue"
    exit 1
fi
if ! iptables -P OUTPUT ACCEPT 2>/dev/null; then
    echo "ERROR: Failed to set OUTPUT policy to ACCEPT"
    echo "Insufficient permissions or iptables configuration issue"
    exit 1
fi

echo ""
echo "============================================================================"
echo "FIREWALL CONFIGURED SUCCESSFULLY"
echo "============================================================================"
echo "Mode: PERMISSIVE (Container isolation only)"
echo "Network restrictions: None"
echo ""
echo "Security considerations:"
echo "  - Container isolation is your primary protection"
echo "  - Be cautious about running untrusted code"
echo "  - Consider using domain allowlist configuration for network-level restrictions"
echo "============================================================================"

exit 0
