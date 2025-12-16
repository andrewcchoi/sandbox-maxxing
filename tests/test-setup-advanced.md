# Test: Setup Advanced Mode

## Prerequisites
- [ ] Docker Desktop running
- [ ] Fresh test directory created
- [ ] No existing `.devcontainer/` directory

## Test Steps

### 1. Install Plugin Locally
```bash
cd D:\!wip\plugins-sandbox\windows-sandbox
claude plugins add .
```

Expected: Plugin installed successfully

### 2. Create Test Project
```bash
mkdir -p D:\!wip\test-sandbox-advanced
cd D:\!wip\test-sandbox-advanced
echo '{"name": "test-app", "version": "1.0.0"}' > package.json
echo 'console.log("Hello");' > index.js
```

Expected: Node.js project created

### 3. Invoke Advanced Setup
```bash
claude
```

Then type: `/sandbox:setup --advanced`

Expected:
- Asks 5-7 customization questions
- Explains trade-offs for each choice
- Generates optimized config

### 4. Answer Wizard Questions

During wizard, select:
1. **Language**: Node.js
2. **Database**: MongoDB
3. **Cache**: Redis
4. **AI Integration**: No
5. **Firewall**: Strict
6. **Network name**: (accept default)

Expected: Claude generates configs based on answers

### 5. Verify Generated Files
```bash
ls -la .devcontainer/
cat docker-compose.yml
```

Expected:
- All 4 files exist (.devcontainer/*, docker-compose.yml)
- MongoDB service configured
- Redis service configured
- Firewall mode is strict

### 6. Verify Customization Applied
```bash
cat docker-compose.yml | grep mongodb
cat docker-compose.yml | grep redis
cat .devcontainer/devcontainer.json | grep "strict"
```

Expected:
- MongoDB service present
- Redis service present
- Firewall mode set to strict

### 7. Start Services
```bash
docker compose up -d
docker compose ps
```

Expected:
- mongodb: healthy
- redis: healthy

### 8. Open in DevContainer
From VS Code:
- Open D:\!wip\test-sandbox-advanced
- Ctrl+Shift+P → "Dev Containers: Reopen in Container"

Expected:
- Container builds successfully
- Services accessible

### 9. Test Connectivity
Inside container:
```bash
# Test MongoDB (requires mongosh installed)
mongosh mongodb://admin:devpassword@mongodb:27017/

# Test Redis
redis-cli -h redis ping
```

Expected: Both connections work

## Cleanup
```bash
docker compose down -v
cd ..
rm -rf D:\!wip\test-sandbox-advanced
```
