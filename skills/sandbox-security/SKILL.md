---
name: sandbox-security
description: Use when user wants to audit sandbox security, review firewall configuration, check for security best practices, or harden their Claude Code Docker sandbox environment
---

# Sandbox Security Auditor

## Overview

Performs comprehensive security audits of Claude Code Docker sandbox configurations and provides recommendations for hardening based on best practices.

## When to Use This Skill

Use this skill when:
- User wants security audit of existing sandbox
- User asks about security best practices
- User needs to review firewall configuration
- User preparing for production deployment
- User working with sensitive data
- User wants to verify secure configuration

Do NOT use this skill when:
- Setting up new sandbox (security review is part of `sandbox-setup`)
- Troubleshooting connectivity issues (use `sandbox-troubleshoot`)

## Security Audit Workflow

### 1. Scan Configuration Files

Check for security issues in:
- `.devcontainer/devcontainer.json`
- `.devcontainer/Dockerfile`
- `.devcontainer/init-firewall.sh`
- `docker-compose.yml`
- Environment variable files

### 2. Firewall Configuration Audit

**Check Firewall Mode**:
```bash
grep FIREWALL_MODE .devcontainer/devcontainer.json
echo $FIREWALL_MODE
```

**Verify Allowed Domains**:
- Review `ALLOWED_DOMAINS` array in `init-firewall.sh`
- Check each domain's necessity
- Look for wildcard domains (less secure)
- Verify no suspicious or unnecessary domains

**Recommendations**:
- ✅ **Use strict mode** for production, team environments, sensitive data
- ✅ **Minimize whitelisted domains** - only what's absolutely needed
- ✅ **Prefer specific subdomains** over wildcards
- ✅ **Document why each domain** is needed (add comments)

**Report Format**:
```
Firewall Audit:
- Mode: [strict/permissive]
- Whitelisted domains: [count]
- Concerns:
  ⚠ domain.com - Explain why this might be problematic
  ✓ api.anthropic.com - Necessary for Claude Code
```

### 3. Credentials and Secrets Audit

**Check for Hardcoded Credentials**:
```bash
# Search for common password patterns
grep -r "password.*=" .devcontainer/ docker-compose.yml
grep -r "API_KEY.*=" .devcontainer/
grep -r "SECRET.*=" .devcontainer/
```

**Verify Default Passwords**:
- Check `docker-compose.yml` for `devpassword`, `rootpassword`, etc.
- Ensure these aren't used in production
- Verify `.env` files are in `.gitignore`

**Recommendations**:
- ❌ **Never commit credentials** to version control
- ✅ **Use environment variables**: `${localEnv:API_KEY}`
- ✅ **Use `.env` files** (and add to `.gitignore`)
- ✅ **Rotate credentials regularly**
- ✅ **Use secrets management** for production (Docker secrets, Vault)

### 4. Port Exposure Audit

**Check Exposed Ports** in `docker-compose.yml`:
```yaml
# BAD: Unnecessary exposure
postgres:
  ports:
    - "5432:5432"  # Only needed if accessing from host

# GOOD: Internal only
postgres:
  # No ports section - only accessible from Docker network
```

**Recommendations**:
- ✅ **Don't expose ports** unless needed from host
- ✅ **Use Docker networks** for inter-container communication
- ⚠ **Document why ports are exposed**
- ❌ **Never expose in production** without firewall rules

### 5. Container Permissions Audit

**Check User Configuration** in Dockerfile:
```dockerfile
# GOOD: Non-root user
USER node

# BAD: Running as root
# USER root
```

**Check Linux Capabilities**:
```json
"runArgs": [
  "--cap-add=NET_ADMIN",  // Required for firewall
  "--cap-add=NET_RAW"     // Required for packet filtering
]
```

**Recommendations**:
- ✅ **Run as non-root user** (node, UID 1000)
- ✅ **Only add necessary capabilities**
- ⚠ **NET_ADMIN/NET_RAW needed** for firewall, but are powerful
- ✅ **Verify sudoers config** limits what node user can sudo

### 6. Volume and Mount Audit

**Check Volume Mounts**:
```json
"workspaceMount": "source=${localWorkspaceFolder},target=/workspace,type=bind"
```

**Recommendations**:
- ✅ **Only mount what's needed**
- ❌ **Never mount Docker socket** unless absolutely necessary
- ✅ **Use volumes** for database data (not bind mounts)
- ⚠ **Workspace is shared** with host (by design, but be aware)

### 7. Network Isolation Audit

**Check Network Configuration**:
```yaml
networks:
  default:
    name: my-project-network
```

**Verify**:
- Services on same network can communicate freely
- Network name is unique per project
- No unexpected services on the network

### 8. Dependency Security

**For Python projects**:
```bash
# Check for known vulnerabilities
pip install safety
safety check
```

**For Node.js projects**:
```bash
npm audit
npm audit fix
```

**Recommendations**:
- ✅ **Audit dependencies** regularly
- ✅ **Keep base images updated**
- ✅ **Use official images** only
- ✅ **Pin versions** in production

## Security Report Format

Provide comprehensive report:

```markdown
# Security Audit Report - [Project Name]

## Summary
- Overall Risk Level: [Low/Medium/High]
- Critical Issues: [count]
- Warnings: [count]
- Recommendations: [count]

## Critical Issues ❌
1. [Issue] - [Explanation] - [Fix]

## Warnings ⚠
1. [Warning] - [Explanation] - [Recommendation]

## Good Practices ✅
1. [What's done well]

## Recommendations
1. [Improvement] - [Why] - [How]

## Security Checklist
- [ ] Firewall configured and tested
- [ ] No hardcoded credentials
- [ ] Default passwords changed/not in production
- [ ] Minimal port exposure
- [ ] Non-root user configured
- [ ] Dependencies audited
- [ ] Secrets properly managed
- [ ] Network isolation verified
```

## Threat Model Reference

From `references/security.md`:

**What we protect against**:
- Accidental data exfiltration
- Malicious dependencies
- Credential theft
- Resource exhaustion

**What we DON'T protect against**:
- Trusted user abuse
- Docker escape
- Side-channel attacks
- Compromised base images

## Hardening Recommendations

### For Development
- Use strict firewall mode
- Document all allowed domains
- Use project-specific API keys
- Review AI-generated code before committing

### For Production
- **Switch to strict firewall** if not already
- **Change ALL default passwords**
- **Use secrets management** (not env vars)
- **Enable Docker security scanning**
- **Implement network monitoring**
- **Set up intrusion detection**
- **Regular security audits**
- **Resource limits** on containers
- **Log all firewall blocks**

## Key Principles

- **Defense in depth** - Multiple security layers
- **Principle of least privilege** - Minimal permissions
- **Trust but verify** - Audit even with firewall
- **Document security decisions** - Explain trade-offs
- **Regular audits** - Security is ongoing process
