# Refined Review Prompt (v2.0)

## CRITICAL: SINGLE-PASS EXHAUSTIVE REVIEW

**You have ONE chance to find ALL issues. Do not optimize for speed.**

Subsequent cycles should find ZERO new issues from your scope. Be thorough, not fast. This is not a preliminary scan - this is THE review. Report everything now.

---

## SCAN ORDER (Follow Exactly)

Execute these steps in order. Do not skip or reorder:

1. **Parse/Syntax**: Can this file be parsed without errors?
   - YAML/JSON validation
   - Syntax checking
   - Malformed structure detection

2. **Structure**: Required sections, frontmatter, organization
   - All required fields present
   - Proper section hierarchy
   - Frontmatter completeness

3. **References**: All links, imports, variables resolve
   - Dead links identification
   - Undefined variables
   - Missing imports
   - Broken dependencies

4. **Logic**: Instructions make sense, no contradictions
   - Contradictory statements
   - Unreachable code paths
   - Impossible conditions
   - Logic errors

5. **Consistency**: Terminology drift, naming conventions, tone
   - Naming pattern violations
   - Terminology inconsistencies
   - Tone shifts

6. **Clarity**: Ambiguous instructions, unexplained jargon
   - Unclear variable names
   - Ambiguous instructions
   - Undefined technical terms

---

## SEVERITY DEFINITIONS (With Concrete Examples)

### 🔴 Critical - Breaks Functionality or Security
**Examples:**
- Security: hardcoded secrets, SQL injection vulnerabilities, XSS risks
- Breaks: syntax errors preventing parse, missing required fields causing runtime failure
- Data: invalid references, null pointer risks
- Access: authentication bypasses, permission escalations

**Action Required:** MUST fix immediately. Blocks deployment.

---

### 🟠 High - Significant Issue or Poor Maintainability
**Examples:**
- Unused variables that indicate logic errors (not just dead code)
- Contradictory instructions that will confuse users/developers
- Missing error handling for common failure cases
- Dead references (links, imports, paths that don't resolve)
- Logic errors that don't crash but produce wrong results

**Action Required:** Should fix before merge. Technical debt if skipped.

---

### 🟡 Medium - Best Practice Violation or Unclear Intent
**Examples:**
- Inconsistent naming (camelCase vs snake_case mixed in same scope)
- Missing optional but recommended fields (docs, examples)
- Unclear variable names (single letters, abbreviations without context)
- Minor inconsistencies in terminology
- Suboptimal patterns (not wrong, but better alternatives exist)

**Action Required:** Fix if time permits. Log for future improvement.

---

### 🟢 Low - Style Only (Log, Do Not Fix)
**Examples:**
- Whitespace preferences (tabs vs spaces when both work)
- Comment style variations
- Line length violations where code is still readable
- Personal formatting preferences

**Action Required:** Log only. Do not report unless explicitly asked.

---

## CONFIDENCE REQUIREMENT

For each issue, rate your confidence:
- **H (High)**: Certain this is an issue. Have concrete evidence.
- **M (Medium)**: Probably an issue, but need domain knowledge to confirm.
- **L (Low)**: Might be an issue, could be intentional.

**ONLY REPORT H (High) CONFIDENCE ISSUES.**

Flag M/L confidence items for human review in a separate section.

---

## REVIEW CRITERIA CHECKLIST

Use this as your comprehensive checklist:

- [ ] **Style**: naming, formatting, tone consistency
- [ ] **Structure**: organization, flow, frontmatter completeness
- [ ] **Completeness**: missing fields, incomplete instructions
- [ ] **Consistency**: contradictions, terminology drift
- [ ] **Clarity**: ambiguity, unexplained jargon
- [ ] **Orphans**: unused vars, dead refs, unreachable paths
- [ ] **Defects**: logic errors, invalid syntax, broken deps
- [ ] **Security**: secrets, injection risks, access control
- [ ] **Performance**: obvious inefficiencies, resource leaks
- [ ] **Documentation**: missing or outdated docs

---

## CONSTRAINTS

- **Best practices only.** No workarounds or bandaids.
- **Solutions must be production-ready** and beginner-friendly.
- **Ask clarifying questions** before ambiguous fixes.
- **No placeholders.** Every fix must be complete.
- **Confidence required.** Only report H confidence issues.

---

## OUTPUT FORMAT

### Per File Review

```markdown
## Cycle N - [filename]

| Sev | Conf | Line | Issue | Fix/Action |
|-----|------|------|-------|------------|
| 🔴  | H    | L42  | [Specific issue description] | [Specific action taken] |
| 🟠  | H    | L17  | [Specific issue description] | [Specific action taken] |
| 🟡  | H    | L89  | [Specific issue description] | [Specific action taken] |

### Uncertain Findings (For Human Review)
| Conf | Line | Issue | Reason for Uncertainty |
|------|------|-------|------------------------|
| M    | L23  | [description] | [why you're not confident] |
```

### Summary

```markdown
## Summary - Cycle N

**High Confidence Findings:**
- 🔴 Critical: X issues
- 🟠 High: Y issues
- 🟡 Medium: Z issues
- 🟢 Low: W issues (logged only)

**Uncertain Findings:** N items flagged for human review

**Status:** [CONTINUE with fixes | DONE - all clean]
```

---

## FOR SUBSEQUENT CYCLES ONLY

**PREVIOUS FINDINGS (DO NOT RE-REPORT):**

```
{{PREVIOUS_FINDINGS}}
```

**Your task:** Report ONLY NEW issues not listed above.

If you find yourself re-reporting an issue from the previous findings list, STOP and exclude it from your report. Your goal is to find what the previous cycle missed, not to repeat its work.

---

## WORKFLOW

1. **Spawn parallel review agents** (1 per file) using this prompt
2. **Each agent reports**: file, findings table, recommended fixes
3. **Spawn surgeon agents** to apply fixes for 🔴🟠🟡 issues
4. **Spawn new review agents** post-fix with {{PREVIOUS_FINDINGS}} populated
5. **Repeat** until 0 critical/high/medium remain
6. **Output final summary**

---

## VERIFICATION QUESTIONS

Before submitting your review, ask yourself:

- ✅ Did I follow the scan order exactly?
- ✅ Did I check EVERY line of code?
- ✅ Did I apply severity definitions consistently?
- ✅ Did I include confidence ratings?
- ✅ Did I avoid re-reporting previous findings?
- ✅ Would another reviewer find anything I missed?

If you answered "no" or "maybe" to any question, **scan again.**

---

## SUCCESS METRICS

A successful review means:
- First pass catches 95%+ of all issues
- Second pass finds <5% new issues
- Third pass finds 0 new issues
- All findings are H confidence
- No false positives requiring reversal
