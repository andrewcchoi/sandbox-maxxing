# Test: Setup Pro Mode

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
mkdir -p D:\!wip\test-sandbox-pro
cd D:\!wip\test-sandbox-pro
mkdir backend frontend
echo "print('backend')" > backend/main.py
echo '{"name": "frontend"}' > frontend/package.json
```

Expected: Fullstack project structure created

### 3. Invoke Pro Setup
```bash
claude
```

Then type: `/sandbox:setup --pro`

Expected:
- Step-by-step wizard
- Detailed explanations for each setting
- Educational content about security
- 10-15+ questions with explanations

### 4. Complete Pro Wizard

Answer questions with attention to:
- Security explanations
- Best practice guidance
- Architecture trade-offs

Expected educational content:
- Explanation of network name importance
- Firewall security model explained
- Docker layer caching explained
- Health check importance explained

### 5. Verify Generated Files
```bash
ls -la .devcontainer/
cat .devcontainer/Dockerfile
cat docker-compose.yml
cat .devcontainer/init-firewall.sh
```

Expected:
- All 4 files exist
- Technology-specific Dockerfile (not generic)
- Optimized for chosen stack
- Security hardened configuration

### 6. Verify Optimized Configs

Check for:
- Appropriate base image for stack
- Health checks on all services
- Strict firewall configuration
- Non-root user setup
- Minimal allowed domains

### 7. Start Services
```bash
docker compose up -d
docker compose ps
```

Expected: All services (backend, frontend, DB) start healthy

### 8. Open in DevContainer
From VS Code:
- Open D:\!wip\test-sandbox-pro
- Ctrl+Shift+P → "Dev Containers: Reopen in Container"

Expected:
- Container builds successfully
- Optimized for fullstack development
- All services accessible

### 9. Test Full Stack
Inside container:
```bash
# Test PostgreSQL
pg_isready -h postgres

# Test Redis
redis-cli -h redis ping

# Verify Claude Code CLI
claude --version

# Check firewall is active
sudo iptables -L OUTPUT -v -n
```

Expected:
- All services responding
- Firewall configured in strict mode
- Development tools available

## Cleanup
```bash
docker compose down -v
cd ..
rm -rf D:\!wip\test-sandbox-pro
```
