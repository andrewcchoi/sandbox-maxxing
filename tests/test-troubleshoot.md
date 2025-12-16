# Test: Troubleshooting Assistant

## Prerequisites
- [ ] Docker Desktop running
- [ ] Existing sandbox project with intentional issues
- [ ] Plugin installed

## Test Steps

### 1. Create Test Project with Issues
```bash
mkdir -p D:\!wip\test-sandbox-trouble
cd D:\!wip\test-sandbox-trouble

# Create basic Python project
echo "print('test')" > main.py
echo "fastapi" > requirements.txt
```

### 2. Set Up Sandbox (Basic Mode)
```bash
claude
```

Type: `/sandbox:setup --basic`

Expected: Sandbox created successfully

### 3. Introduce Network Issue

Edit `.devcontainer/devcontainer.json`:
- Change network to `"--network=wrong-network-name"`

Save and rebuild container.

### 4. Test Network Issue Diagnosis
```bash
claude
```

Type: `/sandbox:troubleshoot`

Tell Claude: "Container won't connect to postgres"

Expected:
- Runs diagnostic commands (`docker compose ps`, `docker inspect`)
- Identifies network mismatch issue
- Explains that devcontainer and compose networks must match
- Provides fix: update network name in devcontainer.json

### 5. Apply Fix and Verify

Apply the suggested fix.

Expected: Network connectivity restored

### 6. Introduce Service Connectivity Issue

Create test connection script:
```python
# test_db.py
import psycopg2
conn = psycopg2.connect("postgresql://user:pass@localhost:5432/db")
```

Run it - should fail.

### 7. Test Service Connectivity Diagnosis
```bash
claude
```

Type: `/sandbox:troubleshoot`

Tell Claude: "Getting connection refused from postgres"

Expected:
- Identifies `localhost` vs service name issue
- Explains Docker networking (use service name not localhost)
- Provides correct connection string: `postgres:5432` not `localhost:5432`

### 8. Introduce Firewall Issue

In strict firewall mode, try:
```bash
npm install some-package
```

Expected: Should fail if npm registry not whitelisted

### 9. Test Firewall Issue Diagnosis
```bash
claude
```

Type: `/sandbox:troubleshoot`

Tell Claude: "npm install fails with connection timeout"

Expected:
- Checks firewall mode (`echo $FIREWALL_MODE`)
- Identifies blocked domain (registry.npmjs.org)
- Shows how to add to whitelist in `init-firewall.sh`
- Provides restart command: `sudo /usr/local/bin/init-firewall.sh`

### 10. Verify Fixes Work

Apply all suggested fixes and verify:
- Network connectivity works
- Service connections use correct hostnames
- Firewall allows necessary domains

## Cleanup
```bash
docker compose down -v
cd ..
rm -rf D:\!wip\test-sandbox-trouble
```

## Test Results

Document:
- ✅ Network issue diagnosed correctly
- ✅ Service connectivity issue diagnosed correctly
- ✅ Firewall issue diagnosed correctly
- ✅ Fixes provided were accurate
- ✅ All issues resolved after applying fixes
