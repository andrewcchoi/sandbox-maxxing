# Repository Organization Checklist

**Purpose:** Ongoing checklist to maintain repository consistency, minimize redundancy, and ensure all components stay aligned.

**Location:** `docs/repo-keeper/`

**Related Files:**
- [`docs/RELEASE_CHECKLIST.md`](../RELEASE_CHECKLIST.md) - For release-time checks
- [`docs/audits/CONSISTENCY_AUDIT_2025-12-16.md`](../audits/CONSISTENCY_AUDIT_2025-12-16.md) - Comprehensive audit
- [`docs/audits/CONSOLIDATION_RECOMMENDATIONS.md`](../audits/CONSOLIDATION_RECOMMENDATIONS.md) - Future opportunities
- [`INVENTORY.json`](./INVENTORY.json) - Entity inventory for auditing

---

## Table of Contents

1. [Changelog Management](#1-changelog-management)
2. [Version Footer Consistency](#2-version-footer-consistency)
3. [Skills, Templates, Examples Alignment](#3-skills-templates-examples-alignment)
4. [Redundancy Minimization Rules](#4-redundancy-minimization-rules)
5. [Discrepancy Prevention](#5-discrepancy-prevention)
6. [Cross-Reference Integrity](#6-cross-reference-integrity)
7. [Data Files Consistency](#7-data-files-consistency)
8. [Consolidation Rules](#8-consolidation-rules)
9. [Naming Conventions](#9-naming-conventions)
10. [CI/CD Automation](#10-cicd-automation)
11. [Dependency Version Sync](#11-dependency-version-sync)
12. [DevContainer Config Sync](#12-devcontainer-config-sync)
13. [Template Hierarchy Sync](#13-template-hierarchy-sync)
14. [Firewall Script Sync](#14-firewall-script-sync)
15. [Dockerfile Sync](#15-dockerfile-sync)
16. [Test File Consistency](#16-test-file-consistency)
17. [EditorConfig Standardization](#17-editorconfig-standardization)
18. [Inventory Maintenance](#18-inventory-maintenance)

---

## 1. Changelog Management

- [ ] **CHANGELOG.md follows Keep a Changelog format**
- [ ] **All versions documented** (features, fixes, breaking changes)
- [ ] **Version header matches plugin.json version**
- [ ] **Dates follow ISO format** (YYYY-MM-DD)
- [ ] **Breaking changes clearly marked** with `### Breaking Changes` section

**Files to check:**
- `CHANGELOG.md`
- `.claude-plugin/plugin.json` (version field)
- `.claude-plugin/marketplace.json` (version field)

**Automation:** Use `scripts/check-version-sync.ps1` to verify version consistency

---

## 2. Version Footer Consistency

**Standard footer format:**
```markdown
---

**Last Updated:** YYYY-MM-DD
**Version:** X.Y.Z
```

- [ ] **All 47 documentation files have matching version footers**
- [ ] **Plugin configuration versions match:**
  - `.claude-plugin/plugin.json`
  - `.claude-plugin/marketplace.json`
- [ ] **Data file versions match:**
  - `data/secrets.json`
  - `data/variables.json`

**Known Issues (as of v2.2.1):**
- 39 files missing footers (7 commands, 6 core docs, 7 examples, 10 skills, 5 templates, 4 other)
- `data/secrets.json` shows 2.1.0 (should be 2.2.1)
- `data/variables.json` shows 2.1.0 (should be 2.2.1)

**Automation:** Use `scripts/check-version-sync.ps1` to find mismatches

---

## 3. Skills, Templates, Examples Alignment

**Relationship Structure:**
```
Commands (7) → Skills (6) → Templates (by mode) → Examples (5)
```

- [ ] **Each mode has complete coverage:**

| Mode | Command | Skill | Templates | Example |
|------|---------|-------|-----------|---------|
| Basic | `commands/basic.md` | `skills/sandbox-setup-basic/` | `templates/*/*.basic.*` | `examples/demo-app-sandbox-basic/` |
| Intermediate | `commands/intermediate.md` | `skills/sandbox-setup-intermediate/` | `templates/*/*.intermediate.*` | `examples/demo-app-sandbox-intermediate/` |
| Advanced | `commands/advanced.md` | `skills/sandbox-setup-advanced/` | `templates/*/*.advanced.*` | `examples/demo-app-sandbox-advanced/` |
| YOLO | `commands/yolo.md` | `skills/sandbox-setup-yolo/` | `templates/*/*.yolo.*` | `examples/demo-app-sandbox-yolo/` |

- [ ] **Utility skills have matching commands:**
  - `sandbox-troubleshoot` → `commands/troubleshoot.md`
  - `sandbox-security` → `commands/audit.md`

- [ ] **Template files exist for all modes:**
  - `templates/compose/docker-compose.{mode}.yml`
  - `templates/firewall/{mode}-*.sh`
  - `templates/extensions/extensions.{mode}.json`
  - `templates/mcp/mcp.{mode}.json`
  - `templates/variables/variables.{mode}.json`
  - `templates/env/.env.{mode}.template`

**Automation:** Use `scripts/validate-inventory.ps1` to verify coverage

---

## 4. Redundancy Minimization Rules

**Acceptable Duplication (keep separate):**
- [ ] Mode comparison tables in example READMEs (~15 lines each, standalone readability)
- [ ] Shell scripts in examples (copied from shared, allows customization)
- [ ] Skill reference content (contextual, each skill needs own context)

**Should Consolidate (single source of truth):**
- [ ] Mode philosophy details → `docs/MODES.md` only (not README.md)
- [ ] Credential handling → `docs/SECRETS.md` only (not VARIABLES.md)
- [ ] Troubleshooting steps → `docs/TROUBLESHOOTING.md` is authoritative

**Decision Rule:**
1. Content is contextual and standalone → duplicate is OK
2. Content is detailed and changes frequently → consolidate to one source
3. Content is a simple table/reference → cross-reference is better

---

## 5. Discrepancy Prevention

**Version numbers (must all match):**
- [ ] `CHANGELOG.md` header
- [ ] `.claude-plugin/plugin.json` version field
- [ ] `.claude-plugin/marketplace.json` version field
- [ ] All 47 documentation footers
- [ ] `data/secrets.json` version field
- [ ] `data/variables.json` version field
- [ ] `INVENTORY.json` version field

**Author/team naming (standardize to):**
| Context | Use |
|---------|-----|
| Formal docs/titles | "Claude Code Sandbox Plugin" |
| Conversational | "sandbox plugin" |
| Technical/GitHub | "sandbox-maxxing" |
| Commands | "sandbox:*" |
| Skills | "sandbox-*" |

**Known Issues:**
- [ ] `data/README.md` says "Docker Sandbox Plugin" → should be "Claude Code Sandbox Plugin"
- [ ] marketplace.json owner vs plugin.json author inconsistency

**Mode descriptions (must be consistent across):**
- `docs/MODES.md` (authoritative)
- `README.md` (summary only)
- `skills/*/SKILL.md` (contextual)
- `examples/*/README.md` (mode-specific)

---

## 6. Cross-Reference Integrity

- [ ] **No broken links** (use `scripts/check-links.ps1`)
- [ ] **Use relative paths** (not `/workspace/...` absolute paths)
- [ ] **Archive files marked** with warning banner

**Known Issues (as of v2.2.1):**
- `docs/CONSOLIDATION_RECOMMENDATIONS.md` (3 broken links)
- `skills/sandbox-setup-advanced/references/customization.md` (1 link)
- `skills/sandbox-setup-advanced/references/troubleshooting.md` (1 link)
- `templates/legacy/README.md` (3 links - uses absolute paths)

**Automation:** Use `scripts/check-links.ps1` to find broken links

---

## 7. Data Files Consistency

**All data files should have:**
- [ ] Consistent `$schema` or version field
- [ ] Documentation in `data/README.md`
- [ ] Referenced somewhere in skills/docs

**Data file checklist:**
| File | Has Version | Documented | Referenced |
|------|-------------|------------|------------|
| `allowable-domains.json` | - | Yes | Yes (10x) |
| `mcp-servers.json` | - | No | No ⚠️ |
| `official-images.json` | - | Yes | Yes (11x) |
| `sandbox-templates.json` | - | Yes | Yes (8x) |
| `secrets.json` | Yes (outdated) | Yes | Yes (1x) |
| `variables.json` | Yes (outdated) | Yes | Yes (1x) |
| `vscode-extensions.json` | - | Yes | Yes (1x) |

**Actions needed:**
- [ ] Document or remove `mcp-servers.json`
- [ ] Update `secrets.json` version to 2.2.1
- [ ] Update `variables.json` version to 2.2.1

---

## 8. Consolidation Rules

**When to merge files:**
1. Content overlap > 50%
2. Same information maintained in 2+ places
3. Updates to one require updates to another

**When to keep separate:**
1. Different audiences (user vs developer)
2. Different contexts (skill vs documentation)
3. Standalone readability required
4. Content is stable and rarely changes

**Documentation hierarchy:**
```
README.md (entry point, summaries)
├── docs/MODES.md (detailed mode info)
├── docs/VARIABLES.md (non-sensitive config)
├── docs/SECRETS.md (sensitive credentials)
├── docs/TROUBLESHOOTING.md (authoritative troubleshooting)
├── commands/README.md (command reference)
├── skills/README.md (skill reference)
├── templates/README.md (template system)
└── examples/README.md (working examples)
```

---

## 9. Naming Conventions

**Commands:**
- [ ] Format: `/sandbox:{action}` (lowercase, hyphenated for multi-word)
- [ ] Examples: `/sandbox:setup`, `/sandbox:troubleshoot`, `/sandbox:audit`

**Skills:**
- [ ] Format: `sandbox-{action}[-mode]` with `SKILL.md` files
- [ ] Examples: `sandbox-setup-basic/SKILL.md`, `sandbox-troubleshoot/SKILL.md`

**Templates:**
- [ ] Format: `{component}.{mode}.{ext}` or `{mode}-{description}.{ext}`
- [ ] Examples: `docker-compose.basic.yml`, `advanced-strict.sh`

**Examples:**
- [ ] Format: `{app-type}-sandbox-{mode}` or `{app-type}-shared`
- [ ] Examples: `demo-app-sandbox-basic`, `streamlit-shared`

**File structure consistency:**
- [ ] Every directory has a `README.md`
- [ ] Skills follow `{skill-name}/SKILL.md` pattern
- [ ] Examples follow `.devcontainer/` structure for sandbox examples

**Archive policy:**
- [ ] Archived files go to `docs/archive/`
- [ ] Archive files get warning banner: "⚠️ Archived document - links may be outdated"
- [ ] Archive files don't get version footers (frozen in time)

---

## 10. CI/CD Automation

### Implementation Guide

**Available tools (zero-install):**
- GitHub Actions (cloud CI/CD)
- PowerShell (Windows built-in)
- Bash (Linux/macOS/WSL)
- Git hooks (Git built-in)

### Three-Tier Validation System

The comprehensive validation suite runs checks in three tiers:

**Tier 1: Structural Validation** (~10 seconds)
- Version sync across 50+ files
- Link integrity in markdown files
- Inventory accuracy vs filesystem
- Relationship validation (skill ↔ command ↔ template)
- JSON schema validation

**Tier 2: Completeness Validation** (~30 seconds)
- Feature coverage (all features have documentation)
- Mode coverage (all 4 modes have complete vertical slices)

**Tier 3: Content Validation** (~2-5 minutes)
- Required sections in documentation
- Mode consistency (files reference correct mode)
- Step sequence validation
- External link checking (optional)

### Automation Checklist

- [ ] **Run orchestrator before commits**
  - Quick check: `./docs/repo-keeper/scripts/run-all-checks.sh --quick`
  - Standard check: `./docs/repo-keeper/scripts/run-all-checks.sh`
  - Full check: `./docs/repo-keeper/scripts/run-all-checks.sh --full`

- [ ] **Version validation workflow** (`workflows/validate-versions.yml`)
  - Triggers on PR and push to master
  - Runs `scripts/check-version-sync.sh`
  - Fails if versions mismatch

- [ ] **Link validation workflow** (`workflows/validate-links.yml`)
  - Triggers on PR and weekly schedule
  - Runs `scripts/check-links.sh`
  - Comments on PR with broken links

- [ ] **Comprehensive validation workflow** (optional, recommended)
  - Runs `scripts/run-all-checks.sh` (standard mode)
  - Validates all Tier 1 + Tier 2 checks
  - Provides detailed failure reports

### Setup Instructions

**1. Run Local Validation (Recommended):**
```bash
# Bash (Linux/macOS/WSL)
./docs/repo-keeper/scripts/run-all-checks.sh           # Standard (Tier 1+2)
./docs/repo-keeper/scripts/run-all-checks.sh --quick   # Quick (Tier 1 only)
./docs/repo-keeper/scripts/run-all-checks.sh --full    # Full (all tiers)
```

```powershell
# PowerShell (Windows)
.\docs\repo-keeper\scripts\run-all-checks.ps1           # Standard (Tier 1+2)
.\docs\repo-keeper\scripts\run-all-checks.ps1 -Quick    # Quick (Tier 1 only)
.\docs\repo-keeper\scripts\run-all-checks.ps1 -Full     # Full (all tiers)
```

**2. Run Individual Scripts:**
```bash
# Bash
./docs/repo-keeper/scripts/check-version-sync.sh
./docs/repo-keeper/scripts/check-links.sh
./docs/repo-keeper/scripts/validate-inventory.sh
./docs/repo-keeper/scripts/validate-relationships.sh
./docs/repo-keeper/scripts/validate-schemas.sh
./docs/repo-keeper/scripts/validate-completeness.sh
./docs/repo-keeper/scripts/validate-content.sh
```

**3. Copy workflows to activate CI/CD:**
```powershell
# PowerShell
Copy-Item -Path "docs/repo-keeper/workflows/*" -Destination ".github/workflows/" -Recurse
```

**3. Git hooks (optional):**
```bash
# Add pre-commit hook
cp docs/repo-keeper/scripts/check-version-sync.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

### Maintenance

- [ ] **When adding new markdown files:** Ensure link checker covers them
- [ ] **When adding version footers:** Ensure version sync script detects them
- [ ] **When updating workflows:** Test locally first

---

## 11. Dependency Version Sync

**Files to monitor:**

**Python dependencies (8 files):**
- `examples/demo-app-sandbox-basic/backend/requirements.txt`
- `examples/demo-app-sandbox-intermediate/backend/requirements.txt`
- `examples/demo-app-sandbox-advanced/backend/requirements.txt`
- `examples/demo-app-sandbox-yolo/backend/requirements.txt`
- `examples/demo-app-shared/backend/requirements.txt`
- `examples/streamlit-sandbox-basic/requirements.txt`
- `examples/streamlit-shared/requirements.txt`
- `templates/legacy/python/requirements.txt`

**Node.js dependencies (6 files):**
- `examples/demo-app-sandbox-basic/frontend/package.json`
- `examples/demo-app-sandbox-intermediate/frontend/package.json`
- `examples/demo-app-sandbox-advanced/frontend/package.json`
- `examples/demo-app-sandbox-yolo/frontend/package.json`
- `examples/demo-app-shared/frontend/package.json`
- `templates/legacy/node/package.json`

### Checklist

- [ ] **Major versions match** across all examples for same packages
- [ ] **Shared examples are source of truth** for package versions
- [ ] **Security vulnerabilities addressed** (run `npm audit`, `pip-audit`)
- [ ] **Legacy templates marked as deprecated** if versions diverge

### Maintenance Schedule

- **Monthly:** Check for security updates
- **Quarterly:** Update to latest stable versions
- **On version bump:** Sync across all examples

---

## 12. DevContainer Config Sync

**DevContainer locations (6 files):**
1. `.devcontainer/devcontainer.json` (repo's own container - Intermediate mode)
2. `examples/demo-app-sandbox-basic/.devcontainer/devcontainer.json`
3. `examples/demo-app-sandbox-intermediate/.devcontainer/devcontainer.json`
4. `examples/demo-app-sandbox-advanced/.devcontainer/devcontainer.json`
5. `examples/demo-app-sandbox-yolo/.devcontainer/devcontainer.json`
6. `examples/streamlit-sandbox-basic/.devcontainer/devcontainer.json`

### Checklist

- [ ] **All devcontainers specify mode** in name/description
- [ ] **Dockerfile paths are correct** for each mode
- [ ] **Port mappings align** with services in docker-compose
- [ ] **VS Code extensions match** mode's extension template
- [ ] **MCP server configs match** mode's MCP template
- [ ] **Environment variables align** with mode's variable template

### Mode-Specific Requirements

| Mode | Firewall | Services | Extensions | MCP |
|------|----------|----------|------------|-----|
| Basic | None | Minimal | 6-8 | Basic |
| Intermediate | Permissive | Standard | 15-20 | Standard |
| Advanced | Strict | Full | 22-28 | Advanced |
| YOLO | Configurable | Maximum | 35+ | Full |

---

## 13. Template Hierarchy Sync

**Template flow:**
```
templates/master/*.master
    ↓ (sections extracted)
templates/{category}/*.{mode}.*
    ↓ (copied to examples)
examples/*/.devcontainer/*
```

### Master Templates (source of truth)

**Location:** `templates/master/`
- `devcontainer.json.master` - All devcontainer options (37 sections)
- `Dockerfile.master` - All language toolchains (14 sections)
- `docker-compose.master.yml` - All service configurations
- `init-firewall.master.sh` - All firewall modes (200+ domain categories)
- `setup-claude-credentials.master.sh` - Credential setup script
- `VALIDATION.txt` - Section validation rules

### Mode-Specific Templates

**Compose files:**
- `templates/compose/docker-compose.basic.yml`
- `templates/compose/docker-compose.intermediate.yml`
- `templates/compose/docker-compose.advanced.yml`
- `templates/compose/docker-compose.yolo.yml`

**Firewall scripts:**
- `templates/firewall/basic-no-firewall.sh`
- `templates/firewall/intermediate-permissive.sh`
- `templates/firewall/advanced-strict.sh`
- `templates/firewall/yolo-configurable.sh`

### Checklist

- [ ] **Master templates are most comprehensive**
- [ ] **Mode templates extract relevant sections** from master
- [ ] **Examples copy templates** (not reference them)
- [ ] **Template changes propagate** to affected examples
- [ ] **Regeneration scripts work** (`scripts/regenerate-devcontainer.ps1|.sh`)

### Update Workflow

1. Edit master template in `templates/master/`
2. Regenerate mode-specific templates (if using extraction tool)
3. Update examples that use affected template
4. Test example builds
5. Document breaking changes in CHANGELOG

---

## 14. Firewall Script Sync

**Firewall script locations (8 files):**

**Templates:**
1. `templates/firewall/basic-no-firewall.sh`
2. `templates/firewall/intermediate-permissive.sh`
3. `templates/firewall/advanced-strict.sh`
4. `templates/firewall/yolo-configurable.sh`

**Examples:**
5. `examples/demo-app-sandbox-basic/.devcontainer/init-firewall.sh`
6. `examples/demo-app-sandbox-intermediate/.devcontainer/init-firewall.sh`
7. `examples/demo-app-sandbox-advanced/.devcontainer/init-firewall.sh`
8. `examples/demo-app-sandbox-yolo/.devcontainer/init-firewall.sh`

**Also:**
- `.devcontainer/init-firewall.sh` (repo's own - Intermediate mode)
- `examples/streamlit-sandbox-basic/.devcontainer/init-firewall.sh`
- Master template: `templates/master/init-firewall.master.sh`

### Checklist

- [ ] **Mode policies are consistent:**
  - Basic: No firewall rules
  - Intermediate: Permissive outbound, allows common services
  - Advanced: Strict whitelist from `data/allowable-domains.json`
  - YOLO: User-configurable via environment variables

- [ ] **Domain allowlists sync** with `data/allowable-domains.json`
- [ ] **iptables commands are valid** (test with `iptables-save`)
- [ ] **DNS resolution works** before applying rules
- [ ] **Error handling is consistent** across modes

### Security Review

- [ ] **Advanced mode uses strict whitelist** (no broad wildcards)
- [ ] **YOLO mode documents risks** in README
- [ ] **Domain list is current** (review quarterly)

---

## 15. Dockerfile Sync

**Dockerfile locations (21 total):**

**Master:**
- `templates/master/Dockerfile.master` (comprehensive, all languages)

**Language-specific (11):**
- `templates/dockerfiles/Dockerfile.python`
- `templates/dockerfiles/Dockerfile.node`
- `templates/dockerfiles/Dockerfile.go`
- `templates/dockerfiles/Dockerfile.rust`
- `templates/dockerfiles/Dockerfile.java`
- `templates/dockerfiles/Dockerfile.ruby`
- `templates/dockerfiles/Dockerfile.php`
- `templates/dockerfiles/Dockerfile.cpp-gcc`
- `templates/dockerfiles/Dockerfile.cpp-clang`
- `templates/dockerfiles/Dockerfile.postgres`
- `templates/dockerfiles/Dockerfile.redis`

**Examples (6):**
- `examples/demo-app-sandbox-basic/.devcontainer/Dockerfile`
- `examples/demo-app-sandbox-intermediate/.devcontainer/Dockerfile`
- `examples/demo-app-sandbox-advanced/.devcontainer/Dockerfile`
- `examples/demo-app-sandbox-yolo/.devcontainer/Dockerfile`
- `examples/streamlit-sandbox-basic/.devcontainer/Dockerfile`
- `.devcontainer/Dockerfile` (repo's own)

**Legacy (3):**
- `templates/legacy/base/Dockerfile.flexible`
- `templates/legacy/node/Dockerfile`
- `templates/legacy/python/Dockerfile`

### Checklist

- [ ] **All Dockerfiles use Issue #29 fix** (multi-stage Node.js build)
- [ ] **Base images come from** `data/official-images.json`
- [ ] **Security best practices followed:**
  - Non-root user
  - Minimal attack surface
  - No secrets in layers
  - Updated packages

- [ ] **Language versions match** across templates and examples
- [ ] **Build optimizations applied** (layer caching, multi-stage)

### Issue #29 Pattern (Required)

All Dockerfiles must include:
```dockerfile
# Stage 1: Get Node.js from official image (Issue #29)
FROM node:20-slim AS node-source

# Stage 2: Copy Node.js to mcr.microsoft.com/devcontainers base
FROM mcr.microsoft.com/devcontainers/base:ubuntu
COPY --from=node-source /usr/local /usr/local
```

---

## 16. Test File Consistency

**Frontend tests (Jest - 15 files):**
- `examples/demo-app-sandbox-{basic,intermediate,advanced,yolo}/.../tests/`
  - `PostDetail.test.jsx`
  - `PostForm.test.jsx`
  - `PostList.test.jsx`
- `examples/demo-app-shared/frontend/src/components/__tests__/`
  - Same 3 test files (source of truth)

**Backend tests (Pytest - 5 files):**
- `examples/demo-app-sandbox-{basic,intermediate,advanced,yolo}/backend/tests/`
  - `test_api.py`
  - `test_cache.py`
- `examples/demo-app-shared/backend/tests/`
  - Same 2 test files (source of truth)

**Manual tests (5 files):**
- `tests/test-setup-basic.md`
- `tests/test-setup-advanced.md`
- `tests/test-setup-yolo.md`
- `tests/test-troubleshoot.md`
- `tests/test-security.md`

### Checklist

- [ ] **Shared tests are source of truth** (demo-app-shared)
- [ ] **Example tests copy from shared** (not modify)
- [ ] **Test configuration files sync:**
  - `jest.config.js` (5 locations)
  - `pytest.ini` (5 locations)
  - `vite.config.js` (5 locations)

- [ ] **Manual test procedures are current** (updated with features)
- [ ] **All tests pass** before release

### Test Coverage

- [ ] Frontend components: PostDetail, PostForm, PostList
- [ ] Backend API: CRUD operations, caching, errors
- [ ] Integration: API + frontend interaction
- [ ] Manual: Setup flows for each mode

---

## 17. EditorConfig Standardization

**Current state:**
- `.editorconfig` only exists in `examples/demo-app-sandbox-yolo/.devcontainer/`
- Other examples and repo root do not have editorconfig

### Checklist

- [ ] **Decide: Add .editorconfig to all examples or none**
- [ ] **If adding, standardize settings:**
  ```ini
  root = true

  [*]
  indent_style = space
  indent_size = 2
  end_of_line = lf
  charset = utf-8
  trim_trailing_whitespace = true
  insert_final_newline = true

  [*.md]
  trim_trailing_whitespace = false

  [*.py]
  indent_size = 4
  ```

- [ ] **Consider repo-wide .editorconfig** for consistency

### Decision Needed

**Option A:** Add .editorconfig to all examples and repo root (consistency)
**Option B:** Remove from YOLO example (keep simple)
**Option C:** Make it mode-specific (YOLO only for now)

---

## 18. Inventory Maintenance

**Inventory file:** `docs/repo-keeper/INVENTORY.json`

### Purpose

Single source of truth for:
- All skills (6)
- All commands (7)
- All templates (40+)
- All examples (7)
- All data files (7)
- All documentation files (47+)
- All devcontainers (6)

### Checklist

- [ ] **Inventory version matches repo version**
- [ ] **All paths in inventory exist on disk**
- [ ] **All critical files are in inventory**
- [ ] **Relationships are accurate** (skill ← command, example ← template)
- [ ] **Metadata is current** (last_updated, version)

### Maintenance

**On every file add:**
1. Add entry to `INVENTORY.json`
2. Include path, version, relationships
3. Validate with `scripts/validate-inventory.ps1`

**On every file remove:**
1. Remove entry from `INVENTORY.json`
2. Update dependent entries' relationships
3. Validate inventory

**On version bump:**
1. Update `INVENTORY.json` version field
2. Update all entity versions
3. Update last_updated timestamps

### Validation

```powershell
# Validate inventory against filesystem
.\docs\repo-keeper\scripts\validate-inventory.ps1

# Expected output:
# ✓ All 120 paths exist
# ✓ No orphaned files found
# ✓ All relationships valid
```

---

## Maintenance Schedule

### On Every Commit
- Run link checker (if CI/CD active)
- Verify no broken references

### On Every Version Bump
1. Update `CHANGELOG.md` with new version header
2. Update all version footers in documentation
3. Update `plugin.json` and `marketplace.json`
4. Update `INVENTORY.json` version
5. Update `data/secrets.json` and `variables.json` versions
6. Run `scripts/check-version-sync.ps1` to verify

### Monthly
- Review and update `data/official-images.json` tags
- Check for security updates in dependencies
- Scan for broken external links

### Quarterly
- Run full consistency audit
- Review consolidation opportunities
- Check for new redundancy
- Update domain allowlists (`data/allowable-domains.json`)

### Before Each Release
- Review this checklist
- Review `docs/RELEASE_CHECKLIST.md`
- Run all validation scripts
- Test manual procedures

---

## Quick Fix Priorities

| Priority | Issue | Files | Effort | Script |
|----------|-------|-------|--------|--------|
| High | Add missing version footers | 39 files | 30-45 min | Manual |
| High | Fix broken links | 10 links | 15-20 min | `check-links.ps1` |
| High | Update data file versions | 2 files | 5 min | Manual |
| Medium | Document mcp-servers.json | 1 file | 10 min | Manual |
| Medium | Fix plugin naming | 1 file | 5 min | Manual |
| Low | VARIABLES/SECRETS separation | 2 files | 1-2 hours | Manual |
| Low | README/MODES consolidation | 2 files | TBD | Community feedback |

---

## Implementation Notes

**This checklist should be:**
1. Reviewed before each release alongside `docs/RELEASE_CHECKLIST.md`
2. Referenced from `CONTRIBUTING.md` for contributors
3. Updated as repository evolves and new patterns emerge
4. Used with automation scripts in `docs/repo-keeper/scripts/`

**Related automation:**
- `scripts/check-version-sync.ps1` - Version footer validation
- `scripts/check-links.ps1` - Markdown link checker
- `scripts/validate-inventory.ps1` - Inventory vs filesystem validator
- `workflows/validate-versions.yml` - GitHub Action for version checking
- `workflows/validate-links.yml` - GitHub Action for link validation

---

**Last Updated:** 2025-12-16
**Version:** 3.0.0
