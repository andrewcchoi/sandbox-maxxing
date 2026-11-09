---
description: Diagnose and fix common VS Code DevContainer issues
argument-hint: ""
allowed-tools: []
---

## Overview

Interactive diagnostic agent that systematically identifies and resolves Docker sandbox issues. Runs automated checks, analyzes results, and provides specific fixes based on your actual system state.

## When to Use

- **Container won't start** - Build fails or container crashes on startup
- **Can't connect to services** - PostgreSQL, Redis, MongoDB connection issues
- **Network problems** - DNS failures, npm install timeouts
- **Firewall blocking** - Legitimate traffic being blocked
- **Permission errors** - Volume mount or file access issues

## Usage

Run the command and describe your problem:

```bash
/sandboxxer:troubleshoot
```

Claude will interactively diagnose and fix issues by:
- Container startup failures
- Network connectivity issues
- Service connectivity problems (database, redis, etc.)
- Firewall blocking legitimate traffic
- Permission errors
- VS Code DevContainer issues

## Example Sessions

**Container startup failure:**
```
User: "My container fails to start with 'Error: Cannot start service app'"
→ Checks Docker logs, identifies port conflict, fixes configuration
```

**Service connectivity:**
```
User: "Getting 'connection refused' when connecting to postgres:5432"
→ Verifies service is running, checks network topology, fixes connection string
```

**Firewall blocking:**
```
User: "npm install times out inside the container"
→ Identifies firewall blocking, adds npmjs.org to allowlist, verifies fix
```

**Volume permission error:**
```
User: "Permission denied when writing to /workspace"
→ Checks mount configuration, fixes user/group mappings
```

## Command vs Skill

**Use this command (`/sandboxxer:troubleshoot`)** when:
- You have an active problem that needs fixing now
- You want automated diagnostics and specific solutions

**Use the skill documentation** when:
- You want to understand troubleshooting methodology
- You're building troubleshooting documentation
- You need reference material

---

## Related Commands

- **`/sandboxxer:health`** - Run comprehensive diagnostic checks
- **`/sandboxxer:linux-troubleshoot`** - For native Linux/WSL2 issues
- **`/sandboxxer:audit`** - Security configuration review

## Related Documentation

- [Troubleshooting Guide](../docs/features/TROUBLESHOOTING.md) - Comprehensive troubleshooting reference
- [Service Connectivity](../docs/diagrams/svg/service-connectivity.svg) - Network topology diagram
- [Firewall Resolution](../docs/diagrams/svg/firewall-resolution.svg) - Firewall troubleshooting flow

