# Troubleshooting Guide

This guide helps diagnose and resolve common issues with Claude Code sandbox environments. For interactive troubleshooting assistance, use the `/devcontainer:troubleshoot` command.

## Table of Contents

1. [Quick Reference](#quick-reference)
2. [Claude Code Installation](#claude-code-installation)
3. [Problem Categories](#problem-categories)
4. [Container Issues](#container-issues)
5. [Network Issues](#network-issues)
6. [Service Connectivity](#service-connectivity)
7. [Firewall Issues](#firewall-issues)
8. [Permission Errors](#permission-errors)
9. [VS Code DevContainer Problems](#vs-code-devcontainer-problems)
10. [Performance Issues](#performance-issues)
11. [Nuclear Option: Reset Everything](#nuclear-option-reset-everything)

## Quick Reference

Common problems and their immediate fixes:

| Problem                         | Quick Fix                                       | Details                                                         |
| ------------------------------- | ----------------------------------------------- | --------------------------------------------------------------- |
| Cannot connect to Docker daemon | Start Docker Desktop                            | [Container Issues](#container-issues)                           |
| Container won't start           | `docker compose down && docker compose up -d`   | [Container Issues](#container-issues)                           |
| Network not found               | Start docker-compose services first             | [Container Issues](#container-issues)                           |
| Can't reach external sites      | Check firewall mode, whitelist domains          | [Network Issues](#network-issues)                               |
| Can't connect to postgres/redis | Use service name (not localhost)                | [Service Connectivity](#service-connectivity)                   |
| npm/uv add fails                | Firewall blocking, whitelist registries         | [Firewall Issues](#firewall-issues)                             |
| Permission denied               | Fix file ownership: `sudo chown -R 1000:1000 .` | [Permission Errors](#permission-errors)                         |
| Port already in use             | Stop conflicting service or change port         | [Service Connectivity](#service-connectivity)                   |
| VS Code extension not loading   | Rebuild container without cache                 | [VS Code DevContainer Problems](#vs-code-devcontainer-problems) |

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
curl -fsSL https://claude.ai/install.sh | sh
```

**Automation Option:**
Add to `.devcontainer/postCreateCommand` or `postStartCommand`:

```json
{
  "postCreateCommand": "curl -fsSL https://claude.ai/install.sh | sh"
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

## Problem Categories

### How to Identify Your Problem

1. **Container Issues**: Container won't start, build failures, Docker daemon errors
2. **Network Issues**: Can't reach external websites, DNS failures, timeout errors
3. **Service Connectivity**: Can't connect to database, Redis, RabbitMQ, or other services
4. **Firewall Issues**: Legitimate traffic blocked, package installation fails
5. **Permission Errors**: Permission denied, file ownership problems
6. **VS Code Issues**: Extensions not working, connection problems, DevContainer errors
7. **Performance Issues**: Slow container, high CPU/memory, lag

## Container Issues

### "Cannot connect to Docker daemon"

**Symptoms:**
```
Cannot connect to the Docker daemon at unix:///var/run/docker.sock.
Is the docker daemon running?
```

**Cause:** Docker is not running on your host machine.

**Solutions:**

**Windows/Mac:**
```bash
# Start Docker Desktop
# Check system tray for Docker icon
# Wait for "Docker Desktop is running" message
```

**Linux:**
```bash
# Start Docker daemon
sudo systemctl start docker

# Enable on boot
sudo systemctl enable docker

# Check status
sudo systemctl status docker
```

**Verify:**
```bash
docker ps
```

---

### Container Won't Start

**Symptoms:**
- DevContainer fails to start
- "Container has stopped" error
- Build process hangs or fails

**Diagnostic Commands:**
```bash
# Check container status
docker ps -a

# Check compose services
docker compose ps

# View logs
docker compose logs

# Check disk space
docker system df
```

**Solutions:**

**1. Restart Services:**
```bash
# Stop all services
docker compose down

# Start services
docker compose up -d

# Check health
docker compose ps
```

**2. Rebuild Container (VS Code):**
1. Open Command Palette (Ctrl/Cmd+Shift+P)
2. Select "Dev Containers: Rebuild Container"
3. If that fails, try "Dev Containers: Rebuild Container Without Cache"

**3. Rebuild Container (CLI):**
```bash
# Rebuild specific service
docker compose build app

# Rebuild without cache
docker compose build --no-cache app

# Restart
docker compose up -d
```

**4. Check Disk Space:**
```bash
# View disk usage
docker system df

# Clean up unused images, containers, networks
docker system prune

# More aggressive cleanup (includes volumes)
docker system prune -a --volumes
```
⚠️ Warning: `prune -a --volumes` deletes all stopped containers and unused volumes

---

### "Network not found" Error

**Symptoms:**
```
network <network-name> not found
```

**Cause:** Docker Compose services haven't created the network yet.

**Solution:**
```bash
# Start Docker Compose services FIRST
cd /workspace  # or your project root
docker compose up -d

# THEN open DevContainer
# VS Code: Command Palette -> "Dev Containers: Reopen in Container"
```

**Verification:**
```bash
# List networks
docker network ls

# Should see your project network (e.g., sandbox-dev-network)
```

---

### Build Fails with Dependency Errors

**Symptoms:**
- `npm install` fails during build
- `uv add` fails during build
- Package registry unreachable

**Cause:** Firewall blocking package registries during build, or network issues.

**Solutions:**

**1. Temporarily Disable Firewall (Development Only):**

Edit `.devcontainer/init-firewall.sh` and change:
```bash
FIREWALL_MODE="permissive"  # or "disabled"
```

Rebuild container.

**2. Add Package Registries to Allowlist:**

Edit `.devcontainer/init-firewall.sh`, add to `ALLOWED_DOMAINS`:
```bash
ALLOWED_DOMAINS=(
  # ... existing domains ...

  # Python
  "pypi.org"
  "files.pythonhosted.org"

  # Node.js
  "registry.npmjs.org"

  # Rust
  "crates.io"
  "static.crates.io"
)
```

Rebuild container.

## Network Issues

### Can't Reach External Websites

**Symptoms:**
- `curl https://api.github.com` fails
- `ping google.com` fails (if ping installed)
- DNS resolution errors

**Diagnostic Commands:**
```bash
# Inside container

# Test DNS resolution
nslookup google.com

# Test connectivity to known site
curl https://api.github.com/zen

# Check firewall rules
sudo iptables -L OUTPUT -v -n

# Check firewall mode
echo $FIREWALL_MODE
```

**Solutions:**

**1. Check Firewall Mode:**
```bash
echo $FIREWALL_MODE
# If "strict", firewall is actively blocking
```

**2. Verify Domain is Whitelisted:**

Check if the domain you need is in `/usr/local/bin/init-firewall.sh` or `.devcontainer/init-firewall.sh`:
```bash
cat /usr/local/bin/init-firewall.sh | grep -A 100 "ALLOWED_DOMAINS"
```

**3. Add Domain to Allowlist:**

Edit `.devcontainer/init-firewall.sh`:
```bash
ALLOWED_DOMAINS=(
  # ... existing domains ...
  "api.yourservice.com"
  "cdn.yourservice.com"
)
```

**4. Restart Firewall:**
```bash
sudo /usr/local/bin/init-firewall.sh
```

**5. Temporarily Use Permissive Mode (Testing Only):**

Edit `.devcontainer/init-firewall.sh`:
```bash
FIREWALL_MODE="permissive"
```

Rebuild container. ⚠️ Remember to restore strict mode after testing.

---

### DNS Resolution Failures

**Symptoms:**
```
Could not resolve host: api.github.com
```

**Solutions:**

**1. Check Docker DNS:**
```bash
# Inside container
cat /etc/resolv.conf

# Should show Docker's DNS server (usually 127.0.0.11)
```

**2. Restart Docker (Host):**
```bash
# Mac/Windows: Restart Docker Desktop
# Linux:
sudo systemctl restart docker
```

**3. Check Host DNS:**

Ensure your host machine can resolve DNS. If host DNS is broken, containers will also fail.

## Service Connectivity

### Can't Connect to PostgreSQL/Redis/RabbitMQ

**Symptoms:**
- Connection refused
- Connection timeout
- "Could not connect to server"

**Diagnostic Commands:**
```bash
# Check service status
docker compose ps

# Check service logs
docker compose logs postgres
docker compose logs redis

# Test connectivity (inside container)
nc -zv postgres 5432
nc -zv redis 6379

# Check networks
docker inspect <container-name> | grep Networks -A 5
```

**Common Mistakes:**

❌ **Using localhost:**
```python
# WRONG
DATABASE_URL = "postgresql://user:pass@localhost:5432/db"
```

✅ **Using service name:**
```python
# CORRECT
DATABASE_URL = "postgresql://user:pass@postgres:5432/db"
```

**Solutions:**

**1. Verify Service is Running:**
```bash
docker compose ps

# Look for "Up" and "healthy" status
# Example output:
# postgres   Up (healthy)
# redis      Up (healthy)
```

**2. Check Service Logs:**
```bash
docker compose logs postgres
# Look for startup errors or crashes
```

**3. Use Service Name in Connection Strings:**

Update your application configuration:
```bash
# PostgreSQL
POSTGRES_HOST=postgres  # NOT localhost

# Redis
REDIS_HOST=redis  # NOT localhost

# RabbitMQ
RABBITMQ_HOST=rabbitmq  # NOT localhost
```

**4. Verify Same Network:**
```bash
# Check both containers are on same network
docker network inspect <network-name>

# Should show both app and service containers
```

**5. Test Health Check:**
```bash
# PostgreSQL
docker exec -it <postgres-container> pg_isready -U sandbox_user

# Redis
docker exec -it <redis-container> redis-cli ping
```

---

### Service Shows "Unhealthy"

**Symptoms:**
```bash
docker compose ps
# Shows: postgres   Up (unhealthy)
```

**Diagnostic Commands:**
```bash
# Check health check configuration
docker compose config | grep -A 10 healthcheck

# View health check logs
docker inspect <container-name> | grep -A 20 Health
```

**Solutions:**

**1. Increase Health Check Timeouts:**

Edit `docker-compose.yml`:
```yaml
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U sandbox_user"]
  interval: 10s
  timeout: 5s
  retries: 5
  start_period: 30s  # Increase this for slow systems
```

**2. Fix Health Check Command:**

Ensure command matches service configuration:
```yaml
# PostgreSQL - match username
test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]

# Redis - use correct auth
test: ["CMD", "redis-cli", "--pass", "${REDIS_PASSWORD}", "ping"]
```

**3. Wait Longer:**

Services may take time to initialize, especially PostgreSQL. Wait 30-60 seconds after `docker compose up`.

## Firewall Issues

### Package Installation Fails

**Symptoms:**
- `npm install` hangs or fails
- `uv add <package>` fails with connection error
- `cargo build` can't fetch dependencies

**Cause:** Strict firewall mode blocking package registries.

**Solutions:**

**Identify Blocked Domain:**

Look at error message:
```
Could not connect to registry.npmjs.org
Failed to fetch https://files.pythonhosted.org
```

**Add to Allowlist:**

Edit `.devcontainer/init-firewall.sh`:
```bash
ALLOWED_DOMAINS=(
  # ... existing domains ...

  # ===CATEGORY:project_specific===
  # Python packages
  "pypi.org"
  "files.pythonhosted.org"

  # Node.js packages
  "registry.npmjs.org"

  # Rust crates
  "crates.io"
  "static.crates.io"

  # Ruby gems
  "rubygems.org"
  # ===END_CATEGORY===
)
```

**Restart Firewall:**
```bash
sudo /usr/local/bin/init-firewall.sh
```

**Common Package Registry Domains:**

| Language     | Domains to Whitelist                  |
| ------------ | ------------------------------------- |
| Python       | `pypi.org`, `files.pythonhosted.org`  |
| Node.js      | `registry.npmjs.org`, `yarnpkg.com`   |
| Rust         | `crates.io`, `static.crates.io`       |
| Ruby         | `rubygems.org`, `api.rubygems.org`    |
| Go           | `proxy.golang.org`, `sum.golang.org`  |
| Java/Maven   | `repo.maven.org`, `repo1.maven.org`   |
| PHP/Composer | `packagist.org`, `repo.packagist.org` |
| .NET/NuGet   | `nuget.org`, `api.nuget.org`          |

**Temporary Workaround:**

For testing purposes, temporarily use permissive mode:
```bash
# Edit .devcontainer/init-firewall.sh
FIREWALL_MODE="permissive"

# Rebuild container
```

⚠️ Remember to restore strict mode and whitelist needed domains afterward.

---

### npm Registry Blocked by Firewall (Issue #32)

**Symptoms:**
- Cannot install npm packages
- `npm install` fails with network errors
- Claude Code updates fail with registry connection errors
- `npm ERR! network request to https://registry.npmjs.org failed`

**Cause:**
The firewall is blocking access to the npm registry, preventing package installations and Claude Code updates.

**Solution:**
The npm registry domains are included in the firewall allowlist by default since version 2.2.1:

In `.devcontainer/init-firewall.sh`:
```bash
ALLOWED_DOMAINS=(
  # ... existing domains ...

  # ===CATEGORY:npm_registry===
  # NPM package registry (Issue #32)
  "registry.npmjs.org"
  "npmjs.org"
  "*.npmjs.org"
  # ===END_CATEGORY===
)
```

**If you're using an older version:**

1. Add the npm registry domains to your allowlist manually
2. Restart the firewall:
```bash
sudo /usr/local/bin/init-firewall.sh
```

3. Test npm access:
```bash
npm ping
npm install --dry-run
```

**Verify the fix:**
```bash
# Should succeed without errors
npm view claude-code version
npm install -g @anthropic-ai/claude-code
```

---

### Firewall Verification Fails

**Symptoms:**
```
ERROR: Firewall verification failed - unable to reach https://api.github.com
```

**Cause:** GitHub IPs may have changed, or DNS resolution failed during firewall setup.

**Solutions:**

**1. Retry Firewall Initialization:**
```bash
sudo /usr/local/bin/init-firewall.sh
```

**2. Check DNS Resolution:**
```bash
nslookup api.github.com
# Should return IP addresses
```

**3. Manual GitHub IP Update:**

If GitHub IPs change frequently:
```bash
# Fetch latest GitHub IPs
curl -s https://api.github.com/meta | jq '.web + .api + .git'

# Or temporarily add static IP
# (not recommended long-term)
```

**4. Use Permissive Mode Temporarily:**

If firewall keeps failing verification, use permissive mode until fixed:
```bash
FIREWALL_MODE="permissive"
```

## Permission Errors

### "Permission denied" Errors

**Symptoms:**
```
EACCES: permission denied, open '/workspace/file.txt'
bash: /workspace/script.sh: Permission denied
```

**Cause:** File ownership mismatch between host and container users.

**Container User Info:**
- Most containers run as `node` user (UID 1000, GID 1000)
- Files created on host may have different ownership
- Files created in container owned by UID 1000

**Solutions:**

**1. Fix Ownership from Host:**
```bash
# On host machine (outside container)
sudo chown -R 1000:1000 /path/to/project

# Or use your username (if your UID is 1000)
sudo chown -R $USER:$USER /path/to/project
```

**2. Fix Ownership from Container:**
```bash
# Inside container
sudo chown -R node:node /workspace

# For specific files
sudo chown node:node /workspace/specific-file.txt
```

**3. Make Scripts Executable:**
```bash
# On host or in container
chmod +x script.sh
```

**4. Adjust DevContainer User:**

If you need different UID/GID, edit `devcontainer.json`:
```json
{
  "remoteUser": "node",
  "containerUser": "node",
  "updateRemoteUserUID": true
}
```

## VS Code DevContainer Problems

### Extension Not Loading

**Symptoms:**
- Extension installed but not working
- Extension shows "Install in Container" button
- Features missing

**Solutions:**

**1. Check Extension Installation:**
```json
// devcontainer.json
{
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python",
        "dbaeumer.vscode-eslint"
      ]
    }
  }
}
```

**2. Rebuild Container:**

1. Command Palette (Ctrl/Cmd+Shift+P)
2. "Dev Containers: Rebuild Container"

**3. Check Extension Logs:**

1. Command Palette → "Developer: Show Logs"
2. Select extension from dropdown
3. Look for error messages

**4. Manual Installation:**

1. Extensions view (Ctrl/Cmd+Shift+X)
2. Search for extension
3. Click "Install in Container"

---

### Container Keeps Disconnecting

**Symptoms:**
- "Container has stopped" messages
- Frequent reconnection attempts
- VS Code disconnects randomly

**Diagnostic Commands:**
```bash
# Check container logs
docker compose logs app

# Check container resource usage
docker stats

# Check container health
docker inspect <container-name> | grep Health -A 20
```

**Solutions:**

**1. Increase Docker Resources:**

Docker Desktop → Settings → Resources:
- CPU: 4+ cores recommended
- Memory: 8GB+ recommended
- Swap: 2GB+

**2. Check Container Logs for Crashes:**
```bash
docker compose logs app
# Look for OOM (Out of Memory) errors or crashes
```

**3. Disable Resource-Intensive Extensions:**

Temporarily disable extensions to identify culprit:
```json
{
  "customizations": {
    "vscode": {
      "extensions": []  // Start with empty list
    }
  }
}
```

**4. Check Host System Resources:**

Ensure host has sufficient resources and isn't swapping heavily.

---

### Port Forwarding Not Working

**Symptoms:**
- Can't access application at localhost:PORT
- "Connection refused" when accessing forwarded port
- Port shows in VS Code but doesn't work

**Solutions:**

**1. Verify Port Configuration:**
```json
// devcontainer.json
{
  "forwardPorts": [8000, 3000, 5432, 6379],
  "portsAttributes": {
    "8000": {
      "label": "Backend API",
      "onAutoForward": "notify"
    }
  }
}
```

**2. Check Application is Listening:**
```bash
# Inside container
netstat -tlnp | grep 8000
# or
ss -tlnp | grep 8000
```

**3. Bind to 0.0.0.0, Not 127.0.0.1:**

Ensure application listens on all interfaces:
```python
# Python/Flask
app.run(host='0.0.0.0', port=8000)  # NOT host='127.0.0.1'
```

```javascript
// Node.js/Express
app.listen(3000, '0.0.0.0');  // NOT '127.0.0.1'
```

**4. Check Port Conflicts:**
```bash
# On host machine
lsof -i :8000
# or
netstat -an | grep 8000
```

**5. Manually Forward Port (VS Code):**

1. Open "Ports" tab in VS Code terminal panel
2. Click "+" to add port
3. Enter port number

## Performance Issues

### Slow Container Performance

**Symptoms:**
- Commands take long time to execute
- File operations slow
- Application laggy

**Solutions:**

**1. Increase Docker Resources:**

Docker Desktop → Settings → Resources:
- Increase CPU allocation
- Increase memory allocation
- Enable VirtioFS (Mac) for faster file sharing

**2. Use Cached Volumes:**

Edit `docker-compose.yml`:
```yaml
volumes:
  - ../..:/workspace:cached  # Add :cached flag
```

**3. Exclude node_modules from Sync:**

Edit `devcontainer.json`:
```json
{
  "mounts": [
    "source=${localWorkspaceFolder},target=/workspace,type=bind,consistency=cached"
  ],
  "postCreateCommand": "npm install"
}
```

Use anonymous volumes for dependencies:
```yaml
volumes:
  - ../..:/workspace:cached
  - /workspace/node_modules  # Don't sync with host
```

**4. Disable Resource-Intensive Services:**

If you don't need all services, disable them:
```bash
# Only start specific services
docker compose up postgres redis
```

**5. Check Disk Space:**
```bash
docker system df
docker system prune -a
```

---

### High CPU/Memory Usage

**Diagnostic Commands:**
```bash
# Check container resource usage
docker stats

# Check processes inside container
docker exec -it <container> top
```

**Solutions:**

**1. Set Resource Limits:**

Edit `docker-compose.yml`:
```yaml
services:
  app:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 4G
        reservations:
          memory: 2G
```

**2. Identify Resource-Hungry Processes:**
```bash
# Inside container
top
# or
htop  # if installed
```

**3. Optimize Build Process:**

Use multi-stage builds to reduce image size:
```dockerfile
FROM node:20-slim AS build
# Build steps

FROM node:20-slim AS runtime
COPY --from=build /app/dist /app/dist
# Runtime only
```

## Nuclear Option: Reset Everything

If nothing works and you need a fresh start:

⚠️ **WARNING:** This deletes all containers, images, volumes, and data. Back up important information first.

```bash
# 1. Stop all containers
docker compose down -v

# 2. Clean VS Code DevContainers
# Command Palette → "Dev Containers: Clean Up Dev Containers"

# 3. Prune entire Docker system
docker system prune -a --volumes

# 4. Restart Docker
# Mac/Windows: Restart Docker Desktop
# Linux: sudo systemctl restart docker

# 5. Start fresh
docker compose up -d

# 6. Rebuild DevContainer without cache
# Command Palette → "Dev Containers: Rebuild Container Without Cache"
```

**Verification:**
```bash
# Check everything is running
docker ps
docker compose ps

# Test connectivity
curl https://api.github.com/zen
```

## Windows-Specific Issues

### Line Ending Problems (CRLF vs LF)

**Symptoms:**
- Shell scripts fail with `/bin/bash^M: bad interpreter`
- Docker build fails with syntax errors in shell scripts
- `init-firewall.sh` won't execute inside container

**Cause:** Windows Git may convert LF line endings to CRLF, which breaks shell scripts in Linux containers.

**Solutions:**

**1. Configure Git (Recommended - Prevents Future Issues):**
```bash
# Set global Git config to preserve LF line endings
git config --global core.autocrlf input

# Or for this repository only
cd /path/to/sandbox-maxxing
git config core.autocrlf input
```

**2. Use Repository `.gitattributes` File:**

The repository includes a `.gitattributes` file that enforces LF for shell scripts and Docker files. If you cloned before this was added:

```bash
# Re-normalize files after .gitattributes is present
git add --renormalize .
git checkout -- .
```

**3. Manual Fix (Single File):**
```bash
# Convert CRLF to LF
sed -i 's/\r$//' .devcontainer/init-firewall.sh

# Or using dos2unix if available
dos2unix .devcontainer/init-firewall.sh
```

**4. VS Code Settings:**

Add to `.vscode/settings.json`:
```json
{
  "files.eol": "\n"
}
```

---

### Docker Desktop WSL 2 Backend Issues

**Symptoms:**
- Very slow file operations
- Container takes long time to start
- High CPU usage from `vmmem` process

**Solutions:**

**1. Use WSL 2 Backend (Required for Best Performance):**
- Docker Desktop > Settings > General > "Use the WSL 2 based engine" (check)

**2. Store Project Files in WSL Filesystem:**
```bash
# Instead of /mnt/c/Users/... (slow Windows filesystem)
# Use ~/projects/... in WSL (fast native filesystem)

# Move project to WSL filesystem
cd ~
git clone https://github.com/andrewcchoi/sandbox-maxxing
cd sandbox-maxxing
code .
```

**3. Configure WSL Memory Limits:**

Create/edit `%USERPROFILE%\.wslconfig` on Windows:
```ini
[wsl2]
memory=8GB
processors=4
swap=2GB
```

Then restart WSL:
```powershell
# In PowerShell as Administrator
wsl --shutdown
```

---

### Corporate Proxy / SSL Certificate Issues

**Symptoms:**
- `SSL: CERTIFICATE_VERIFY_FAILED`
- `unable to get local issuer certificate`
- Package installation fails with SSL errors (pip, npm, curl)
- UV installation fails during Docker build

**Solutions:**

**1. Add Custom CA Certificate to Docker Image:**

If your corporate network uses a custom CA certificate:

```dockerfile
# Add to your Dockerfile
COPY corporate-ca.crt /usr/local/share/ca-certificates/
RUN update-ca-certificates
```

**2. Configure Proxy Environment Variables:**

Add to your `docker-compose.yml` or `.env`:

```yaml
# docker-compose.yml
services:
  app:
    environment:
      - HTTP_PROXY=http://proxy.company.com:8080
      - HTTPS_PROXY=http://proxy.company.com:8080
      - NO_PROXY=localhost,127.0.0.1,.company.com
```

Or in your `Dockerfile`:
```dockerfile
ARG HTTP_PROXY
ARG HTTPS_PROXY
ENV HTTP_PROXY=${HTTP_PROXY}
ENV HTTPS_PROXY=${HTTPS_PROXY}
```

Then build with proxy args:
```bash
docker build \
  --build-arg HTTP_PROXY=http://proxy.company.com:8080 \
  --build-arg HTTPS_PROXY=http://proxy.company.com:8080 \
  -t myimage .
```

**3. Configure pip to Use Proxy:**

Inside the container:
```bash
pip config set global.proxy http://proxy.company.com:8080
pip config set global.trusted-host pypi.org
pip config set global.trusted-host files.pythonhosted.org
```

**4. Disable SSL Verification (Last Resort - Not Recommended):**

Only use this for testing in controlled environments:
```bash
# For pip
uv add --trusted-host pypi.org --trusted-host files.pythonhosted.org package-name

# For npm
npm config set strict-ssl false

# For git
git config --global http.sslVerify false
```

**5. UV Installation Fallback:**

The repository's Python Dockerfile automatically falls back to pip if UV installation fails due to SSL/proxy issues. This is handled automatically - no action needed.

---

## Getting Help

If you're still stuck:

1. **Use Interactive Troubleshooting:**
   ```
   /devcontainer:troubleshoot
   ```

2. **Check Logs:**
   - Container logs: `docker compose logs`
   - VS Code logs: Command Palette → "Developer: Show Logs"
   - Docker logs: Docker Desktop → Troubleshooting

3. **Consult Documentation:**
   - [Security Model](security-model.md)
   - [Modes Guide](MODES.md)
   - [Variables Guide](VARIABLES.md)
   - [Secrets Guide](SECRETS.md)

4. **Ask for Help:**
   - GitHub Issues: Report bugs or ask questions
   - GitHub Discussions: Community support
   - Include: Container logs, error messages, devcontainer.json, docker-compose.yml

---

**Last Updated:** 2025-12-24
**Version:** 4.5.0
