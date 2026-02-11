# Testing Documentation

This document describes the testing approach for the Claude Code sandbox setup project.

## Overview

The project currently uses manual testing procedures for sandbox setup commands. Manual testing ensures that skills generate valid container configurations and work correctly across different scenarios.

## Test Coverage

> **See also:** [TEST-COVERAGE-REPORT.md](TEST-COVERAGE-REPORT.md) - Detailed coverage analysis and recommendations

Manual testing covers:
- ✅ Interactive quickstart setup
- ✅ Non-interactive YOLO docker maxxing setup
- ✅ Native Linux/WSL2 setup
- ✅ Troubleshooting diagnostics (Docker and Linux)
- ✅ Security auditing
- ✅ Template generation
- ✅ Placeholder replacement
- ✅ Docker services
- ✅ Firewall configuration (container isolation and domain allowlist)

## Manual Testing Procedures

### Testing Setup Commands

#### Testing `/sandboxxer:quickstart`

1. Create a test project:
```bash
mkdir -p /tmp/test-quickstart
cd /tmp/test-quickstart
git init
echo '{"name": "test"}' > package.json
```

2. Run the command in Claude Code:
```
/sandboxxer:quickstart
```

3. Verify the setup:
   - Answer project type questions (test with Python/Node, Go, Ruby, etc.)
   - Answer firewall questions (test both with and without domain allowlist)
   - Confirm all files are generated

4. Validate generated files:
```bash
# Check files exist
ls -la .devcontainer/
test -f .devcontainer/devcontainer.json
test -f .devcontainer/docker-compose.yml
test -f .devcontainer/Dockerfile

# Validate JSON syntax
cat .devcontainer/devcontainer.json | jq .

# Validate YAML syntax
docker-compose -f .devcontainer/docker-compose.yml config

# Check firewall script (if enabled)
if [ -f .devcontainer/init-firewall.sh ]; then
    bash -n .devcontainer/init-firewall.sh
fi
```

5. Test container startup:
```bash
# Start DevContainer in VS Code or via CLI
docker-compose -f .devcontainer/docker-compose.yml up -d
docker-compose -f .devcontainer/docker-compose.yml exec app bash -c "echo 'Container is running'"
docker-compose -f .devcontainer/docker-compose.yml down
```

#### Testing `/sandboxxer:yolo-docker-maxxing`

1. Create a test project:
```bash
mkdir -p /tmp/test-yolo-docker
cd /tmp/test-yolo-docker
git init
echo '{"name": "test"}' > package.json
```

2. Run the command in Claude Code:
```
/sandboxxer:yolo-docker-maxxing
```

3. Verify zero-question setup:
   - Command should complete without asking questions
   - Defaults to Python 3.12 + Node 20
   - No firewall enabled

4. Validate files (same validation as quickstart above)

5. Test container startup and verify services:
```bash
docker-compose -f .devcontainer/docker-compose.yml up -d
docker-compose -f .devcontainer/docker-compose.yml exec app bash -c "python3 --version"
docker-compose -f .devcontainer/docker-compose.yml exec app bash -c "node --version"
docker-compose -f .devcontainer/docker-compose.yml down
```

#### Testing `/sandboxxer:yolo-linux-maxxing`

1. Create a test project (on Linux or WSL2):
```bash
mkdir -p /tmp/test-yolo-linux
cd /tmp/test-yolo-linux
git init
```

2. Run the command in Claude Code:
```
/sandboxxer:yolo-linux-maxxing
```

3. Verify installation steps:
   - Claude CLI installation
   - Bubblewrap installation and configuration
   - GitHub CLI setup
   - Authentication checks

4. Test Bubblewrap sandbox:
```bash
bwrap --ro-bind / / --dev /dev --proc /proc --tmpfs /tmp -- echo "Bubblewrap is working!"
```

5. Verify Claude CLI works:
```bash
claude --version
claude --help
```

### Testing Troubleshooting Commands

#### Testing `/sandboxxer:troubleshoot`

1. Set up a project with issues:
```bash
# Create broken configuration
mkdir -p /tmp/test-troubleshoot/.devcontainer
cd /tmp/test-troubleshoot
echo '{"invalid": json}' > .devcontainer/devcontainer.json
```

2. Run troubleshooting:
```
/sandboxxer:troubleshoot
```

3. Verify diagnostics:
   - Command identifies the problem category
   - Runs appropriate diagnostic commands
   - Suggests or applies fixes
   - Verifies resolution

4. Test different problem categories:
   - Container startup failures
   - Network connectivity issues
   - Service connection problems
   - Firewall blocking
   - Permission errors

#### Testing `/sandboxxer:linux-troubleshoot`

1. Test on Linux/WSL2 with various issues:
```bash
# Example: Missing Bubblewrap
which bwrap  # Should fail if not installed
```

2. Run troubleshooting:
```
/sandboxxer:linux-troubleshoot
```

3. Verify it handles:
   - Bubblewrap installation/configuration
   - Claude CLI issues
   - WSL2-specific problems
   - Authentication failures
   - System package problems

### Testing Security Audit

#### Testing `/sandboxxer:audit`

1. Set up a project with various configurations:
```bash
mkdir -p /tmp/test-audit
cd /tmp/test-audit
# Use quickstart or yolo-docker-maxxing to create config
```

2. Run audit:
```
/sandboxxer:audit
```

3. Verify audit checks:
   - Reviews security configuration
   - Audits firewall rules (if present)
   - Checks credential management
   - Validates best practices
   - Provides actionable recommendations

4. Test with different configurations:
   - No firewall (container isolation only)
   - Domain allowlist firewall
   - With/without secrets
   - Different service configurations

## Test Checklist

Use this checklist when testing changes to commands or skills:

### Pre-Release Testing

- [ ] `/sandboxxer:quickstart` with Python/Node project
- [ ] `/sandboxxer:quickstart` with Go project
- [ ] `/sandboxxer:quickstart` with Ruby project
- [ ] `/sandboxxer:quickstart` with firewall enabled
- [ ] `/sandboxxer:quickstart` with firewall disabled
- [ ] `/sandboxxer:yolo-docker-maxxing` basic functionality
- [ ] `/sandboxxer:yolo-linux-maxxing` on Linux/WSL2
- [ ] `/sandboxxer:troubleshoot` with container issues
- [ ] `/sandboxxer:troubleshoot` with network issues
- [ ] `/sandboxxer:linux-troubleshoot` with Bubblewrap issues
- [ ] `/sandboxxer:linux-troubleshoot` with authentication issues
- [ ] `/sandboxxer:audit` with various configurations
- [ ] All generated files have valid syntax (JSON/YAML/shell)
- [ ] Containers start successfully
- [ ] Services connect properly (PostgreSQL, Redis)
- [ ] Firewall allows expected traffic (when enabled)
- [ ] Documentation matches behavior

### Regression Testing

When modifying templates or skills, test:

- [ ] Existing projects still work with new changes
- [ ] No breaking changes to file structure
- [ ] Backward compatibility maintained
- [ ] Version numbers updated appropriately

### Edge Case Testing

- [ ] Empty project directory
- [ ] Existing DevContainer configuration (update scenario)
- [ ] Projects with unusual file structures
- [ ] Multiple services enabled
- [ ] Custom domain allowlists
- [ ] WSL2-specific scenarios
- [ ] Different Linux distributions

## Testing Different Scenarios

### Firewall Configurations

Test both firewall modes:

1. **No Firewall (Container Isolation):**
   - Choose "No" when asked about network restrictions
   - Verify no `init-firewall.sh` is created
   - Confirm container has normal network access

2. **Domain Allowlist Firewall:**
   - Choose "Yes" for network restrictions
   - Select domain categories to allow
   - Verify `init-firewall.sh` is created with correct rules
   - Test that allowed domains work, blocked domains don't

### Service Configurations

Test with different service combinations:

1. **PostgreSQL + Redis (default):**
   - Verify both services start
   - Test connections from app container

2. **Custom Services:**
   - Add additional services to docker-compose.yml
   - Verify all services start and connect

### Project Types

Test each language option:

1. **Python/Node (base only)**
2. **Go** - Verify Go toolchain installed
3. **Ruby** - Verify Ruby and bundler installed
4. **Rust** - Verify Rust toolchain installed
5. **C++ (Clang)** - Verify Clang compiler
6. **C++ (GCC)** - Verify GCC compiler
7. **PHP** - Verify PHP 8.3 installed
8. **PostgreSQL** - Verify psql client tools

## Validation Commands Reference

### File Validation

```bash
# JSON syntax
jq empty file.json

# YAML syntax
python3 -c "import yaml; yaml.safe_load(open('file.yml'))"
docker-compose -f file.yml config

# Shell script syntax
bash -n script.sh

# Check file exists
test -f path/to/file || echo "File missing"
```

### Container Validation

```bash
# Start containers
docker-compose -f .devcontainer/docker-compose.yml up -d

# Check container is running
docker-compose -f .devcontainer/docker-compose.yml ps

# Execute command in container
docker-compose -f .devcontainer/docker-compose.yml exec app bash -c "command"

# Check logs
docker-compose -f .devcontainer/docker-compose.yml logs

# Stop containers
docker-compose -f .devcontainer/docker-compose.yml down
```

### Service Validation

```bash
# PostgreSQL
docker-compose exec app bash -c "psql -h postgres -U postgres -c 'SELECT 1'"

# Redis
docker-compose exec app bash -c "redis-cli -h redis ping"
```

### Firewall Validation

```bash
# Check firewall script exists
test -f .devcontainer/init-firewall.sh

# Validate script syntax
bash -n .devcontainer/init-firewall.sh

# Check iptables rules (inside container)
docker-compose exec app iptables -L -n
```

## Documentation Validation Testing

The plugin includes automated scripts to validate documentation consistency and integrity.

### Running Documentation Health Checks

Execute the master health check script to validate all documentation:

```bash
bash scripts/doc-health-check.sh
```

This performs the following validations:
1. **Version Consistency**: Ensures version numbers match across:
   - `.claude-plugin/plugin.json`
   - `.claude-plugin/marketplace.json`
   - `README.md` version badge
   - `CHANGELOG.md` latest entry

2. **Diagram Inventory**: Validates that all diagrams have source files:
   - All `.mmd` (Mermaid source) files have corresponding `.svg` outputs
   - No orphaned SVG files without source files
   - Checks all 12 diagrams in `docs/diagrams/`

### Individual Validation Scripts

You can run individual checks for specific validations:

#### Version Consistency Check
```bash
bash scripts/version-checker.sh
```
**Purpose:** Detects version mismatches that could confuse users or break releases.

**Expected Output:**
```
=== Version Consistency Check ===

plugin.json:       4.13.3
marketplace.json:  4.13.3
README.md badge:   4.13.3
CHANGELOG.md:      4.13.3

✅ All critical version references are consistent
```

#### Diagram Source Validation
```bash
bash scripts/diagram-inventory.sh
```
**Purpose:** Ensures all diagrams can be regenerated if modified.

**Expected Output:**
```
=== Diagram Inventory Check ===

Mermaid source files (.mmd): 12
SVG output files (.svg):     12

Checking .mmd → .svg pairs...
✅ plugin-architecture.mmd → plugin-architecture.svg
[... 11 more diagrams ...]

✅ All diagrams have source files and outputs
```

#### Internal Link Validation (Optional)
```bash
bash scripts/link-checker.sh
```
**Purpose:** Detects broken internal documentation links.

**Note:** May report false positives for complex relative paths. Manual verification recommended.

### When to Run Documentation Tests

- **Before committing documentation changes**: Catch issues early
- **After version updates**: Ensure all version references are synchronized
- **After adding/removing commands, skills, or agents**: Validate counts and references
- **After modifying diagrams**: Ensure source files are preserved
- **In CI/CD pipelines**: Automate validation for pull requests

### CI/CD Integration

To integrate documentation validation into GitHub Actions:

```yaml
name: Documentation Validation
on: [push, pull_request]

jobs:
  validate-docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install jq
        run: sudo apt-get update && sudo apt-get install -y jq
      - name: Run Documentation Health Check
        run: bash scripts/doc-health-check.sh
```

### Pre-commit Hook (Optional)

For contributors who frequently modify documentation, setting up a pre-commit hook ensures validation runs automatically:

```bash
cat > .git/hooks/pre-commit << 'EOF'
#!/usr/bin/env bash
echo "Running documentation health check..."
bash scripts/doc-health-check.sh || exit 1
EOF

chmod +x .git/hooks/pre-commit
```

**Note:** This is optional and not enforced globally to avoid disrupting development workflows.

## Future: Automated Testing

Automated testing infrastructure is planned for future implementation. The automated test framework would:

- Validate container configurations automatically
- Compare generated files against templates
- Run syntax checks on all generated files
- Test container startup and service connectivity
- Generate accuracy scores and reports
- Support CI/CD integration

When automated testing is implemented, it will complement (not replace) manual testing procedures.

## Debugging Failed Tests

### Common Issues

1. **Invalid JSON/YAML Syntax:**
   - Use `jq` or `docker-compose config` to identify errors
   - Check for missing commas, brackets, or quotes
   - Verify indentation in YAML files

2. **Container Won't Start:**
   - Check `docker-compose logs`
   - Verify Dockerfile syntax
   - Check for missing dependencies
   - Verify service names and ports

3. **Services Not Connecting:**
   - Verify service names match docker-compose.yml
   - Check network configuration
   - Verify ports are exposed correctly
   - Check firewall rules (if enabled)

4. **Firewall Blocking Traffic:**
   - Review allowlist domains
   - Check iptables rules: `docker-compose exec app iptables -L -n`
   - Verify DNS resolution works
   - Test with firewall disabled to isolate issue

### Debugging Process

1. **Identify the Problem:**
   - What command was run?
   - What was expected vs. actual behavior?
   - What error messages appear?

2. **Review Generated Files:**
   - Check all files were created
   - Validate syntax
   - Compare with templates

3. **Test Incrementally:**
   - Test file syntax first
   - Then container build
   - Then container startup
   - Then service connectivity
   - Finally full application

4. **Check Logs:**
   - Docker build logs
   - Container runtime logs
   - VS Code DevContainer logs
   - Claude Code session logs

## Best Practices

### When Adding New Commands

1. Create command following established patterns
2. Test manually with multiple scenarios
3. Document command in README files
4. Add to test checklist above
5. Test with both new and existing projects

### When Modifying Templates

1. Update master templates in `skills/_shared/templates/`
2. Run full test suite manually
3. Test backward compatibility with existing projects
4. Update documentation to reflect changes
5. Test all affected commands

### When Fixing Issues

1. Reproduce the issue manually
2. Identify root cause
3. Apply fix
4. Verify fix with original scenario
5. Test for regressions
6. Document the fix in CHANGELOG.md

## Related Documentation

- [Setup Options Guide](features/SETUP-OPTIONS.md) - Command comparison
- [Troubleshooting Guide](features/TROUBLESHOOTING.md) - Common issues
- [Security Model](features/SECURITY-MODEL.md) - Security architecture
- [Commands README](../commands/README.md) - Command documentation
- [Skills README](../skills/README.md) - Skill documentation

## Support

For testing-related issues:

1. Review this testing documentation
2. Check command-specific documentation
3. Review troubleshooting guides
4. Test in isolation to identify root cause
5. Check recent changes that might have affected behavior
