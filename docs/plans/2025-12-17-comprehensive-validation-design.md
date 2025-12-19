# Comprehensive Repository Validation System Design

**Date:** 2025-12-17
**Status:** Design Complete
**Purpose:** Extend repo-keeper to provide complete validation of repository consistency, documentation, and relationships

---

## Problem Statement

The current repo-keeper system has automation for:
- Version sync checking
- Internal link validation (PowerShell only)
- Inventory vs filesystem validation (PowerShell only)

**Gaps identified:**
1. No completeness check for features → documentation mapping
2. No cross-reference validation (skill ↔ command ↔ template ↔ example relationships)
3. No content validation (required sections, mode consistency, step completeness)
4. No external link checking
5. Missing bash versions of link checker and inventory validator
6. No JSON schema validation for structured data files

---

## Solution: Layered Validation System

### Three-Tier Architecture

**Tier 1: Structural Validation** (Fast, CI-friendly, ~10 seconds)
- Version sync - All version numbers match
- Link integrity - Internal links resolve
- Inventory accuracy - Paths exist on disk
- Relationship validation - Skills reference correct templates, commands invoke correct skills
- Schema validation - JSON files conform to schemas

**Tier 2: Completeness Validation** (Medium, ~30 seconds)
- Feature coverage - Every skill has docs, every command has README entry
- Mode coverage - All 4 modes have complete vertical slices
- Template completeness - Each mode has all 6 template types

**Tier 3: Content Validation** (Thorough, ~2-5 minutes)
- Required sections - Skills/commands have expected sections
- Mode consistency - Documents mention correct mode name
- Step completeness - Numbered steps have no gaps
- External links - Optional deep check of external URLs

---

## Script Organization

```
docs/repo-keeper/scripts/
├── check-version-sync.sh/.ps1     (existing - Tier 1)
├── check-links.sh/.ps1            (add bash - Tier 1)
├── validate-inventory.sh/.ps1     (add bash - Tier 1)
├── validate-relationships.sh/.ps1 (NEW - Tier 1)
├── validate-schemas.sh/.ps1       (NEW - Tier 1)
├── validate-completeness.sh/.ps1  (NEW - Tier 2)
├── validate-content.sh/.ps1       (NEW - Tier 3)
└── run-all-checks.sh/.ps1         (NEW - orchestrator)
```

---

## Component Details

### 1. Relationship Validation (`validate-relationships.sh/.ps1`)

**Purpose:** Verify INVENTORY.json relationships are accurate and bidirectional

**Checks:**
- Skills → Templates: Verify template files exist and contain mode references
- Skills → Commands: Verify command file mentions the skill
- Skills → Examples: Verify example uses correct templates
- Commands → Skills: Verify command's `invokes_skill` exists
- Bidirectional: Check reverse relationships

**Output:**
```
=== Relationship Validation ===

Checking skill → template relationships...
  ✓ sandbox-setup-basic → 6 templates (all exist)
  ✗ sandbox-setup-advanced → templates/firewall/advanced-strict.sh (NOT FOUND)

Checking skill → command relationships...
  ✓ sandbox-setup-basic ↔ commands/basic.md (bidirectional)

Summary: 18 relationships checked, 1 error
```

### 2. Completeness Validation (`validate-completeness.sh/.ps1`)

**Purpose:** Ensure every feature has documentation and all modes have full coverage

**Checks:**

**Feature → Documentation Matrix:**
- Each skill → must have `SKILL.md`
- Each command → must have entry in `commands/README.md`
- Each template category → must have entry in `templates/README.md`
- Each example → must have `README.md`
- Each data file → must have entry in `data/README.md`

**Mode Coverage Matrix (all 4 modes):**
| Component | basic | intermediate | advanced | yolo |
|-----------|-------|--------------|----------|------|
| Skill | ✓ | ✓ | ✓ | ✓ |
| Command | ✓ | ✓ | ✓ | ✓ |
| docker-compose | ✓ | ✓ | ✓ | ✓ |
| Firewall script | ✓ | ✓ | ✓ | ✓ |
| Extensions | ✓ | ✓ | ✓ | ✓ |
| MCP config | ✓ | ✓ | ✓ | ✓ |
| Variables | ✓ | ✓ | ✓ | ✓ |
| Env template | ✓ | ✓ | ✓ | ✓ |
| Example app | ✓ | ✓ | ✓ | ✓ |

**Utility Features:**
- Troubleshoot: skill + command + docs
- Security/Audit: skill + command + docs

**Output:**
```
=== Completeness Validation ===

Feature Documentation:
  ✓ 6/6 skills have SKILL.md
  ✓ 7/7 commands documented in README
  ✗ data/mcp-servers.json missing from data/README.md

Mode Coverage:
  ✓ basic: 9/9 components
  ✓ intermediate: 9/9 components
  ✓ advanced: 9/9 components
  ✓ yolo: 9/9 components

Summary: 1 completeness issue found
```

### 3. Content Validation (`validate-content.sh/.ps1`)

**Purpose:** Check that documents contain expected sections and correct references

**Checks:**

**Required Sections by Document Type:**
- `SKILL.md`: Overview, Usage, Examples, (footer)
- `commands/*.md`: Description, Usage, Arguments (if any), (footer)
- `examples/*/README.md`: Overview, Quick Start, Mode info table
- `templates/*/README.md`: Purpose, Files list, Usage

**Mode Consistency:**
- Mode-specific files must mention their mode (case-insensitive)
- Example: `skills/sandbox-setup-basic/SKILL.md` must contain "basic"

**Step Completeness:**
- Verify numbered steps (1., 2., 3...) have no gaps
- Flag sequences like: 1, 2, 4 (missing 3)

**External Links (optional, slow):**
- Flag with `--check-external`
- HTTP HEAD request to verify URLs respond
- Skip by default for speed

**Output:**
```
=== Content Validation ===

Required Sections:
  ✓ skills/sandbox-setup-basic/SKILL.md has all sections
  ✗ skills/sandbox-security/SKILL.md missing "Examples" section

Mode Consistency:
  ✓ 24/24 files reference correct mode

Step Sequences:
  ✓ No broken step sequences found

Summary: 1 content issue found
```

### 4. Schema Validation (`validate-schemas.sh/.ps1`)

**Purpose:** Validate JSON files against schemas

**New Schema Files:**
- `docs/repo-keeper/schemas/inventory.schema.json` - INVENTORY.json structure
- `docs/repo-keeper/schemas/data-file.schema.json` - Common schema for data/*.json

**Example Schema Structure:**
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["version", "skills", "commands"],
  "properties": {
    "version": {
      "type": "string",
      "pattern": "^\\d+\\.\\d+\\.\\d+$"
    },
    "skills": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["name", "path", "mode"],
        "properties": {
          "mode": {
            "enum": ["basic", "intermediate", "advanced", "yolo", "utility"]
          }
        }
      }
    }
  }
}
```

**Validation Tool:**
- Use `jq` with custom validation logic (bash)
- Use `ConvertFrom-Json` with manual validation (PowerShell)
- Fast validation (< 1 second)

### 5. Orchestrator (`run-all-checks.sh/.ps1`)

**Purpose:** Single command to run all validations

**Usage Patterns:**

```bash
# Quick check (Tier 1 only - ~10 seconds)
./docs/repo-keeper/scripts/run-all-checks.sh --quick

# Standard check (Tier 1 + 2 - ~30 seconds)
./docs/repo-keeper/scripts/run-all-checks.sh

# Full check (All tiers - ~2-5 minutes)
./docs/repo-keeper/scripts/run-all-checks.sh --full
```

**Flags:**
- `--quick` - Tier 1 only
- `--full` - All tiers including content validation and external links
- `--verbose` - Show all checks, not just failures
- `--fix-crlf` - Auto-convert line endings

**Output Format:**
```
=== Repository Validation Suite ===
Version: 2.2.1
Date: 2025-12-17

Running Tier 1: Structural Validation...
  [1/5] Version sync................. ✓ PASS (2 warnings)
  [2/5] Link integrity............... ✓ PASS
  [3/5] Inventory accuracy........... ✓ PASS
  [4/5] Relationship validation...... ✗ FAIL (1 error)
  [5/5] Schema validation............ ✓ PASS

Running Tier 2: Completeness Validation...
  [6/6] Feature coverage............. ✗ FAIL (1 error)

=== Summary ===
Status: FAILED
Errors: 2
Warnings: 2

Details:
  ✗ Relationship: sandbox-setup-advanced → templates/firewall/advanced-strict.sh (NOT FOUND)
  ✗ Completeness: data/mcp-servers.json missing from data/README.md
  ⚠ Version: data/secrets.json version 2.1.0 (expected 2.2.1)
  ⚠ Version: data/variables.json version 2.1.0 (expected 2.2.1)

Exit code: 1 (for CI/CD)
```

### 6. Bash Script Parity

**Port to Bash:**
- `check-links.sh` (from check-links.ps1)
- `validate-inventory.sh` (from validate-inventory.ps1)

**Implementation Notes:**
- Use `jq` for JSON parsing
- Use `grep`, `sed`, `awk` for text processing
- ANSI color codes for output formatting
- Identical output format to PowerShell versions
- Same exit codes (0 = success, 1 = failure)
- Test on Linux, macOS, and WSL

---

## Line Ending Strategy

**Fix existing scripts:**
```bash
# Convert all .sh files from CRLF to LF
dos2unix docs/repo-keeper/scripts/*.sh
# or
sed -i 's/\r$//' docs/repo-keeper/scripts/*.sh
```

**Prevent future issues:**

Add to `.gitattributes`:
```
*.sh text eol=lf
*.ps1 text eol=crlf
*.json text eol=lf
*.md text eol=lf
```

**Pre-commit hook (optional):**
```bash
#!/bin/bash
# .git/hooks/pre-commit
for file in $(git diff --cached --name-only --diff-filter=ACM | grep '\.sh$'); do
  if file "$file" | grep -q CRLF; then
    echo "Error: $file has CRLF line endings"
    exit 1
  fi
done
```

---

## Implementation Plan

### Phase 1: Foundation (New Scripts)
1. Create `validate-relationships.sh/.ps1`
2. Create `validate-completeness.sh/.ps1`
3. Create `validate-content.sh/.ps1`
4. Create `validate-schemas.sh/.ps1`
5. Create `run-all-checks.sh/.ps1`

### Phase 2: Bash Parity
6. Create `check-links.sh` (port from .ps1)
7. Create `validate-inventory.sh` (port from .ps1)
8. Fix line endings on all .sh files
9. Add `.gitattributes` rules

### Phase 3: Schemas
10. Create `schemas/inventory.schema.json`
11. Create `schemas/data-file.schema.json`

### Phase 4: Documentation
12. Update `docs/repo-keeper/README.md`
13. Update `docs/repo-keeper/ORGANIZATION_CHECKLIST.md` (§10 CI/CD Automation)

### Phase 5: Testing
14. Run all scripts on current repository
15. Fix any issues discovered
16. Verify exit codes work correctly
17. Test on both Windows (PowerShell) and Linux (Bash)

---

## Files to Create/Modify

### New Files (20 total)

**Scripts (14 files):**
- `docs/repo-keeper/scripts/check-links.sh`
- `docs/repo-keeper/scripts/validate-inventory.sh`
- `docs/repo-keeper/scripts/validate-relationships.sh`
- `docs/repo-keeper/scripts/validate-relationships.ps1`
- `docs/repo-keeper/scripts/validate-completeness.sh`
- `docs/repo-keeper/scripts/validate-completeness.ps1`
- `docs/repo-keeper/scripts/validate-content.sh`
- `docs/repo-keeper/scripts/validate-content.ps1`
- `docs/repo-keeper/scripts/validate-schemas.sh`
- `docs/repo-keeper/scripts/validate-schemas.ps1`
- `docs/repo-keeper/scripts/run-all-checks.sh`
- `docs/repo-keeper/scripts/run-all-checks.ps1`

**Schemas (2 files):**
- `docs/repo-keeper/schemas/inventory.schema.json`
- `docs/repo-keeper/schemas/data-file.schema.json`

**Design docs (1 file):**
- `docs/plans/2025-12-17-comprehensive-validation-design.md` (this file)

### Modified Files (3 files)

- `.gitattributes` - Add line ending rules
- `docs/repo-keeper/README.md` - Document new scripts
- `docs/repo-keeper/ORGANIZATION_CHECKLIST.md` - Update §10 automation section

---

## GitHub Integration (Optional - Skipped)

**Note:** GitHub workflow integration is optional and can be added later if needed. The validation scripts are designed to work standalone and can be run manually or integrated into any CI/CD system.

If GitHub Actions integration is desired in the future:
- Update `workflows/validate-versions.yml` → `workflows/validate-tier1.yml`
- Create `workflows/validate-tier2.yml` (runs on PR)
- Create `workflows/validate-full.yml` (weekly schedule)

---

## Success Criteria

After implementation, the system should:

1. ✅ Detect all version mismatches across configs, data files, and documentation footers
2. ✅ Find all broken internal links in markdown files
3. ✅ Verify all INVENTORY.json paths exist on disk
4. ✅ Validate all relationships between skills, commands, templates, and examples
5. ✅ Ensure every feature has documentation
6. ✅ Verify all 4 modes have complete coverage
7. ✅ Check documents have required sections and correct mode references
8. ✅ Validate JSON files conform to schemas
9. ✅ Run on both Windows (PowerShell) and Linux (Bash) with identical output
10. ✅ Complete Tier 1 checks in under 15 seconds
11. ✅ Complete Tier 2 checks in under 45 seconds
12. ✅ Exit with non-zero code on failure (CI/CD compatible)

---

## Maintenance

**On every commit:**
- Run `./scripts/run-all-checks.sh --quick` before pushing

**On every version bump:**
- Run `./scripts/run-all-checks.sh` (standard) to catch version mismatches

**Before each release:**
- Run `./scripts/run-all-checks.sh --full` for comprehensive validation

**Monthly:**
- Review validation failures and update scripts as repository evolves

---

**Last Updated:** 2025-12-17
**Version:** 2.2.2
**Status:** ✅ Design Complete, Ready for Implementation
