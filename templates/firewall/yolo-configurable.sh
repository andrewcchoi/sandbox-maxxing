#!/bin/bash
# ============================================================================
# CLAUDE CODE SANDBOX - YOLO Tier Firewall Configuration
# ============================================================================
# YOLO tier provides complete flexibility with optional firewall modes:
# - DISABLED: No firewall (relies on container isolation only)
# - PERMISSIVE: Allow all traffic (like Intermediate tier)
# - STRICT: Whitelist-based firewall with comprehensive domain categories
#
# This template includes all available domain categories from the standard
# allowable domains list. Users can enable/disable categories as needed.
#
# Security model:
# - User-controlled security posture
# - Full access to all domain categories
# - Configurable via FIREWALL_MODE environment variable
#
# Usage:
#   Set FIREWALL_MODE in devcontainer.json or edit the variable below:
#   - disabled: No firewall restrictions
#   - permissive: Allow all traffic
#   - strict: Whitelist-based firewall (customize ALLOWED_DOMAINS)
# ============================================================================

set -euo pipefail  # Exit on error, undefined vars, and pipeline failures
IFS=$'\n\t'       # Stricter word splitting

# ----------------------------------------------------------------------------
# CONFIGURATION
# ----------------------------------------------------------------------------

# CUSTOMIZE: Set to "disabled", "permissive", or "strict"
# - disabled: No firewall (container isolation only)
# - permissive: Allow all outbound traffic (no restrictions)
# - strict: Whitelist only (deny all except allowed domains)
FIREWALL_MODE="${FIREWALL_MODE:-strict}"

# CUSTOMIZE: Add your project-specific domains to this array
# Uncomment categories you need or add custom domains
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

  # ===CATEGORY:cloud_platforms_google===
  # Google Cloud Platform
  # "cloud.google.com"
  # "accounts.google.com"
  # "gcloud.google.com"
  # "storage.googleapis.com"
  # "compute.googleapis.com"
  # "container.googleapis.com"
  # ===END_CATEGORY===

  # ===CATEGORY:cloud_platforms_azure===
  # Microsoft Azure
  # "azure.com"
  # "portal.azure.com"
  # "microsoft.com"
  # "www.microsoft.com"
  # "packages.microsoft.com"
  # "dotnet.microsoft.com"
  # "dot.net"
  # "visualstudio.com"
  # "dev.azure.com"
  # ===END_CATEGORY===

  # ===CATEGORY:cloud_platforms_oracle===
  # Oracle Cloud
  # "oracle.com"
  # "www.oracle.com"
  # "java.com"
  # "www.java.com"
  # "java.net"
  # "www.java.net"
  # "download.oracle.com"
  # "yum.oracle.com"
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

  # ===CATEGORY:package_managers_ruby===
  # Ruby gems
  # "rubygems.org"
  # "www.rubygems.org"
  # "api.rubygems.org"
  # "index.rubygems.org"
  # "ruby-lang.org"
  # "www.ruby-lang.org"
  # "rubyforge.org"
  # "www.rubyforge.org"
  # "rubyonrails.org"
  # "www.rubyonrails.org"
  # "rvm.io"
  # "get.rvm.io"
  # ===END_CATEGORY===

  # ===CATEGORY:package_managers_rust===
  # Rust crates
  # "crates.io"
  # "www.crates.io"
  # "static.crates.io"
  # "rustup.rs"
  # "static.rust-lang.org"
  # "www.rust-lang.org"
  # ===END_CATEGORY===

  # ===CATEGORY:package_managers_go===
  # Go modules
  # "proxy.golang.org"
  # "sum.golang.org"
  # "index.golang.org"
  # "golang.org"
  # "www.golang.org"
  # "goproxy.io"
  # "pkg.go.dev"
  # ===END_CATEGORY===

  # ===CATEGORY:package_managers_maven===
  # JVM packages (Maven, Gradle)
  # "maven.org"
  # "repo.maven.org"
  # "central.maven.org"
  # "repo1.maven.org"
  # "jcenter.bintray.com"
  # "gradle.org"
  # "www.gradle.org"
  # "services.gradle.org"
  # "spring.io"
  # "repo.spring.io"
  # ===END_CATEGORY===

  # ===CATEGORY:package_managers_php===
  # PHP Composer packages
  # "packagist.org"
  # "www.packagist.org"
  # "repo.packagist.org"
  # ===END_CATEGORY===

  # ===CATEGORY:package_managers_dotnet===
  # .NET NuGet packages
  # "nuget.org"
  # "www.nuget.org"
  # "api.nuget.org"
  # ===END_CATEGORY===

  # ===CATEGORY:package_managers_dart===
  # Dart/Flutter packages
  # "pub.dev"
  # "api.pub.dev"
  # ===END_CATEGORY===

  # ===CATEGORY:package_managers_erlang===
  # Elixir/Erlang packages
  # "hex.pm"
  # "www.hex.pm"
  # ===END_CATEGORY===

  # ===CATEGORY:package_managers_perl===
  # Perl CPAN packages
  # "cpan.org"
  # "www.cpan.org"
  # "metacpan.org"
  # "www.metacpan.org"
  # "api.metacpan.org"
  # ===END_CATEGORY===

  # ===CATEGORY:package_managers_cocoapods===
  # iOS/macOS packages
  # "cocoapods.org"
  # "www.cocoapods.org"
  # "cdn.cocoapods.org"
  # ===END_CATEGORY===

  # ===CATEGORY:package_managers_haskell===
  # Haskell packages
  # "haskell.org"
  # "www.haskell.org"
  # "hackage.haskell.org"
  # ===END_CATEGORY===

  # ===CATEGORY:package_managers_swift===
  # Swift packages
  # "swift.org"
  # "www.swift.org"
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

  # ===CATEGORY:development_tools===
  # Development infrastructure and tools
  # "dl.k8s.io"
  # "pkgs.k8s.io"
  # "k8s.io"
  # "www.k8s.io"
  # "releases.hashicorp.com"
  # "apt.releases.hashicorp.com"
  # "rpm.releases.hashicorp.com"
  # "archive.releases.hashicorp.com"
  # "hashicorp.com"
  # "www.hashicorp.com"
  # "repo.anaconda.com"
  # "conda.anaconda.org"
  # "anaconda.org"
  # "www.anaconda.com"
  # "anaconda.com"
  # "continuum.io"
  # "apache.org"
  # "www.apache.org"
  # "archive.apache.org"
  # "downloads.apache.org"
  # "eclipse.org"
  # "www.eclipse.org"
  # "download.eclipse.org"
  # "nodejs.org"
  # "www.nodejs.org"
  # ===END_CATEGORY===

  # ===CATEGORY:vscode===
  # VS Code extensions and updates
  "marketplace.visualstudio.com"
  "vscode.blob.core.windows.net"
  "update.code.visualstudio.com"
  # ===END_CATEGORY===

  # ===CATEGORY:analytics_telemetry===
  # Analytics and telemetry services
  # "statsig.com"
  # "www.statsig.com"
  # "api.statsig.com"
  # ===END_CATEGORY===

  # ===CATEGORY:content_delivery===
  # CDNs and mirrors
  # "packagecloud.io"
  # ===END_CATEGORY===

  # ===CATEGORY:schema_configuration===
  # Schema and configuration repositories
  # "json-schema.org"
  # "www.json-schema.org"
  # "json.schemastore.org"
  # "www.schemastore.org"
  # ===END_CATEGORY===

  # ===CATEGORY:project_specific===
  # CUSTOMIZE: Add your project-specific domains here
  # Example: Your API endpoints, CDNs, third-party services
  # "api.yourproject.com"
  # "cdn.yourproject.com"
  # "example.com"
  # ===END_CATEGORY===
)

# Test domain for firewall verification (should NOT be accessible in strict mode)
TEST_BLOCKED_DOMAIN="example.com"

# Test domain for firewall verification (should be accessible in strict mode)
TEST_ALLOWED_DOMAIN="api.github.com"

# ----------------------------------------------------------------------------
# DISABLED MODE - No firewall
# ----------------------------------------------------------------------------
if [ "$FIREWALL_MODE" = "disabled" ]; then
  echo "=========================================="
  echo "FIREWALL MODE: DISABLED (YOLO)"
  echo "=========================================="
  echo "No firewall configured (relies on container isolation only)"
  echo ""
  echo "WARNING: This mode provides no network-level restrictions."
  echo "Use only in trusted development environments."
  echo ""

  # Clear any existing rules
  iptables -F 2>/dev/null || true
  iptables -X 2>/dev/null || true
  iptables -t nat -F 2>/dev/null || true
  iptables -t nat -X 2>/dev/null || true
  iptables -t mangle -F 2>/dev/null || true
  iptables -t mangle -X 2>/dev/null || true
  ipset destroy allowed-domains 2>/dev/null || true

  # Set default policies to ACCEPT
  iptables -P INPUT ACCEPT 2>/dev/null || true
  iptables -P FORWARD ACCEPT 2>/dev/null || true
  iptables -P OUTPUT ACCEPT 2>/dev/null || true

  echo "Firewall configuration complete (disabled mode)"
  exit 0
fi

# ----------------------------------------------------------------------------
# PERMISSIVE MODE - Allow all traffic
# ----------------------------------------------------------------------------
if [ "$FIREWALL_MODE" = "permissive" ]; then
  echo "=========================================="
  echo "FIREWALL MODE: PERMISSIVE (YOLO)"
  echo "=========================================="
  echo "All outbound traffic will be allowed."
  echo ""
  echo "WARNING: No network restrictions applied."
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
echo "FIREWALL MODE: STRICT (YOLO)"
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
echo "Mode: $FIREWALL_MODE (YOLO tier)"
echo "Allowed domains: ${#ALLOWED_DOMAINS[@]}"
echo "Host network: $HOST_NETWORK"
echo ""
echo "To allow additional domains:"
echo "1. Edit ALLOWED_DOMAINS array in /usr/local/bin/init-firewall.sh"
echo "2. Uncomment categories you need or add custom domains"
echo "3. Add domains in the ===CATEGORY:project_specific=== section"
echo "4. Re-run: sudo /usr/local/bin/init-firewall.sh"
echo ""
echo "To switch modes:"
echo "1. Set FIREWALL_MODE in devcontainer.json:"
echo "   - disabled: No firewall (container isolation only)"
echo "   - permissive: Allow all traffic (no restrictions)"
echo "   - strict: Whitelist-based firewall (current)"
echo "2. Rebuild container"
echo ""
echo "Available categories (uncomment to enable):"
echo "  - Cloud platforms (Google, Azure, Oracle)"
echo "  - Package managers (Ruby, Rust, Go, Maven, PHP, .NET, etc.)"
echo "  - Development tools (Kubernetes, HashiCorp, Anaconda, Apache)"
echo "  - Analytics/telemetry (Statsig)"
echo "  - Content delivery (CDNs, mirrors)"
echo "  - Schema/configuration repositories"
echo "=========================================="
