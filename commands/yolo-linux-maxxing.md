---
description: Setup Claude Code CLI on native Linux/WSL2 (no Docker required)
argument-hint: "[--skip-validation] [--with-tools] [--with-shell] [--project-config] [--with-vscode] [--full]"
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

### Optional Enhancements (via flags)

Add these flags to enhance your setup:

- `--with-tools` - Install Python (uv, pytest, black, ruff, mypy, ipython) and Node (typescript, eslint, prettier) development tools
- `--with-shell` - Install zsh + Powerlevel10k + fzf + git-delta for enhanced terminal experience
- `--project-config` - Create .gitignore, .editorconfig, .gitattributes in current directory
- `--with-vscode` - Output VS Code extension install command for recommended extensions
- `--full` - Enable all optional features (equivalent to all flags above)

Example:
```bash
/sandboxxer:yolo-linux-maxxing --full
/sandboxxer:yolo-linux-maxxing --with-tools --project-config
```

## What You Don't Get (vs Docker-based `/sandboxxer:yolo-docker-maxxing`)

✗ **Network isolation** - no firewall/domain allowlist
✗ **Container-level process isolation** - no container boundaries
✗ **Isolated filesystem with copy-on-write** - direct filesystem access
✗ **Resource limits** - no CPU/memory caps

**Note**: Optional features (--with-tools, --with-shell, --project-config) bring native Linux setup closer to Docker-based DevX, while maintaining faster startup and simpler architecture.

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
  # Check if running directly on Windows (Git Bash, MSYS, Cygwin)
  case "$OSTYPE" in
    msys*|cygwin*|mingw*)
      echo "✗ ERROR: Running on Windows shell (Git Bash/MSYS/Cygwin)"
      echo ""
      echo "This command requires WSL2 or native Linux."
      echo ""
      echo "Fix: Open WSL2 terminal and run this command there:"
      echo "  1. Open PowerShell or Windows Terminal"
      echo "  2. Run: wsl"
      echo "  3. Navigate to your project"
      echo "  4. Run: claude"
      echo "  5. Then: /sandboxxer:yolo-linux-maxxing"
      return 1
      ;;
  esac

  # Existing WSL2/Debian detection continues...
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

# Check sudo access - opens popup window for password if needed
check_sudo_access() {
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

  # User needs to enter password - try popup window
  echo "  Sudo requires password authentication."
  echo ""
  echo "  Opening authentication window..."
  echo ""

  if open_auth_window; then
    # Verify sudo now works
    if sudo -n true 2>/dev/null; then
      return 0
    fi
  fi

  # Popup failed or unavailable - provide manual instructions
  echo ""
  echo "  ✗ Could not open authentication window."
  echo ""
  echo "  Please run this command in your terminal first:"
  echo "    sudo -v"
  echo ""
  echo "  Then re-run: /sandboxxer:yolo-linux-maxxing"
  return 1
}

# Opens a separate terminal window for sudo authentication
# Works on: WSL2 (Windows 10/11), Native Linux with GUI
open_auth_window() {
  # Create authentication script
  cat > /tmp/sandboxxer-sudo-auth.sh << 'AUTHSCRIPT'
#!/bin/bash
clear
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║           SANDBOXXER AUTHENTICATION                       ║"
echo "╠═══════════════════════════════════════════════════════════╣"
echo "║  Enter your sudo password to continue installation        ║"
echo "║  This window will close automatically after success       ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
if sudo -v; then
  touch /tmp/.sandboxxer_authenticated
  echo ""
  echo "✓ Authentication successful!"
  echo "  Closing in 2 seconds..."
  sleep 2
else
  echo ""
  echo "✗ Authentication failed."
  echo "  Press Enter to close and try again."
  read
fi
AUTHSCRIPT
  chmod +x /tmp/sandboxxer-sudo-auth.sh

  # Try to open a terminal window based on environment
  local opened=false

  # WSL2: Try Windows Terminal first (Windows 11 default)
  if grep -qi microsoft /proc/version 2>/dev/null; then
    if command -v wt.exe &>/dev/null; then
      wt.exe -w 0 nt wsl.exe -e bash /tmp/sandboxxer-sudo-auth.sh 2>/dev/null && opened=true
    fi

    # WSL2: Fallback to cmd.exe (always available on Windows)
    if [ "$opened" = false ] && command -v cmd.exe &>/dev/null; then
      cmd.exe /c start wsl.exe -e bash /tmp/sandboxxer-sudo-auth.sh 2>/dev/null && opened=true
    fi
  else
    # Native Linux: Try common terminal emulators
    if command -v gnome-terminal &>/dev/null; then
      gnome-terminal -- bash /tmp/sandboxxer-sudo-auth.sh 2>/dev/null && opened=true
    elif command -v xterm &>/dev/null; then
      xterm -e bash /tmp/sandboxxer-sudo-auth.sh 2>/dev/null && opened=true
    elif command -v konsole &>/dev/null; then
      konsole -e bash /tmp/sandboxxer-sudo-auth.sh 2>/dev/null && opened=true
    fi
  fi

  if [ "$opened" = false ]; then
    return 1  # Could not open window
  fi

  # Wait for authentication (poll for flag file)
  echo -n "  Waiting for authentication"
  for i in {1..90}; do
    if [ -f /tmp/.sandboxxer_authenticated ]; then
      rm -f /tmp/.sandboxxer_authenticated
      echo ""
      echo "  ✓ Sudo credentials cached"
      return 0
    fi
    echo -n "."
    sleep 1
  done

  echo ""
  echo "  ✗ Authentication timed out (90 seconds)"
  return 1
}

# Parse flags BEFORE sudo check (so --skip-validation can bypass it)
SKIP_VALIDATION=false
WITH_TOOLS=false
WITH_SHELL=false
PROJECT_CONFIG=false
WITH_VSCODE=false

for arg in "$@"; do
  case "$arg" in
    --skip-validation) SKIP_VALIDATION=true ;;
    --with-tools) WITH_TOOLS=true ;;
    --with-shell) WITH_SHELL=true ;;
    --project-config) PROJECT_CONFIG=true ;;
    --with-vscode) WITH_VSCODE=true ;;
    --full) WITH_TOOLS=true; WITH_SHELL=true; PROJECT_CONFIG=true; WITH_VSCODE=true ;;
  esac
done

# Sudo access check (can be skipped with --skip-validation)
if [ "$SKIP_VALIDATION" != true ]; then
  echo ""
  echo "=== Sudo Access Check ==="
  check_sudo_access || exit 1
else
  echo ""
  echo "=== Sudo Access Check (SKIPPED) ==="
  echo "  --skip-validation provided. Sudo will be validated on first use."
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

# Show what will be installed
if [ "$WITH_TOOLS" = true ] || [ "$WITH_SHELL" = true ] || [ "$PROJECT_CONFIG" = true ] || [ "$WITH_VSCODE" = true ]; then
  echo "=== Optional Features Enabled ==="
  [ "$WITH_TOOLS" = true ] && echo "  ✓ Development tools (Python + Node)"
  [ "$WITH_SHELL" = true ] && echo "  ✓ Shell enhancements (zsh + Powerlevel10k + fzf + delta)"
  [ "$PROJECT_CONFIG" = true ] && echo "  ✓ Project configuration files"
  [ "$WITH_VSCODE" = true ] && echo "  ✓ VS Code extension recommendations"
  echo ""
fi
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

## Step 6: Development Tools (--with-tools)

Install Python and Node development tools for enhanced productivity:

```bash
if [ "$WITH_TOOLS" = true ]; then
  echo "=== Step 6: Development Tools ==="
  echo ""

  # Python tools (if pip available)
  if command -v pip3 &>/dev/null; then
    echo "Installing Python tools..."
    pip3 install --user uv pytest black ruff mypy ipython 2>/dev/null || echo "⚠️  Some Python tools failed (non-critical)"
  else
    echo "⚠️  pip3 not found - skipping Python tools"
  fi

  # Node tools (if npm available)
  if command -v npm &>/dev/null; then
    echo "Installing Node tools..."
    sudo npm install -g typescript ts-node eslint prettier 2>/dev/null || echo "⚠️  Some Node tools failed (non-critical)"
  else
    echo "⚠️  npm not found - skipping Node tools"
  fi

  # CLI tools
  echo "Installing CLI tools..."
  sudo apt-get install -y jq 2>/dev/null || echo "⚠️  jq installation failed (non-critical)"

  echo ""
  echo "✓ Development tools installed"
  echo ""
fi
```

**What this does**:
- **Python tools**: uv (fast package manager), pytest (testing), black (formatting), ruff (linting), mypy (type checking), ipython (enhanced REPL)
- **Node tools**: TypeScript compiler, ts-node (execute TypeScript), ESLint (linting), Prettier (formatting)
- **CLI tools**: jq (JSON processor)
- **Graceful degradation**: Skips unavailable tools without failing

---

## Step 7: Shell Enhancements (--with-shell)

Install zsh with Powerlevel10k theme, fzf, and git-delta for a premium terminal experience:

```bash
if [ "$WITH_SHELL" = true ]; then
  echo "=== Step 7: Shell Enhancements ==="
  echo ""

  # Install zsh
  echo "Installing zsh..."
  sudo apt-get install -y zsh 2>/dev/null || echo "⚠️  zsh installation failed"

  # Install fzf
  if [ ! -d "$HOME/.fzf" ]; then
    echo "Installing fzf (fuzzy finder)..."
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf 2>/dev/null
    ~/.fzf/install --key-bindings --completion --no-update-rc --no-bash --no-fish 2>/dev/null || echo "⚠️  fzf setup failed (non-critical)"
  else
    echo "✓ fzf already installed"
  fi

  # Install git-delta
  if ! command -v delta &>/dev/null; then
    echo "Installing git-delta (enhanced diff viewer)..."
    DELTA_VERSION="0.16.5"
    curl -sL "https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/git-delta_${DELTA_VERSION}_amd64.deb" -o /tmp/delta.deb 2>/dev/null
    sudo dpkg -i /tmp/delta.deb 2>/dev/null || sudo apt-get install -f -y 2>/dev/null
    rm -f /tmp/delta.deb

    # Configure git to use delta
    git config --global core.pager "delta"
    git config --global interactive.diffFilter "delta --color-only"
    git config --global delta.navigate true
    git config --global merge.conflictstyle diff3
    git config --global diff.colorMoved default
  else
    echo "✓ git-delta already installed"
  fi

  # Install Powerlevel10k (oh-my-zsh not required)
  if [ ! -d "$HOME/powerlevel10k" ]; then
    echo "Installing Powerlevel10k theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k 2>/dev/null
    echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >> ~/.zshrc
  else
    echo "✓ Powerlevel10k already installed"
  fi

  echo ""
  echo "✓ Shell enhancements installed"
  echo ""
  echo "  To use zsh as your default shell, run:"
  echo "    chsh -s \$(which zsh)"
  echo ""
  echo "  Restart your terminal, then run 'p10k configure' to customize your prompt"
  echo ""
fi
```

**What this does**:
- **zsh**: Modern shell with better completion and customization
- **Powerlevel10k**: Fast, beautiful, highly customizable prompt theme
- **fzf**: Fuzzy finder for command history, file search, and more (Ctrl+R for history search)
- **git-delta**: Syntax-highlighted diff viewer with side-by-side view
- **Idempotent**: Skips components already installed

---

## Step 8: Project Configuration (--project-config)

Create standard project configuration files in the current directory:

```bash
if [ "$PROJECT_CONFIG" = true ]; then
  echo "=== Step 8: Project Configuration ==="
  echo ""

  # Create .editorconfig if not exists
  if [ ! -f ".editorconfig" ]; then
    cat > .editorconfig << 'EDITORCONFIG'
root = true

[*]
indent_style = space
indent_size = 2
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true

[*.py]
indent_size = 4

[*.md]
trim_trailing_whitespace = false

[Makefile]
indent_style = tab
EDITORCONFIG
    echo "  ✓ Created .editorconfig"
  else
    echo "  ⊘ Skipped .editorconfig (already exists)"
  fi

  # Create .gitignore if not exists
  if [ ! -f ".gitignore" ]; then
    cat > .gitignore << 'GITIGNORE'
# Environment (CRITICAL - contains secrets)
.env
.env.local
.env.*.local

# Dependencies
node_modules/
.venv/
venv/
__pycache__/
*.pyc
*.pyo

# Build artifacts
dist/
build/
*.egg-info/
coverage/

# Test/lint caches
.pytest_cache/
.mypy_cache/
.ruff_cache/
.coverage
htmlcov/

# IDE/Editor
.vscode/
.idea/
*.swp
*.swo
*~

# OS files
.DS_Store
Thumbs.db

# DevContainer backups
.devcontainer.backup/

# Logs
*.log
logs/

# Database files (if local)
*.sqlite3
*.db
GITIGNORE
    echo "  ✓ Created .gitignore"
  else
    echo "  ⊘ Skipped .gitignore (already exists)"
  fi

  # Create .gitattributes if not exists
  if [ ! -f ".gitattributes" ]; then
    cat > .gitattributes << 'GITATTRIBUTES'
# Auto detect text files and perform LF normalization
* text=auto

# ============================================================================
# Shell Scripts - MUST be LF (critical for Docker)
# ============================================================================
*.sh text eol=lf
*.ps1 text eol=crlf

# ============================================================================
# Windows Batch/CMD Files - MUST be CRLF
# ============================================================================
*.bat text eol=crlf
*.cmd text eol=crlf

# ============================================================================
# Shell RC/Config Files Without Extensions - MUST be LF
# ============================================================================
.bashrc text eol=lf
.bash_profile text eol=lf
.profile text eol=lf
.zshrc text eol=lf

# ============================================================================
# Docker Files - MUST be LF
# ============================================================================
Dockerfile text eol=lf
Dockerfile.* text eol=lf
*.dockerfile text eol=lf
docker-compose*.yml text eol=lf
docker-compose*.yaml text eol=lf
.dockerignore text eol=lf
devcontainer.json text eol=lf

# ============================================================================
# Code Files - LF preferred
# ============================================================================
*.py text eol=lf
*.js text eol=lf
*.jsx text eol=lf
*.ts text eol=lf
*.tsx text eol=lf
*.json text eol=lf
*.yml text eol=lf
*.yaml text eol=lf
*.sql text eol=lf

# ============================================================================
# Web/Frontend Files - LF preferred
# ============================================================================
*.html text eol=lf
*.css text eol=lf
*.svg text eol=lf

# ============================================================================
# Config Files - LF preferred
# ============================================================================
*.env text eol=lf
*.env.* text eol=lf
.gitignore text eol=lf
.gitattributes text eol=lf
.editorconfig text eol=lf

# ============================================================================
# Python Config Files - LF preferred
# ============================================================================
*.ini text eol=lf
*.toml text eol=lf
*.txt text eol=lf

# ============================================================================
# Infrastructure/Cloud Files - LF preferred
# ============================================================================
*.bicep text eol=lf

# ============================================================================
# Diagram/Template Files - LF preferred
# ============================================================================
*.mmd text eol=lf
*.template text eol=lf
*.example text eol=lf

# ============================================================================
# Documentation - LF preferred
# ============================================================================
*.md text eol=lf

# ============================================================================
# Additional Files - LF preferred
# ============================================================================
.gitkeep text eol=lf
LICENSE text eol=lf
Makefile text eol=lf

# ============================================================================
# Binary Files - Do not modify
# ============================================================================
*.png binary
*.jpg binary
*.pdf binary
*.zip binary
GITATTRIBUTES
    echo "  ✓ Created .gitattributes"
  else
    echo "  ⊘ Skipped .gitattributes (already exists)"
  fi

  echo ""
  echo "✓ Project configuration created"
  echo ""
fi
```

**What this does**:
- **.editorconfig**: Consistent code formatting across editors (indent style, line endings, trailing whitespace)
- **.gitignore**: Prevents committing secrets (.env), dependencies (node_modules), build artifacts, and IDE files
- **.gitattributes**: Enforces correct line endings (LF for scripts/Docker, CRLF for Windows batch files)
- **Idempotent**: Skips files that already exist

---

## Step 9: VS Code Extensions (--with-vscode)

Output recommended VS Code extension install command:

```bash
if [ "$WITH_VSCODE" = true ]; then
  echo "=== Step 9: VS Code Extensions ==="
  echo ""
  echo "Run this command to install recommended extensions:"
  echo ""
  echo "code --install-extension anthropic.claude-code \\"
  echo "     --install-extension ms-python.python \\"
  echo "     --install-extension ms-python.vscode-pylance \\"
  echo "     --install-extension dbaeumer.vscode-eslint \\"
  echo "     --install-extension esbenp.prettier-vscode \\"
  echo "     --install-extension eamodio.gitlens \\"
  echo "     --install-extension redhat.vscode-yaml \\"
  echo "     --install-extension PKief.material-icon-theme"
  echo ""
fi
```

**What this does**:
- **Claude Code**: Official Claude Code extension for VS Code
- **Python**: Python language support, linting, debugging
- **Pylance**: Fast, feature-rich Python language server
- **ESLint/Prettier**: JavaScript/TypeScript linting and formatting
- **GitLens**: Enhanced Git integration with blame, history, and more
- **YAML**: YAML language support for config files
- **Material Icon Theme**: Beautiful file icons

---

## Step 10: Final Verification

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

# Check optional components if flags were used
if [ "$WITH_TOOLS" = true ] || [ "$WITH_SHELL" = true ] || [ "$PROJECT_CONFIG" = true ]; then
  echo ""
  echo "=== Optional Components ==="

  if [ "$WITH_TOOLS" = true ]; then
    echo -n "Development tools: "
    tools_ok=true
    command -v pytest &>/dev/null || tools_ok=false
    command -v black &>/dev/null || tools_ok=false
    command -v eslint &>/dev/null || tools_ok=false
    command -v jq &>/dev/null || tools_ok=false
    if [ "$tools_ok" = true ]; then
      echo "✅ installed"
    else
      echo "⚠️  partially installed (some tools missing)"
    fi
  fi

  if [ "$WITH_SHELL" = true ]; then
    echo -n "Shell enhancements: "
    shell_ok=true
    command -v zsh &>/dev/null || shell_ok=false
    [ -d "$HOME/.fzf" ] || shell_ok=false
    command -v delta &>/dev/null || shell_ok=false
    [ -d "$HOME/powerlevel10k" ] || shell_ok=false
    if [ "$shell_ok" = true ]; then
      echo "✅ installed"
    else
      echo "⚠️  partially installed (some components missing)"
    fi
  fi

  if [ "$PROJECT_CONFIG" = true ]; then
    echo -n "Project config files: "
    config_count=0
    [ -f ".editorconfig" ] && ((config_count++))
    [ -f ".gitignore" ] && ((config_count++))
    [ -f ".gitattributes" ] && ((config_count++))
    echo "✅ $config_count/3 files created"
  fi
fi

echo ""
echo "=== Summary ==="
if [ "$all_ok" = true ]; then
    echo "✅ All core components installed successfully!"
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

## Step 11: Next Steps

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
- Use the `/sandboxxer:linux-troubleshoot` command for issues
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

### Installation Variations

```bash
# Minimal setup (fastest)
/sandboxxer:yolo-linux-maxxing

# Full-featured setup (all enhancements)
/sandboxxer:yolo-linux-maxxing --full

# Custom combination
/sandboxxer:yolo-linux-maxxing --with-tools --project-config

# Individual features
/sandboxxer:yolo-linux-maxxing --with-shell
/sandboxxer:yolo-linux-maxxing --with-vscode
```

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

---

## Related Commands

- **`/sandboxxer:linux-troubleshoot`** - Fix native Linux/WSL2 issues
- **`/sandboxxer:yolo-docker-maxxing`** - Docker-based alternative with enhanced isolation
- **`/sandboxxer:health`** - Verify installation

## Related Documentation

- [Troubleshooting Guide](../docs/features/TROUBLESHOOTING.md) - Native Linux troubleshooting
- [Setup Options](../docs/features/SETUP-OPTIONS.md) - Configuration alternatives
