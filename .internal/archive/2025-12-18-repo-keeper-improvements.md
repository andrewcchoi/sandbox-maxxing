# Repo-Keeper Improvement Plan

**Date:** 2025-12-18
**Status:** Prioritized Roadmap
**Total Gaps Identified:** 57

---

## Executive Summary

This document outlines all identified gaps and improvements for the repo-keeper validation system, organized by priority and category. Use this as a roadmap for future development.

### Key Decision: Node.js as Single Dependency

All JSON processing (currently using jq and python) will be replaced with **Node.js**:
- `ajv-cli` for JSON Schema validation
- `node -e` for JSON parsing in bash scripts
- Eliminates jq and python dependencies
- Cross-platform consistency

---

## Priority Matrix

| Priority | Category | Count | Effort |
|----------|----------|-------|--------|
| **P1 - Critical** | Missing functionality | 4 | High |
| **P2 - High** | Dependencies & Hardcoded values | 16 | Medium |
| **P3 - Medium** | Error handling & Cross-platform | 15 | Medium |
| **P4 - Low** | Missing checks & Testing | 22 | High |

---

## P1: Critical Gaps (Fix Before Next Release)

### 1.1 Orphan File Detection Not Implemented in Bash

**File:** `/workspace/docs/repo-keeper/scripts/validate-inventory.sh`
**Lines:** 245, 335-336
**Issue:** Script explicitly states "Not implemented in bash version yet"
**Impact:** Linux/macOS users cannot detect files that exist but aren't in INVENTORY.json

**Fix:**
```bash
# Add orphan detection function (port from PowerShell version)
find_orphan_files() {
    local INVENTORY_FILE="$1"
    local DIRS_TO_SCAN=("skills" "commands" "templates" "examples" "data" "docs")

    for dir in "${DIRS_TO_SCAN[@]}"; do
        if [[ -d "$REPO_ROOT/$dir" ]]; then
            while IFS= read -r -d '' file; do
                # Check if file is in INVENTORY.json
                local rel_path="${file#$REPO_ROOT/}"
                if ! grep -q "\"$rel_path\"" "$INVENTORY_FILE"; then
                    echo "ORPHAN: $rel_path"
                fi
            done < <(find "$REPO_ROOT/$dir" -type f -print0)
        fi
    done
}
```

**Effort:** 2-3 hours

---

### 1.2 JSON Schema Validation Not Performed

**Files:**
- `/workspace/docs/repo-keeper/scripts/validate-schemas.sh` (lines 31-36)
- `/workspace/docs/repo-keeper/scripts/validate-schemas.ps1`

**Issue:** Scripts only validate JSON syntax and check for required fields manually. They do NOT actually validate against the JSON Schema files (`inventory.schema.json`, `data-file.schema.json`).

**Impact:** INVENTORY.json and data files may have structural issues not caught by validation.

**Fix: Use ajv-cli (Node.js) - SELECTED**
```bash
# Install: npm install -g ajv-cli ajv-formats
ajv validate -s schemas/inventory.schema.json -d INVENTORY.json --spec=draft7
```

**Effort:** 4-6 hours (including testing)

> **Note:** Node.js selected as the single dependency for ALL JSON operations across repo-keeper. This replaces jq and python usage.

---

### 1.3 Minimal Data-File Schema

**File:** `/workspace/docs/repo-keeper/schemas/data-file.schema.json`

**Current Schema (too permissive):**
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "version": { "type": "string" },
    "description": { "type": "string" }
  }
}
```

**Issue:** Only defines 2 optional properties. Cannot validate actual data file structure.

**Fix:** Create specific schemas for each data file type:
- `secrets.schema.json`
- `variables.schema.json`
- `mcp-servers.schema.json`
- `official-images.schema.json`
- etc.

**Effort:** 4-6 hours

---

### 1.4 Hardcoded Windows Paths in PowerShell Scripts

**Files with wrong paths:**
| File | Line | Current Value |
|------|------|---------------|
| `validate-inventory.ps1` | 10 | `$repoRoot = "D:\!wip\sandbox-maxxing"` |
| `check-links.ps1` | 10 | `$repoRoot = "D:\!wip\sandbox-maxxing"` |
| `check-version-sync.ps1` | 9 | `$repoRoot = "D:\!wip\sandbox-maxxing"` |

**Fix:** Standardize all scripts to auto-detect repo root:
```powershell
# Auto-detect repo root from script location
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Get-Item "$scriptPath\..\..\..").FullName

# Or allow override via environment variable
if ($env:REPO_ROOT) {
    $repoRoot = $env:REPO_ROOT
}
```

**Effort:** 1-2 hours

---

## P2: High Priority (Next Sprint)

### 2.1 Unified Node.js Dependency

**Decision:** Replace ALL jq and python usage with Node.js

| ID | Script | Current Dependency | New Approach |
|----|--------|-------------------|--------------|
| D1 | `validate-inventory.sh:31-34` | python3 | **Node.js** `node -e` |
| D2 | `validate-relationships.sh:31-38` | jq | **Node.js** `node -e` |
| D3 | `validate-completeness.sh:31-34` | jq | **Node.js** `node -e` |
| D4 | `validate-content.sh:150-168` | curl | Keep curl (HTTP only) |
| D5 | `validate-schemas.sh:31-36` | jq | **ajv-cli** (Node.js) |
| D6 | `validate-links.yml:25` | pwsh | Use bash version instead |

**Single Dependency Check:**
```bash
check_node() {
    if ! command -v node &>/dev/null; then
        echo -e "${RED}Error: Node.js is required but not installed${NC}"
        echo "Install with: https://nodejs.org/ or 'nvm install --lts'"
        exit 1
    fi

    # Check for ajv-cli
    if ! command -v ajv &>/dev/null; then
        echo -e "${YELLOW}Installing ajv-cli...${NC}"
        npm install -g ajv-cli ajv-formats
    fi
}
```

**Node.js JSON Helper (replaces jq/python):**
```bash
# Create helper script: scripts/json-helper.js
# Usage: node scripts/json-helper.js <file> <query>
# Example: node scripts/json-helper.js INVENTORY.json '.skills[].name'

# Or inline:
node -e "console.log(JSON.parse(require('fs').readFileSync('$FILE')).version)"
```

**Benefits:**
- Single dependency (Node.js) instead of jq + python
- ajv-cli provides robust JSON Schema validation
- Native JSON support in Node.js
- Cross-platform consistency

**Effort:** 4-5 hours (refactor all scripts)

---

### 2.2 Additional Hardcoded Values

| ID | Location | Issue | Fix |
|----|----------|-------|-----|
| H1 | `run-all-checks.sh:8` | `REPO_ROOT="/workspace"` | Auto-detect |
| H2 | `run-all-checks.ps1:13` | `$repoRoot = "/workspace"` | Auto-detect |
| H7 | `validate-content.sh:118` | `head -50` limit | Make configurable |
| H8 | `validate-content.sh:150` | `head -20` external links | Make configurable |
| H9 | `check-version-sync.sh:135-136` | Hardcoded data files list | Read from INVENTORY.json |
| H10 | `INVENTORY.json:2` | Relative schema path | Use absolute or document |

**Effort:** 2-3 hours

---

### 2.3 Document Dependencies in README

**File:** `/workspace/docs/repo-keeper/README.md`

**Add section:**
```markdown
## Dependencies

### Required
- `Node.js` 18+ (for JSON processing and schema validation)
- `bash` 4.0+ (for bash scripts)
- `PowerShell Core` 7.0+ (for PowerShell scripts)

### Auto-installed (via npm)
- `ajv-cli` - JSON Schema validation
- `ajv-formats` - Additional schema format validators

### Optional
- `curl` - External link checking (bash only)

### Install Dependencies

**All Platforms (Node.js):**
```bash
# Install Node.js from https://nodejs.org/ or use nvm:
nvm install --lts

# Install validation tools (done automatically by scripts)
npm install -g ajv-cli ajv-formats
```

**External Link Checking (optional):**
```bash
# Ubuntu/Debian
apt install curl

# macOS (pre-installed)

# Windows (use PowerShell's Invoke-WebRequest instead)
```
```

**Effort:** 1 hour

---

## P3: Medium Priority (Next Month)

### 3.1 Error Handling Gaps

| ID | Location | Issue | Fix |
|----|----------|-------|-----|
| E1 | `run-all-checks.sh:96` | Subshell exit codes may be swallowed | Check $? explicitly |
| E2 | `validate-inventory.sh:60-73` | `((VAR++))` fails with set -e when VAR=0 | Use `VAR=$((VAR + 1))` |
| E3 | `check-links.sh:50-121` | Pipe errors not propagated | Use `set -o pipefail` |
| E4 | `validate-completeness.sh:55-58` | `|| true` suppresses errors | Add error logging before suppression |
| E5 | All scripts | No SIGINT/SIGTERM handlers | Add `trap cleanup EXIT` |
| E6 | `validate-schemas.sh:59,134` | `2>/dev/null` hides jq errors | Log to debug file |
| E7 | `run-all-checks.ps1:84-104` | Generic try-catch loses stack trace | Add `-ErrorAction Stop` and log full exception |

**Effort:** 4-6 hours

---

### 3.2 Cross-Platform Parity

| ID | Feature | Bash | PowerShell | Fix |
|----|---------|------|------------|-----|
| X1 | Repo root | `/workspace` | `D:\!wip\...` or `/workspace` | Standardize to auto-detect |
| X2 | Path separator | `/` | Mixed `/` and `\` | Use `[IO.Path]::Combine()` in PS |
| X3 | Orphan detection | NOT IMPLEMENTED | Implemented | Port to bash |
| X4 | External links | `curl` | `Invoke-WebRequest` | Document differences |
| X5 | File finding | `find -print0` | `Get-ChildItem` | Ensure same results |
| X6 | Regex | `grep -oP` | PowerShell regex | Test equivalence |
| X7 | Verbose flag | `-v`/`--verbose` | `-Verbose` | Standardize interface |
| X8 | CRLF handling | `--fix-crlf` | `-FixCrlf` | Document both |

**Effort:** 6-8 hours

---

## P4: Low Priority (Future)

### 4.1 Missing Validation Checks

| ID | Check | Description | Effort |
|----|-------|-------------|--------|
| V1 | Schema compliance | Actually validate against JSON Schemas | 4h |
| V2 | Duplicate entries | Check for duplicate paths in INVENTORY | 1h |
| V3 | Circular references | Detect skill A → B → A loops | 2h |
| V4 | Semver format | Strict semver validation | 1h |
| V5 | Future timestamps | Check `last_updated` not in future | 0.5h |
| V6 | File permissions | Verify scripts are executable | 1h |
| V7 | UTF-8 BOM | Detect encoding issues | 1h |
| V8 | Anchor links | Validate `#section` references | 3h |
| V9 | Image references | Check images in markdown exist | 2h |
| V10 | Code block syntax | Validate fenced code language tags | 1h |
| V11 | YAML frontmatter | Validate markdown frontmatter | 2h |
| V12 | Data file schemas | Validate each data file type | 4h |
| V13 | Template variables | Check `{{placeholder}}` syntax | 2h |
| V14 | Dockerfile syntax | Lint Dockerfiles | 2h |
| V15 | docker-compose syntax | Validate compose files | 2h |

**Total Effort:** ~28 hours

---

### 4.2 Testing & Documentation

| ID | Item | Description | Effort |
|----|------|-------------|--------|
| T1 | Test suite | Create test framework for validation scripts | 8h |
| T2 | Unit tests | Add tests for each validator function | 16h |
| T3 | Dependencies doc | Document all required tools | 1h |
| T4 | Exit codes doc | Document return codes for all scripts | 1h |
| T5 | Error recovery doc | Guide for handling validation failures | 2h |
| T6 | Schema docs | Explain each JSON Schema | 2h |
| T7 | Fix README | Remove reference to non-existent bash orphan detection | 0.5h |

**Total Effort:** ~30 hours

---

## Implementation Roadmap

### Phase 1: Critical Fixes (Week 1-2)
- [ ] 1.1 Implement orphan detection in bash
- [ ] 1.2 Add proper JSON Schema validation
- [ ] 1.3 Expand data-file schemas
- [ ] 1.4 Fix hardcoded Windows paths

### Phase 2: Dependencies & Config (Week 3-4)
- [ ] 2.1 Add dependency checks to all scripts
- [ ] 2.2 Standardize repo root detection
- [ ] 2.3 Update README with dependencies

### Phase 3: Robustness (Week 5-6)
- [ ] 3.1 Fix error handling issues
- [ ] 3.2 Achieve cross-platform parity

### Phase 4: Completeness (Week 7-12)
- [ ] 4.1 Add missing validation checks (prioritize V1, V2, V8)
- [ ] 4.2 Create test suite
- [ ] 4.2 Write comprehensive documentation

---

## Quick Wins (Can Do Today)

1. **Fix README orphan detection claim** - Remove mention of bash capability (T7) - 10 min
2. **Standardize repo root in 3 PS scripts** - Find/replace (1.4) - 15 min
3. **Add dependency check template** - Create reusable function (2.1) - 30 min
4. **Document known limitations** - Add to README (2.3) - 20 min

---

## Files to Modify

### Scripts
- `/workspace/docs/repo-keeper/scripts/validate-inventory.sh` - orphan detection
- `/workspace/docs/repo-keeper/scripts/validate-schemas.sh` - schema validation
- `/workspace/docs/repo-keeper/scripts/validate-schemas.ps1` - schema validation
- `/workspace/docs/repo-keeper/scripts/validate-inventory.ps1` - fix path
- `/workspace/docs/repo-keeper/scripts/check-links.ps1` - fix path
- `/workspace/docs/repo-keeper/scripts/check-version-sync.ps1` - fix path
- `/workspace/docs/repo-keeper/scripts/run-all-checks.sh` - dependency checks
- `/workspace/docs/repo-keeper/scripts/run-all-checks.ps1` - dependency checks

### Schemas
- `/workspace/docs/repo-keeper/schemas/data-file.schema.json` - expand
- `/workspace/docs/repo-keeper/schemas/secrets.schema.json` - create
- `/workspace/docs/repo-keeper/schemas/variables.schema.json` - create

### Documentation
- `/workspace/docs/repo-keeper/README.md` - dependencies, exit codes, limitations

---

## Metrics for Success

| Metric | Current | Target |
|--------|---------|--------|
| Critical gaps | 4 | 0 |
| External dependencies | 3 (jq, python, curl) | 1 (Node.js) |
| Scripts with dependency checks | 0/8 | 8/8 |
| Cross-platform parity | ~70% | 100% |
| Test coverage | 0% | 80% |
| Documented dependencies | 0 | All |

---

## Summary of Changes from Original Plan

1. **JSON Schema validation:** Using `ajv-cli` (Node.js)
2. **JSON parsing:** Replaced jq/python with `node -e`
3. **Single dependency:** Node.js replaces jq + python
4. **Curl retained:** For external HTTP link checking only
