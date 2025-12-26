#!/bin/bash
# ============================================================================
# CLAUDE CODE SANDBOX - Domain Allowlist Firewall Configuration
# ============================================================================
# This firewall implements strict network restrictions with a curated allowlist
# of essential development domains. This provides strong security while
# maintaining functionality for common development workflows.
#
# Security model:
# - Strict whitelist-based firewall (deny by default)
# - Curated list of essential development domains
# - User can add project-specific domains as needed
# - Full verification of firewall rules
#
# Usage:
#   1. Review and customize ALLOWED_DOMAINS section below
#   2. Run script with sudo: sudo /usr/local/bin/init-firewall.sh
#   3. Verify firewall is working correctly
# ============================================================================

set -euo pipefail  # Exit on error, undefined vars, and pipeline failures
IFS=$'\n\t'       # Stricter word splitting

# ----------------------------------------------------------------------------
# CONFIGURATION
# ----------------------------------------------------------------------------

# Firewall mode is always strict for domain allowlist configuration
FIREWALL_MODE="strict"

# CUSTOMIZE: Add your project-specific domains to this array
# These domains will be allowed in addition to the defaults below
ALLOWED_DOMAINS=(
  # ===CATEGORY:anthropic_services===
  # Anthropic API and services
  "api.anthropic.com"
  "statsig.anthropic.com"
  "claude.ai"
  # ===END_CATEGORY===

  # ===CATEGORY:version_control===
  # Git hosting platforms
  "github.com"
  "www.github.com"
  "api.github.com"
  "raw.githubusercontent.com"
  "objects.githubusercontent.com"
  "codeload.githubusercontent.com"
  "avatars.githubusercontent.com"
  "camo.githubusercontent.com"
  "gist.github.com"
  "gitlab.com"
  "www.gitlab.com"
  "registry.gitlab.com"
  "bitbucket.org"
  "www.bitbucket.org"
  "api.bitbucket.org"
  # ===END_CATEGORY===

  # ===CATEGORY:container_registries===
  # Docker and container registries
  "registry-1.docker.io"
  "auth.docker.io"
  "index.docker.io"
  "hub.docker.com"
  "www.docker.com"
  "production.cloudflare.docker.com"
  "download.docker.com"
  "ghcr.io"
  "mcr.microsoft.com"
  # ===END_CATEGORY===

  # ===CATEGORY:package_managers_npm===
  # JavaScript/Node.js packages
  "registry.npmjs.org"
  "www.npmjs.com"
  "www.npmjs.org"
  "npmjs.com"
  "npmjs.org"
  "yarnpkg.com"
  "registry.yarnpkg.com"
  # ===END_CATEGORY===

  # ===CATEGORY:package_managers_python===
  # Python packages
  "pypi.org"
  "www.pypi.org"
  "files.pythonhosted.org"
  "pythonhosted.org"
  "test.pypi.org"
  "pypi.python.org"
  "pypa.io"
  "www.pypa.io"
  # ===END_CATEGORY===

  # ===CATEGORY:linux_distributions===
  # Linux package repositories
  "archive.ubuntu.com"
  "security.ubuntu.com"
  "ubuntu.com"
  "www.ubuntu.com"
  "ppa.launchpad.net"
  "launchpad.net"
  "www.launchpad.net"
  # ===END_CATEGORY===

  # ===CATEGORY:vscode===
  # VS Code extensions and updates
  "marketplace.visualstudio.com"
  "vscode.blob.core.windows.net"
  "update.code.visualstudio.com"
  # ===END_CATEGORY===

  # ===CATEGORY:project_specific===
  # CUSTOMIZE: Add your project-specific domains here
  # Example: Your API endpoints, CDNs, third-party services
  # "api.yourproject.com"
  # "cdn.yourproject.com"
  # ===END_CATEGORY===
)

# Test domain for firewall verification (should NOT be accessible in strict mode)
TEST_BLOCKED_DOMAIN="example.com"

# Test domain for firewall verification (should be accessible in strict mode)
TEST_ALLOWED_DOMAIN="api.github.com"

# ----------------------------------------------------------------------------
# STRICT MODE - Whitelist approach
# ----------------------------------------------------------------------------
echo "=========================================="
echo "FIREWALL MODE: STRICT (ADVANCED)"
echo "=========================================="
echo "Only specified domains will be allowed."
echo ""

# Extract Docker DNS info BEFORE any flushing
DOCKER_DNS_RULES=$(iptables-save -t nat | grep "127\.0\.0\.11" || true)

# Flush existing rules and delete existing ipsets
echo "Flushing existing firewall rules..."
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
ipset destroy allowed-domains 2>/dev/null || true

# Selectively restore ONLY internal Docker DNS resolution
if [ -n "$DOCKER_DNS_RULES" ]; then
    echo "Restoring Docker DNS rules..."
    iptables -t nat -N DOCKER_OUTPUT 2>/dev/null || true
    iptables -t nat -N DOCKER_POSTROUTING 2>/dev/null || true
    echo "$DOCKER_DNS_RULES" | xargs -L 1 iptables -t nat
else
    echo "No Docker DNS rules to restore"
fi

# ----------------------------------------------------------------------------
# ALLOW ESSENTIAL SERVICES FIRST
# ----------------------------------------------------------------------------
echo "Configuring essential services..."

# Allow outbound DNS
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
# Allow inbound DNS responses
iptables -A INPUT -p udp --sport 53 -j ACCEPT

# Allow outbound SSH
iptables -A OUTPUT -p tcp --dport 22 -j ACCEPT
# Allow inbound SSH responses
iptables -A INPUT -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT

# Allow localhost
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# ----------------------------------------------------------------------------
# CREATE IP SET FOR ALLOWED DOMAINS
# ----------------------------------------------------------------------------
echo "Creating IP set for allowed domains..."
ipset create allowed-domains hash:net

# ----------------------------------------------------------------------------
# FETCH AND ADD GITHUB IP RANGES
# ----------------------------------------------------------------------------
echo "Fetching GitHub IP ranges..."
gh_ranges=$(curl -s https://api.github.com/meta)
if [ -z "$gh_ranges" ]; then
    echo "ERROR: Failed to fetch GitHub IP ranges"
    exit 1
fi

if ! echo "$gh_ranges" | jq -e '.web and .api and .git' >/dev/null; then
    echo "ERROR: GitHub API response missing required fields"
    exit 1
fi

echo "Processing GitHub IPs..."
while read -r cidr; do
    if [[ ! "$cidr" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$ ]]; then
        echo "ERROR: Invalid CIDR range from GitHub meta: $cidr"
        exit 1
    fi
    echo "  Adding GitHub range $cidr"
    ipset add -exist allowed-domains "$cidr"
done < <(echo "$gh_ranges" | jq -r '(.web + .api + .git)[]' | aggregate -q)

# ----------------------------------------------------------------------------
# RESOLVE AND ADD ALLOWED DOMAINS
# ----------------------------------------------------------------------------
echo "Resolving and adding allowed domains..."
for domain in "${ALLOWED_DOMAINS[@]}"; do
    # Skip comments and empty lines
    [[ "$domain" =~ ^#.*$ ]] && continue
    [[ -z "$domain" ]] && continue

    echo "  Resolving $domain..."
    ips=$(dig +noall +answer A "$domain" | awk '$4 == "A" {print $5}')

    if [ -z "$ips" ]; then
        echo "  WARNING: Failed to resolve $domain (skipping)"
        continue
    fi

    while read -r ip; do
        if [[ ! "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            echo "  WARNING: Invalid IP from DNS for $domain: $ip (skipping)"
            continue
        fi
        echo "    Adding $ip for $domain"
        ipset add -exist allowed-domains "$ip"
    done < <(echo "$ips")
done

# ----------------------------------------------------------------------------
# ALLOW HOST NETWORK
# ----------------------------------------------------------------------------
# Get host IP from default route
HOST_IP=$(ip route | grep default | cut -d" " -f3)
if [ -z "$HOST_IP" ]; then
    echo "ERROR: Failed to detect host IP"
    exit 1
fi

HOST_NETWORK=$(echo "$HOST_IP" | sed "s/\.[0-9]*$/.0\/24/")
echo "Host network detected as: $HOST_NETWORK"

# Allow traffic to/from host network (for Docker services)
iptables -A INPUT -s "$HOST_NETWORK" -j ACCEPT
iptables -A OUTPUT -d "$HOST_NETWORK" -j ACCEPT

# ----------------------------------------------------------------------------
# SET DEFAULT POLICIES AND FIREWALL RULES
# ----------------------------------------------------------------------------
echo "Applying firewall rules..."

# Set default policies to DROP
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

# Allow established connections for already approved traffic
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow only specific outbound traffic to allowed domains
iptables -A OUTPUT -m set --match-set allowed-domains dst -j ACCEPT

# Explicitly REJECT all other outbound traffic for immediate feedback
iptables -A OUTPUT -j REJECT --reject-with icmp-admin-prohibited

# ----------------------------------------------------------------------------
# VERIFICATION
# ----------------------------------------------------------------------------
echo ""
echo "=========================================="
echo "FIREWALL VERIFICATION"
echo "=========================================="

# Verify we CANNOT reach a blocked domain
echo "Testing blocked domain ($TEST_BLOCKED_DOMAIN)..."
if curl --connect-timeout 5 https://$TEST_BLOCKED_DOMAIN >/dev/null 2>&1; then
    echo "ERROR: Firewall verification failed - was able to reach https://$TEST_BLOCKED_DOMAIN"
    exit 1
else
    echo "  ✓ Unable to reach $TEST_BLOCKED_DOMAIN as expected"
fi

# Verify we CAN reach an allowed domain
echo "Testing allowed domain ($TEST_ALLOWED_DOMAIN)..."
if ! curl --connect-timeout 5 https://$TEST_ALLOWED_DOMAIN/zen >/dev/null 2>&1; then
    echo "ERROR: Firewall verification failed - unable to reach https://$TEST_ALLOWED_DOMAIN"
    exit 1
else
    echo "  ✓ Able to reach $TEST_ALLOWED_DOMAIN as expected"
fi

echo ""
echo "=========================================="
echo "FIREWALL CONFIGURED SUCCESSFULLY"
echo "=========================================="
echo "Mode: $FIREWALL_MODE (Domain allowlist configuration)"
echo "Allowed domains: ${#ALLOWED_DOMAINS[@]}"
echo "Host network: $HOST_NETWORK"
echo ""
echo "To allow additional domains:"
echo "1. Edit ALLOWED_DOMAINS array in /usr/local/bin/init-firewall.sh"
echo "2. Add domains in the ===CATEGORY:project_specific=== section"
echo "3. Re-run: sudo /usr/local/bin/init-firewall.sh"
echo ""
echo "Categories included:"
echo "  - Anthropic services"
echo "  - Version control (GitHub, GitLab, BitBucket)"
echo "  - Container registries (Docker Hub, GHCR, MCR)"
echo "  - Package managers (npm, Python/PyPI)"
echo "  - Linux distributions (Ubuntu)"
echo "  - VS Code extensions and updates"
echo "=========================================="
