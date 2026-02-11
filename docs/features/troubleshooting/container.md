# Container Issues

Common Docker container and DevContainer problems and solutions.

**See also:** [Main Troubleshooting Guide](../TROUBLESHOOTING.md) | [Network Issues](network.md) | [Service Connectivity](services.md)

---

## "Cannot connect to Docker daemon"

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

## Container Won't Start

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

## "Network not found" Error

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

## Build Fails with Dependency Errors

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

---

## Python Virtual Environment Errors After Rebuild

**Symptoms:**
- `uv sync` fails with "Failed to spawn: `/workspace/.venv/bin/python3`"
- Error message: "No such file or directory (os error 2)"
- Occurs after rebuilding DevContainer

**Cause:** Stale `.venv` directory with symlinks pointing to previous container's Python installation.

**Background:** When you rebuild a DevContainer, the workspace directory (`.venv` included) persists via bind mount. However, `.venv` contains symlinks to container-specific Python paths like `libpython3.12.so.1.0`. After rebuild, the new container has different Python installation paths, making these symlinks invalid.

**Automatic Solution:**

As of version 4.6.0, this is **automatically handled** by lifecycle hooks:
- `updateContentCommand` - Cleans `.venv` during rebuilds
- `onCreateCommand` - Cleans `.venv` on fresh container creation

If using an older template, regenerate with `/sandboxxer:quickstart` or manually update your `devcontainer.json`:

```json
{
  "onCreateCommand": "rm -rf /workspace/.venv 2>/dev/null || true; ...",
  "updateContentCommand": "echo '🧹 Cleaning stale .venv after rebuild...' && rm -rf /workspace/.venv 2>/dev/null || true"
}
```

**Manual Workaround:**

If cleanup doesn't happen automatically, manually remove the stale `.venv`:

```bash
# Inside the container
rm -rf /workspace/.venv
uv sync  # Recreates the virtual environment
```

**Prevention:**

Always use the latest DevContainer template which includes automatic cleanup.

---

**Next:** [Network Issues](network.md) | [Back to Main](../TROUBLESHOOTING.md)
