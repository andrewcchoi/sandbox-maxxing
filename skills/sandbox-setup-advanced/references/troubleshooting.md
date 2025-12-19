# Troubleshooting Guide

Common issues and solutions when using the Claude Code Docker sandbox template.

## Table of Contents

- [Container Issues](#container-issues)
- [Network Issues](#network-issues)
- [Service Connectivity](#service-connectivity)
- [Firewall Issues](#firewall-issues)
- [Performance Issues](#performance-issues)
- [VS Code Issues](#vs-code-issues)
- [Claude Code Issues](#claude-code-issues)

## Container Issues

### Container won't start

**Symptoms:**
- DevContainer fails to build or start
- Error: "Cannot connect to Docker daemon"

**Solutions:**

1. **Check Docker is running:**
   ```bash
   docker ps
   ```
   If this fails, start Docker Desktop or Docker daemon.

2. **Check Docker Compose services are not blocking:**
   ```bash
   docker compose down
   docker compose up -d
   ```

3. **Rebuild container from scratch:**
   ```bash
   # In VS Code: Ctrl+Shift+P
   # → "Dev Containers: Rebuild Container Without Cache"
   ```

4. **Check disk space:**
   ```bash
   docker system df
   docker system prune  # Remove unused data
   ```

### Build fails with dependency errors

**Symptoms:**
- `npm install` or `pip install` fails during build
- Network timeout errors

**Solutions:**

1. **Temporarily use permissive firewall mode:**

   Edit `devcontainer.json`:
   ```json
   "containerEnv": {
     "FIREWALL_MODE": "permissive"
   }
   ```
   Rebuild container.

2. **Clear Docker build cache:**
   ```bash
   docker builder prune
   ```

3. **Check Docker network connectivity:**
   ```bash
   docker run --rm alpine ping -c 3 google.com
   ```

### "Permission denied" errors

**Symptoms:**
- Can't write files in `/workspace`
- `sudo` commands fail

**Solutions:**

1. **Check user ownership of workspace:**
   ```bash
   ls -la /workspace
   # Should show owner as 'node' (UID 1000)
   ```

2. **Fix ownership from host:**
   ```bash
   sudo chown -R 1000:1000 /path/to/your/project
   ```

3. **For sudo issues, check sudoers configuration:**
   ```bash
   sudo cat /etc/sudoers.d/node-firewall
   # Should show: node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh
   ```

## Network Issues

### Can't reach external sites

**Symptoms:**
- `curl https://google.com` fails
- `npm install` can't reach registry
- `git clone` fails

**Diagnosis:**

1. **Check firewall mode:**
   ```bash
   echo $FIREWALL_MODE
   # Should show: strict or permissive
   ```

2. **Test basic connectivity:**
   ```bash
   # Should work (DNS)
   nslookup google.com

   # May fail in strict mode (blocked)
   curl https://google.com

   # Should work (whitelisted)
   curl https://api.github.com/zen
   ```

**Solutions:**

1. **For strict mode, add domain to whitelist:**

   Edit `.devcontainer/init-firewall.sh`:
   ```bash
   ALLOWED_DOMAINS=(
     "github.com"
     "your-blocked-domain.com"  # Add here
   )
   ```

   Restart firewall:
   ```bash
   sudo /usr/local/bin/init-firewall.sh
   ```

2. **Switch to permissive mode temporarily:**
   ```bash
   export FIREWALL_MODE=permissive
   sudo /usr/local/bin/init-firewall.sh
   ```

3. **Check iptables rules:**
   ```bash
   sudo iptables -L OUTPUT -v -n
   # Should show DROP or REJECT as default policy in strict mode
   ```

### DNS resolution fails

**Symptoms:**
- `ping google.com` says "unknown host"
- Can ping IPs but not domain names

**Solutions:**

1. **Check DNS configuration:**
   ```bash
   cat /etc/resolv.conf
   # Should show: nameserver 127.0.0.11 (Docker DNS)
   ```

2. **Test DNS directly:**
   ```bash
   nslookup google.com 8.8.8.8
   ```

3. **Restart Docker DNS:**
   ```bash
   # From host machine
   docker compose down
   docker compose up -d
   ```

### Docker network not found

**Symptoms:**
- Container startup fails with "network not found"
- Error: "network my-project-network not found"

**Solutions:**

1. **Start docker-compose services first:**
   ```bash
   docker compose up -d
   # This creates the network
   ```

2. **Check network exists:**
   ```bash
   docker network ls | grep my-project-network
   ```

3. **Verify network name matches:**

   In `docker-compose.yml`:
   ```yaml
   networks:
     default:
       name: my-project-network  # Note this name
   ```

   In `.devcontainer/devcontainer.json`:
   ```json
   "runArgs": [
     "--network=my-project-network"  # Must match above
   ]
   ```

## Service Connectivity

### Can't connect to postgres/redis/etc.

**Symptoms:**
- Connection refused on port 5432, 6379, etc.
- "No route to host" errors

**Diagnosis:**

1. **Check service is running:**
   ```bash
   docker compose ps
   # All services should show "Up" and "healthy"
   ```

2. **Check service logs:**
   ```bash
   docker compose logs postgres
   docker compose logs redis
   ```

3. **Test connectivity from DevContainer:**
   ```bash
   # PostgreSQL
   psql postgresql://user:pass@postgres:5432/db

   # Redis
   redis-cli -h redis ping

   # Generic TCP test
   nc -zv postgres 5432
   ```

**Solutions:**

1. **Use service names, not localhost:**

   ❌ Wrong:
   ```
   DATABASE_URL=postgresql://user:pass@localhost:5432/db
   ```

   ✅ Correct:
   ```
   DATABASE_URL=postgresql://user:pass@postgres:5432/db
   ```

2. **Restart services:**
   ```bash
   docker compose down
   docker compose up -d
   ```

3. **Check containers are on same network:**
   ```bash
   docker inspect <devcontainer-name> | grep NetworkMode
   docker inspect <postgres-container-name> | grep Networks -A 5
   # Both should show same network name
   ```

### Service health checks fail

**Symptoms:**
- Container shows "unhealthy" status
- Service appears running but connections fail

**Solutions:**

1. **Check health check command:**
   ```yaml
   healthcheck:
     test: ["CMD-SHELL", "pg_isready -U myuser -d mydb"]
   ```
   Ensure username and database match your configuration.

2. **Test health check manually:**
   ```bash
   docker exec my-project-postgres pg_isready -U myuser -d mydb
   ```

3. **Increase health check timeout:**
   ```yaml
   healthcheck:
     timeout: 10s  # Increase from 5s
     retries: 10   # Increase from 5
   ```

## Firewall Issues

### Firewall script fails to run

**Symptoms:**
- Container starts but firewall not configured
- Error in postStartCommand

**Solutions:**

1. **Check script permissions:**
   ```bash
   ls -la /usr/local/bin/init-firewall.sh
   # Should be executable (rwxr-xr-x)
   ```

2. **Check sudo access:**
   ```bash
   sudo -l
   # Should show: /usr/local/bin/init-firewall.sh
   ```

3. **Run manually to see error:**
   ```bash
   sudo /usr/local/bin/init-firewall.sh
   ```

4. **Check required tools are installed:**
   ```bash
   which iptables ipset dig curl jq
   # All should return paths
   ```

### Firewall blocks legitimate traffic

**Symptoms:**
- npm install fails on strict mode
- Can't reach package registries
- git operations fail

**Solutions:**

1. **Check what's being blocked:**
   ```bash
   # In another terminal, watch iptables
   sudo iptables -L OUTPUT -v -n --line-numbers

   # Try your operation, see which rule blocks it
   npm install
   ```

2. **Add missing domains:**

   Common domains to whitelist:
   ```bash
   ALLOWED_DOMAINS=(
     # Existing domains...

     # Python
     "pypi.org"
     "files.pythonhosted.org"

     # Node.js
     "registry.npmjs.org"

     # Rust
     "crates.io"

     # Ruby
     "rubygems.org"
   )
   ```

3. **Temporarily disable firewall:**
   ```bash
   export FIREWALL_MODE=permissive
   sudo /usr/local/bin/init-firewall.sh
   ```

## Performance Issues

### Container is slow

**Symptoms:**
- File operations are laggy
- Build times are very long
- IDE feels sluggish

**Solutions:**

1. **Check Docker resource allocation:**

   Docker Desktop → Settings → Resources:
   - CPU: At least 4 cores
   - Memory: At least 8 GB
   - Disk: At least 60 GB

2. **Use delegated consistency for bind mounts:**

   In `.devcontainer/devcontainer.json`:
   ```json
   "workspaceMount": "source=${localWorkspaceFolder},target=/workspace,type=bind,consistency=delegated"
   ```

3. **Exclude node_modules from sync (if using Docker Desktop):**

   Use volumes for large dependency directories:
   ```yaml
   volumes:
     - ./frontend:/app
     - /app/node_modules  # Don't sync this
   ```

4. **Pre-install dependencies in Dockerfile:**

   Reduces startup time:
   ```dockerfile
   COPY package*.json ./
   RUN npm ci
   ```

### Database queries are slow

**Solutions:**

1. **Use volume mounts for database data:**
   ```yaml
   volumes:
     - postgres_data:/var/lib/postgresql/data
   # Not: - ./data:/var/lib/postgresql/data
   ```

2. **Increase database resources:**
   ```yaml
   postgres:
     deploy:
       resources:
         limits:
           cpus: '2'
           memory: 2G
   ```

## VS Code Issues

### Extensions not working

**Symptoms:**
- Extensions show as "Not installed"
- ESLint, Prettier don't activate

**Solutions:**

1. **Rebuild container:**
   ```
   Ctrl+Shift+P → "Dev Containers: Rebuild Container"
   ```

2. **Check extensions are in devcontainer.json:**
   ```json
   "customizations": {
     "vscode": {
       "extensions": [
         "anthropic.claude-code",
         "dbaeumer.vscode-eslint"
       ]
     }
   }
   ```

3. **Install extensions manually:**
   ```
   Ctrl+Shift+P → "Extensions: Install Extensions"
   ```

### "Cannot connect to Docker" in VS Code

**Solutions:**

1. **Ensure Docker is running:**
   ```bash
   docker ps
   ```

2. **Restart VS Code and Docker:**
   ```
   Close VS Code → Restart Docker Desktop → Reopen VS Code
   ```

3. **Check Dev Containers extension is installed:**
   ```
   Extensions → Search "Dev Containers" → Install
   ```

## Claude Code Issues

### Claude Code CLI not found

**Symptoms:**
- `claude` command not available
- "command not found: claude"

**Solutions:**

1. **Check installation:**
   ```bash
   which claude
   # Should show: /usr/local/share/npm-global/bin/claude
   ```

2. **Check PATH includes npm global bin:**
   ```bash
   echo $PATH | grep npm-global
   ```

3. **Reinstall Claude Code:**
   ```bash
   npm install -g @anthropic-ai/claude-code
   ```

### Claude Code can't reach Anthropic API

**Symptoms:**
- Error: "Failed to connect to api.anthropic.com"
- Timeout errors

**Solutions:**

1. **Add to firewall whitelist:**

   In `init-firewall.sh`:
   ```bash
   ALLOWED_DOMAINS=(
     "api.anthropic.com"  # Should already be here
   )
   ```

2. **Check API key is set:**
   ```bash
   claude auth status
   ```

3. **Test API connectivity:**
   ```bash
   curl https://api.anthropic.com/v1/messages \
     -H "x-api-key: $ANTHROPIC_API_KEY" \
     -H "anthropic-version: 2023-06-01"
   ```

## Getting More Help

### Enable verbose logging

**Docker:**
```bash
docker compose up  # Without -d flag
```

**DevContainer:**
```
Ctrl+Shift+P → "Dev Containers: Show Container Log"
```

**Firewall:**
```bash
# Run with debugging
bash -x /usr/local/bin/init-firewall.sh
```

### Collect diagnostic information

```bash
# System info
docker version
docker compose version
uname -a

# Container info
docker ps -a
docker network ls
docker volume ls

# Network connectivity
ip addr
ip route
sudo iptables -L -v -n
```

### Reset everything

**Nuclear option - deletes all data:**

```bash
# Stop and remove containers
docker compose down -v

# Remove DevContainer
# Ctrl+Shift+P → "Dev Containers: Clean Up Dev Containers"

# Prune Docker system
docker system prune -a --volumes

# Rebuild from scratch
docker compose up -d
# Ctrl+Shift+P → "Dev Containers: Rebuild Container Without Cache"
```

## Still having issues?

1. Check the [examples](../../../examples/) for working configurations
2. Review [customization.md](customization.md) for configuration tips
3. Check [security.md](security.md) for firewall behavior
4. Search existing GitHub issues
5. Open a new issue with:
   - Operating system and version
   - Docker version (`docker version`)
   - Full error message
   - Steps to reproduce
   - Diagnostic information (see above)

---

**Last Updated:** 2025-12-16
**Version:** 3.0.0
