# Linux/WSL2 Troubleshooting

Native Linux and WSL2 setup issues (non-Docker).

**See also:** [Main Troubleshooting Guide](../TROUBLESHOOTING.md)

---

## Overview

For native Linux/WSL2 setups (not Docker-based), use:
```
/sandboxxer:linux-troubleshoot
```

## Common Native Linux Issues

| Problem | Quick Fix |
|---------|-----------|
| Claude CLI not found | `source ~/.bashrc` |
| Bubblewrap permission denied | Enable user namespaces |
| WSL2 networking issues | Reset `/etc/resolv.conf` |
| Installation hangs waiting for sudo password | See sudo hang issue below |

For Docker-based issues, use `/sandboxxer:troubleshoot` instead.

---

## Issue #247: Sudo Hang During yolo-linux-maxxing Installation

**Symptoms:**
- Installation hangs indefinitely waiting for sudo password
- No timeout on password prompt
- Installation fails if user not in sudoers group
- Multiple password prompts during installation (7+ times)
- Credentials expire between manual steps (~15 minute timeout)

**Cause:**
The original `yolo-linux-maxxing` command scattered 7+ separate `sudo` commands across 6 manual steps. This caused:
1. **Indefinite hangs** when `sudo -v` blocked without timeout
2. **Credential timeouts** when users took >15 minutes between steps
3. **No detection** for users lacking sudo access before starting
4. **Poor UX** with repeated password prompts

**Root Cause:**
Architectural flaw - linear sequence of privileged operations without consolidation or timeout protection.

**Resolution (Fixed in v4.12.0):**
The command now uses a consolidated approach:

1. **Pre-flight sudo validation** with 30-second timeout:
   ```bash
   # Detects non-interactive terminals
   # Checks group membership (sudo/wheel/admin)
   # Uses timeout to prevent hangs
   timeout 30 sudo -v
   ```

2. **Consolidated privileged operations** (7+ prompts → 2 max):
   - **Block 1**: All apt packages in single heredoc
   - **Block 2**: GitHub CLI setup in single heredoc
   - Prevents credential timeout between operations

3. **Idempotency checks**:
   - Skips GitHub CLI if already installed
   - Safe to re-run after failures

4. **Clear error messages**:
   - Actionable fixes for missing sudo access
   - Cleanup instructions for partial installs

**Solutions:**

**If installation hangs:**
1. Press Ctrl+C to cancel
2. Verify sudo access: `sudo -v`
3. Check group membership: `groups | grep -E "(sudo|wheel)"`
4. Retry installation (now has timeout protection)

**If not in sudoers group:**
```bash
# Ask administrator to run:
sudo usermod -aG sudo $USER

# Then log out and back in
```

**For WSL2 users:**
```powershell
# From Windows PowerShell (as Administrator):
wsl --terminate Ubuntu
wsl
```

**If GitHub CLI installation fails mid-way:**
```bash
# Clean up partial installation
sudo rm -f /etc/apt/keyrings/githubcli-archive-keyring.gpg
sudo rm -f /etc/apt/sources.list.d/github-cli.list
sudo apt update

# Retry installation
/sandboxxer:yolo-linux-maxxing
```

**Impact of Fix:**
- Maximum 2 password prompts (down from 7+)
- 30-second timeout prevents indefinite hangs
- Upfront detection of sudo access issues
- Atomic privileged operations with cleanup guidance

For detailed diagnostics and additional native Linux issues, use:
```
/sandboxxer:linux-troubleshoot
```

---

**Back to Main:** [Main Troubleshooting Guide](../TROUBLESHOOTING.md)
