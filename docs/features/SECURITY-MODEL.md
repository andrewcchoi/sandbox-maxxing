# Security Model

This document describes the security architecture of the Claude Code Sandbox Plugin, covering container isolation, network restrictions, and credential handling across different configuration options.

## Table of Contents

1. [Overview](#overview)
2. [Multi-Layer Security](#multi-layer-security)
3. [Container Isolation](#container-isolation)
4. [Network Isolation & Firewall Modes](#network-isolation--firewall-modes)
5. [Credentials and Secrets](#credentials-and-secrets)
6. [Threat Model](#threat-model)
7. [Best Practices by Mode](#best-practices-by-mode)
8. [Related Documentation](#related-documentation)

## Overview

The Claude Code Sandbox Plugin implements a defense-in-depth security model with multiple layers of protection:

- **Container Isolation**: All code runs in isolated Docker containers
- **Network Restrictions**: Configurable firewall options control outbound network access
- **Secret Management**: Multiple methods for handling sensitive credentials
- **Flexible Security**: Adaptable security profiles from minimal to maximum protection

The security model adapts to your needs through two setup commands (interactive quickstart and non-interactive YOLO vibe maxxing) with firewall options ranging from container isolation only to strict domain allowlists.

## Multi-Layer Security

### Layer 1: Container Isolation (All Configurations)

Every configuration uses Docker containers to provide fundamental isolation:

- **Process Isolation**: Separate process namespace from host
- **Filesystem Isolation**: Independent filesystem with controlled mount points
- **User Isolation**: Non-root users (typically `node` user with UID 1000)
- **Resource Limits**: Optional CPU, memory, and I/O constraints
- **Capability Dropping**: Minimal Linux capabilities (except `NET_ADMIN` for firewall)

**What this protects against:**
- Direct access to host filesystem
- Interference with host processes
- Host system privilege escalation
- Resource exhaustion of host system

**What this doesn't protect against:**
- Network-based attacks (handled by Layer 2)
- Container escape vulnerabilities (mitigated by kernel/Docker security updates)
- Malicious code contacting external services (handled by Layer 2)

### Layer 2: Network Isolation (Configurable)

Network restrictions are configurable using iptables-based firewalls:

| Configuration | Network Policy | Protection Level |
|------|---------------|-----------------|
| **Container Isolation Only** | No firewall | Container isolation only |
| **Domain Allowlist** | Strict whitelist firewall | High (30-100+ curated domains) |
| **Custom** | User-configurable | Variable depending on configuration |

See [Network Isolation & Firewall Modes](#network-isolation--firewall-modes) for details.

### Layer 3: Secret Management (All Configurations)

Proper credential handling prevents accidental exposure:

- **VS Code Input Variables**: User-prompted credentials (not in repository)
- **Docker Build Secrets**: Build-time credentials (not in image history)
- **Docker Runtime Secrets**: Production credentials (not in environment)
- **Host Mounts**: Cloud CLI credentials (read-only when possible)

See [Credentials and Secrets](#credentials-and-secrets) for details.

## Container Isolation

### How Container Isolation Works

Docker containers use Linux kernel features to provide isolation:

1. **Namespaces**: Separate views of system resources
   - PID namespace: Process isolation
   - Network namespace: Network stack isolation
   - Mount namespace: Filesystem isolation
   - UTS namespace: Hostname isolation
   - IPC namespace: Inter-process communication isolation
   - User namespace: UID/GID mapping (optional)

2. **Control Groups (cgroups)**: Resource limiting
   - CPU limits: Prevent CPU exhaustion
   - Memory limits: Prevent memory exhaustion
   - Disk I/O limits: Prevent I/O starvation
   - Network bandwidth limits: Prevent network flooding

3. **Capabilities**: Fine-grained privilege control
   - Dropped by default: CAP_SYS_ADMIN, CAP_NET_RAW, etc.
   - Added for firewall: CAP_NET_ADMIN (required for iptables)

### Security Boundaries

**Container isolation provides:**
- Protection from accidental host modification
- Multi-tenancy on development machines
- Safe execution of untrusted dependencies
- Quick recovery (destroy and recreate container)

**Container isolation does NOT provide:**
- Complete protection against determined attackers (kernel exploits exist)
- Network-level attack prevention (requires firewall)
- Protection against malicious package dependencies contacting C2 servers
- Cryptographic separation (use VMs for high-security scenarios)

### When to Trust Container Isolation Alone

**Safe scenarios (container isolation only):**
- Working with your own code
- Using well-known open-source dependencies
- Development on single-user machines
- Trusted development teams
- Short-lived experimentation

**Risky scenarios (consider domain allowlist):**
- Evaluating unknown/suspicious packages
- Running code from untrusted sources
- Multi-user development servers
- Production-like environments
- Handling sensitive data or credentials

## Network Isolation & Firewall Modes

### Firewall Options Comparison

| Option | Firewall | Default Policy | Use Case |
|------|----------|---------------|----------|
| **Container Isolation Only** | Disabled | ACCEPT all | Trusted environments, rapid development |
| **Permissive** | Cleared rules | ACCEPT all | Legacy compatibility, debugging |
| **Domain Allowlist** | Whitelist-based | DROP by default | Security-conscious development, production-like environments |

### Container Isolation Only (No Firewall)

**Available with:** Both interactive quickstart and non-interactive YOLO vibe maxxing

**Configuration:**
- No iptables rules configured
- All outbound connections allowed
- Relies solely on container isolation

**Security implications:**
- Malicious code can contact any external service
- Package dependencies can phone home to C2 servers
- No protection against data exfiltration over network
- Suitable for trusted code and dependencies only

Example: Firewall configuration
```bash
# Clear any existing rules
iptables -F
iptables -X
# Set default policies to ACCEPT
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
```

### Domain Allowlist (Whitelist-Based Firewall)

**Available with:** Interactive quickstart (optional), configurable after setup

**Configuration:**
- Default DROP policy on all chains
- Explicit ALLOW rules for essential services
- Domain-based whitelist using ipset
- DNS and localhost always allowed
- Host network always allowed (for Docker services)

**How it works:**
1. **Domain Resolution**: Allowed domains resolved to IP addresses via DNS
2. **IP Set Creation**: IPs added to `allowed-domains` ipset
3. **Firewall Rules**: iptables allows traffic to IPs in set
4. **Verification**: Tests blocked domain (example.com) and allowed domain (api.github.com)

**Security implications:**
- Strong protection against unauthorized network access
- Prevents malicious code from contacting C2 servers
- Reduces data exfiltration risk
- Requires manual domain additions for new services
- DNS resolution can change IPs (run init-firewall.sh to refresh)

**Example: Domain allowlist firewall**
```bash
# Default DROP policy
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

# Allow essential services
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT  # DNS
iptables -A OUTPUT -o lo -j ACCEPT              # localhost

# Allow specific domains via ipset
ipset create allowed-domains hash:net
# (domains resolved and added to set)
iptables -A OUTPUT -m set --match-set allowed-domains dst -j ACCEPT

# Reject everything else
iptables -A OUTPUT -j REJECT --reject-with icmp-admin-prohibited
```

### Allowed Domain Categories

**Standard Allowlist (Curated - ~30-40 domains):**
- Anthropic services (api.anthropic.com, claude.ai)
- Version control (github.com, gitlab.com, bitbucket.org)
- Container registries (docker.io, ghcr.io, mcr.microsoft.com)
- Package managers (npmjs.org, pypi.org)
- Linux repositories (ubuntu.com, security.ubuntu.com)
- VS Code (marketplace.visualstudio.com)

**Extended Allowlist (Comprehensive - 200+ domains available):**
- All standard allowlist domains
- Cloud platforms (Google Cloud, Azure, Oracle)
- Additional package managers (Ruby, Rust, Go, Maven, PHP, .NET, Dart, Perl, Haskell, Swift)
- Development tools (Kubernetes, HashiCorp, Anaconda, Apache, Eclipse)
- Analytics/telemetry (Statsig)
- CDNs and mirrors
- Schema repositories (json-schema.org, schemastore.org)
- User-defined project-specific domains

### Customizing the Firewall

**Adding Custom Domains:**
```bash
# Edit /usr/local/bin/init-firewall.sh
ALLOWED_DOMAINS=(
  # ... existing domains ...

  # ===CATEGORY:project_specific===
  "api.yourproject.com"
  "cdn.yourproject.com"
  # ===END_CATEGORY===
)

# Re-run firewall initialization
sudo /usr/local/bin/init-firewall.sh
```

**Changing Firewall Mode:**
```bash
# Set firewall mode in devcontainer.json
{
  "containerEnv": {
    "FIREWALL_MODE": "strict"  // or "disabled" or "permissive"
  }
}

# Edit /usr/local/bin/init-firewall.sh to uncomment domain categories
# Uncomment lines in ALLOWED_DOMAINS array:
# "proxy.golang.org"  # Go modules
# "cloud.google.com"  # Google Cloud

# Rebuild container
```

### Firewall Verification

All strict firewalls include automatic verification:

```bash
# Test 1: Verify blocked domain is NOT accessible
curl --connect-timeout 5 https://example.com
# Expected: Connection refused or timeout

# Test 2: Verify allowed domain IS accessible
curl --connect-timeout 5 https://api.github.com/zen
# Expected: Success with GitHub zen message
```

If verification fails, the init-firewall.sh script exits with error and container startup fails, preventing insecure configuration.

## Credentials and Secrets

### Secret Management Methods

The sandbox plugin supports multiple methods for handling sensitive credentials, each appropriate for different scenarios:

| Method | When to Use | Security Level | Mode Availability |
|--------|-------------|----------------|-------------------|
| **VS Code Input** | Development credentials, user-specific tokens | Medium | Domain Allowlist, Custom |
| **Docker Build Secret** | Private registry auth during build | High | Domain Allowlist, Custom |
| **Docker Runtime Secret** | Production deployments | High | Domain Allowlist, Custom |
| **Host Mount** | Cloud CLI credentials (~/.aws, ~/.gcloud) | Medium-High | Domain Allowlist, Custom |
| **Environment Variables** | Non-sensitive configuration only | Low | All modes |

### Critical Security Rules

**NEVER do this:**
```dockerfile
# ❌ WRONG: Secrets in Dockerfile
ARG GITHUB_TOKEN=ghp_xxxxxxxxxxxx
ENV API_KEY=sk-xxxxxxxxxxxx
RUN git clone https://${GITHUB_TOKEN}@github.com/private/repo.git
```

**Why this is dangerous:**
- ARG values persist in image history (`docker history`)
- ENV values visible in `docker inspect`
- Anyone with image access can extract secrets
- Secrets remain even if removed in later layers
- Committed to version control if Dockerfile is tracked

### Recommended Approach by Secret Type

**1. API Keys (Development)**
```json
// devcontainer.json
{
  "containerEnv": {
    "GITHUB_TOKEN": "${localEnv:GITHUB_TOKEN}",
    "OPENAI_API_KEY": "${localEnv:OPENAI_API_KEY}"
  }
}
```
- Values from host environment or VS Code settings
- Not stored in repository
- User-specific per developer

**2. Database Passwords (Development)**
```json
// devcontainer.json
{
  "containerEnv": {
    "POSTGRES_PASSWORD": "devpassword"  // OK for local dev
  }
}
```
- Hardcoded development defaults are acceptable
- Production uses Docker secrets (see below)

**3. Private Registry Auth (Build-Time)**
```dockerfile
# Dockerfile
RUN --mount=type=secret,id=npmrc,target=/root/.npmrc \
    npm install
```
```bash
# Build command
docker build --secret id=npmrc,src=$HOME/.npmrc .
```
- Secrets never stored in image layers
- Not visible in image history

**4. Production Credentials (Runtime)**
```yaml
# docker-compose.yml
services:
  app:
    secrets:
      - api_key
      - db_password

secrets:
  api_key:
    file: ./secrets/api_key.txt
  db_password:
    file: ./secrets/db_password.txt
```
- Secrets mounted at `/run/secrets/`
- Not in environment variables
- Not in image layers

**5. Cloud CLI Credentials (Host Mount)**
```json
// devcontainer.json
{
  "mounts": [
    "source=${localEnv:HOME}/.aws,target=/home/node/.aws,type=bind,readonly"
  ]
}
```
- Read-only mount when possible
- Preserves host credentials
- No duplication or exposure

### Secret Handling by Configuration

**Minimal Configuration:**
- Hardcoded development defaults (POSTGRES_PASSWORD=devpassword)
- No user-prompted secrets
- Acceptable for local development only

**Production-Ready Configuration:**
- Required VS Code inputs for all service credentials
- Docker secrets for production deployment
- Build secrets for private registries
- Host mounts for cloud CLI tools
- Comprehensive secret management

**Custom Configuration:**
- User-controlled secret management
- All methods available
- Responsibility on user to configure properly

See [Secrets Management Guide](SECRETS.md) for detailed examples and best practices.

## Threat Model

### What This Security Model Protects Against

**Tier 1: Accidental Damage (All Modes)**
- Accidentally deleting host files
- Corrupting host system configuration
- Installing conflicting software on host
- Polluting host with development dependencies

**Tier 2: Malicious Dependencies (Domain Allowlist/Custom (Strict))**
- Package dependencies contacting C2 servers
- Cryptocurrency miners using network resources
- Data exfiltration to attacker-controlled domains
- Unexpected network reconnaissance

**Tier 3: Supply Chain Attacks (Domain Allowlist/Custom (Strict) + Secrets)**
- Compromised packages attempting to steal credentials
- Typosquatting packages reaching out to malicious domains
- Backdoored dependencies attempting data exfiltration

### What This Security Model Does NOT Protect Against

**Kernel-Level Exploits:**
- Container escape vulnerabilities (rare but possible)
- Kernel privilege escalation bugs
- Docker daemon vulnerabilities
→ **Mitigation**: Keep host kernel and Docker updated

**Determined Attackers with Code Execution:**
- Sophisticated container escape attempts
- Zero-day exploits in container runtime
→ **Mitigation**: Use VMs instead of containers for high-security scenarios

**Permitted Network Activity:**
- Malicious behavior within allowed domains
- Abuse of GitHub/PyPI/npm for C2 communication
→ **Mitigation**: Audit dependencies, use minimal domain lists, monitor network traffic

**Social Engineering:**
- User manually adding malicious domains to allowlist
- User disabling firewall for convenience
→ **Mitigation**: Security awareness training, policy enforcement

**Insider Threats:**
- Authorized developers with malicious intent
- Credential theft from authorized users
→ **Mitigation**: Access controls, audit logging, least privilege

### Security Posture by Mode

| Threat | Minimal | Domain Allowlist | Custom (Strict) |
|--------|-------|--------------|----------|---------------|
| Accidental host damage | ✓ Protected | ✓ Protected | ✓ Protected | ✓ Protected |
| Dependency phone-home | ✗ Vulnerable | ✗ Vulnerable | ✓ Protected | ✓ Protected |
| Data exfiltration | ✗ Vulnerable | ✗ Vulnerable | ✓ Mitigated | ✓ Mitigated |
| Credential theft | ✗ Vulnerable | ~ Partial | ✓ Protected | ~ User-dependent |
| Container escape | ~ Mitigated | ~ Mitigated | ~ Mitigated | ~ Mitigated |

Legend: ✓ Protected, ~ Mitigated, ✗ Vulnerable

## Best Practices by Configuration

### Container Isolation Only

**Security Philosophy:** Trust + Convenience

**Appropriate for:**
- Personal development machines
- Trusted code and well-known dependencies
- Short-lived experimentation
- Learning and tutorials

**Security practices:**
- Accept that network is unrestricted
- Don't use with untrusted code or unknown packages
- Keep container updated regularly
- Review container contents if sharing images

**When to add domain allowlist:**
- Working in team environments
- Evaluating unknown packages
- Handling sensitive data or credentials
- Need compliance with security policies

### Domain Allowlist

**Security Philosophy:** Security + Control

**Appropriate for:**
- Security-conscious development
- Production-like environments
- Evaluating untrusted packages
- Compliance requirements
- Sensitive data handling

**Security practices:**
- Review and customize allowed domains list
- Use Docker secrets for all sensitive credentials
- Enable read-only mounts where possible
- Audit container configuration before deployment
- Regular firewall updates (`sudo /usr/local/bin/init-firewall.sh`)
- Monitor container logs for blocked connection attempts
- Document all custom domains with justifications

**When to extend allowlist:**
- Need additional domain categories
- Require custom firewall configuration
- Building specialized development environments
- Project-specific external services

### Custom Configuration

**Security Philosophy:** Complete Control + Responsibility

**Appropriate for:**
- Expert users with security knowledge
- Highly specialized requirements
- Custom security policies
- Experimental configurations

**Security practices:**
- Carefully review all domain categories before enabling
- Start with domain allowlist, customize as needed
- Document all security decisions
- Regular security audits of configuration
- Implement additional monitoring if needed
- Consider external security tools (network monitoring, IDS)
- Test firewall thoroughly before deploying

**Security anti-patterns to avoid:**
- Disabling firewall "just to get it working"
- Adding all domain categories indiscriminately
- Skipping firewall verification
- Assuming container isolation is sufficient

## Related Documentation

- [Secrets Management Guide](SECRETS.md) - Detailed secret handling methods and examples
- [Variables Guide](VARIABLES.md) - Environment variables and build arguments
- [Mode Comparison Guide](SETUP-OPTIONS.md) - Choosing the right sandbox mode
- [Docker Security Best Practices](https://docs.docker.com/engine/security/) - Official Docker security documentation
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker) - Security hardening guidelines

## Questions or Concerns?

If you have security questions or discover vulnerabilities:

1. **General questions**: Open a discussion on GitHub
2. **Security vulnerabilities**: Follow responsible disclosure (see SECURITY.md in repository root, if available)
3. **Configuration help**: See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) or `/sandboxxer:troubleshoot` command

---

**Last Updated:** 2025-12-25
**Version:** 4.6.0
