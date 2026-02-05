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

# Check sudo access
if ! sudo -n true 2>/dev/null; then
  echo ""
  echo "=== Sudo Access Check ==="
  echo "This installation requires sudo privileges."
  echo "You will be prompted for your password."
  sudo -v
fi

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

## Step 1: System Update

Update package lists and upgrade existing packages:

```bash
echo "=== Step 1: System Update ==="
sudo apt update && sudo apt upgrade -y
echo "✓ System updated"
```

**What this does**: Ensures you have the latest security patches and package information.

---

## Step 2: Install Core Dependencies

Install bubblewrap (sandboxing) and socat (socket communication):

```bash
echo "=== Step 2: Core Dependencies ==="

# Install bubblewrap
echo "Installing bubblewrap..."
sudo apt-get install bubblewrap -y

# Install socat
echo "Installing socat..."
sudo apt-get install socat -y

# Install curl, wget, unzip (often pre-installed)
echo "Installing network tools..."
sudo apt-get install curl wget unzip -y

echo "✓ Core dependencies installed"
```

**What this does**:
- **bubblewrap**: Provides process-level filesystem sandboxing for Claude Code
- **socat**: Enables socket communication between Claude Code and system services
- **curl/wget/unzip**: Required for downloading and installing packages

---

## Step 3: Install Development Tools

Install Git and GitHub CLI:

```bash
echo "=== Step 3: Development Tools ==="

# Install Git
echo "Installing Git..."
sudo apt-get install git -y

# Install GitHub CLI
echo "Installing GitHub CLI..."
(type -p wget >/dev/null || (sudo apt update && sudo apt install wget -y)) \
    && sudo mkdir -p -m 755 /etc/apt/keyrings \
    && out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    && cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && sudo mkdir -p -m 755 /etc/apt/sources.list.d \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && sudo apt update \
    && sudo apt install gh -y

echo "✓ Development tools installed"
```

**What this does**:
- **Git**: Version control system required for repository operations
- **GitHub CLI**: Official GitHub command-line tool for authentication and repo management

---

## Step 4: Install Claude Code CLI

Download and install Claude Code CLI:

```bash
echo "=== Step 4: Claude Code CLI ==="

# Download and run official installation script
curl -fsSL https://claude.ai/install.sh | bash

# Reload shell configuration
source ~/.bashrc

echo "✓ Claude Code CLI installed"
```

**What this does**: Installs the official Claude Code CLI tool from Anthropic.

---

## Step 5: Configure Environment

Ensure PATH is correctly configured:

```bash
echo "=== Step 5: Environment Configuration ==="

# Check if /usr/local/bin is in PATH
if ! echo "$PATH" | grep -q "/usr/local/bin"; then
  echo "Adding /usr/local/bin to PATH..."
  echo 'export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"' >> ~/.bashrc
  source ~/.bashrc
  echo "✓ PATH updated"
else
  echo "✓ PATH already configured correctly"
fi

# Optional: Git configuration
echo ""
echo "Would you like to configure Git? (recommended for first-time setup)"
echo "You can skip this if you've already configured Git."
read -p "Configure Git now? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  read -p "Enter your name: " git_name
  read -p "Enter your email: " git_email
  git config --global user.name "$git_name"
  git config --global user.email "$git_email"
  echo "✓ Git configured"
else
  echo "Skipping Git configuration (you can run 'git config --global user.name \"Your Name\"' later)"
fi
```

**What this does**: Ensures Claude Code and other tools are accessible from your PATH.

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
