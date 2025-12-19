# Exit Codes Reference

**Last Updated:** 2025-12-18
**Version:** 2.2.2

This document describes the exit codes used by all repo-keeper validation scripts.

## Standard Exit Codes

All validation scripts follow this standard:

| Exit Code | Meaning | Description |
|-----------|---------|-------------|
| `0` | Success | All checks passed, no errors found |
| `1` | Failure | One or more checks failed, errors found |
| `127` | Command Not Found | Missing required dependency or tool |
| `128` | Invalid Argument | Script received invalid or unknown argument |

## Script-Specific Exit Codes

### check-version-sync.sh / check-version-sync.ps1

| Exit Code | Condition |
|-----------|-----------|
| `0` | All versions match plugin.json |
| `1` | Version mismatches found OR invalid semver format |

**Example Output:**
```
✗ Version sync check failed!
Errors: 3
```

### check-links.sh / check-links.ps1

| Exit Code | Condition |
|-----------|-----------|
| `0` | All internal links valid |
| `1` | Broken links found |

**Note:** Broken anchors and missing images are warnings only (don't cause exit code 1)

### validate-inventory.sh / validate-inventory.ps1

| Exit Code | Condition |
|-----------|-----------|
| `0` | Inventory matches filesystem, no missing paths |
| `1` | Missing paths found in inventory |

**Note:** Warnings for future timestamps don't cause failure

### validate-relationships.sh / validate-relationships.ps1

| Exit Code | Condition |
|-----------|-----------|
| `0` | All relationships valid (skills ↔ commands ↔ templates) |
| `1` | Broken relationships found |

### validate-schemas.sh / validate-schemas.ps1

| Exit Code | Condition |
|-----------|-----------|
| `0` | All JSON files pass schema validation |
| `1` | Schema validation failures |

**Note:** Missing schemas generate warnings, not failures

### validate-completeness.sh / validate-completeness.ps1

| Exit Code | Condition |
|-----------|-----------|
| `0` | All features documented, all modes complete |
| `1` | Missing documentation or incomplete modes |

### validate-content.sh / validate-content.ps1

| Exit Code | Condition |
|-----------|-----------|
| `0` | Content checks passed (may have warnings) |
| `1` | Content errors found (missing required sections) |

**Note:** UTF-8 BOM, code block syntax, and YAML frontmatter issues are warnings only

### validate-templates.sh

| Exit Code | Condition |
|-----------|-----------|
| `0` | Template variable syntax valid (may have warnings) |
| `1` | Invalid JSON in variables files |

**Note:** Variable syntax issues generate warnings, not failures

### validate-dockerfiles.sh

| Exit Code | Condition |
|-----------|-----------|
| `0` | Dockerfiles valid (may have warnings) |
| `1` | Dockerfile errors (missing FROM, invalid instructions) |

**Note:** MAINTAINER deprecation and ADD usage are warnings only

### validate-compose.sh

| Exit Code | Condition |
|-----------|-----------|
| `0` | Docker compose files valid (may have warnings) |
| `1` | YAML syntax errors or missing required keys |

**Note:** Unknown top-level keys and missing service properties are warnings only

### check-permissions.sh

| Exit Code | Condition |
|-----------|-----------|
| `0` | Always succeeds (warnings for non-executable scripts) |

**Note:** Permission issues generate warnings, never failures

### run-all-checks.sh / run-all-checks.ps1

| Exit Code | Condition |
|-----------|-----------|
| `0` | All enabled checks passed |
| `1+` | Number of failed checks |

**Example:** If 3 checks fail, exit code is `3`

## Testing Exit Codes

### test-runner.sh

| Exit Code | Condition |
|-----------|-----------|
| `0` | All test suites passed |
| `1` | One or more test suites failed |

## Interpreting Exit Codes in CI/CD

### GitHub Actions Usage

```yaml
- name: Run validation
  run: ./docs/repo-keeper/scripts/run-all-checks.sh
  continue-on-error: false  # Fail the job on non-zero exit code
```

### Exit Code Handling in Scripts

```bash
# Check if script succeeded
if ./docs/repo-keeper/scripts/check-version-sync.sh; then
    echo "Version sync passed"
else
    echo "Version sync failed with exit code $?"
    exit 1
fi

# Store exit code for analysis
./docs/repo-keeper/scripts/check-links.sh
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
    echo "Link check failed with code $EXIT_CODE"
fi
```

### PowerShell Exit Code Handling

```powershell
# Check if script succeeded
if (.\docs\repo-keeper\scripts\check-version-sync.ps1) {
    Write-Host "Version sync passed"
} else {
    Write-Host "Version sync failed with exit code $LASTEXITCODE"
    exit 1
}

# Store exit code
.\docs\repo-keeper\scripts\check-links.ps1
$exitCode = $LASTEXITCODE
if ($exitCode -ne 0) {
    Write-Host "Link check failed with code $exitCode"
}
```

## Exit Code Patterns

### Errors vs Warnings

**Errors (exit code 1):**
- Version mismatches
- Broken links (internal only)
- Missing files referenced in inventory
- Invalid JSON syntax
- Missing required documentation
- Missing required content sections

**Warnings (exit code 0):**
- UTF-8 BOM detected
- Deprecated Docker instructions
- Unknown code block languages
- Future timestamps
- Broken anchor links
- Missing images
- Unknown template variables
- Non-executable scripts

### Quick Reference

| Want to... | Check exit code... |
|------------|-------------------|
| Fail CI on broken links | `check-links.sh` exit code |
| Fail CI on version mismatch | `check-version-sync.sh` exit code |
| Allow warnings but fail on errors | All scripts (warnings don't affect exit code) |
| Count failed checks | `run-all-checks.sh` exit code (count) |

## Troubleshooting Exit Codes

### Exit Code 127 (Command Not Found)

**Cause:** Missing dependency (Node.js, ajv-cli, etc.)

**Solution:**
```bash
# Check Node.js
node --version

# Install ajv-cli if missing
npm install -g ajv-cli ajv-formats
```

### Exit Code 128 (Invalid Argument)

**Cause:** Unknown command-line argument

**Solution:** Check script usage with `--help` or review script documentation

### Exit Code 1 (Multiple Possible Causes)

**Solution:** Review script output for specific error messages. Each validation script provides detailed error reports showing:
- File paths with issues
- Line numbers where applicable
- Expected vs actual values
- Suggested fixes

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 2.2.1 | 2025-12-18 | Added documentation for new P4 scripts (V10-V15, T1-T2) |
| 2.2.0 | 2025-12-17 | Added P2 High Priority scripts (Node.js migration) |
| 2.1.0 | 2025-12-16 | Initial P1 Critical implementation |

---

**Related Documentation:**
- [ERROR_RECOVERY.md](./ERROR_RECOVERY.md) - Handling validation failures
- [README.md](./README.md) - Main documentation
- [schemas/README.md](./schemas/README.md) - Schema documentation
