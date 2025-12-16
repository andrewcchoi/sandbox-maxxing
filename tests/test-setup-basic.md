# Test: Setup Basic Mode

## Prerequisites
- [ ] Docker Desktop running
- [ ] Fresh test directory created
- [ ] No existing `.devcontainer/` directory

## Test Steps

### 1. Install Plugin Locally
```bash
cd D:\!wip\plugins-sandbox\claude-code-sandbox-plugin
claude plugins add .
```

Expected: Plugin installed successfully

### 2. Create Test Project
```bash
mkdir -p D:\!wip\test-sandbox-basic
cd D:\!wip\test-sandbox-basic
echo "print('hello')" > main.py
echo "fastapi" > requirements.txt
```

Expected: Python project created

### 3. Invoke Basic Setup
```bash
claude
```

Then type: `/sandbox:setup --basic`

Expected:
- Claude detects Python project
- Auto-selects PostgreSQL and Redis
- Uses strict firewall mode
- Generates 4 files without asking questions

### 4. Verify Generated Files
```bash
ls -la .devcontainer/
cat .devcontainer/devcontainer.json
cat .devcontainer/Dockerfile
cat .devcontainer/init-firewall.sh
cat docker-compose.yml
```

Expected:
- All 4 files exist
- Placeholders replaced with actual values
- Network name is consistent
- Firewall mode is "strict"

### 5. Start Services
```bash
docker compose up -d
```

Expected:
- postgres container starts
- redis container starts
- Both healthy

### 6. Open in DevContainer
From VS Code:
- Open D:\!wip\test-sandbox-basic
- Ctrl+Shift+P → "Dev Containers: Reopen in Container"

Expected:
- Container builds successfully
- Firewall initializes
- VS Code extensions load
- Claude Code CLI available

### 7. Test Connectivity
Inside container:
```bash
# Test PostgreSQL
pg_isready -h postgres

# Test Redis
redis-cli -h redis ping

# Test firewall (should succeed)
curl https://api.anthropic.com

# Test firewall (should fail in strict mode)
curl https://example.com
```

Expected:
- postgres: ready
- redis: PONG
- anthropic.com: success
- example.com: fails (blocked by firewall)

## Cleanup
```bash
docker compose down -v
cd ..
rm -rf D:\!wip\test-sandbox-basic
```
