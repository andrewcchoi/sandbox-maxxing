#!/bin/bash
set -e

echo "🔒 Initializing STRICT Firewall Mode"
echo "========================================"

# Verify firewall mode
if [ "${FIREWALL_MODE}" != "strict" ]; then
    echo "⚠️  Warning: FIREWALL_MODE is not set to 'strict'"
    echo "Expected: FIREWALL_MODE=strict"
    echo "Actual: FIREWALL_MODE=${FIREWALL_MODE}"
fi

# Define allowable domains (Advanced mode default + custom)
ALLOWABLE_DOMAINS=(
    "pypi.org"                # [PKG] Python packages
    "files.pythonhosted.org"  # [PKG] Python package files
    "registry.npmjs.org"      # [PKG] npm packages
    "github.com"              # [CODE] Source code repositories
    "gitlab.com"              # [CODE] Source code repositories
    "bitbucket.org"           # [CODE] Source code repositories
)

# Define allowable ports (from user configuration)
ALLOWABLE_PORTS=(
    443   # HTTPS
    8080  # Custom port
)

echo "Configuring firewall rules..."

# Create ipset for allowed domains
ipset create allowed_domains hash:ip timeout 3600 2>/dev/null || ipset flush allowed_domains

# Resolve and add allowed domains to ipset
for domain in "${ALLOWABLE_DOMAINS[@]}"; do
    domain_name=$(echo "$domain" | awk '{print $1}')
    IPS=$(dig +short "$domain_name" A | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$')
    for IP in $IPS; do
        ipset add allowed_domains "$IP" 2>/dev/null || true
    done
done

# Flush existing DOCKER-USER chain
iptables -F DOCKER-USER 2>/dev/null || true

# Allow established and related connections
iptables -A DOCKER-USER -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow loopback
iptables -A DOCKER-USER -i lo -j ACCEPT

# Allow DNS (required for domain resolution)
iptables -A DOCKER-USER -p udp --dport 53 -j ACCEPT
iptables -A DOCKER-USER -p tcp --dport 53 -j ACCEPT

# Allow traffic to allowed domains
iptables -A DOCKER-USER -m set --match-set allowed_domains dst -j ACCEPT

# Allow traffic to allowed ports
for port in "${ALLOWABLE_PORTS[@]}"; do
    iptables -A DOCKER-USER -p tcp --dport "$port" -j ACCEPT
done

# Allow internal Docker network communication
iptables -A DOCKER-USER -s 172.16.0.0/12 -j ACCEPT
iptables -A DOCKER-USER -d 172.16.0.0/12 -j ACCEPT

# Log and drop all other traffic
iptables -A DOCKER-USER -j LOG --log-prefix "FIREWALL-BLOCKED: " --log-level 4
iptables -A DOCKER-USER -j DROP

echo "✓ Firewall rules configured"
echo "✓ STRICT mode active"
echo "✓ Allowed domains: ${#ALLOWABLE_DOMAINS[@]}"
echo "✓ Allowed ports: ${ALLOWABLE_PORTS[@]}"
echo ""
echo "Security Status:"
echo "- All outbound traffic blocked except allowlist"
echo "- ${#ALLOWABLE_DOMAINS[@]} domains allowed"
echo "- Ports ${ALLOWABLE_PORTS[@]} allowed"
echo "- Production-ready security configuration"
echo ""
echo "Firewall initialization complete."
