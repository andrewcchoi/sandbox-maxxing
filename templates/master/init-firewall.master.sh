#!/bin/bash
# ============================================================================
# CLAUDE CODE SANDBOX - Network Firewall Configuration Script (MASTER)
# ============================================================================
# This script configures iptables to restrict outbound network access from
# the DevContainer. It supports three modes:
#
# - STRICT MODE: Whitelist approach - only allow specified domains
# - PERMISSIVE MODE: Allow all outbound traffic (no restrictions)
# - DISABLED MODE: Skip firewall configuration entirely
#
# Usage:
#   - Set FIREWALL_MODE environment variable in devcontainer.json
#   - Or edit the FIREWALL_MODE variable below directly
# ============================================================================

set -euo pipefail  # Exit on error, undefined vars, and pipeline failures
IFS=$'\n\t'       # Stricter word splitting

# ----------------------------------------------------------------------------
# CONFIGURATION
# ----------------------------------------------------------------------------

# CUSTOMIZE: Set to "strict", "permissive", or "disabled"
# - strict: Whitelist only (deny all except allowed domains)
# - permissive: Allow all (no network restrictions)
# - disabled: Skip firewall configuration entirely
FIREWALL_MODE="${FIREWALL_MODE:-strict}"

# CUSTOMIZE: Add your project-specific domains to this array
# These domains will be allowed in STRICT mode
ALLOWED_DOMAINS=(
  # ===CATEGORY_START:version_control===
  # Version control and collaboration
  "github.com"
  "api.github.com"
  "gitlab.com"
  "bitbucket.org"
  # ===CATEGORY_END:version_control===

  # ===CATEGORY_START:package_registries===
  # Package registries - JavaScript/Node.js
  "registry.npmjs.org"

  # Package registries - Python
  "pypi.org"
  "files.pythonhosted.org"

  # Package registries - Ruby
  "rubygems.org"

  # Package registries - Rust
  "crates.io"
  "static.crates.io"

  # Package registries - Go
  "proxy.golang.org"
  "sum.golang.org"

  # Package registries - PHP
  "packagist.org"
  "repo.packagist.org"

  # Package registries - Maven/Java
  "repo.maven.apache.org"
  "central.maven.org"
  # ===CATEGORY_END:package_registries===

  # ===CATEGORY_START:ai_providers===
  # AI providers (if using Claude Code or other AI services)
  "api.anthropic.com"
  "api.openai.com"
  "api.groq.com"
  # ===CATEGORY_END:ai_providers===

  # ===CATEGORY_START:analytics_telemetry===
  # Analytics and telemetry (Claude Code, VS Code)
  "sentry.io"
  "statsig.anthropic.com"
  "statsig.com"
  # ===CATEGORY_END:analytics_telemetry===

  # ===CATEGORY_START:vscode===
  # VS Code marketplace and updates
  "marketplace.visualstudio.com"
  "vscode.blob.core.windows.net"
  "update.code.visualstudio.com"
  "vscode.download.prss.microsoft.com"
  "vscode-sync.trafficmanager.net"
  # ===CATEGORY_END:vscode===

  # ===CATEGORY_START:cdn===
  # Common CDNs
  "cdn.jsdelivr.net"
  "unpkg.com"
  "cdnjs.cloudflare.com"
  # ===CATEGORY_END:cdn===

  # ===CATEGORY_START:container_registries===
  # Container registries
  "registry.hub.docker.com"
  "ghcr.io"
  "gcr.io"
  "quay.io"
  # ===CATEGORY_END:container_registries===

  # ===CATEGORY_START:cloud_providers===
  # Cloud providers (storage, APIs)
  "s3.amazonaws.com"
  "storage.googleapis.com"
  "blob.core.windows.net"
  # ===CATEGORY_END:cloud_providers===

  # ===CATEGORY_START:language_tools===
  # Language-specific tooling
  "go.dev"
  "dl.google.com"  # Go downloads
  "sh.rustup.rs"   # Rust toolchain installer
  # ===CATEGORY_END:language_tools===

  # ===CATEGORY_START:custom===
  # CUSTOMIZE: Add your project-specific domains here
  # Example: Your API endpoints, CDNs, third-party services
  # "api.yourproject.com"
  # "cdn.yourproject.com"
  # "example.com"
  # ===CATEGORY_END:custom===
)

# Test domain for firewall verification (should NOT be accessible in strict mode)
TEST_BLOCKED_DOMAIN="example.com"

# Test domain for firewall verification (should be accessible in strict mode)
TEST_ALLOWED_DOMAIN="api.github.com"

# ----------------------------------------------------------------------------
# DISABLED MODE - Skip firewall configuration
# ----------------------------------------------------------------------------
if [ "$FIREWALL_MODE" = "disabled" ]; then
  echo "=========================================="
  echo "FIREWALL MODE: DISABLED"
  echo "=========================================="
  echo "Firewall configuration is disabled."
  echo "No network restrictions will be applied."
  echo ""
  exit 0
fi

# ----------------------------------------------------------------------------
# PERMISSIVE MODE - Allow all traffic
# ----------------------------------------------------------------------------
if [ "$FIREWALL_MODE" = "permissive" ]; then
  echo "=========================================="
  echo "FIREWALL MODE: PERMISSIVE"
  echo "=========================================="
  echo "All outbound traffic will be allowed."
  echo ""

  # Clear any existing rules
  iptables -F
  iptables -X
  iptables -t nat -F
  iptables -t nat -X
  iptables -t mangle -F
  iptables -t mangle -X
  ipset destroy allowed-domains 2>/dev/null || true

  # Set default policies to ACCEPT
  iptables -P INPUT ACCEPT
  iptables -P FORWARD ACCEPT
  iptables -P OUTPUT ACCEPT

  echo "Firewall configuration complete (permissive mode)"
  echo "No network restrictions applied."
  exit 0
fi

# ----------------------------------------------------------------------------
# STRICT MODE - Whitelist approach
# ----------------------------------------------------------------------------
echo "=========================================="
echo "FIREWALL MODE: STRICT"
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
    ipset add allowed-domains "$cidr"
done < <(echo "$gh_ranges" | jq -r '(.web + .api + .git)[]' | aggregate -q)

# ----------------------------------------------------------------------------
# RESOLVE AND ADD ALLOWED DOMAINS
# ----------------------------------------------------------------------------
echo "Resolving and adding allowed domains..."
for domain in "${ALLOWED_DOMAINS[@]}"; do
    # Skip commented lines
    [[ "$domain" =~ ^[[:space:]]*# ]] && continue
    # Skip empty lines
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
        ipset add allowed-domains "$ip"
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
echo "Mode: $FIREWALL_MODE"
echo "Allowed domains: ${#ALLOWED_DOMAINS[@]}"
echo "Host network: $HOST_NETWORK"
echo ""
echo "To allow additional domains:"
echo "1. Edit ALLOWED_DOMAINS array in /usr/local/bin/init-firewall.sh"
echo "2. Re-run: sudo /usr/local/bin/init-firewall.sh"
echo ""
echo "To switch modes:"
echo "1. Set FIREWALL_MODE in devcontainer.json to 'strict', 'permissive', or 'disabled'"
echo "2. Rebuild container"
echo "=========================================="
