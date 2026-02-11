# Nuclear Option: Reset Everything

Complete Docker environment reset when nothing else works.

**See also:** [Main Troubleshooting Guide](../TROUBLESHOOTING.md) | [Container Issues](container.md)

---

## Complete Reset Procedure

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

---

**Next:** [Windows-Specific Issues](windows.md) | [Back to Main](../TROUBLESHOOTING.md)
