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

---

**Next:** [VS Code DevContainer Problems](vscode.md) | [Back to Main](../TROUBLESHOOTING.md)
