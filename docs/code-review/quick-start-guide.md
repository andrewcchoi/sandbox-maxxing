# Quick Start Guide - Using the Refined Review Prompt

## TL;DR

Use `refined-review-prompt.md` for thorough, consistent code reviews. First pass should catch 95%+ of issues.

## Basic Usage

### First Cycle (Initial Review)

1. Copy the prompt from `refined-review-prompt.md`
2. **Remove** the "FOR SUBSEQUENT CYCLES ONLY" section
3. Provide the file(s) to review
4. Review agent will follow the 6-step scan order
5. Collect all findings in a list

### Subsequent Cycles (After Fixes)

1. Apply fixes from first cycle
2. Copy the prompt again
3. **Keep** the "FOR SUBSEQUENT CYCLES ONLY" section
4. Replace `{{PREVIOUS_FINDINGS}}` with the list from first cycle
5. Run review again
6. Should find <5% new issues

### Final Cycle

When a cycle finds 0 new issues, you're done!

## Example Workflow

### Step 1: First Review

```markdown
# Using refined-review-prompt.md (without PREVIOUS FINDINGS section)

Files to review:
- src/components/UserProfile.tsx
- src/utils/validator.ts

Agent spawns and reports findings...
```

**Output:**
```markdown
## Cycle 1 - UserProfile.tsx
| Sev | Conf | Line | Issue | Fix |
|-----|------|------|-------|-----|
| 🔴  | H    | L42  | Missing null check for user.email | Added null check |
| 🟠  | H    | L17  | Unused import 'useState' | Removed import |
| 🟡  | H    | L89  | Inconsistent naming: userName vs user_name | Renamed to userName |

Summary: 1🔴 1🟠 1🟡 → CONTINUE
```

### Step 2: Apply Fixes

Surgeon agents fix the 3 issues found in Cycle 1.

### Step 3: Second Review (With Previous Findings)

```markdown
# Using refined-review-prompt.md (WITH PREVIOUS FINDINGS section)

FOR SUBSEQUENT CYCLES ONLY:
PREVIOUS FINDINGS (DO NOT RE-REPORT):

Cycle 1 Findings - UserProfile.tsx:
- 🔴 L42: Missing null check for user.email [FIXED]
- 🟠 L17: Unused import 'useState' [FIXED]
- 🟡 L89: Inconsistent naming: userName vs user_name [FIXED]

Report ONLY NEW issues not listed above.

Files to review:
- src/components/UserProfile.tsx (post-fix)
```

**Output:**
```markdown
## Cycle 2 - UserProfile.tsx
| Sev | Conf | Line | Issue | Fix |
|-----|------|------|-------|-----|
| 🟡  | H    | L45  | Missing JSDoc comment for formatEmail function | Added comment |

Summary: 0🔴 0🟠 1🟡 → CONTINUE
```

### Step 4: Apply Fixes & Final Review

```markdown
## Cycle 3 - UserProfile.tsx
(No new issues found)

Summary: 0🔴 0🟠 0🟡 → DONE
```

## Command-Line Usage Pattern

```bash
# Cycle 1: Full review
claude review --prompt=refined-review-prompt.md --files="src/**/*.ts"

# Collect findings, apply fixes

# Cycle 2: Incremental review with history
claude review --prompt=refined-review-prompt.md \
  --files="src/**/*.ts" \
  --previous-findings="cycle1-findings.txt"

# Repeat until clean
```

## Pro Tips

### Tip 1: Parallel File Reviews

Review multiple files in parallel for speed:

```markdown
Spawn parallel review agents:
- Agent 1: UserProfile.tsx
- Agent 2: validator.ts
- Agent 3: api.ts

Collect findings from all agents
Apply fixes in parallel
Re-review in parallel
```

### Tip 2: Focus on High-Severity First

If time-constrained:
1. First cycle: Fix only 🔴 Critical
2. Second cycle: Fix only 🟠 High
3. Third cycle: Fix 🟡 Medium
4. Log 🟢 Low for later

### Tip 3: Use Confidence for Triage

**H Confidence:** Fix immediately
**M Confidence:** Flag for domain expert review
**L Confidence:** Skip or investigate manually

### Tip 4: Track Metrics

Monitor these over time:
- Issues found per cycle
- Cycles needed to reach 0 issues
- False positive rate
- Time to completion

Target metrics:
- Cycle 1: 95% of all issues
- Cycle 2: <5% new issues
- Cycle 3: 0 new issues

## Customization

### Adding Domain-Specific Checks

Add to the scan order:

```markdown
7. **Domain**: Custom checks for your project
   - API endpoint naming follows convention
   - Database queries use prepared statements
   - i18n strings are properly tagged
```

### Adjusting Severity Examples

Tailor to your project:

```markdown
🔴 Critical - For a medical app:
- PHI exposure risks
- Incorrect dosage calculations
- Missing HIPAA compliance checks
```

### Confidence Calibration

If getting too many M/L items:
- Tighten H confidence definition
- Require concrete evidence (not intuition)
- Add examples of H vs M confidence

## Troubleshooting

### Problem: Agent ignores scan order

**Solution:** Add emphasis:
```markdown
CRITICAL: Follow scan order EXACTLY.
Do steps 1-6 in order. Do not skip.
```

### Problem: Re-reports old issues

**Solution:** Make previous findings more explicit:
```markdown
These issues were ALREADY FOUND and FIXED:
[detailed list]

DO NOT REPORT THESE AGAIN.
```

### Problem: Misses obvious issues

**Solution:** Add to verification questions:
```markdown
- Did I check for [specific issue type]?
- Would a junior dev catch what I missed?
```

## Integration with Existing Tools

### GitHub Actions

```yaml
- name: Review PR changes
  run: |
    claude review \
      --prompt=refined-review-prompt.md \
      --files=$(git diff --name-only main)
```

### Pre-commit Hook

```bash
#!/bin/bash
changed_files=$(git diff --cached --name-only)
claude review --prompt=refined-review-prompt.md --files="$changed_files"
```

### CI/CD Pipeline

```yaml
review:
  stage: test
  script:
    - claude review --prompt=refined-review-prompt.md --strict
  only:
    - merge_requests
```

## Support

For issues with the prompt:
1. Check the verification questions
2. Review severity examples
3. Ensure previous findings are populated correctly
4. Compare output against expected metrics

## Next Steps

1. ✅ Read `refined-review-prompt.md` in full
2. ✅ Test on a sample file
3. ✅ Compare results to old prompt
4. ✅ Integrate into your workflow
5. ✅ Track metrics and adjust as needed

---

**Remember:** The goal is 95%+ issues found on first pass. If you're seeing more than 5% new issues in cycle 2, something needs adjustment.
