# VS Code DevContainer Problems

Extension loading, connection issues, and port forwarding in VS Code DevContainers.

**See also:** [Main Troubleshooting Guide](../TROUBLESHOOTING.md) | [Container Issues](container.md) | [Performance Issues](performance.md)

---

## Extension Not Loading

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

## Container Keeps Disconnecting

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

## Port Forwarding Not Working

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

---

**Next:** [Performance Issues](performance.md) | [Back to Main](../TROUBLESHOOTING.md)
