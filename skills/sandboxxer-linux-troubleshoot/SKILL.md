---
name: sandboxxer-linux-troubleshoot
description: Use when user encounters problems with native Linux/WSL2 Claude Code setup - diagnose and fix bubblewrap, PATH, authentication, or WSL2-specific issues
---

# Native Linux/WSL2 Troubleshooting Assistant

## Overview

Diagnoses and resolves common issues with Claude Code CLI running natively on Linux/WSL2 (without Docker containers). This skill focuses on bubblewrap sandboxing, environment configuration, WSL2-specific issues, and authentication problems.

## When to Use This Skill

Use this skill when:
- Bubblewrap sandbox failures or permission errors
- Claude Code CLI not found or installation failures
- PATH environment issues
- WSL2-specific problems (networking, file permissions, distro issues)
- Git or GitHub CLI authentication problems
- Claude API authentication failures
- System package installation errors

Do NOT use this skill when:
- Setting up a new native Linux installation (use `/sandboxxer:yolo-linux-maxxing` instead)
- Working with Docker-based sandboxes (use `/sandboxxer:troubleshoot` instead)
- Auditing security (use `/sandboxxer:audit` instead)

## Usage

**Via slash command:**
```
/sandboxxer:linux-troubleshoot
```

**Via natural language:**
- "Claude Code not found after installation"
- "Bubblewrap permission denied"
- "WSL2 networking issues"
- "Can't authenticate Claude"
- "PATH not working on Linux"

## Examples

### Example: Claude Code Not Found

**User:** "I installed Claude Code but the command isn't found"

**Assistant:** "I'll help troubleshoot the PATH configuration issue."

The skill will:
1. Check if Claude Code binary exists
2. Verify PATH configuration in ~/.bashrc
3. Test shell environment loading
4. Provide commands to fix PATH
5. Verify the fix works

### Example: Bubblewrap Permission Error

**User:** "Getting permission denied when running bubblewrap"

**Assistant:** "Let's diagnose the bubblewrap sandbox issue."

The skill will:
1. Verify bubblewrap installation
2. Test basic bubblewrap functionality
3. Check kernel user namespace support
4. Identify permission issues
5. Provide specific fix based on error

## Troubleshooting Workflow

### 1. Identify the Problem Category

Ask user to describe the issue, then categorize:
- **Bubblewrap Issues**: Sandbox failures, permission errors, kernel limitations
- **Claude CLI Issues**: Installation failures, command not found, API errors
- **WSL2-Specific Issues**: Networking, file permissions, systemd problems
- **PATH/Environment Issues**: Tools not found after installation
- **Git/GitHub CLI Issues**: Authentication, configuration problems
- **Authentication Issues**: Claude auth login failures, API key problems

### 2. Gather Diagnostic Information

Run appropriate diagnostic commands:

**Bubblewrap Issues**:
```bash
# Check bubblewrap installation
bwrap --version

# Test basic functionality
bwrap --ro-bind / / --dev /dev --proc /proc --tmpfs /tmp -- echo "test"

# Check user namespace support
cat /proc/sys/kernel/unprivileged_userns_clone

# Check setuid bit (some distros)
ls -la $(which bwrap)
```

**Claude CLI Issues**:
```bash
# Check if claude is installed
which claude

# Check version
claude --version

# Check PATH
echo $PATH | tr ':' '\n' | grep -i claude

# Check binary location
ls -la ~/.local/bin/claude /usr/local/bin/claude 2>/dev/null

# Check shell configuration
cat ~/.bashrc | grep -E "(PATH|claude)"
```

**WSL2-Specific Issues**:
```bash
# Verify WSL2 environment
cat /proc/version | grep -i microsoft

# Check WSL version (from Windows)
wsl.exe --status 2>/dev/null

# Check networking
ping -c 1 google.com

# Check DNS resolution
nslookup google.com

# Check file permissions
ls -la /etc/resolv.conf
```

**PATH/Environment Issues**:
```bash
# Check current PATH
echo $PATH

# Check shell configuration files
cat ~/.bashrc
cat ~/.bash_profile 2>/dev/null
cat ~/.profile 2>/dev/null

# Test shell reload
source ~/.bashrc && echo "Reload successful"

# Check which shell
echo $SHELL
```

**Git/GitHub CLI Issues**:
```bash
# Check installations
git --version
gh --version

# Check Git config
git config --global --list

# Check GitHub authentication
gh auth status

# Check Git credentials
git config --global credential.helper
```

**Authentication Issues**:
```bash
# Check Claude authentication status
claude auth whoami

# Check API key location
ls -la ~/.claude/

# Test API connectivity
curl -I https://api.anthropic.com/
```

### 3. Apply Systematic Fixes

Based on the diagnostic results, apply fixes:

#### Bubblewrap Permission Denied

**Issue**: `bwrap: setting up uid map: Permission denied`

**Fix 1 - Enable user namespaces (Debian/Ubuntu)**:
```bash
# Check current setting
cat /proc/sys/kernel/unprivileged_userns_clone

# Enable user namespaces (requires sudo)
sudo sysctl -w kernel.unprivileged_userns_clone=1

# Make persistent across reboots
echo "kernel.unprivileged_userns_clone=1" | sudo tee -a /etc/sysctl.conf

# Verify
bwrap --ro-bind / / --dev /dev --proc /proc --tmpfs /tmp -- echo "Success!"
```

**Fix 2 - WSL2-specific (if Fix 1 doesn't work)**:
```bash
# Add to /etc/wsl.conf
sudo tee /etc/wsl.conf > /dev/null <<EOF
[boot]
systemd=true

[user]
default=$(whoami)
EOF

# Restart WSL from Windows PowerShell
wsl.exe --shutdown
```

**Fix 3 - Reinstall bubblewrap with proper permissions**:
```bash
sudo apt-get remove bubblewrap -y
sudo apt-get update
sudo apt-get install bubblewrap -y
```

#### Claude Code Not Found

**Issue**: `bash: claude: command not found`

**Fix 1 - Reload shell configuration**:
```bash
# Reload ~/.bashrc
source ~/.bashrc

# Verify
which claude
claude --version
```

**Fix 2 - Fix PATH in ~/.bashrc**:
```bash
# Check if Claude install location is in PATH
echo $PATH | grep -E "(\.local/bin|usr/local/bin)"

# Add to PATH if missing
echo 'export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Verify
which claude
```

**Fix 3 - Reinstall Claude Code CLI**:
```bash
# Download and run installer
curl -fsSL https://claude.ai/install.sh | bash

# Reload shell
source ~/.bashrc

# Verify
claude --version
```

**Fix 4 - Check binary exists**:
```bash
# Find Claude binary
find ~ -name "claude" -type f 2>/dev/null

# If found in ~/.local/bin but not working
chmod +x ~/.local/bin/claude
export PATH="$HOME/.local/bin:$PATH"
```

#### WSL2 Networking Issues

**Issue**: Can't reach external sites or DNS resolution fails

**Fix 1 - Reset DNS configuration**:
```bash
# Remove existing resolv.conf
sudo rm /etc/resolv.conf

# Create new one with Google DNS
sudo tee /etc/resolv.conf > /dev/null <<EOF
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF

# Prevent WSL from overwriting
sudo chattr +i /etc/resolv.conf

# Test
ping -c 1 google.com
```

**Fix 2 - Restart WSL networking (from Windows PowerShell)**:
```powershell
wsl --shutdown
# Wait 10 seconds, then restart WSL
wsl
```

**Fix 3 - Disable WSL DNS generation**:
```bash
# Edit /etc/wsl.conf
sudo tee /etc/wsl.conf > /dev/null <<EOF
[network]
generateResolvConf = false
EOF

# Then apply Fix 1 (DNS reset) and restart WSL
```

#### Git/GitHub CLI Authentication

**Issue**: Git push fails or GitHub CLI not authenticated

**Fix 1 - Configure Git**:
```bash
# Set Git credentials
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Set credential helper
git config --global credential.helper store

# Verify
git config --global --list
```

**Fix 2 - Authenticate GitHub CLI**:
```bash
# Login to GitHub
gh auth login

# Follow prompts:
# - Choose "GitHub.com"
# - Choose "HTTPS"
# - Authenticate with browser

# Verify
gh auth status
```

**Fix 3 - Generate SSH key for Git**:
```bash
# Generate new SSH key
ssh-keygen -t ed25519 -C "your.email@example.com"

# Start ssh-agent
eval "$(ssh-agent -s)"

# Add key
ssh-add ~/.ssh/id_ed25519

# Display public key (add to GitHub)
cat ~/.ssh/id_ed25519.pub
```

#### Claude Authentication Failures

**Issue**: `claude auth login` fails or API errors

**Fix 1 - Re-authenticate**:
```bash
# Logout first
claude auth logout

# Login again
claude auth login

# Follow browser prompts

# Verify
claude auth whoami
```

**Fix 2 - Clear authentication cache**:
```bash
# Remove existing credentials
rm -rf ~/.claude/

# Re-authenticate
claude auth login

# Verify
claude auth whoami
```

**Fix 3 - Check network connectivity to Anthropic API**:
```bash
# Test API endpoint
curl -I https://api.anthropic.com/

# Should return HTTP 200 or similar

# If fails, check firewall/proxy settings
```

#### System Package Installation Failures

**Issue**: `apt-get install` fails or packages not found

**Fix 1 - Update package lists**:
```bash
# Update apt cache
sudo apt-get update

# Upgrade existing packages
sudo apt-get upgrade -y

# Retry installation
sudo apt-get install <package-name> -y
```

**Fix 2 - Fix broken packages**:
```bash
# Fix broken dependencies
sudo apt-get install -f

# Reconfigure packages
sudo dpkg --configure -a

# Clean apt cache
sudo apt-get clean
sudo apt-get autoclean

# Update again
sudo apt-get update
```

**Fix 3 - Check disk space**:
```bash
# Check available space
df -h

# If low, clean up
sudo apt-get autoremove -y
sudo apt-get clean

# Check again
df -h
```

### 4. Verify the Fix

After applying fixes, verify:
- Tools are accessible via command line
- Authentication works
- Bubblewrap can run sandboxed commands
- Networking is functional
- Original error is resolved

Provide verification commands:
```bash
# Verify Claude Code
claude --version
claude auth whoami

# Verify bubblewrap
bwrap --version
bwrap --ro-bind / / --dev /dev --proc /proc --tmpfs /tmp -- echo "Sandbox working!"

# Verify Git/GitHub
git --version
gh auth status

# Verify networking (WSL2)
ping -c 1 google.com
curl -I https://api.anthropic.com/

# Verify PATH
echo $PATH
which claude
which git
which gh
```

## Common Issues Quick Reference

### "claude: command not found"
**Cause**: PATH not configured or shell not reloaded
**Fix**: Run `source ~/.bashrc` and verify PATH includes Claude install location

### "bwrap: Permission denied"
**Cause**: User namespaces disabled in kernel
**Fix**: Enable with `sudo sysctl -w kernel.unprivileged_userns_clone=1`

### "Network unreachable" in WSL2
**Cause**: WSL DNS configuration issues
**Fix**: Reset /etc/resolv.conf with Google DNS (8.8.8.8)

### "gh auth status" shows not authenticated
**Cause**: GitHub CLI not logged in
**Fix**: Run `gh auth login` and authenticate via browser

### "claude auth login" fails
**Cause**: Network issues or expired credentials
**Fix**: Check network connectivity, clear ~/.claude/ and re-authenticate

### Package installation hangs
**Cause**: Stale apt cache or network issues
**Fix**: Run `sudo apt-get update` and retry

### Bubblewrap works but Claude doesn't
**Cause**: Claude CLI installation incomplete
**Fix**: Reinstall with `curl -fsSL https://claude.ai/install.sh | bash`

### Changes to ~/.bashrc not taking effect
**Cause**: Shell not reloaded or wrong shell configuration file
**Fix**: Run `source ~/.bashrc` or restart terminal

## Reset Everything (Last Resort)

If nothing works, provide nuclear option:

```bash
# === COMPLETE REINSTALL ===

# 1. Remove all components
sudo apt-get remove bubblewrap socat git gh -y
rm -rf ~/.claude/
rm -rf ~/.local/bin/claude

# 2. Clean apt cache
sudo apt-get autoremove -y
sudo apt-get clean

# 3. Update system
sudo apt-get update && sudo apt-get upgrade -y

# 4. Reinstall everything (run /sandboxxer:yolo-linux-maxxing)
# Or manually:
sudo apt-get install bubblewrap socat git curl wget unzip -y

# Install GitHub CLI
(type -p wget >/dev/null || (sudo apt update && sudo apt install wget -y)) \
    && sudo mkdir -p -m 755 /etc/apt/keyrings \
    && out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    && cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && sudo apt update \
    && sudo apt install gh -y

# Install Claude Code CLI
curl -fsSL https://claude.ai/install.sh | bash

# 5. Configure environment
echo 'export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# 6. Verify everything
bwrap --version
socat -V
git --version
gh version
claude --version

# 7. Authenticate
claude auth login
gh auth login
```

**Warning**: This removes all configurations. Back up important data first.

## WSL2-Specific Troubleshooting

### Identifying WSL2 Environment

```bash
# Check if running in WSL2
cat /proc/version | grep -i microsoft

# Check WSL version (from Windows PowerShell)
wsl.exe --status

# Check WSL distro name
cat /etc/os-release | grep PRETTY_NAME
```

### Common WSL2 Issues

**Issue 1: Systemd not available**
```bash
# Enable systemd in /etc/wsl.conf
sudo tee /etc/wsl.conf > /dev/null <<EOF
[boot]
systemd=true
EOF

# Restart WSL (from Windows PowerShell)
wsl.exe --shutdown
```

**Issue 2: File permissions incorrect**
```bash
# Fix file permissions for project
chmod -R u+rwX,go+rX-w .

# Fix WSL2 metadata (if using NTFS)
# Add to /etc/wsl.conf
sudo tee -a /etc/wsl.conf > /dev/null <<EOF
[automount]
options = "metadata"
EOF
```

**Issue 3: Slow file access**
```bash
# Move project from /mnt/c to ~ for better performance
cp -r /mnt/c/Users/YourName/project ~/project
cd ~/project
```

## Key Principles

- **Systematic approach** - Run diagnostic commands before guessing
- **One fix at a time** - Test after each change
- **Verify assumptions** - Check actual state, not expected state
- **Document what worked** - Help user understand the fix
- **Explain root cause** - Teach, don't just fix
- **Environment-specific** - Recognize WSL2 vs native Linux differences

## Reference Documentation

For detailed setup instructions, see:
- `/sandboxxer:yolo-linux-maxxing` - Complete installation guide
- [Claude Code Documentation](https://claude.ai/code) - Official documentation
- WSL2 documentation: https://docs.microsoft.com/en-us/windows/wsl/

## Footer

---
