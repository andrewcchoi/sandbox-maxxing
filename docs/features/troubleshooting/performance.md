# Performance Issues

Slow container performance and high resource usage.

**See also:** [Main Troubleshooting Guide](../TROUBLESHOOTING.md) | [Container Issues](container.md) | [VS Code DevContainer Problems](vscode.md)

---

## Slow Container Performance

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

## High CPU/Memory Usage

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

---

**Next:** [Git Worktree Issues](worktrees.md) | [Back to Main](../TROUBLESHOOTING.md)
