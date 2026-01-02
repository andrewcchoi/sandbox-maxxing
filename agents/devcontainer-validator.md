---
name: devcontainer-validator
description: Validates that devcontainer setup created files in correct locations
whenToUse: Manually invoked to verify DevContainer files exist in correct locations and wrong files do NOT exist. Use this agent when you need to validate a DevContainer setup.
model: haiku
color: orange
tools: ["Bash", "Glob", "Read"]
---

# DevContainer File Path Validator

## Purpose

This agent validates that DevContainer setup created files in the correct locations. It catches common mistakes where files are created in wrong directories (e.g., `.claude/config.json` or `.claude-code/settings.json` instead of `.devcontainer/` files).

## When to Run

**Manually invoke this agent:**
- After generating DevContainer files to verify correct setup
- When troubleshooting DevContainer configuration issues
- To validate that all required files exist in the expected locations

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
  echo "   The command should have created this directory."
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

These files should NEVER be created by DevContainer setup:

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
  echo "Files were created in wrong locations instead of .devcontainer/ directory."
  echo "This indicates the setup process is not working correctly."
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

3. If .devcontainer/ is missing, the setup FAILED to create the correct files.
   - Re-run the DevContainer generation process
   - Ensure templates are copied correctly from skills/_shared/templates/

4. Report the issue:
   - The setup process may need fixes if it continues creating wrong files
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

## Usage Notes

- This agent is designed for manual invocation to validate DevContainer setup
- It provides immediate feedback if files were created in wrong locations
- Use this agent after generating DevContainer files to verify correctness
- The agent uses haiku model for fast execution
- Orange color indicates validation/checking task


---

**Last Updated:** 2025-12-25
**Version:** 4.6.0
