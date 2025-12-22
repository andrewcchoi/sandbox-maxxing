---
name: devcontainer-validator
description: Validates that devcontainer skills created files in correct locations
whenToUse: Run after devcontainer-setup-* skills complete to verify correct files exist and wrong files do NOT exist
model: haiku
color: orange
tools: ["Bash", "Glob", "Read"]
---

# DevContainer File Path Validator

## Purpose

This agent automatically validates that DevContainer setup skills created files in the correct locations. It catches common mistakes where Claude creates `.claude/config.json` or `.claude-code/settings.json` instead of `.devcontainer/` files.

## When to Run

**Automatically trigger after:**
- `devcontainer-setup-basic` skill completes
- `devcontainer-setup-intermediate` skill completes
- `devcontainer-setup-advanced` skill completes
- `devcontainer-setup-yolo` skill completes
- `devcontainer-basic` skill completes (after renaming)
- `devcontainer-intermediate` skill completes (after renaming)
- `devcontainer-advanced` skill completes (after renaming)
- `devcontainer-yolo` skill completes (after renaming)

## Validation Steps

### 1. Check for Correct Files

Run these checks to verify the expected DevContainer files exist:

```bash
echo "=== CHECKING CORRECT FILES ==="

# Check .devcontainer directory exists
if [ -d ".devcontainer" ]; then
  echo "✓ .devcontainer/ directory exists"
else
  echo "❌ ERROR: .devcontainer/ directory NOT found!"
  echo "   The skill should have created this directory."
fi

# Check for required files
if [ -f ".devcontainer/devcontainer.json" ]; then
  echo "✓ .devcontainer/devcontainer.json exists"
else
  echo "⚠️  WARNING: .devcontainer/devcontainer.json NOT found"
fi

if [ -f ".devcontainer/init-firewall.sh" ]; then
  echo "✓ .devcontainer/init-firewall.sh exists"
else
  echo "⚠️  WARNING: .devcontainer/init-firewall.sh NOT found"
fi

if [ -f ".devcontainer/setup-claude-credentials.sh" ]; then
  echo "✓ .devcontainer/setup-claude-credentials.sh exists"
else
  echo "⚠️  WARNING: .devcontainer/setup-claude-credentials.sh NOT found"
fi

if [ -f "docker-compose.yml" ]; then
  echo "✓ docker-compose.yml exists (project root)"
elif [ -f ".devcontainer/docker-compose.yml" ]; then
  echo "⚠️  WARNING: docker-compose.yml is in .devcontainer/ but should be in project root"
else
  echo "⚠️  WARNING: docker-compose.yml NOT found"
fi
```

### 2. Check for WRONG Files (Critical)

These files should NEVER be created by DevContainer skills:

```bash
echo ""
echo "=== CHECKING FOR WRONG FILES ==="

ERRORS=0

# Check for Claude Code config files
if [ -f ".claude/config.json" ]; then
  echo "❌ ERROR: .claude/config.json exists - THIS IS WRONG!"
  echo "   This is Claude Code's internal config, NOT DevContainer."
  echo "   Action: DELETE this file immediately."
  ERRORS=$((ERRORS + 1))
fi

if [ -f ".claude-code/settings.json" ]; then
  echo "❌ ERROR: .claude-code/settings.json exists - THIS IS WRONG!"
  echo "   This is Claude Code's settings, NOT DevContainer."
  echo "   Action: DELETE this file immediately."
  ERRORS=$((ERRORS + 1))
fi

if [ -f ".claude-code/config.json" ]; then
  echo "❌ ERROR: .claude-code/config.json exists - THIS IS WRONG!"
  echo "   This is Claude Code's config, NOT DevContainer."
  echo "   Action: DELETE this file immediately."
  ERRORS=$((ERRORS + 1))
fi

# Check home directory (should never create files there)
if [ -f "$HOME/.claude-code/settings.json" ]; then
  echo "❌ ERROR: ~/.claude-code/settings.json exists - THIS IS WRONG!"
  echo "   DevContainer files should be in project directory only."
  ERRORS=$((ERRORS + 1))
fi

if [ $ERRORS -eq 0 ]; then
  echo "✓ No wrong files detected"
else
  echo ""
  echo "⚠️  $ERRORS CRITICAL ERROR(S) DETECTED!"
  echo ""
  echo "The skill created Claude Code configuration files instead of DevContainer files."
  echo "This indicates the skill is not working correctly."
fi
```

### 3. Provide Remediation Guidance

If errors are found, provide specific guidance:

```
REMEDIATION STEPS:

1. DELETE the wrong files:
   - rm -f .claude/config.json
   - rm -f .claude-code/settings.json

2. VERIFY the correct files exist:
   - ls -la .devcontainer/
   - Should contain: devcontainer.json, init-firewall.sh, setup-claude-credentials.sh

3. If .devcontainer/ is missing, the skill FAILED to create the correct files.
   - Re-run the skill with the updated instructions
   - The skill should now have TASK IDENTITY and PRE-WRITE VALIDATION sections

4. Report the issue:
   - The skill may need further fixes if it continues creating wrong files
```

## Validation Output Format

Provide a summary at the end:

```
=== VALIDATION SUMMARY ===

Correct Files:
  ✓ .devcontainer/ directory
  ✓ .devcontainer/devcontainer.json
  ✓ .devcontainer/init-firewall.sh
  ✓ .devcontainer/setup-claude-credentials.sh
  ✓ docker-compose.yml (project root)

Wrong Files Detected:
  ❌ .claude/config.json (DELETE THIS)

Status: FAILED - Wrong files detected
Action Required: Delete wrong files, verify DevContainer setup
```

## Integration Notes

- This agent should run automatically after any DevContainer setup skill completes
- It provides immediate feedback if the skill created wrong files
- Users can manually invoke this agent with `/devcontainer-validator` to check their setup
- The agent uses haiku model for fast execution
- Orange color indicates validation/checking task


---

**Last Updated:** 2025-12-21
**Version:** 4.0.0
