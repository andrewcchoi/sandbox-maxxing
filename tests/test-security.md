# Test: Security Audit

## Prerequisites
- [ ] Docker Desktop running
- [ ] Existing sandbox project
- [ ] Plugin installed

## Test Steps

### 1. Create Test Project with Security Issues
```bash
mkdir -p D:\!wip\test-sandbox-security
cd D:\!wip\test-sandbox-security

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

### 3. Introduce Security Issues

**Issue 1: Permissive Firewall**
Edit `.devcontainer/devcontainer.json`:
```json
"containerEnv": {
  "FIREWALL_MODE": "permissive"
}
```

**Issue 2: Default Password**
Edit `docker-compose.yml`:
```yaml
environment:
  POSTGRES_PASSWORD: devpassword  # This is already there, should be flagged
```

**Issue 3: Unnecessary Port Exposure**
Edit `docker-compose.yml`:
```yaml
postgres:
  ports:
    - "5432:5432"  # Expose to host (unnecessary for dev)
```

**Issue 4: Root User**
Edit `.devcontainer/Dockerfile`:
Add at end:
```dockerfile
USER root  # Should run as non-root
```

### 4. Run Security Audit
```bash
claude
```

Type: `/sandbox:audit`

Expected: Security scan starts

### 5. Verify Firewall Audit

Expected in report:
```
⚠ Firewall in permissive mode
  Current: FIREWALL_MODE=permissive
  Recommendation: Switch to strict mode for better security
```

### 6. Verify Credentials Audit

Expected in report:
```
⚠ Default password found in docker-compose.yml
  Found: POSTGRES_PASSWORD: devpassword
  Recommendation: Use environment variables or change for production
```

### 7. Verify Port Exposure Audit

Expected in report:
```
⚠ PostgreSQL port exposed to host
  Found: ports: "5432:5432"
  Recommendation: Remove port mapping if not needed from host
  Services can communicate via Docker network without port exposure
```

### 8. Verify User Permissions Audit

Expected in report:
```
⚠ Container running as root user
  Found: USER root in Dockerfile
  Recommendation: Run as non-root user (node, UID 1000)
```

### 9. Verify Security Report Format

Expected sections:
1. **Summary**
   - Overall Risk Level: Medium/High
   - Critical Issues: count
   - Warnings: count

2. **Critical Issues** (if any)

3. **Warnings**
   - List of all issues found

4. **Recommendations**
   - Specific fixes for each issue

5. **Security Checklist**
   - [ ] Firewall configured
   - [ ] No hardcoded credentials
   - [ ] Minimal port exposure
   - [ ] Non-root user
   - etc.

### 10. Apply Recommended Fixes

Follow Claude's recommendations:
- Change firewall to strict mode
- Document why default password is acceptable for dev
- Remove unnecessary port mappings
- Change USER to node

### 11. Re-run Audit
```bash
claude
```

Type: `/sandbox:audit`

Expected:
- Overall Risk Level: Low
- All critical issues resolved
- Only informational warnings remain

## Cleanup
```bash
docker compose down -v
cd ..
rm -rf D:\!wip\test-sandbox-security
```

## Test Results

Document:
- ✅ Firewall audit works
- ✅ Credentials audit works
- ✅ Port exposure audit works
- ✅ User permissions audit works
- ✅ Security report format correct
- ✅ Re-audit shows improvements
