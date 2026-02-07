---
description: Setup Claude Code CLI on native Linux/WSL2 (no Docker required)
argument-hint: "[--skip-validation]"
allowed-tools: [Bash]
---

# Native Linux/WSL2 Setup for Claude Code CLI

⚠️  **IMPORTANT: Native Linux Setup (No Docker Sandboxing)**

This command installs Claude Code CLI directly on your Linux system.

## What You Get

✓ **Bubblewrap** - process-level filesystem sandboxing
✓ **Seccomp filter** (optional) - syscall-level filtering for enhanced security
✓ **All Claude Code CLI features** - full functionality
✓ **Faster startup** - no container overhead

## What You Don't Get (vs Docker-based `/sandboxxer:yolo-docker-maxxing`)

✗ **Network isolation** - no firewall/domain allowlist
✗ **Container-level process isolation** - no container boundaries
✗ **Isolated filesystem with copy-on-write** - direct filesystem access
✗ **Resource limits** - no CPU/memory caps

## Recommendation

**For security-sensitive work**, use:
```
/sandboxxer:yolo-docker-maxxing
```
(requires Docker)

## Continue with Native Setup?

This is suitable for:
- Personal development machines you trust
- Quick prototyping without Docker overhead
- Environments where Docker isn't available

---

## Pre-flight Checks

Before installation, let's verify your environment:

```bash
#!/bin/bash
echo "=== Environment Detection ==="
echo ""

# Detect environment
detect_environment() {
  if grep -qi "microsoft" /proc/version 2>/dev/null; then
    echo "✓ Detected: WSL2"
    return 0
  elif [ -f /etc/debian_version ]; then
    echo "✓ Detected: Debian/Ubuntu"
    return 0
  elif [ -f /etc/redhat-release ]; then
    echo "✗ RHEL/Fedora/CentOS detected"
    echo "This command only supports Debian/Ubuntu systems"
    echo "For manual setup, see: https://claude.ai/code"
    return 1
  else
    echo "✗ Unknown Linux distribution"
    echo "This command only supports Debian/Ubuntu systems"
    echo "For manual setup, see: https://claude.ai/code"
    return 1
  fi
}

detect_environment || exit 1

# Check sudo access with timeout and clear error handling
check_sudo_access() {
  # Check if stdin is interactive
  if [ ! -t 0 ]; then
    echo "WARNING: Running in non-interactive mode."
    echo "Password prompts may not work correctly."
  fi

  # Test passwordless sudo first
  if sudo -n true 2>/dev/null; then
    echo "  ✓ Sudo access available (passwordless)"
    return 0
  fi

  # Check group membership
  if ! groups | grep -qE '\b(sudo|wheel|admin)\b'; then
    echo "  ✗ ERROR: User not in sudo/wheel group"
    echo ""
    echo "  To fix, ask an administrator to run:"
    echo "    sudo usermod -aG sudo $(whoami)"
    echo ""
    echo "  Then log out and back in, and retry."
    return 1
  fi

  echo "  Sudo access requires password authentication."
  echo "  You will be prompted for your password (30 second timeout)."
  echo ""

  # Attempt with timeout to prevent hang
  if ! timeout 30 sudo -v 2>/dev/null; then
    echo ""
    echo "  ✗ ERROR: Could not validate sudo access"
    echo ""
    echo "  Possible causes:"
    echo "    - Incorrect password"
    echo "    - Sudo timeout (30 seconds)"
    echo "    - Authentication backend issue"
    echo ""
    echo "  Fix: Run 'sudo -v' manually to verify access"
    return 1
  fi

  echo "  ✓ Sudo access verified"
  return 0
}

echo ""
echo "=== Sudo Access Check ==="
check_sudo_access || exit 1

# Check disk space (minimum 4GB)
available_space=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$available_space" -lt 4 ]; then
  echo ""
  echo "⚠️  Warning: Low disk space detected (${available_space}GB available)"
  echo "Minimum recommended: 4GB"
  echo "Installation may fail or run slowly"
fi

echo ""
echo "✓ Pre-flight checks complete"
echo ""
```

---

## Step 1: System Packages

Install all required system packages in one consolidated operation:

```bash
echo "=== Step 1: System Packages ==="
echo "Installing all required packages in one operation..."
echo "(This requires sudo - you may be prompted for your password)"
echo ""

# Single consolidated privileged block for all core packages
sudo bash << 'PKGINSTALL'
set -e
apt update && apt upgrade -y && \
apt-get install -y bubblewrap socat curl wget unzip git
PKGINSTALL

if [ $? -ne 0 ]; then
  echo ""
  echo "✗ Package installation failed"
  echo "  Fix: Check network connection and retry"
  exit 1
fi

echo ""
echo "✓ Core packages installed"
```

**What this does**:
- **System update**: Ensures latest security patches
- **bubblewrap**: Process-level filesystem sandboxing for Claude Code
- **socat**: Socket communication between Claude Code and system services
- **curl/wget/unzip**: Required for downloading and installing packages
- **git**: Version control system for repository operations

---

## Step 2: GitHub CLI

Install GitHub CLI (consolidated privileged operation):

```bash
echo "=== Step 2: GitHub CLI ==="

# Check if already installed
if command -v gh &>/dev/null; then
  echo "  ✓ GitHub CLI already installed ($(gh version 2>&1 | head -1))"
else
  echo "Installing GitHub CLI (requires sudo)..."
  echo ""

  # Single privileged block for all GitHub CLI setup
  sudo bash << 'GHINSTALL'
set -e
mkdir -p -m 755 /etc/apt/keyrings
wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
mkdir -p -m 755 /etc/apt/sources.list.d
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list
apt update && apt install -y gh
GHINSTALL

  if [ $? -ne 0 ]; then
    echo ""
    echo "✗ GitHub CLI installation failed"
    echo ""
    echo "  To clean up partial installation and retry:"
    echo "    sudo rm -f /etc/apt/keyrings/githubcli-archive-keyring.gpg"
    echo "    sudo rm -f /etc/apt/sources.list.d/github-cli.list"
    echo "    sudo apt update"
    exit 1
  fi

  echo "✓ GitHub CLI installed"
fi
```

**What this does**:
- **GitHub CLI**: Official GitHub command-line tool for authentication and repo management
- **Idempotency**: Skips installation if already present
- **Atomic operation**: All privileged steps in one block to avoid credential timeout

---

## Step 3: Install Claude Code CLI

Download and install Claude Code CLI:

```bash
echo "=== Step 3: Claude Code CLI ==="

# Download and run official installation script
curl -fsSL https://claude.ai/install.sh | bash

# Reload shell configuration
source ~/.bashrc

echo "✓ Claude Code CLI installed"
```

**What this does**: Installs the official Claude Code CLI tool from Anthropic.

---

## Step 4: Configure Environment

Ensure PATH is correctly configured:

```bash
echo "=== Step 4: Environment Configuration ==="

# Check if /usr/local/bin is in PATH
if ! echo "$PATH" | grep -q "/usr/local/bin"; then
  echo "Adding /usr/local/bin to PATH..."
  echo 'export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"' >> ~/.bashrc
  source ~/.bashrc
  echo "✓ PATH updated"
else
  echo "✓ PATH already configured correctly"
fi

# Git configuration check (auto-detect, no prompts)
echo ""
git_name=$(git config --global user.name 2>/dev/null || true)
git_email=$(git config --global user.email 2>/dev/null || true)
if [ -n "$git_name" ] && [ -n "$git_email" ]; then
  echo "✓ Git already configured: $git_name <$git_email>"
else
  echo "ℹ Git user not configured (optional)"
  echo "  To configure later: git config --global user.name \"Your Name\""
  echo "                      git config --global user.email \"you@example.com\""
fi
```

**What this does**: Ensures Claude Code and other tools are accessible from your PATH.

---

## Step 5: Seccomp Filter (Optional Enhanced Security)

The seccomp filter provides additional syscall-level sandboxing. This step is **optional** but recommended for enhanced security.

```bash
echo "=== Step 5: Seccomp Filter (Optional) ==="
echo ""

# Check if already installed
if npm list -g @anthropic-ai/sandbox-runtime &>/dev/null 2>&1; then
  echo "✓ Seccomp filter already installed"
else
  # Check if Node.js 18+ is available
  if command -v node &>/dev/null; then
    NODE_MAJOR=$(node --version | sed 's/v//' | cut -d. -f1)
    if [ "$NODE_MAJOR" -ge 18 ]; then
      echo "Node.js $NODE_MAJOR detected. Installing seccomp filter..."
      sudo npm install -g @anthropic-ai/sandbox-runtime
      if [ $? -eq 0 ]; then
        echo "✓ Seccomp filter installed"
      else
        echo "⚠️  Seccomp filter installation failed (optional - continuing)"
      fi
    else
      echo "⚠️  Node.js $NODE_MAJOR found but version 18+ required for seccomp filter"
      echo "   Skipping seccomp filter (optional)"
    fi
  else
    echo ""
    echo "ℹ Seccomp filter skipped (Node.js 18+ not installed)"
    echo "  This is optional - Claude Code works without it."
    echo ""
    echo "  To install later:"
    echo "    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -"
    echo "    sudo apt-get install -y nodejs"
    echo "    sudo npm install -g @anthropic-ai/sandbox-runtime"
  fi
fi
```

**What this does**:
- **Smart detection**: Auto-installs if Node.js 18+ exists, skips with instructions if not
- **@anthropic-ai/sandbox-runtime**: Provides seccomp syscall filtering
- **Optional**: Claude Code works without it; this is defense-in-depth
- **Non-blocking**: Failures are warnings, not errors

**To install later** (if skipped):
```bash
# Install Node.js 20 (if needed)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install seccomp filter
sudo npm install -g @anthropic-ai/sandbox-runtime
```

---

## Step 6: Final Verification

Run comprehensive verification to ensure all components are installed:

```bash
#!/bin/bash
echo ""
echo "=== Final Verification ==="
echo ""

# Function to check command
check_cmd() {
    local cmd=$1
    local display_name=${2:-$1}

    if command -v $cmd &> /dev/null; then
        case $cmd in
            bwrap)
                version=$(bwrap --version 2>&1 | head -1)
                ;;
            socat)
                version=$(socat -V 2>&1 | head -1)
                ;;
            git)
                version=$(git --version 2>&1)
                ;;
            gh)
                version=$(gh version 2>&1 | head -1)
                ;;
            claude)
                version=$(claude --version 2>&1)
                ;;
            *)
                version=$($cmd --version 2>&1 | head -1)
                ;;
        esac
        echo "✅ $display_name: $version"
        return 0
    else
        echo "❌ $display_name: NOT FOUND"
        return 1
    fi
}

# Check each tool
all_ok=true
check_cmd bwrap "bubblewrap" || all_ok=false
check_cmd socat "socat" || all_ok=false
check_cmd git "git" || all_ok=false
check_cmd gh "GitHub CLI" || all_ok=false
check_cmd claude "Claude Code CLI" || all_ok=false

# Check seccomp filter (optional)
echo -n "Checking seccomp filter... "
if npm list -g @anthropic-ai/sandbox-runtime &>/dev/null 2>&1; then
  echo "✅ seccomp filter: installed"
else
  echo "⚠️  seccomp filter: not installed (optional)"
fi

echo ""
echo "=== Summary ==="
if [ "$all_ok" = true ]; then
    echo "✅ All components installed successfully!"
    echo ""
    echo "Next step: Run 'claude auth login' to authenticate"
else
    echo "❌ Some components missing. Review installation steps above."
    echo ""
    echo "Common issues:"
    echo "- Run 'source ~/.bashrc' and retry verification"
    echo "- Check internet connection and retry failed installations"
    echo "- For detailed troubleshooting, see documentation below"
fi
```

---

## Step 7: Next Steps

### 1. Authenticate Claude Code

```bash
claude auth login
```

Follow the prompts to connect your Anthropic account.

### 2. Verify Authentication

```bash
claude auth whoami
```

### 3. Start Your First Project

```bash
# Navigate to your project directory
cd ~/your-project

# Start Claude Code
claude
```

---

## Troubleshooting

### Sudo Authentication Issues

**Symptom**: Installation hangs waiting for password, or sudo access check fails

**Common Causes**:
- User not in sudoers group (sudo/wheel/admin)
- Incorrect password entry
- Non-interactive terminal session
- Sudo authentication backend misconfigured

**Fixes**:

1. **Verify sudo access manually**:
   ```bash
   sudo -v
   ```
   If this hangs or fails, your sudo setup needs attention.

2. **Check group membership**:
   ```bash
   groups | grep -E "(sudo|wheel|admin)"
   ```
   If no match, you're not in the sudoers group.

3. **Add user to sudoers group** (requires admin/root):
   ```bash
   # Ask an administrator to run:
   sudo usermod -aG sudo $USER

   # Then log out and back in
   ```

4. **For WSL2 users** - reset sudo configuration:
   ```bash
   # From Windows PowerShell (as Administrator):
   wsl --terminate Ubuntu
   wsl
   ```

5. **Check sudo timeout settings**:
   ```bash
   sudo -l | grep timestamp_timeout
   ```
   Default is 15 minutes. If too short, credentials may expire between manual steps.

**Prevention**: This installation now consolidates all sudo operations into 2 blocks to minimize password prompts and avoid credential timeouts.

---

### Command Not Found After Installation

Reload your shell configuration:

```bash
source ~/.bashrc

# Or restart your terminal/WSL session
```

### Permission Denied Errors

Ensure you're using sudo for system installations:

```bash
sudo apt-get install <package-name>
```

### GitHub CLI Installation Failed

Remove existing repository configuration and retry:

```bash
sudo rm -f /etc/apt/sources.list.d/github-cli.list
sudo rm -f /etc/apt/keyrings/githubcli-archive-keyring.gpg
# Then retry Step 3
```

### WSL2 Not Starting (Windows Users)

From PowerShell (as Administrator):

```powershell
wsl --shutdown
wsl --update
```

### Claude Code CLI Installation Failed

Manual installation:

```bash
# Download installer
curl -fsSL https://claude.ai/install.sh -o /tmp/claude-install.sh

# Review script (optional)
less /tmp/claude-install.sh

# Run installer
bash /tmp/claude-install.sh
```

### Bubblewrap Issues

Check bubblewrap is working:

```bash
bwrap --ro-bind / / --dev /dev --proc /proc --tmpfs /tmp -- echo "Bubblewrap is working!"
```

If you see "Bubblewrap is working!", the installation is correct.

### Still Having Issues?

For detailed troubleshooting patterns and solutions, see:
- [Linux Troubleshooting](/sandboxxer:linux-troubleshoot) - Use the troubleshooting command for issues
- [Claude Code Documentation](https://claude.ai/code) - Official documentation

---

## Security Comparison

| Feature | Native Linux Setup | Docker-based Setup |
|---------|-------------------|-------------------|
| **Process Sandboxing** | ✓ Bubblewrap | ✓ Container |
| **Seccomp Filter** | ✓ Optional | ✓ Container provides |
| **Network Isolation** | ✗ No | ✓ Firewall + Allowlist |
| **Filesystem Isolation** | Partial | ✓ Full |
| **Resource Limits** | ✗ No | ✓ CPU/Memory Caps |
| **Startup Time** | Fast | Slower |
| **Complexity** | Simple | Moderate |
| **Best For** | Personal dev machines | Production-like environments |

---

## For Enhanced Security

If you need Docker-level isolation, use:

```
/sandboxxer:yolo-docker-maxxing
```

This provides:
- Container-level isolation
- Network firewall with domain allowlist
- Resource limits (CPU/memory)
- Copy-on-write filesystem
- PostgreSQL + Redis services

---

## Quick Reference

### Essential Commands

```bash
# Check Claude Code status
claude --version

# Authenticate
claude auth login

# Check authentication
claude auth whoami

# Start Claude Code
claude

# Update Claude Code
curl -fsSL https://claude.ai/install.sh | bash
```

### System Maintenance

```bash
# Update all packages
sudo apt update && sudo apt upgrade -y

# Check disk space
df -h

# Restart WSL (from Windows PowerShell)
wsl --shutdown
```

---

**Installation Complete!** 🎉

You now have Claude Code CLI running natively on Linux/WSL2. Start coding with AI assistance by running `claude` in your project directory.

For enhanced security and isolation, consider the Docker-based setup: `/sandboxxer:yolo-docker-maxxing`
