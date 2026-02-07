---
description: Comprehensive health check for sandbox-maxxing environment
argument-hint: "[--verbose]"
allowed-tools: [Bash]
---

# Sandbox-Maxxing Health Check

Performs comprehensive diagnostics of your sandbox-maxxing environment, checking:
- ✅ Docker daemon and version
- ✅ Docker Compose v2 availability
- ✅ Required tools (jq, git, gh)
- ✅ VS Code DevContainers extension
- ✅ Disk space availability
- ✅ Port availability for standard services
- ✅ Running container status
- ✅ Configuration file validation
- ✅ Service health (PostgreSQL, Redis if running)

## Execute These Bash Commands

```bash
#!/bin/bash
# ============================================================================
# Sandbox-Maxxing Health Check
# Comprehensive environment diagnostics
# ============================================================================

set -uo pipefail

# Source common utility functions
source "${CLAUDE_PLUGIN_ROOT}/scripts/common.sh"

# Colors for output (if terminal supports it)
if [ -t 1 ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  NC='\033[0m' # No Color
else
  RED=''
  GREEN=''
  YELLOW=''
  BLUE=''
  NC=''
fi

# Check verbose flag
VERBOSE=0
for arg in "$@"; do
  if [ "$arg" = "--verbose" ] || [ "$arg" = "-v" ]; then
    VERBOSE=1
    break
  fi
done

# Counters
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0

# Helper functions
print_pass() {
  echo -e "${GREEN}✓${NC} $1"
  CHECKS_PASSED=$((CHECKS_PASSED + 1))
}

print_fail() {
  echo -e "${RED}✗${NC} $1"
  CHECKS_FAILED=$((CHECKS_FAILED + 1))
}

print_warn() {
  echo -e "${YELLOW}⚠${NC} $1"
  CHECKS_WARNING=$((CHECKS_WARNING + 1))
}

print_info() {
  echo -e "${BLUE}ℹ${NC} $1"
}

print_section() {
  echo ""
  echo -e "${BLUE}━━━ $1 ━━━${NC}"
}

# ============================================================================
# Check 1: Docker Daemon
# ============================================================================
print_section "Docker Daemon"

if command -v docker >/dev/null 2>&1; then
  if docker info >/dev/null 2>&1; then
    DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed 's/,//')
    print_pass "Docker daemon running (v${DOCKER_VERSION})"

    # Check Docker version (minimum 20.10)
    DOCKER_MAJOR=$(echo "$DOCKER_VERSION" | cut -d. -f1)
    DOCKER_MINOR=$(echo "$DOCKER_VERSION" | cut -d. -f2)
    if [ "$DOCKER_MAJOR" -lt 20 ] || ([ "$DOCKER_MAJOR" -eq 20 ] && [ "$DOCKER_MINOR" -lt 10 ]); then
      print_warn "Docker version $DOCKER_VERSION is old (recommended: 20.10+)"
    fi
  else
    print_fail "Docker daemon not running"
    print_info "  Fix: Start Docker Desktop or run 'sudo systemctl start docker'"
  fi
else
  print_fail "Docker not installed"
  print_info "  Fix: Install Docker from https://docker.com"
fi

# ============================================================================
# Check 2: Docker Compose
# ============================================================================
print_section "Docker Compose"

if command -v docker >/dev/null 2>&1; then
  # Check for Docker Compose v2 (plugin)
  if docker compose version >/dev/null 2>&1; then
    COMPOSE_VERSION=$(docker compose version --short 2>/dev/null || docker compose version | awk '{print $NF}')
    print_pass "Docker Compose v2 available (v${COMPOSE_VERSION})"
  else
    print_fail "Docker Compose v2 not available"
    print_info "  Fix: Update Docker Desktop or install docker-compose-plugin"
  fi
fi

# ============================================================================
# Check 3: Required Tools
# ============================================================================
print_section "Required Tools"

# jq (required for hooks)
if command -v jq >/dev/null 2>&1; then
  JQ_VERSION=$(jq --version | sed 's/jq-//')
  print_pass "jq installed (${JQ_VERSION})"
else
  print_fail "jq not installed (required for docker-safety-hook)"
  print_info "  Fix: sudo apt-get install jq (or brew install jq on macOS)"
fi

# git
if command -v git >/dev/null 2>&1; then
  GIT_VERSION=$(git --version | awk '{print $3}')
  print_pass "git installed (v${GIT_VERSION})"

  # Check git config
  if [ "$VERBOSE" -eq 1 ]; then
    GIT_NAME=$(git config --global user.name 2>/dev/null || echo "not set")
    GIT_EMAIL=$(git config --global user.email 2>/dev/null || echo "not set")
    print_info "  Git user: $GIT_NAME <$GIT_EMAIL>"
  fi
else
  print_warn "git not installed (optional but recommended)"
  print_info "  Fix: sudo apt-get install git"
fi

# GitHub CLI
if command -v gh >/dev/null 2>&1; then
  GH_VERSION=$(gh version 2>&1 | head -1 | awk '{print $3}')
  print_pass "GitHub CLI installed (v${GH_VERSION})"

  # Check gh auth status
  if [ "$VERBOSE" -eq 1 ]; then
    if gh auth status >/dev/null 2>&1; then
      print_info "  GitHub authentication: active"
    else
      print_info "  GitHub authentication: not configured (run 'gh auth login')"
    fi
  fi
else
  print_warn "GitHub CLI not installed (optional)"
  print_info "  Fix: See /sandboxxer:yolo-linux-maxxing for installation"
fi

# ============================================================================
# Check 4: VS Code & DevContainers
# ============================================================================
print_section "VS Code & Extensions"

if command -v code >/dev/null 2>&1; then
  CODE_VERSION=$(code --version 2>/dev/null | head -1)
  print_pass "VS Code installed (${CODE_VERSION})"

  # Check for DevContainers extension
  if code --list-extensions 2>/dev/null | grep -q 'ms-vscode-remote.remote-containers'; then
    print_pass "DevContainers extension installed"
  else
    print_warn "DevContainers extension not installed"
    print_info "  Fix: Install 'ms-vscode-remote.remote-containers' from VS Code marketplace"
  fi
else
  print_warn "VS Code CLI not in PATH (optional)"
  print_info "  VS Code may still work via GUI"
fi

# ============================================================================
# Check 5: Disk Space
# ============================================================================
print_section "Disk Space"

# Cross-platform disk space check (df -BG is GNU-specific, use -k for compatibility)
AVAILABLE_KB=$(df -k . | awk 'NR==2 {print $4}')
AVAILABLE_GB=$((AVAILABLE_KB / 1024 / 1024))
if [ "$AVAILABLE_GB" -ge 10 ]; then
  print_pass "Disk space sufficient (${AVAILABLE_GB}GB available)"
elif [ "$AVAILABLE_GB" -ge 5 ]; then
  print_warn "Disk space low (${AVAILABLE_GB}GB available, recommended: 10GB+)"
else
  print_fail "Disk space critical (${AVAILABLE_GB}GB available, minimum: 5GB)"
  print_info "  Fix: Free up disk space or use different location"
fi

# ============================================================================
# Check 6: Port Availability
# ============================================================================
print_section "Port Availability"

# Check standard ports (using port_in_use from common.sh)
STANDARD_PORTS="8000:App 3000:Frontend 5432:PostgreSQL 6379:Redis"
PORTS_BUSY=0
for entry in $STANDARD_PORTS; do
  PORT=$(echo "$entry" | cut -d: -f1)
  NAME=$(echo "$entry" | cut -d: -f2)

  if port_in_use "$PORT"; then
    if [ "$VERBOSE" -eq 1 ]; then
      print_warn "$NAME port $PORT is in use"
    fi
    PORTS_BUSY=$((PORTS_BUSY + 1))
  fi
done

if [ "$PORTS_BUSY" -eq 0 ]; then
  print_pass "Standard ports available (8000, 3000, 5432, 6379)"
else
  print_info "Some standard ports in use (will auto-reassign if needed)"
fi

# ============================================================================
# Check 7: Running Containers
# ============================================================================
print_section "Container Status"

if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  RUNNING_CONTAINERS=$(docker ps --format '{{.Names}}' 2>/dev/null | wc -l)

  if [ "$RUNNING_CONTAINERS" -eq 0 ]; then
    print_info "No containers currently running"
  else
    print_pass "$RUNNING_CONTAINERS container(s) running"

    if [ "$VERBOSE" -eq 1 ]; then
      # Use process substitution to avoid subshell variable scoping issues
      while read line; do
        print_info "  $line"
      done < <(docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null)
    fi
  fi
fi

# ============================================================================
# Check 8: DevContainer Configuration (if present)
# ============================================================================
print_section "DevContainer Configuration"

if [ -f ".devcontainer/devcontainer.json" ]; then
  print_pass "devcontainer.json found"

  # Validate JSON syntax
  if command -v jq >/dev/null 2>&1; then
    if jq empty .devcontainer/devcontainer.json 2>/dev/null; then
      print_pass "devcontainer.json is valid JSON"
    else
      print_fail "devcontainer.json has syntax errors"
      print_info "  Fix: Check JSON syntax at line $(jq empty .devcontainer/devcontainer.json 2>&1 | grep -oP 'line \K\d+')"
    fi
  fi
else
  print_info "No devcontainer.json (run /sandboxxer:yolo-docker-maxxing to create)"
fi

if [ -f "docker-compose.yml" ]; then
  print_pass "docker-compose.yml found"

  # Basic YAML validation (check for common issues)
  if grep -q $'\t' docker-compose.yml; then
    print_warn "docker-compose.yml contains tabs (should use spaces)"
  fi
else
  print_info "No docker-compose.yml"
fi

if [ -f ".env" ]; then
  print_pass ".env file found"

  if [ "$VERBOSE" -eq 1 ]; then
    ENV_VARS=$(grep -c '^[A-Z_]*=' .env 2>/dev/null || echo 0)
    print_info "  Variables defined: $ENV_VARS"
  fi
else
  print_info "No .env file"
fi

# ============================================================================
# Check 9: Service Health (if running)
# ============================================================================
print_section "Service Health"

if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  # Check PostgreSQL
  POSTGRES_CONTAINER=$(docker ps --filter "expose=5432" --format '{{.Names}}' 2>/dev/null | head -1)
  if [ -n "$POSTGRES_CONTAINER" ]; then
    if docker exec "$POSTGRES_CONTAINER" pg_isready >/dev/null 2>&1; then
      print_pass "PostgreSQL is healthy"
    else
      print_warn "PostgreSQL container running but not ready"
    fi
  else
    print_info "PostgreSQL not running"
  fi

  # Check Redis
  REDIS_CONTAINER=$(docker ps --filter "expose=6379" --format '{{.Names}}' 2>/dev/null | head -1)
  if [ -n "$REDIS_CONTAINER" ]; then
    if docker exec "$REDIS_CONTAINER" redis-cli ping 2>/dev/null | grep -q "PONG"; then
      print_pass "Redis is healthy"
    else
      print_warn "Redis container running but not responding"
    fi
  else
    print_info "Redis not running"
  fi
fi

# ============================================================================
# Check 10: Docker Safety Hook
# ============================================================================
print_section "Plugin Configuration"

# Find plugin root using common.sh function
PLUGIN_ROOT=$(find_plugin_root 2>/dev/null || echo "")

if [ -n "$PLUGIN_ROOT" ] && [ -f "$PLUGIN_ROOT/hooks/docker-safety-hook.sh" ]; then
  print_pass "docker-safety-hook.sh found"

  # Check if hook is executable
  if [ -x "$PLUGIN_ROOT/hooks/docker-safety-hook.sh" ]; then
    print_pass "Hook is executable"
  else
    print_warn "Hook is not executable"
    print_info "  Fix: chmod +x $PLUGIN_ROOT/hooks/docker-safety-hook.sh"
  fi
else
  print_info "Plugin hooks not found (only relevant if using plugin features)"
fi

# ============================================================================
# Summary
# ============================================================================
echo ""
echo "=========================================="
TOTAL_CHECKS=$((CHECKS_PASSED + CHECKS_FAILED + CHECKS_WARNING))

if [ "$CHECKS_FAILED" -eq 0 ] && [ "$CHECKS_WARNING" -eq 0 ]; then
  echo -e "${GREEN}Health Check: PASSED${NC}"
  STATUS="PASSED"
elif [ "$CHECKS_FAILED" -eq 0 ]; then
  echo -e "${YELLOW}Health Check: PASSED (with warnings)${NC}"
  STATUS="PASSED WITH WARNINGS"
else
  echo -e "${RED}Health Check: FAILED${NC}"
  STATUS="FAILED"
fi

echo "Status: $STATUS"
echo "Issues: $CHECKS_FAILED | Warnings: $CHECKS_WARNING | Passed: $CHECKS_PASSED"
echo "=========================================="
echo ""

if [ "$CHECKS_FAILED" -gt 0 ]; then
  echo "🔧 Fix critical issues above before proceeding."
  echo ""
  exit 1
elif [ "$CHECKS_WARNING" -gt 0 ]; then
  echo "⚠️  Address warnings for optimal experience."
  echo ""
  exit 0
else
  echo "✅ All systems operational!"
  echo ""
  exit 0
fi
```

## Usage Examples

### Basic Health Check
```
/sandboxxer:health
```

### Verbose Output (detailed information)
```
/sandboxxer:health --verbose
```

### In CI/CD Pipeline
```bash
# Run health check and fail pipeline if issues found
/sandboxxer:health || exit 1
```

## What Gets Checked

| Category | Checks | Impact |
|----------|--------|--------|
| **Docker** | Daemon running, version ≥20.10 | Critical |
| **Docker Compose** | v2 plugin available | Critical |
| **Tools** | jq (required), git, gh (optional) | Critical/Optional |
| **VS Code** | Installed, DevContainers extension | Optional |
| **Disk Space** | ≥10GB recommended, ≥5GB minimum | Critical |
| **Ports** | 8000, 3000, 5432, 6379 availability | Info |
| **Containers** | Running container status | Info |
| **Config** | devcontainer.json, docker-compose.yml validity | Critical |
| **Services** | PostgreSQL, Redis health (if running) | Info |
| **Plugin** | docker-safety-hook.sh presence/permissions | Optional |

## Exit Codes

- **0**: All checks passed (or passed with warnings only)
- **1**: One or more critical checks failed

## Common Issues & Fixes

### Docker Daemon Not Running
```bash
# Linux
sudo systemctl start docker

# macOS/Windows
# Start Docker Desktop application
```

### jq Not Installed
```bash
# Ubuntu/Debian
sudo apt-get install jq

# macOS
brew install jq
```

### DevContainers Extension Missing
```bash
# Install via VS Code CLI
code --install-extension ms-vscode-remote.remote-containers

# Or install from VS Code marketplace
```

### Port Already In Use
Port conflicts are automatically handled by `/sandboxxer:yolo-docker-maxxing` - it will find available ports.

For manual resolution:
```bash
# Find process using port
lsof -i :8000

# Stop the process or use --portless mode
/sandboxxer:yolo-docker-maxxing --portless
```

## Integration with Other Commands

The health check is designed to work seamlessly with other sandbox-maxxing commands:

1. **Before setup**: Run health check to verify prerequisites
2. **After setup**: Run health check to verify configuration
3. **Troubleshooting**: Run with `--verbose` for detailed diagnostics
4. **CI/CD**: Use in automated pipelines for environment validation

## See Also

- `/sandboxxer:troubleshoot` - Interactive troubleshooting guide
- `/sandboxxer:linux-troubleshoot` - Linux-specific issues
- `/sandboxxer:audit` - Security audit and best practices
