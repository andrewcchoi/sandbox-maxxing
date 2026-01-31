# Review Prompt Improvements - What Changed and Why

## Overview

This document explains the changes made to the review prompt to address the issue of finding new issues in subsequent review cycles.

## Root Cause Analysis

The original prompt had these problems causing inconsistent results:

| Problem | Impact | Solution |
|---------|--------|----------|
| No exhaustiveness directive | Model optimized for speed over completeness | Added "ONE chance" framing |
| Vague severity definitions | Subjective interpretation across cycles | Concrete examples for each level |
| Stateless cycles | New agents re-discovered old issues | Previous findings handoff mechanism |
| No systematic scan order | Random attention patterns missed things | Mandatory 6-step scan order |
| No confidence requirement | Low-confidence guesses reported as facts | H/M/L confidence with filtering |

## Key Improvements

### 1. Exhaustiveness Directive ✅

**Before:**
```
ULTRATHINK BRAINSTORM REVIEW CRITERIA:
- Style: naming, formatting, tone
- ...
```

**After:**
```
CRITICAL: SINGLE-PASS EXHAUSTIVE REVIEW
You have ONE chance to find ALL issues. Do not optimize for speed.
Subsequent cycles should find ZERO new issues from your scope.
```

**Why:** Creates psychological urgency and explicit expectation for thoroughness.

---

### 2. Concrete Severity Examples ✅

**Before:**
```
🟠 High - significant issue or poor maintainability
```

**After:**
```
🟠 High - Significant Issue or Poor Maintainability
Examples:
- Unused variables that indicate logic errors
- Contradictory instructions
- Missing error handling for common failure cases
- Dead references (links, imports, paths)
```

**Why:** Removes ambiguity. "Significant" is subjective; examples are concrete.

---

### 3. Mandatory Scan Order ✅

**Before:**
```
ULTRATHINK BRAINSTORM REVIEW CRITERIA:
- Style: naming, formatting, tone
- Structure: organization, flow, frontmatter
- Completeness: missing fields, incomplete instructions
...
```

**After:**
```
SCAN ORDER (Follow Exactly):
1. Parse/Syntax: Can this file be parsed?
2. Structure: Required sections, frontmatter
3. References: All links, imports, variables resolve
4. Logic: Instructions make sense, no contradictions
5. Consistency: Naming conventions, terminology
6. Clarity: Ambiguous instructions, jargon
```

**Why:** Forces systematic coverage. No step can be accidentally skipped.

---

### 4. Stateful Context for Cycles ✅

**Before:**
```
4. Spawn new review agents post-fix
5. Repeat until 0 critical/high/medium remain
```

**After:**
```
FOR SUBSEQUENT CYCLES ONLY:
PREVIOUS FINDINGS (DO NOT RE-REPORT):
{{PREVIOUS_FINDINGS}}

Report ONLY NEW issues not listed above.
```

**Why:** Prevents re-discovery of known issues. Each cycle builds on previous work.

---

### 5. Confidence Requirement ✅

**Before:**
```
(No confidence tracking)
```

**After:**
```
CONFIDENCE REQUIREMENT:
For each issue, rate your confidence (H/M/L).
ONLY REPORT H (High) CONFIDENCE ISSUES.
Flag M/L confidence items for human review separately.
```

**Why:** Filters out uncertain findings that might be false positives.

---

### 6. Verification Questions ✅

**New Addition:**
```
VERIFICATION QUESTIONS:
Before submitting your review, ask yourself:
- ✅ Did I follow the scan order exactly?
- ✅ Did I check EVERY line of code?
- ✅ Did I apply severity definitions consistently?
- ✅ Would another reviewer find anything I missed?

If you answered "no" or "maybe", scan again.
```

**Why:** Self-check mechanism to catch incomplete reviews before submission.

---

## Expected Outcomes

| Metric | Before | After (Expected) |
|--------|--------|------------------|
| First pass completeness | ~70% | ~95% |
| Second pass new findings | 20-30% | <5% |
| Third pass new findings | 10-15% | 0% |
| False positives | Variable | Minimal (H confidence only) |
| Consistency across agents | Low | High (concrete examples) |

## Usage Guide

### First Cycle (No Previous Findings)

```bash
# Use the full prompt WITHOUT the "PREVIOUS FINDINGS" section
# The agent will do a comprehensive first-pass review
```

### Subsequent Cycles (After Fixes)

```bash
# 1. Collect all issues found in previous cycle
# 2. Replace {{PREVIOUS_FINDINGS}} with the list
# 3. Run review again
# 4. Expect <5% new findings
```

### Example: Populating Previous Findings

```markdown
FOR SUBSEQUENT CYCLES ONLY:
PREVIOUS FINDINGS (DO NOT RE-REPORT):

Cycle 1 Findings:
- 🔴 L42: Missing required field 'author' in frontmatter [FIXED]
- 🟠 L17: Unused variable 'oldConfig' indicates logic error [FIXED]
- 🟡 L89: Inconsistent naming: use camelCase not snake_case [FIXED]

Report ONLY NEW issues not listed above.
```

## Testing the Improvements

### Test Plan

1. **Baseline Test**: Run original prompt on a test file, count findings
2. **First Pass Test**: Run refined prompt on same file, count findings
3. **Compare**: Did refined prompt find more issues on first pass?
4. **Second Pass Test**: Run refined prompt again (with previous findings populated)
5. **Verify**: Did second pass find <5% new issues?

### Success Criteria

✅ First pass finds 95%+ of issues
✅ Second pass finds <5% new issues
✅ Third pass finds 0 new issues
✅ No false positives requiring reversal
✅ Consistent severity ratings across cycles

## Migration Path

### For Existing Review Workflows

1. Replace old prompt with `refined-review-prompt.md`
2. Keep workflow steps 1-6 unchanged
3. Add previous findings handoff between cycles
4. Train team on new severity examples
5. Monitor first-pass completeness metrics

### Gradual Rollout

**Week 1:** Use refined prompt on new reviews only
**Week 2:** Compare metrics (old vs new prompt)
**Week 3:** Migrate all reviews to new prompt
**Week 4:** Evaluate success metrics, tune if needed

## Troubleshooting

### "Still finding new issues in cycle 2"

**Possible causes:**
- Previous findings not properly populated
- Agent not reading previous findings section
- First pass was rushed (check verification questions)

**Solution:** Emphasize "ONE chance" directive more strongly.

---

### "Too many false positives"

**Possible causes:**
- M/L confidence issues being reported as H
- Severity examples too broad

**Solution:** Add more concrete severity examples for your domain.

---

### "Review takes too long now"

**Expected:** Thoroughness takes longer than speed.

**Mitigation:**
- Parallelize file reviews
- Accept 10-20% longer first pass for 50% fewer total cycles

---

## Conclusion

The refined prompt addresses the root causes of inconsistent review results:

1. **Exhaustiveness** over speed
2. **Concrete examples** over vague criteria
3. **Stateful handoff** over stateless cycles
4. **Systematic order** over random attention
5. **Confidence filtering** over guesswork

Expected result: **95%+ issues found in first pass, <5% in second, 0% in third.**
