# Permission Errors

File ownership and permission problems between host and container.

**See also:** [Main Troubleshooting Guide](../TROUBLESHOOTING.md) | [Container Issues](container.md)

---

## "Permission denied" Errors

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

## Wrong File Owner, "dubious ownership", or "I have no name!"

**Symptoms:**
```
fatal: detected dubious ownership in repository at '/workspace'
I have no name!@container:/workspace$
# Files created in the container show up on the host owned by another user
```

**Cause:** The container user's UID/GID doesn't match your host user. This happens on hosts where your UID isn't 1000 (macOS uses 501:20; many enterprise Linux hosts use other values), especially with plain `docker compose up` outside VS Code.

**Solution:** Since #377, setup writes your host IDs to `.env` and the image is built with them. For projects created before that, or to fix a mismatch:

1. Check your host IDs: `id -u` and `id -g`
2. Add them to `.env` in the project root:
   ```bash
   CONTAINER_UID=501
   CONTAINER_GID=20
   ```
3. Make sure `docker-compose.yml` passes them as build args (regenerate the project, or add these lines under `app.build.args`):
   ```yaml
   - USER_UID=${CONTAINER_UID:-1000}
   - USER_GID=${CONTAINER_GID:-1000}
   ```
4. Rebuild: `docker compose up --build`, or "Dev Containers: Rebuild Container" in VS Code

**Verify inside the container:** `id` shows your host UID/GID and the name `node`.

**If the build fails with "already used by '<name>'":** your host UID belongs to a system account in the image. Set `CONTAINER_UID=1000` and `CONTAINER_GID=1000` and fix ownership from the host instead (see above).

---

**Next:** [VS Code DevContainer Problems](vscode.md) | [Back to Main](../TROUBLESHOOTING.md)
