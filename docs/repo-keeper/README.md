# Repo-Keeper: Repository Organization System

**Created:** 2025-12-16
**Status:** Implemented and tested
**Purpose:** Maintain repository consistency, minimize redundancy, and ensure all components stay aligned

---

## What is Repo-Keeper?

Repo-Keeper is a comprehensive system for maintaining the sandbox-maxxing repository. It provides:

- **Organization checklist** with 18 categories covering all aspects of repository maintenance
- **Entity inventory** tracking 120+ files with rich metadata
- **Automation scripts** for version sync, link checking, and inventory validation
- **GitHub workflows** for CI/CD integration
- **Issue/PR templates** for standardized contributions

---

## What Was Created

### ✅ Phase 1: Core Structure

| File | Purpose | Lines |
|------|---------|-------|
| `ORGANIZATION_CHECKLIST.md` | 18-category maintenance checklist with implementation guides | 1000+ |
| `INVENTORY.json` | Rich metadata inventory of all repo entities (skills, commands, templates, examples, etc.) | 600+ |

### ✅ Phase 2: Automation Scripts

**Tier 1: Structural Validation** (Fast, ~10 seconds)
| File | Purpose | Platform |
|------|---------|----------|
| `scripts/check-version-sync.sh/.ps1` | Validates version consistency across 50+ files | Bash / PowerShell |
| `scripts/check-links.sh/.ps1` | Scans markdown files for broken internal links | Bash / PowerShell |
| `scripts/validate-inventory.sh/.ps1` | Verifies inventory matches filesystem (orphan detection: PowerShell only) | Bash / PowerShell |
| `scripts/validate-relationships.sh/.ps1` | Validates skill ↔ command ↔ template relationships | Bash / PowerShell |
| `scripts/validate-schemas.sh/.ps1` | Validates JSON files against JSON schemas | Bash / PowerShell |

**Tier 2: Completeness Validation** (Medium, ~30 seconds)
| File | Purpose | Platform |
|------|---------|----------|
| `scripts/validate-completeness.sh/.ps1` | Ensures all features have documentation, all modes complete | Bash / PowerShell |

**Tier 3: Content Validation** (Thorough, ~2-5 minutes)
| File | Purpose | Platform |
|------|---------|----------|
| `scripts/validate-content.sh/.ps1` | Checks required sections, mode consistency, step sequences | Bash / PowerShell |

**Orchestrators**
| File | Purpose | Platform |
|------|---------|----------|
| `scripts/run-all-checks.sh/.ps1` | Runs all validation scripts in tiers with progress tracking | Bash / PowerShell |

### ✅ Phase 3: GitHub Integration

| File | Purpose |
|------|---------|
| `workflows/validate-versions.yml` | GitHub Action for automated version checking on PRs |
| `workflows/validate-links.yml` | Weekly link validation with PR comments |
| `templates/ISSUE_TEMPLATE/bug_report.md` | Mode-specific bug report template |
| `templates/ISSUE_TEMPLATE/feature_request.md` | Structured feature proposal template |
| `templates/ISSUE_TEMPLATE/config.yml` | Issue template configuration |
| `templates/PULL_REQUEST_TEMPLATE.md` | Comprehensive PR checklist |

### ✅ Phase 4: Documentation Updates

- **README.md** - Added "Repository Maintenance" section linking to repo-keeper
- **CONTRIBUTING.md** - Added "Repository Organization" section with validation guidelines

---

## Directory Structure

```
docs/repo-keeper/
├── README.md                          # This file
├── ORGANIZATION_CHECKLIST.md          # 18-category checklist
├── INVENTORY.json                     # Entity inventory
├── scripts/
│   ├── run-all-checks.sh/.ps1         # Orchestrator - runs all checks in tiers
│   ├── check-version-sync.sh/.ps1     # Tier 1: Version validation
│   ├── check-links.sh/.ps1            # Tier 1: Link integrity
│   ├── validate-inventory.sh/.ps1     # Tier 1: Inventory accuracy
│   ├── validate-relationships.sh/.ps1 # Tier 1: Relationship validation
│   ├── validate-schemas.sh/.ps1       # Tier 1: Schema validation
│   ├── validate-completeness.sh/.ps1  # Tier 2: Feature coverage
│   └── validate-content.sh/.ps1       # Tier 3: Content validation
├── schemas/
│   ├── inventory.schema.json          # JSON schema for INVENTORY.json
│   └── data-file.schema.json          # JSON schema for data/*.json files
├── workflows/
│   ├── validate-versions.yml          # GitHub Action for versions
│   └── validate-links.yml             # GitHub Action for links
└── templates/
    ├── ISSUE_TEMPLATE/
    │   ├── bug_report.md
    │   ├── feature_request.md
    │   └── config.yml
    └── PULL_REQUEST_TEMPLATE.md
```

---

## Test Results (2025-12-16)

### Version Sync Check

```
✅ INVENTORY.json: 2.2.1 (correct)
❌ data/secrets.json: 2.1.0 (needs update to 2.2.1)
❌ data/variables.json: 2.1.0 (needs update to 2.2.1)
✅ 51 files with matching version footers
⚠️  11 files missing footers
```

**Status:** Script working correctly, identified 3 issues to fix

### Known Issues Found

1. **Version mismatches (3 files):**
   - `data/secrets.json` - shows 2.1.0, should be 2.2.1
   - `data/variables.json` - shows 2.1.0, should be 2.2.1
   - `.claude-plugin/marketplace.json` - version field parsing issue

2. **Missing version footers (11 files):**
   - Various documentation files need footers added

3. **Broken links (10 known):**
   - From previous audit in `docs/CONSISTENCY_AUDIT_2025-12-16.md`
   - `docs/CONSOLIDATION_RECOMMENDATIONS.md` (3 links)
   - `skills/sandbox-setup-advanced/references/` (2 links)
   - `templates/legacy/README.md` (3 links)
   - Archive files (2 links)

---

## Dependencies

### Required
- **Node.js 18+** - For JSON processing and schema validation
- **bash 4.0+** - For bash scripts (Linux/macOS)
- **PowerShell Core 7.0+** - For PowerShell scripts (Windows/cross-platform)

### Auto-installed (via npm)
- `ajv-cli` - JSON Schema validation
- `ajv-formats` - Additional schema format validators

### Optional
- `curl` - External link checking (bash scripts only)

### Installation

**Node.js:**
```bash
# Via nvm (recommended)
nvm install --lts

# Or download from https://nodejs.org/
```

**Validation tools** (installed automatically by scripts):
```bash
npm install -g ajv-cli ajv-formats
```

---

## Quick Start Guide

### 1. Run Local Validation

**Option A: Use the Orchestrator (Recommended)**

Run all checks in tiers with a single command:

```bash
# Bash (Linux/macOS/WSL)
cd /workspace  # or your repo location

# Quick check (Tier 1 only - ~10 seconds)
./docs/repo-keeper/scripts/run-all-checks.sh --quick

# Standard check (Tier 1 + 2 - ~30 seconds) - DEFAULT
./docs/repo-keeper/scripts/run-all-checks.sh

# Full check (All tiers including external links - ~2-5 minutes)
./docs/repo-keeper/scripts/run-all-checks.sh --full

# With verbose output
./docs/repo-keeper/scripts/run-all-checks.sh --verbose

# Auto-fix line endings
./docs/repo-keeper/scripts/run-all-checks.sh --fix-crlf
```

```powershell
# PowerShell (Windows)
cd D:\!wip\sandbox-maxxing

# Quick check (Tier 1 only)
.\docs\repo-keeper\scripts\run-all-checks.ps1 -Quick

# Standard check (Tier 1 + 2) - DEFAULT
.\docs\repo-keeper\scripts\run-all-checks.ps1

# Full check (All tiers)
.\docs\repo-keeper\scripts\run-all-checks.ps1 -Full

# With verbose output
.\docs\repo-keeper\scripts\run-all-checks.ps1 -Verbose

# Auto-fix line endings
.\docs\repo-keeper\scripts\run-all-checks.ps1 -FixCrlf
```

**Option B: Run Individual Scripts**

For targeted validation:

```bash
# Bash
./docs/repo-keeper/scripts/check-version-sync.sh
./docs/repo-keeper/scripts/check-links.sh
./docs/repo-keeper/scripts/validate-inventory.sh
./docs/repo-keeper/scripts/validate-relationships.sh
./docs/repo-keeper/scripts/validate-schemas.sh
./docs/repo-keeper/scripts/validate-completeness.sh
./docs/repo-keeper/scripts/validate-content.sh

# With verbose output
./docs/repo-keeper/scripts/check-version-sync.sh --verbose
```

```powershell
# PowerShell
.\docs\repo-keeper\scripts\check-version-sync.ps1
.\docs\repo-keeper\scripts\check-links.ps1
.\docs\repo-keeper\scripts\validate-inventory.ps1 -FindOrphans
.\docs\repo-keeper\scripts\validate-relationships.ps1
.\docs\repo-keeper\scripts\validate-schemas.ps1
.\docs\repo-keeper\scripts\validate-completeness.ps1
.\docs\repo-keeper\scripts\validate-content.ps1 -CheckExternal

# With verbose output
.\docs\repo-keeper\scripts\check-version-sync.ps1 -Verbose
```

### 2. Activate GitHub Workflows (Optional)

Copy workflows to activate automated checks:

```powershell
# Create .github directory if it doesn't exist
New-Item -ItemType Directory -Path ".github\workflows" -Force

# Copy workflows
Copy-Item -Path "docs\repo-keeper\workflows\*" -Destination ".github\workflows\" -Force

# Copy issue/PR templates
Copy-Item -Path "docs\repo-keeper\templates\ISSUE_TEMPLATE" -Destination ".github\" -Recurse -Force
Copy-Item -Path "docs\repo-keeper\templates\PULL_REQUEST_TEMPLATE.md" -Destination ".github\" -Force
```

### 3. Fix Known Issues

**High Priority:**

1. Update data file versions:
   ```powershell
   # Edit data/secrets.json
   # Change "version": "2.1.0" to "version": "2.2.1"

   # Edit data/variables.json
   # Change "version": "2.1.0" to "version": "2.2.1"
   ```

2. Add version footers to 11 files (see checklist)

3. Fix 10 broken links (see checklist)

**Medium Priority:**

- Document or remove `data/mcp-servers.json`
- Fix plugin naming in `data/README.md`

---

## How to Use the Checklist

The [`ORGANIZATION_CHECKLIST.md`](./ORGANIZATION_CHECKLIST.md) contains 18 categories:

1. **Changelog Management** - CHANGELOG.md format and version sync
2. **Version Footer Consistency** - 47 files with version footers
3. **Skills, Templates, Examples Alignment** - Mode coverage matrix
4. **Redundancy Minimization Rules** - When to duplicate vs consolidate
5. **Discrepancy Prevention** - Version numbers, naming, descriptions
6. **Cross-Reference Integrity** - No broken links
7. **Data Files Consistency** - JSON files in `data/`
8. **Consolidation Rules** - Documentation hierarchy
9. **Naming Conventions** - Commands, skills, templates, examples
10. **CI/CD Automation** - GitHub Actions implementation
11. **Dependency Version Sync** - requirements.txt, package.json
12. **DevContainer Config Sync** - 6 devcontainer locations
13. **Template Hierarchy Sync** - Master → mode → examples
14. **Firewall Script Sync** - 8 firewall script files
15. **Dockerfile Sync** - 21 Dockerfile locations
16. **Test File Consistency** - Jest + Pytest configs
17. **EditorConfig Standardization** - Decision needed
18. **Inventory Maintenance** - Keep INVENTORY.json current

**Usage:**
- Review checklist before releases
- Reference when adding new files
- Use as PR review guide

---

## How to Use the Inventory

The [`INVENTORY.json`](./INVENTORY.json) tracks:

- **6 skills** with relationships to commands, examples, templates
- **7 commands** with skill invocations
- **48 templates** categorized by type and mode
- **7 examples** with test info and devcontainer paths
- **7 data files** with version and update frequency
- **50+ documentation files** with footer status
- **6 devcontainers** with mode and paths
- **14 dependency files** (Python + Node.js)
- **Test files** (manual, jest, pytest)

**Usage:**
- Validate with `validate-inventory.ps1`
- Update when adding/removing files
- Reference for understanding relationships
- Use for auditing and reporting

---

## Maintenance Schedule

### On Every Commit
- Run `./docs/repo-keeper/scripts/run-all-checks.sh --quick` before pushing
- Verify no broken references
- Fix any Tier 1 failures immediately

### On Every Version Bump
1. Update `CHANGELOG.md` with new version header
2. Update all version footers in documentation
3. Update `plugin.json` and `marketplace.json`
4. Update `INVENTORY.json` version
5. Update `data/secrets.json` and `variables.json` versions
6. Run `./docs/repo-keeper/scripts/run-all-checks.sh` (standard) to verify
7. Fix any validation failures before releasing

### Weekly
- Run `./docs/repo-keeper/scripts/run-all-checks.sh` (standard check)
- Address any Tier 2 completeness issues

### Monthly
- Run `./docs/repo-keeper/scripts/run-all-checks.sh --full` (comprehensive)
- Review and update `data/official-images.json` tags
- Check for security updates in dependencies
- Address any Tier 3 content issues

### Quarterly
- Run full consistency audit
- Review consolidation opportunities
- Check for new redundancy
- Update domain allowlists
- Verify JSON schemas are current

### Before Each Release
- Review ORGANIZATION_CHECKLIST.md
- Review `docs/RELEASE_CHECKLIST.md`
- Run `./docs/repo-keeper/scripts/run-all-checks.sh --full`
- Test manual procedures
- All validation checks must pass

---

## Next Steps (Picking Up Where We Left Off)

### Immediate Actions

1. **Fix version mismatches:**
   - [ ] Update `data/secrets.json` to 2.2.1
   - [ ] Update `data/variables.json` to 2.2.1
   - [ ] Fix `marketplace.json` version field parsing

2. **Add missing footers (11 files):**
   - [ ] Run version sync with `-Verbose` to see which files
   - [ ] Add standard footer to each:
     ```markdown
     ---

     **Last Updated:** 2025-12-16
     **Version:** 2.2.2
     ```

3. **Fix broken links (10 known):**
   - [ ] Run link checker to identify
   - [ ] Update relative paths
   - [ ] Test links work

### Optional Enhancements

4. **Activate CI/CD:**
   - [ ] Copy workflows to `.github/workflows/`
   - [ ] Test workflows on a feature branch
   - [ ] Adjust paths if needed (D:\!wip\sandbox-maxxing vs /workspace)

5. **Add Issue/PR Templates:**
   - [ ] Copy templates to `.github/`
   - [ ] Test issue creation
   - [ ] Test PR creation

6. **Create bash version of link checker:**
   - [ ] Port `check-links.ps1` to bash
   - [ ] Save as `scripts/check-links.sh`
   - [ ] Test on Linux/macOS

### Long-term Improvements

7. **Automate inventory updates:**
   - Create script to regenerate INVENTORY.json from filesystem
   - Add to pre-commit hook

8. **Add JSON schemas:**
   - Create `inventory.schema.json` for validation
   - Create schemas for data files

9. **EditorConfig standardization:**
   - Decide: Add to all examples or remove from YOLO
   - Implement chosen approach

---

## Known Limitations

### Current Limitations
1. **Orphan file detection** - Only available in PowerShell scripts (bash implementation planned)
2. **External link checking** - Optional, requires curl (bash) or uses Invoke-WebRequest (PowerShell)
3. **JSON parsing** - Migrating from jq/python to Node.js (in progress)
4. **Cross-platform differences** - Minor behavioral differences between bash and PowerShell versions

### Planned Improvements
See `docs/plans/2025-12-18-repo-keeper-improvements.md` for comprehensive roadmap.

### Reporting Issues
Found a bug or limitation? Report at: https://github.com/andrewcchoi/sandbox-maxxing/issues

---

## Troubleshooting

### Script Won't Run

**PowerShell Execution Policy:**
```powershell
# Check current policy
Get-ExecutionPolicy

# Allow scripts (run as Administrator)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Path Issues:**
- Scripts use `D:\!wip\sandbox-maxxing` as repo root
- Update `$repoRoot` variable in scripts if your path differs
- Bash scripts use `/workspace` (for devcontainer)

### False Positives

**Version sync script:**
- CHANGELOG.md is excluded (doesn't need footer)
- Archive files in `docs/archive/` don't need footers

**Link checker:**
- External links are skipped by default
- Anchors (#links) are skipped
- Fragment identifiers (#section) are removed before validation

### Performance

**Large repository:**
- Use `-Verbose` only when debugging
- Link checker can be slow on 50+ markdown files
- Inventory validation is fast (<1 second)

---

## Reference Links

### Project Documentation
- [Main README](../../README.md)
- [CONTRIBUTING](../../CONTRIBUTING.md)
- [DEVELOPMENT](../../DEVELOPMENT.md)
- [CHANGELOG](../../CHANGELOG.md)

### Existing Audits
- [Consistency Audit](../audits/CONSISTENCY_AUDIT_2025-12-16.md)
- [Consolidation Recommendations](../audits/CONSOLIDATION_RECOMMENDATIONS.md)
- [Release Checklist](../RELEASE_CHECKLIST.md)

### Related Docs
- [MODES.md](../features/MODES.md) - Mode comparison guide
- [TROUBLESHOOTING.md](../features/TROUBLESHOOTING.md) - Issue resolution
- [ARCHITECTURE.md](../ARCHITECTURE.md) - System design

---

## Contact & Support

For questions about repo-keeper:
1. Check the [ORGANIZATION_CHECKLIST.md](./ORGANIZATION_CHECKLIST.md)
2. Review this README
3. Open an issue on GitHub

For general plugin support:
- **Issues**: https://github.com/andrewcchoi/sandbox-maxxing/issues
- **Documentation**: See `skills/*/references/` directories

---

**Version:** 2.2.2
**Last Updated:** 2025-12-17
**Status:** ✅ Implemented and tested with comprehensive validation suite
