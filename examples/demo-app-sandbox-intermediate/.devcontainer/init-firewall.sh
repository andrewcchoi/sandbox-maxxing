#!/bin/bash
# ============================================================================
# CLAUDE CODE SANDBOX - Intermediate Tier Firewall Configuration
# ============================================================================
# Intermediate tier uses permissive mode with no network restrictions.
# This provides maximum flexibility for development while still maintaining
# container-level isolation.
#
# Security model:
# - Container isolation only (no network restrictions)
# - All outbound traffic allowed
# - User responsible for security considerations
#
# WARNING: This configuration allows unrestricted network access from the
# container. Only use in trusted development environments.
# ============================================================================

set -euo pipefail  # Exit on error, undefined vars, and pipeline failures
IFS=$'\n\t'       # Stricter word splitting

echo "=========================================="
echo "FIREWALL MODE: PERMISSIVE (INTERMEDIATE)"
echo "=========================================="
echo "All outbound traffic will be allowed."
echo ""
echo "WARNING: No network restrictions applied."
echo "This mode provides maximum flexibility but"
echo "relies solely on container isolation for security."
echo ""

# Clear any existing rules
echo "Clearing any existing firewall rules..."
iptables -F 2>/dev/null || true
iptables -X 2>/dev/null || true
iptables -t nat -F 2>/dev/null || true
iptables -t nat -X 2>/dev/null || true
iptables -t mangle -F 2>/dev/null || true
iptables -t mangle -X 2>/dev/null || true
ipset destroy allowed-domains 2>/dev/null || true

# Set default policies to ACCEPT
echo "Setting permissive policies..."
iptables -P INPUT ACCEPT 2>/dev/null || true
iptables -P FORWARD ACCEPT 2>/dev/null || true
iptables -P OUTPUT ACCEPT 2>/dev/null || true

echo ""
echo "=========================================="
echo "FIREWALL CONFIGURED SUCCESSFULLY"
echo "=========================================="
echo "Mode: Permissive (Intermediate tier)"
echo "Network restrictions: None"
echo ""
echo "Security considerations:"
echo "  - Container isolation is your primary protection"
echo "  - Be cautious about running untrusted code"
echo "  - Consider upgrading to Advanced tier for network-level restrictions"
echo "=========================================="

exit 0
