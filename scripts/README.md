# Documentation Validation Scripts

This directory contains automation scripts for validating documentation consistency and integrity in the sandboxxer plugin.

## Quick Start

Run the master health check to validate all documentation:

```bash
bash scripts/doc-health-check.sh
```

Expected output:
```
🎉 EXCELLENT: All documentation health checks passed!
```

## Available Scripts

### Master Orchestrator

#### `doc-health-check.sh`
**Purpose:** Runs all documentation validation checks and provides comprehensive health report.

**Usage:**
```bash
bash scripts/doc-health-check.sh
```

**Exit Codes:**
- `0` - All checks passed
- `1` - Critical errors found

**What it checks:**
- Version consistency across all manifests
- Diagram source file integrity
- Optional internal link validation

---

### Individual Validation Scripts

#### `version-checker.sh`
**Purpose:** Validates version consistency across plugin manifests and documentation.

**Checks:**
- `.claude-plugin/plugin.json` version
- `.claude-plugin/marketplace.json` version
- `README.md` version badge
- `CHANGELOG.md` latest entry

**Usage:**
```bash
bash scripts/version-checker.sh
```

**Example Output:**
```
=== Version Consistency Check ===

plugin.json:       4.13.4
marketplace.json:  4.13.4
README.md badge:   4.13.4
CHANGELOG.md:      4.13.4

✅ All critical version references are consistent
```

**Common Issues:**
- **Version mismatch:** Update all references to match `plugin.json` (the source of truth)
- **Missing version:** Ensure all files have valid version fields

---

#### `diagram-inventory.sh`
**Purpose:** Ensures all diagram source files (.mmd) exist with corresponding SVG outputs.

**Checks:**
- All `.mmd` files in `docs/diagrams/` have `.svg` files in `docs/diagrams/svg/`
- No orphaned SVG files without source files

**Usage:**
```bash
bash scripts/diagram-inventory.sh
```

**Example Output:**
```
=== Diagram Inventory Check ===

Mermaid source files (.mmd): 12
SVG output files (.svg):     12

Checking .mmd → .svg pairs...
✅ plugin-architecture.mmd → plugin-architecture.svg
[... 11 more ...]

✅ All diagrams have source files and outputs
```

**Common Issues:**
- **Missing SVG:** Regenerate using `bash scripts/regenerate-diagrams.sh` or mermaid.live
- **Missing .mmd:** CRITICAL - diagram cannot be edited, must recreate source

**Regeneration:** Use `bash scripts/regenerate-diagrams.sh` to regenerate all SVGs from sources.

---

#### `regenerate-diagrams.sh`
**Purpose:** Regenerates all SVG diagrams from Mermaid source files (.mmd).

**Requirements:**
- Node.js with npx (for mermaid-cli)
- Internet connection (downloads mermaid-cli on demand)

**Usage:**
```bash
bash scripts/regenerate-diagrams.sh
```

**Example Output:**
```
═══════════════════════════════════════════════════════════════
              Diagram Regeneration Utility
═══════════════════════════════════════════════════════════════

Found 12 Mermaid diagram(s) to regenerate

Processing: plugin-architecture.mmd → svg/plugin-architecture.svg
✅ Success: svg/plugin-architecture.svg (27K)
[... 11 more ...]

🎉 SUCCESS: All diagrams regenerated successfully!
```

**When to use:**
- After editing any .mmd file in `docs/diagrams/`
- When SVGs are outdated or missing
- After diagram count or architecture changes

**Note:** This script uses `npx` to run mermaid-cli, which may take longer on first run as it downloads dependencies.

---

#### `link-checker.sh`
**Purpose:** Validates internal markdown links across documentation.

**Status:** ⚠️ Optional - May report false positives for complex relative paths

**Usage:**
```bash
bash scripts/link-checker.sh
```

**Note:** This script checks for broken internal links but may have false positives due to:
- Complex relative path resolution
- Context-dependent links
- Anchor links to sections

Manual verification recommended for reported issues.

---

## Integration

### Pre-commit Hook

Add to `.git/hooks/pre-commit`:

```bash
#!/usr/bin/env bash
echo "Running documentation health check..."
bash scripts/doc-health-check.sh || exit 1
```

**Note:** This is optional and not enforced globally.

### CI/CD Integration

Example GitHub Actions workflow:

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

## Troubleshooting

### Script Permission Errors

If scripts aren't executable:
```bash
chmod +x scripts/*.sh
```

### jq Command Not Found

Install jq:
- **Ubuntu/Debian:** `sudo apt-get install jq`
- **macOS:** `brew install jq`
- **Windows (WSL):** `sudo apt-get install jq`

### False Positive Links

The link checker may report broken links that are actually valid. This happens when:
- Links use relative paths from different document locations
- Links reference generated files
- Links use anchor syntax

Manually verify reported broken links before fixing.

## Development

### Adding New Validation Checks

1. Create a new script in `scripts/` (e.g., `scripts/my-check.sh`)
2. Follow the existing script patterns:
   - Use `#!/usr/bin/env bash` shebang
   - Output clear messages with ✅/❌/⚠️ indicators
   - Exit with code 0 (success) or 1 (failure)
3. Add the check to `doc-health-check.sh`:
   ```bash
   run_check "My Check Description" "$SCRIPT_DIR/my-check.sh" || true
   ```

### Script Conventions

All scripts follow these conventions:

1. **Portable Shebang:** `#!/usr/bin/env bash`
2. **Strict Mode:** `set -euo pipefail`
3. **Color-Coded Output:** Use ✅ (pass), ❌ (fail), ⚠️ (warning)
4. **Clear Error Messages:** Include fix guidance in output
5. **Exit Codes:** 0 = success, 1 = errors, 2+ = warnings

## Related Documentation

- [CONTRIBUTING.md](../CONTRIBUTING.md) - Contribution guidelines with validation section
- [docs/TESTING.md](../docs/TESTING.md) - Comprehensive testing documentation
- [docs/diagrams/README.md](../docs/diagrams/README.md) - Diagram documentation with preservation warning

## Version

These scripts were added in sandboxxer v4.13.1 as part of ULTRATHINK audit implementation.

**Last Updated:** 2026-02-07
