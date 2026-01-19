---
description: Run repo-keeper validation with checker→validator→planner agent pipeline
argument-hint: "[--quick|--full] [--check=NAME] [--skip-validation] [--no-plan]"
allowed-tools: []
---

# Repo-Keeper Validation

Run comprehensive repository validation using the sub-agent architecture.

## Usage

```bash
/sandboxxer:repo-keeper [--quick|--full] [--check=NAME] [--skip-validation] [--no-plan]
```

## Options

- `--quick`: Tier 1 checks only (structural validation) - version-sync, links, inventory, relationships, schemas, permissions
- `--full`: All checks including external link validation and content checks
- `--check=NAME`: Run only a specific check (e.g., `--check=version-sync`)
- `--skip-validation`: Run checkers only, skip validator agents
- `--no-plan`: Skip remediation plan generation

## Default Behavior

Without arguments, runs **standard validation** (Tier 1 + Tier 2 checks).

## Workflow

### Phase 1: Run Checker Agents

Checkers run in sequence. Each checker:
1. Executes its validation script
2. Parses output into JSON findings
3. Writes to `.internal/repo-keeper/reports/findings/`

**Tier 1 Checkers** (structural - quick):
- rk-version-sync-checker
- rk-links-checker (internal only)
- rk-inventory-checker
- rk-relationships-checker
- rk-schemas-checker
- rk-permissions-checker

**Tier 2 Checkers** (completeness - moderate):
- rk-completeness-checker
- rk-compose-checker
- rk-dockerfiles-checker
- rk-templates-checker

**Tier 3 Checkers** (content - thorough):
- rk-content-checker
- rk-links-checker (with --full, includes external links)

### Phase 2: Run Validator Agents

Validators run after their paired checker completes. Each validator:
1. Reads checker findings JSON
2. Verifies each finding for accuracy
3. Filters false positives
4. May request human input for ambiguous cases via AskUserQuestion
5. Writes to `.internal/repo-keeper/reports/validated/`

Validators run conditionally:
- **Skip if `--skip-validation` flag is set**
- **Skip if checker found 0 issues**
- **Run otherwise**

### Phase 3: Run Remediation Planner

The remediation planner:
1. Reads all validated findings
2. Aggregates and prioritizes by severity and effort
3. Creates `docs/plans/remediation-YYYY-MM-DD.md`

Planner runs conditionally:
- **Skip if `--no-plan` flag is set**
- **Skip if all validators found 0 confirmed issues**
- **Run otherwise**

### Phase 4: Report Summary

Display:
- Total checks run
- Findings by category
- Validated findings count
- Link to remediation plan (if created)

## Examples

```bash
# Quick structural validation (~10 seconds)
/sandboxxer:repo-keeper --quick

# Standard validation (~30 seconds)
/sandboxxer:repo-keeper

# Full validation including external links (~2-5 minutes)
/sandboxxer:repo-keeper --full

# Check only version sync
/sandboxxer:repo-keeper --check=version-sync

# Run checkers only, no validation or planning
/sandboxxer:repo-keeper --skip-validation --no-plan
```

## Output Files

| Directory | Purpose | Files |
|-----------|---------|-------|
| `.internal/repo-keeper/reports/findings/` | Checker outputs | `{check-name}-findings.json` (11 files) |
| `.internal/repo-keeper/reports/validated/` | Validator outputs | `{check-name}-validated.json` (11 files) |
| `docs/plans/` | Remediation plans | `remediation-YYYY-MM-DD.md` |

## Notes

- The `.internal/` directory is gitignored, so findings are not committed
- Remediation plans in `docs/plans/` ARE committed for tracking
- Validators may pause for human input on ambiguous findings
- Use `--quick` for CI/CD pipelines
- Use `--full` before releases

---

**Last Updated:** 2026-01-01
**Version:** 4.6.0

