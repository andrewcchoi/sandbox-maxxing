---
description: Audit DevContainer configuration for security best practices
argument-hint: ""
allowed-tools: []
---

## Overview

Performs a comprehensive 12-step security audit of your DevContainer configuration, identifying security risks and providing actionable recommendations based on best practices.

## When to Use

- **Before production deployment** - Verify secure configuration
- **Working with sensitive data** - Ensure proper secrets management
- **Security compliance** - Document security measures
- **After major configuration changes** - Validate security settings
- **Regular security reviews** - Periodic audits (monthly/quarterly)

## Usage

Simply run the command and Claude will execute the full audit workflow:

```bash
/sandboxxer:audit
```

The audit automatically performs comprehensive security review of:
- Firewall configuration and allowed domains
- Default passwords in configs
- Exposed ports and services
- Container permissions and capabilities
- Secrets management
- Network isolation
- Lifecycle hooks (initializeCommand, onCreateCommand, etc.)
- Dev Container features and sources
- Dotfiles repository and installation scripts
- Environment variables and secrets handling

## Example Output

The audit generates a detailed report with:

- **🔴 Critical Issues** - Immediate action required (exposed secrets, overly permissive capabilities)
- **🟠 High Priority** - Should fix soon (insecure firewall, default passwords)
- **🟡 Medium Priority** - Recommended improvements (hardening options)
- **🟢 Best Practices** - Optional enhancements

## Common Use Cases

**Pre-deployment security check:**
```
User: "I'm deploying to Azure, can you audit my security configuration?"
→ Runs full audit, identifies firewall issues, recommends strictest settings
```

**Secrets verification:**
```
User: "Make sure I'm not accidentally exposing any credentials"
→ Scans configs, env files, Dockerfiles for plaintext secrets
```

**Compliance documentation:**
```
User: "I need to document our container security measures"
→ Generates comprehensive security audit report
```

---

## Related Commands

- **`/sandboxxer:quickstart`** - Initial setup includes security review
- **`/sandboxxer:health`** - Diagnostic checks for environment health
- **`/sandboxxer:troubleshoot`** - Troubleshoot security-related issues

## Related Documentation

- [Security Model](../docs/features/SECURITY-MODEL.md) - Detailed security architecture
- [Secrets Management](../docs/features/SECRETS.md) - Best practices for secrets
- [Firewall Configuration](../docs/features/SECURITY-MODEL.md#firewall-modes) - Network isolation options

