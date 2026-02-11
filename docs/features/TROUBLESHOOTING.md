# Troubleshooting Guide

This guide helps diagnose and resolve common issues with Claude Code sandbox environments. For interactive troubleshooting assistance, use the `/sandboxxer:troubleshoot` command.

## Table of Contents

1. [Quick Reference](#quick-reference)
2. [Claude Code Installation](#claude-code-installation)
3. [Plugin and Hooks Issues](#plugin-and-hooks-issues)
4. [Problem Categories](#problem-categories)
5. [Detailed Guides](#detailed-guides)
6. [Getting Help](#getting-help)

## Quick Reference

Common problems and their immediate fixes:

| Problem                         | Quick Fix                                       | Details                                          |
| ------------------------------- | ----------------------------------------------- | ------------------------------------------------ |
| Cannot connect to Docker daemon | Start Docker Desktop                            | [Container Issues](troubleshooting/container.md) |
| Container won't start           | `docker compose down && docker compose up -d`   | [Container Issues](troubleshooting/container.md) |
| Network not found               | Start docker-compose services first             | [Container Issues](troubleshooting/container.md) |
| Can't reach external sites      | Check firewall mode, whitelist domains          | [Network Issues](troubleshooting/network.md)     |
| Can't connect to postgres/redis | Use service name (not localhost)                | [Service Connectivity](troubleshooting/services.md) |
| npm/uv add fails                | Firewall blocking, whitelist registries         | [Firewall Issues](troubleshooting/firewall.md)   |
| Permission denied               | Fix file ownership: `sudo chown -R 1000:1000 .` | [Permission Errors](troubleshooting/permissions.md) |
| Port already in use             | Stop conflicting service or change port         | [Service Connectivity](troubleshooting/services.md) |
| VS Code extension not loading   | Rebuild container without cache                 | [VS Code DevContainer](troubleshooting/vscode.md) |
| Cannot create git worktrees     | Restructure: `projects/my-project/my-repo/`     | [Git Worktrees](troubleshooting/worktrees.md)    |
| Git dubious ownership error     | `git config --global --add safe.directory '*'`  | [Git Worktrees](troubleshooting/worktrees.md)    |
| Plugin hook loading fails       | Fix `matcher` field to use string format        | [Plugin Issues](#plugin-and-hooks-issues)        |
| Native Linux/WSL2 issues        | Use `/sandboxxer:linux-troubleshoot`            | [Linux/WSL2](troubleshooting/linux.md)           |

![Troubleshooting Flow](../diagrams/svg/troubleshooting-flow.svg)

*Decision tree for diagnosing and resolving common sandbox issues. Use `/sandboxxer:troubleshoot` for interactive assistance.*

## Claude Code Installation

### Issue: Claude Code not available after container rebuild

**Symptoms:**
- `claude: command not found` after reopening devcontainer
- Claude Code was working before rebuild

**Cause:**
Claude Code is installed in the container filesystem, which is recreated on rebuild.

**Solution:**
Reinstall Claude Code after each container rebuild:

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

**Automation Option:**
Add to `.devcontainer/postCreateCommand` or `postStartCommand`:

```json
{
  "postCreateCommand": "curl -fsSL https://claude.ai/install.sh | bash"
}
```

### Issue: Cannot download Claude Code installation script

**Symptoms:**
- `curl: (6) Could not resolve host: claude.ai`
- Network timeout during installation
- Corporate firewall blocking download

**Cause:**
Installation requires internet access to Anthropic servers.

**Solutions:**

1. **Add to firewall allowlist:**
   - `claude.ai`
   - `*.anthropic.com`
   - Installation CDN endpoints

2. **Pre-download for offline use:**
   ```bash
   # On connected machine
   curl -fsSL https://claude.ai/install.sh -o install-claude.sh

   # Copy to project and run offline
   sh ./install-claude.sh
   ```

3. **Use volume mount:**
   Pre-install Claude Code on host and mount the installation directory.

### Issue: NodeSource SSL Certificate Errors (Issue #29)

**Symptoms:**
- Build fails with SSL/certificate errors when installing Node.js from NodeSource
- `curl: (60) SSL certificate problem: unable to get local issuer certificate`
- Corporate proxy intercepting SSL certificates

**Cause:**
Corporate proxies intercept HTTPS traffic and inject their own certificates, which breaks NodeSource's SSL verification.

**Solution:**
The devcontainer uses a multi-stage Docker build to copy Node.js binaries from the official Node.js Docker image, avoiding NodeSource entirely:

```dockerfile
# Stage 1: Get Node.js from official image
FROM node:20-slim AS node-source

# Stage 2: Your base image
FROM your-base-image

# Copy Node.js from official image
COPY --from=node-source /usr/local/bin/node /usr/local/bin/
COPY --from=node-source /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm && \
    ln -s /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx
```

This pattern is included in all templates since version 2.2.1.

### Issue: Claude Credentials Not Persisting (Issue #30)

**Symptoms:**
- Need to re-authenticate Claude Code after every container rebuild
- `claude auth` credentials don't persist between container sessions
- Have to run `claude login` repeatedly

**Cause:**
Claude Code credentials are stored in `~/.claude` inside the container, which is recreated on each rebuild.

**Solution:**
Credentials are automatically copied from your host machine using a volume mount and setup script:

1. **Host credentials mount** (in `.devcontainer/docker-compose.yml`):
```yaml
app:
  volumes:
    - ~/.claude:/tmp/host-claude:ro  # Read-only mount
```

2. **Setup script** (in `.devcontainer/setup-claude-credentials.sh`):
```bash
#!/bin/bash
CLAUDE_DIR="$HOME/.claude"
HOST_CLAUDE="/tmp/host-claude"

mkdir -p "$CLAUDE_DIR"

if [ -f "$HOST_CLAUDE/.credentials.json" ]; then
    cp "$HOST_CLAUDE/.credentials.json" "$CLAUDE_DIR/"
    echo "✓ Claude credentials copied"
fi
```

3. **Automatic execution** (in `devcontainer.json`):
```json
{
  "postCreateCommand": ".devcontainer/setup-claude-credentials.sh && echo 'Container ready'"
}
```

This pattern is included in all examples since version 2.2.1.

## Plugin and Hooks Issues

### Issue: Plugin fails to load with "expected string, received object" error

**Symptoms:**
- Plugin fails to load with error: `Failed to load hooks from ...hooks.json: Invalid input: expected string, received object`
- Hooks don't trigger even though they're configured
- Error appears in Claude Code logs when starting a session

**Cause:**
The `matcher` field in PreToolUse/PostToolUse hooks is incorrectly formatted as an object (`{"tool_name": "Bash"}`) instead of a string (`"Bash"`).

**Root Cause:**
Claude Code's hook loader validates that the `matcher` field must be a string (regex pattern) that matches against tool names, not an object structure. The matcher acts as a regex pattern - for example, `"Bash"` matches the Bash tool, or `"Bash|Write|Edit"` matches multiple tools.

**Solution:**

Change the matcher from object format to string format in your hooks configuration file:

**Before (incorrect):**
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": {
          "tool_name": "Bash"
        },
        "hooks": [...]
      }
    ]
  }
}
```

**After (correct):**
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [...]
      }
    ]
  }
}
```

**Files to update:**
1. Check `hooks/hooks.json` in your plugin directory
2. Check `hooks/hooks.example.json` if present
3. Any custom hook configuration files

**Verification:**
1. Reload the plugin: `claude code plugins reload <plugin-name>`
2. Start a new session - no hook loading errors should appear
3. Test that hooks trigger correctly when using the matched tool

**Advanced matcher patterns:**
The matcher field supports regex patterns for flexible matching:
- `"Bash"` - Match only the Bash tool
- `"Bash|Write|Edit"` - Match multiple tools
- `".*"` - Match all tools (use with caution)

This issue was fixed in sandbox-maxxing plugin version 4.12.1.

## Problem Categories

### How to Identify Your Problem

1. **Container Issues**: Container won't start, build failures, Docker daemon errors → [Container Guide](troubleshooting/container.md)
2. **Network Issues**: Can't reach external websites, DNS failures, timeout errors → [Network Guide](troubleshooting/network.md)
3. **Service Connectivity**: Can't connect to database, Redis, RabbitMQ, or other services → [Services Guide](troubleshooting/services.md)
4. **Firewall Issues**: Legitimate traffic blocked, package installation fails → [Firewall Guide](troubleshooting/firewall.md)
5. **Permission Errors**: Permission denied, file ownership problems → [Permissions Guide](troubleshooting/permissions.md)
6. **VS Code Issues**: Extensions not working, connection problems, DevContainer errors → [VS Code Guide](troubleshooting/vscode.md)
7. **Performance Issues**: Slow container, high CPU/memory, lag → [Performance Guide](troubleshooting/performance.md)
8. **Git Worktree Issues**: Worktree creation fails, ownership problems → [Worktrees Guide](troubleshooting/worktrees.md)
9. **Windows-Specific**: Line endings, WSL2, Docker Desktop issues → [Windows Guide](troubleshooting/windows.md)
10. **Linux/WSL2**: Native Linux setup, bubblewrap, sudo hangs → [Linux Guide](troubleshooting/linux.md)

## Detailed Guides

### 📦 [Container Issues](troubleshooting/container.md)
Docker daemon errors, container startup failures, build problems, network not found, Python virtual environment errors after rebuild.

**Common fixes:**
- Start Docker Desktop
- `docker compose down && docker compose up -d`
- Rebuild without cache
- Clean up stale `.venv` directories

---

### 🌐 [Network Issues](troubleshooting/network.md)
External connectivity problems, DNS resolution failures, firewall blocking external sites.

**Common fixes:**
- Check firewall mode
- Whitelist domains in init-firewall.sh
- Restart firewall with `sudo /usr/local/bin/init-firewall.sh`
- Verify Docker DNS configuration

---

### 🔌 [Service Connectivity](troubleshooting/services.md)
Connecting to PostgreSQL, Redis, RabbitMQ, and other services. Service health check failures.

**Common fixes:**
- Use service name (not localhost): `postgres:5432`, `redis:6379`
- Check service status: `docker compose ps`
- View service logs: `docker compose logs <service>`
- Verify same Docker network

---

### 🔥 [Firewall Issues](troubleshooting/firewall.md)
Package installation failures, npm registry blocked, firewall verification errors.

**Common fixes:**
- Add package registries to `ALLOWED_DOMAINS`
- Restart firewall after changes
- Use permissive mode temporarily for testing
- Check firewall logs

---

### 🔒 [Permission Errors](troubleshooting/permissions.md)
File ownership mismatches, permission denied errors, script execution failures.

**Common fixes:**
- Fix ownership: `sudo chown -R 1000:1000 /path/to/project`
- Make scripts executable: `chmod +x script.sh`
- Adjust container user in devcontainer.json

---

### 💻 [VS Code DevContainer Problems](troubleshooting/vscode.md)
Extension loading failures, container disconnections, port forwarding issues.

**Common fixes:**
- Rebuild container
- Check extension configuration
- Increase Docker resources
- Bind to 0.0.0.0 instead of 127.0.0.1

---

### ⚡ [Performance Issues](troubleshooting/performance.md)
Slow container performance, high CPU/memory usage, laggy operations.

**Common fixes:**
- Increase Docker resource allocation
- Use cached volumes
- Exclude node_modules from sync
- Set resource limits in docker-compose.yml

---

### 🌳 [Git Worktree Issues](troubleshooting/worktrees.md)
Worktree creation failures, dubious ownership errors, visibility problems.

**Common fixes:**
- Restructure to `projects/my-project/my-repo/`
- Add to safe directories: `git config --global --add safe.directory '*'`
- Verify parent folder mount

---

### 🪟 [Windows-Specific Issues](troubleshooting/windows.md)
Line ending problems (CRLF vs LF), WSL2 backend configuration, corporate proxy issues.

**Common fixes:**
- Configure Git: `git config --global core.autocrlf input`
- Use WSL2 filesystem for better performance
- Configure WSL memory limits in `.wslconfig`
- Handle corporate proxy certificates

---

### 🐧 [Linux/WSL2 Troubleshooting](troubleshooting/linux.md)
Native Linux setup issues, sudo hangs during installation, bubblewrap permissions.

**Common fixes:**
- Use `/sandboxxer:linux-troubleshoot` for diagnostics
- Verify sudo access before installation
- Check group membership: `groups | grep -E "(sudo|wheel)"`
- Reset WSL if needed

---

### ☢️ [Nuclear Option: Reset Everything](troubleshooting/reset.md)
Complete Docker environment reset when nothing else works.

**Warning:** Deletes all containers, images, volumes, and data.

---

## Getting Help

If you're still stuck:

1. **Use Interactive Troubleshooting:**
   ```
   /sandboxxer:troubleshoot        # For Docker-based sandboxes
   /sandboxxer:linux-troubleshoot  # For native Linux/WSL2 setups
   ```

2. **Check Logs:**
   - Container logs: `docker compose logs`
   - VS Code logs: Command Palette → "Developer: Show Logs"
   - Docker logs: Docker Desktop → Troubleshooting

3. **Consult Documentation:**
   - [Security Model](SECURITY-MODEL.md)
   - [Setup Options Guide](SETUP-OPTIONS.md)
   - [Variables Guide](VARIABLES.md)
   - [Secrets Guide](SECRETS.md)
   - [Windows-Specific Guide](../windows/README.md) - Windows troubleshooting and hooks

4. **Ask for Help:**
   - GitHub Issues: Report bugs or ask questions
   - GitHub Discussions: Community support
   - Include: Container logs, error messages, devcontainer.json, docker-compose.yml
