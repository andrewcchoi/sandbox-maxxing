# Security Model

This document explains the security architecture of the Claude Code Docker sandbox and best practices for secure development.

## Table of Contents

- [Overview](#overview)
- [Network Security](#network-security)
- [Firewall Modes](#firewall-modes)
- [Container Isolation](#container-isolation)
- [Threat Model](#threat-model)
- [Best Practices](#best-practices)
- [Security Checklist](#security-checklist)

## Overview

The Claude Code sandbox implements multiple layers of security:

1. **Network Firewall** - Restricts outbound network access
2. **Container Isolation** - Process and filesystem isolation via Docker
3. **Non-Root User** - All processes run as unprivileged `node` user
4. **Minimal Capabilities** - Only essential Linux capabilities granted

### Security Goals

- **Prevent data exfiltration** - Limit outbound network connections
- **Restrict attack surface** - Minimize exposed services and ports
- **Isolate processes** - Separate development environment from host
- **Enable secure AI development** - Allow Claude Code while maintaining security

### Non-Goals

- **Production-grade security** - This is a development environment
- **Complete network isolation** - Some external access is required for package managers, git, etc.
- **Zero-trust architecture** - Trust is assumed within the Docker network

## Network Security

### Architecture

```
┌─────────────────────────────────────────────────┐
│ Host Machine                                    │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │ Docker Network (my-project-network)      │  │
│  │                                          │  │
│  │  ┌────────────────────────────────────┐ │  │
│  │  │ DevContainer (Claude Code)         │ │  │
│  │  │                                    │ │  │
│  │  │  ┌──────────────────────────────┐ │ │  │
│  │  │  │ iptables Firewall            │ │ │  │
│  │  │  │                              │ │ │  │
│  │  │  │ Default: DROP all            │ │ │  │
│  │  │  │ Allow: Whitelisted domains   │ │ │  │
│  │  │  └──────────────────────────────┘ │ │  │
│  │  │           │                        │ │  │
│  │  └───────────┼────────────────────────┘ │  │
│  │              │                          │  │
│  │  ┌───────────▼───────┐  ┌─────────┐   │  │
│  │  │ postgres:5432     │  │ redis   │   │  │
│  │  └───────────────────┘  └─────────┘   │  │
│  └──────────────────────────────────────────┘  │
│                     │                           │
└─────────────────────┼───────────────────────────┘
                      │
              ┌───────▼────────┐
              │ Internet       │
              │ (Filtered)     │
              └────────────────┘
```

### Firewall Implementation

The firewall is implemented using **iptables** with an **ipset** for efficient IP matching.

#### Allowed Traffic (Default)

1. **DNS** (port 53) - Required for domain resolution
2. **SSH** (port 22) - For git operations
3. **Localhost** - All loopback traffic
4. **Docker network** - Communication with services (postgres, redis, etc.)
5. **Whitelisted domains** - Only explicitly allowed external hosts

#### Blocked Traffic (Default)

Everything else is **REJECTED** with `icmp-admin-prohibited`.

## Firewall Modes

### Strict Mode (Recommended)

**Use when:** Production, CI/CD, shared environments, or handling sensitive data

**Configuration:**
```bash
# In .devcontainer/init-firewall.sh
FIREWALL_MODE="strict"
```

Or in `devcontainer.json`:
```json
"containerEnv": {
  "FIREWALL_MODE": "strict"
}
```

**Behavior:**
- Default policy: **DROP all outbound traffic**
- Only whitelisted domains are allowed
- All attempts to reach non-whitelisted domains are rejected immediately
- GitHub, npm, PyPI, and Claude API allowed by default

**Pros:**
- Maximum security
- Prevents accidental data leakage
- Prevents malicious code from "phoning home"
- Clear audit trail of allowed domains

**Cons:**
- Requires manual whitelist management
- May break tools that use unexpected domains
- Requires firewall restart to add new domains

**Adding domains:**
```bash
# Edit init-firewall.sh
ALLOWED_DOMAINS=(
  "github.com"
  "registry.npmjs.org"
  "your-domain.com"  # Add here
)

# Re-run firewall script
sudo /usr/local/bin/init-firewall.sh
```

### Permissive Mode

**Use when:** Local development, rapid prototyping, exploring new tools

**Configuration:**
```bash
FIREWALL_MODE="permissive"
```

**Behavior:**
- Default policy: **ACCEPT all traffic**
- No restrictions on outbound connections
- All iptables rules are flushed

**Pros:**
- No configuration needed
- Compatible with all tools and services
- Faster development iteration

**Cons:**
- No protection against data exfiltration
- Malicious code can freely access internet
- No visibility into network access patterns

**Recommendation:** Use permissive mode only on trusted networks (home, VPN) and switch to strict mode before committing code.

## Container Isolation

### Docker Security Features

The DevContainer leverages multiple Docker security features:

#### 1. User Namespaces

All processes run as **non-root user** (`node`, UID 1000):

```dockerfile
USER node
```

**Benefits:**
- Limits damage from container escape
- Prevents privilege escalation
- Follows principle of least privilege

**Note:** Some operations require `sudo` (firewall configuration). This is intentional and controlled via `/etc/sudoers.d/`.

#### 2. Filesystem Isolation

- Container filesystem is isolated from host
- Only `/workspace` is bind-mounted from host (read/write)
- Temporary volumes for history and config (isolated)

#### 3. Process Isolation

- Processes inside container cannot see host processes
- Resource limits can be enforced via Docker

#### 4. Linux Capabilities

The container requires two capabilities for firewall configuration:

```json
"runArgs": [
  "--cap-add=NET_ADMIN",  // For iptables/ipset
  "--cap-add=NET_RAW"     // For packet filtering
]
```

**Why needed:**
- `NET_ADMIN` - Configure network interfaces, routing, iptables
- `NET_RAW` - Use RAW and PACKET sockets (firewall)

**Risk:** These are powerful capabilities. The firewall script must be trusted.

**Mitigation:**
- Script is well-reviewed and version-controlled
- Runs with `set -euo pipefail` for safety
- Only runs on container start (not continuously)

### What's NOT Isolated

Important limitations to understand:

1. **Docker network** - Services on the same network can communicate freely
2. **Volume mounts** - `/workspace` is shared with host (by design)
3. **Environment variables** - Can be passed from host
4. **Docker socket** - If mounted, provides full Docker access (avoid unless necessary)

## Threat Model

### What We Protect Against

#### 1. Accidental Data Exfiltration

**Threat:** Developer accidentally installs package with telemetry that sends code to external server

**Protection:** Strict firewall mode blocks non-whitelisted domains

#### 2. Malicious Dependencies

**Threat:** Supply chain attack via npm/PyPI package that exfiltrates data

**Protection:** Strict firewall + manual dependency review

#### 3. Credential Theft

**Threat:** Attacker gains access to container and tries to exfiltrate credentials

**Protection:** Firewall prevents outbound connections to attacker infrastructure

#### 4. Resource Exhaustion

**Threat:** Malicious code consumes all CPU/memory

**Protection:** Docker resource limits (can be configured)

### What We DON'T Protect Against

#### 1. Trusted User Abuse

If a developer intentionally disables firewall or adds malicious domains to whitelist, there's no protection.

**Mitigation:** Code review, version control, access controls

#### 2. Docker Escape

If attacker escapes the container, they have host access.

**Mitigation:** Keep Docker updated, avoid mounting Docker socket

#### 3. Side-Channel Attacks

Timing attacks, CPU cache attacks, etc. are not addressed.

**Mitigation:** Not applicable to typical development workflow

#### 4. Compromised Base Images

If the Docker base image is compromised, the container is compromised.

**Mitigation:** Use official images, verify signatures, scan images

## Best Practices

### Development Workflow

#### 1. Use Strict Mode by Default

```json
"containerEnv": {
  "FIREWALL_MODE": "strict"
}
```

Start with maximum security and whitelist domains as needed.

#### 2. Document Allowed Domains

In your project's README or SECURITY.md:

```markdown
## Network Access

This project requires access to:
- api.anthropic.com - Claude Code AI
- api.stripe.com - Payment processing
- cdn.example.com - Asset delivery
```

#### 3. Review Firewall Logs

Check which domains are being blocked:

```bash
# Inside DevContainer
sudo iptables -L OUTPUT -v -n
```

#### 4. Minimize Whitelisted Domains

Only add domains that are absolutely necessary. Prefer:
- Specific subdomains (api.example.com) over wildcards (*.example.com)
- First-party services over third-party
- Well-known, trusted services

### Sensitive Data

#### 1. Never Commit Credentials

Use environment variables or secret management:

```json
"containerEnv": {
  "DATABASE_URL": "${localEnv:DATABASE_URL}",
  "API_KEY": "${localEnv:API_KEY}"
}
```

#### 2. Use .env Files (Not Committed)

```bash
# .env (add to .gitignore)
DATABASE_URL=postgresql://...
API_KEY=secret-key
```

#### 3. Rotate Credentials Regularly

Especially for shared development environments.

### Docker Compose

#### 1. Change Default Passwords

Never use default passwords in production:

```yaml
postgres:
  environment:
    POSTGRES_PASSWORD: devpassword  # CHANGE THIS
```

#### 2. Don't Expose Unnecessary Ports

Only map ports you need to access from host:

```yaml
# BAD: Exposes to host unnecessarily
ports:
  - "5432:5432"

# GOOD: Only accessible from Docker network
# (No ports mapping)
```

#### 3. Use Secrets for Production

For production deployments, use Docker secrets:

```yaml
secrets:
  db_password:
    external: true

postgres:
  environment:
    POSTGRES_PASSWORD_FILE: /run/secrets/db_password
  secrets:
    - db_password
```

### Claude Code Specific

#### 1. Review AI-Generated Code

Claude Code has access to your entire workspace. Review code before committing.

#### 2. Limit Context

Don't include sensitive files in the workspace if not needed.

#### 3. Use Project-Specific API Keys

Don't share Anthropic API keys across projects.

## Security Checklist

Use this checklist when setting up a new project:

### Initial Setup

- [ ] Change network name from default (`my-project-network`)
- [ ] Choose firewall mode (strict recommended)
- [ ] Review and customize whitelisted domains
- [ ] Change database passwords from defaults
- [ ] Remove unnecessary services from docker-compose.yml
- [ ] Review and minimize Linux capabilities

### Before Committing Code

- [ ] No credentials in code or config files
- [ ] .env files are in .gitignore
- [ ] Firewall configuration is appropriate for project
- [ ] Dependencies are from trusted sources
- [ ] No unnecessary network ports exposed

### Regular Maintenance

- [ ] Update base images monthly
- [ ] Review firewall logs for blocked domains
- [ ] Audit whitelisted domains quarterly
- [ ] Rotate credentials regularly
- [ ] Update Claude Code CLI to latest version

### Production Deployment

- [ ] Switch to strict firewall mode
- [ ] Change all default passwords
- [ ] Use secrets management (not env vars)
- [ ] Enable Docker security scanning
- [ ] Implement network monitoring
- [ ] Set up intrusion detection
- [ ] Regular security audits

## Reporting Security Issues

If you discover a security vulnerability in this template:

1. **Do not** open a public GitHub issue
2. Email the maintainer directly (include "SECURITY" in subject)
3. Provide detailed reproduction steps
4. Allow time for a fix before public disclosure

## Additional Resources

- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [OWASP Docker Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
- [iptables Tutorial](https://www.frozentux.net/iptables-tutorial/iptables-tutorial.html)

## Conclusion

This Claude Code sandbox template provides a good balance between security and usability for development environments. Remember:

- **Development is not production** - This setup is designed for local/team development
- **Security is a process** - Regularly review and update security configurations
- **Trust but verify** - Even with firewall, review dependencies and AI-generated code
- **Defense in depth** - Combine firewall with other security practices

Stay secure while staying productive.

---

**Last Updated:** 2025-12-16
**Version:** 3.0.0
