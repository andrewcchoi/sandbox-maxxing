---
name: sandbox-troubleshoot
description: Use when user encounters problems with Claude Code Docker sandbox - diagnose and fix container startup failures, network issues, service connectivity, firewall blocking, or permission errors
---

# Sandbox Troubleshooting Assistant

## Overview

Diagnoses and resolves common issues with Claude Code Docker sandbox environments using systematic troubleshooting workflows.

## Usage

This skill is invoked via the `/devcontainer:troubleshoot` command.

**Command:**
```
/devcontainer:troubleshoot
```

The skill will:
1. Ask user to describe the issue
2. Categorize the problem (container, network, service, firewall, etc.)
3. Gather diagnostic information systematically
4. Apply appropriate troubleshooting workflow
5. Provide step-by-step resolution guidance
6. Verify the fix and suggest preventive measures

## When to Use This Skill

Use this skill when:
- Container won't start or build fails
- Can't connect to services (PostgreSQL, Redis, MongoDB, etc.)
- Network connectivity issues
- Firewall blocking legitimate traffic
- Permission denied errors
- VS Code DevContainer problems
- Claude Code CLI not working

Do NOT use this skill when:
- Setting up a new sandbox (use `/devcontainer:quickstart` instead)
- Performing security audit (use `/devcontainer:audit` instead)

## Usage

**Via slash command:**
```
/devcontainer:troubleshoot
```

**Via natural language:**
- "My sandbox won't start"
- "I can't connect to the database"
- "The firewall is blocking my requests"
- "Troubleshoot my sandbox"
- "Fix network connectivity issues"

## Examples

### Example: Container Won't Start

**User:** "My sandbox container won't start"

**Assistant:** "I'll help troubleshoot your container startup issue."

The skill will:
1. Check container logs with `docker logs <container>`
2. Verify Docker daemon status
3. Check for port conflicts
4. Examine resource limits
5. Review Dockerfile for syntax errors
6. Suggest specific fixes based on error messages

### Example: Network Connectivity Issue

**User:** "I can't connect to my database service"

**Assistant:** "Let's diagnose the connectivity issue."

The skill will:
1. Verify service is running (`docker ps`)
2. Check port mappings
3. Test network connectivity between containers
4. Review docker-compose network configuration
5. Check firewall rules (if applicable)
6. Provide step-by-step resolution

## Troubleshooting Workflow

### 1. Identify the Problem Category

Ask user to describe the issue, then categorize:
- **Container Issues**: Won't start, build failures
- **Network Issues**: Can't reach external sites, DNS failures
- **Service Connectivity**: Can't connect to database/redis/etc.
- **Firewall Issues**: Legitimate traffic blocked
- **Performance Issues**: Slow, laggy, resource exhaustion
- **VS Code Issues**: Extensions not working, connection problems
- **Claude Code Issues**: CLI not found, API connection failures

### 2. Gather Diagnostic Information

Run appropriate diagnostic commands:

**Container Issues**:
```bash
docker ps -a
docker compose ps
docker compose logs
docker system df
```

**Network Issues**:
```bash
# Inside container
nslookup google.com
curl https://api.github.com/zen
sudo iptables -L OUTPUT -v -n
echo $FIREWALL_MODE
```

**Service Connectivity**:
```bash
docker compose ps
nc -zv postgres 5432
nc -zv redis 6379
docker inspect <container-name> | grep Networks -A 5
```

### 3. Apply Systematic Fixes

Based on the diagnostic results, apply fixes from the reference documentation (`docs/features/TROUBLESHOOTING.md`).

#### Container Won't Start
1. Check Docker is running: `docker ps`
2. Stop and restart services: `docker compose down && docker compose up -d`
3. Rebuild container: VS Code → "Dev Containers: Rebuild Container Without Cache"
4. Check disk space: `docker system df`

#### Network Connectivity Issues
1. Check firewall mode: `echo $FIREWALL_MODE`
2. If strict mode, verify domain is whitelisted in `init-firewall.sh`
3. Temporarily switch to permissive for testing
4. Restart firewall: `sudo /usr/local/bin/init-firewall.sh`

#### Service Connectivity Problems
1. Verify service is running and healthy: `docker compose ps`
2. Check service logs: `docker compose logs <service-name>`
3. Use service name (not localhost) in connection strings
4. Verify containers are on same network
5. Test with health check command

#### Firewall Blocking Legitimate Traffic
1. Identify blocked domain from error message
2. Add to `ALLOWED_DOMAINS` in `.devcontainer/init-firewall.sh`
3. Restart firewall script
4. Common domains to whitelist:
   - Python: `pypi.org`, `files.pythonhosted.org`
   - Node: `registry.npmjs.org`
   - Rust: `crates.io`

### 4. Verify the Fix

After applying fixes, verify:
- Container starts successfully
- Services are healthy
- Connectivity works
- Original error is resolved

Provide verification commands:
```bash
# Check container status
docker ps

# Check services
docker compose ps

# Test connectivity (inside container)
curl https://api.github.com/zen
psql <connection-string> -c "SELECT 1"
redis-cli -h redis ping
```

## Common Issues Quick Reference

### "Cannot connect to Docker daemon"
**Cause**: Docker not running
**Fix**: Start Docker Desktop or Docker daemon

### "Network not found"
**Cause**: docker-compose services not started first
**Fix**: `docker compose up -d` before opening DevContainer

### "Permission denied"
**Cause**: File ownership mismatch
**Fix**: `sudo chown -R 1000:1000 /path/to/project` from host

### "npm install" or "uv add" fails
**Cause**: Firewall blocking package registries
**Fix**: Temporarily use permissive mode or whitelist domains

### Service shows "unhealthy"
**Cause**: Health check command incorrect or service not ready
**Fix**: Verify health check matches service config, increase timeout

### Can't connect to postgres/redis
**Cause**: Using `localhost` instead of service name
**Fix**: Use `postgres` or `redis` as hostname

## Reset Everything (Last Resort)

If nothing works, provide nuclear option:
```bash
# Stop and remove everything
docker compose down -v

# Clean DevContainer (from VS Code)
# Ctrl+Shift+P → "Dev Containers: Clean Up Dev Containers"

# Prune Docker system
docker system prune -a --volumes

# Start fresh
docker compose up -d
# Ctrl+Shift+P → "Dev Containers: Rebuild Container Without Cache"
```

**Warning**: This deletes all data. Back up important information first.

## Reference Documentation

For detailed troubleshooting steps, refer to `docs/features/TROUBLESHOOTING.md` which contains comprehensive solutions for all common issues.

## Key Principles

- **Systematic approach** - Don't guess, diagnose first
- **One fix at a time** - Test after each change
- **Verify assumptions** - Check actual state, not expected state
- **Document what worked** - Help user understand the fix
- **Explain root cause** - Teach, don't just fix

## Usage Examples

### Example 1: Container Build Failure

User reports container won't start:

```
User: My container won't build. It says "ERROR: failed to solve"
Assistant: I'll help troubleshoot this build failure.
/devcontainer:troubleshoot
```

The skill guides through checking Docker logs, Dockerfile syntax, network connectivity during build, and provides specific fix for the identified issue.

### Example 2: Service Connectivity Issue

User can't connect to PostgreSQL:

```
User: My app can't connect to PostgreSQL. Connection refused on port 5432.
Assistant: I'll diagnose this database connectivity issue.
/devcontainer:troubleshoot
```

The skill checks if PostgreSQL service is running, verifies port mappings, tests connectivity from container, and ensures connection string is correct.

### Example 3: Firewall Blocking Issue

User's API calls are being blocked:

```
User: I'm getting network errors when calling the OpenAI API. It works outside the container.
Assistant: This sounds like a firewall configuration issue. Let me troubleshoot.
/devcontainer:troubleshoot
```

The skill checks firewall mode, reviews allowed domains list, tests connectivity to specific domain, and provides guidance on adding OpenAI domains to allowlist.

---

**Last Updated:** 2025-12-24
**Version:** 4.5.0
