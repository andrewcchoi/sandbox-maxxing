---
description: Diagnose and fix native Linux/WSL2 Claude Code setup issues
argument-hint: ""
allowed-tools: []
---

## Overview

Specialized troubleshooting for Claude Code CLI running natively on Linux/WSL2 (without Docker containers). Diagnoses and fixes bubblewrap sandboxing, environment configuration, WSL2-specific issues, and authentication problems.

## When to Use

- **Bubblewrap errors** - Sandbox permission failures or crashes
- **CLI not found** - Installation or PATH configuration issues
- **WSL2 problems** - Networking, file permissions, distro issues
- **Authentication failures** - Git, GitHub CLI, or Claude API auth
- **Package errors** - System package installation problems
- **Sudo issues** - Permission or credential timeout problems

## Usage

Run the command and describe your Linux/WSL2 issue:

```bash
/sandboxxer:linux-troubleshoot
```

The agent systematically diagnoses and fixes native Linux issues including:
- Bubblewrap sandbox failures
- Claude CLI installation and PATH issues
- WSL2-specific problems (networking, file permissions, systemd)
- Git and GitHub CLI authentication
- Claude API authentication failures
- System package installation errors

## Example Sessions

**Bubblewrap sandbox failure:**
```
User: "Getting 'bwrap: Can't make symlink at /usr: File exists' error"
→ Diagnoses bubblewrap configuration, fixes filesystem binding issues
```

**Claude CLI not found:**
```
User: "Command 'claude' not found after installation"
→ Checks PATH configuration, updates shell profile, verifies installation
```

**WSL2 networking issue:**
```
User: "Can't resolve DNS inside WSL2, getting 'Temporary failure in name resolution'"
→ Fixes WSL2 DNS configuration, updates /etc/resolv.conf
```

**GitHub authentication:**
```
User: "gh auth login fails with 'authentication failed'"
→ Checks git config, gh CLI setup, authentication token validity
```

**Systemd issues:**
```
User: "WSL2 systemd not starting services"
→ Enables systemd in wsl.conf, restarts WSL, verifies service status
```

## Docker vs Native Linux

**Use this command (`/sandboxxer:linux-troubleshoot`)** for:
- Native Linux/WSL2 Claude Code CLI issues (no Docker)
- Bubblewrap sandboxing problems
- System-level configuration issues

**Use `/sandboxxer:troubleshoot`** for:
- Docker-based DevContainer issues
- Container startup or service connectivity
- Docker Compose problems

---

## Related Commands

- **`/sandboxxer:yolo-linux-maxxing`** - Quick native Linux/WSL2 setup
- **`/sandboxxer:troubleshoot`** - For Docker-based sandbox issues
- **`/sandboxxer:health`** - Environment health diagnostics

## Related Documentation

- [Troubleshooting Guide](../docs/features/TROUBLESHOOTING.md) - General troubleshooting reference
- [WSL2 Configuration](../docs/features/TROUBLESHOOTING.md#wsl2-issues) - WSL2-specific fixes
