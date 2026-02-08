---
name: devcontainer-validator
description: Validates DevContainer setup - file locations, JSON/YAML syntax, and content structure
whenToUse: |
  Use this agent when the user asks to "validate devcontainer", "check devcontainer files", "verify devcontainer setup",
  "validate my devcontainer configuration", or after generating DevContainer files to ensure they're correct.
  This agent performs comprehensive validation: file locations, JSON/YAML syntax, and content structure.

  <example>
  Context: User just created DevContainer files and wants to verify
  user: "Can you validate that my devcontainer setup is correct?"
  assistant: "I'll use the devcontainer-validator agent to verify files, syntax, and configuration."
  <commentary>Explicit validation request triggers the validator agent</commentary>
  </example>

  <example>
  Context: User is troubleshooting DevContainer issues
  user: "My devcontainer isn't working, can you check if the files are correct?"
  assistant: "I'll use the devcontainer-validator agent to check file locations, syntax, and structure."
  <commentary>Troubleshooting triggers comprehensive validation</commentary>
  </example>

  <example>
  Context: DevContainer fails to build with JSON error
  user: "I'm getting a JSON parse error when opening the devcontainer"
  assistant: "I'll use the devcontainer-validator agent to validate the JSON syntax."
  <commentary>Syntax error triggers the validator</commentary>
  </example>

  <example>
  Context: After running devcontainer generation
  user: "Did the devcontainer setup create all the right files?"
  assistant: "I'll use the devcontainer-validator agent to verify the setup."
  <commentary>Post-generation verification request triggers the validator</commentary>
  </example>
model: haiku
color: orange
tools: ["Bash", "Glob", "Read"]
---

# DevContainer Comprehensive Validator

## Purpose

This agent performs **comprehensive validation** of DevContainer configurations:

1. **File Location Validation** - Files exist in correct directories
2. **JSON/YAML Syntax Validation** - Files are valid JSON/YAML
3. **Content Structure Validation** - Required fields and values present
4. **Wrong File Detection** - Catches misplaced configuration files

## When to Run

**Invoke this agent when:**
- After generating DevContainer files to verify correct setup
- When troubleshooting DevContainer configuration issues
- When seeing JSON/YAML parse errors
- To validate all required fields are present
- Before committing DevContainer configuration

## Validation Steps

### 1. Check for Correct Files

```bash
echo "=== PHASE 1: FILE LOCATION VALIDATION ==="
echo ""

FILE_ERRORS=0
FILE_WARNINGS=0

# Check .devcontainer directory exists
if [ -d ".devcontainer" ]; then
  echo "✓ .devcontainer/ directory exists"
else
  echo "❌ ERROR: .devcontainer/ directory NOT found!"
  echo "   The command should have created this directory."
  FILE_ERRORS=$((FILE_ERRORS + 1))
fi

# Check for required files
if [ -f ".devcontainer/devcontainer.json" ]; then
  echo "✓ .devcontainer/devcontainer.json exists"
else
  echo "❌ ERROR: .devcontainer/devcontainer.json NOT found"
  FILE_ERRORS=$((FILE_ERRORS + 1))
fi

if [ -f ".devcontainer/Dockerfile" ]; then
  echo "✓ .devcontainer/Dockerfile exists"
else
  echo "⚠️  WARNING: .devcontainer/Dockerfile NOT found (may use image instead)"
  FILE_WARNINGS=$((FILE_WARNINGS + 1))
fi

if [ -f ".devcontainer/init-firewall.sh" ]; then
  echo "✓ .devcontainer/init-firewall.sh exists"
else
  echo "⚠️  WARNING: .devcontainer/init-firewall.sh NOT found"
  FILE_WARNINGS=$((FILE_WARNINGS + 1))
fi

if [ -f ".devcontainer/setup-claude-credentials.sh" ]; then
  echo "✓ .devcontainer/setup-claude-credentials.sh exists"
else
  echo "⚠️  WARNING: .devcontainer/setup-claude-credentials.sh NOT found"
  FILE_WARNINGS=$((FILE_WARNINGS + 1))
fi

if [ -f "docker-compose.yml" ]; then
  echo "✓ docker-compose.yml exists (project root)"
elif [ -f ".devcontainer/docker-compose.yml" ]; then
  echo "⚠️  WARNING: docker-compose.yml is in .devcontainer/ but should be in project root"
  FILE_WARNINGS=$((FILE_WARNINGS + 1))
else
  echo "⚠️  WARNING: docker-compose.yml NOT found"
  FILE_WARNINGS=$((FILE_WARNINGS + 1))
fi

echo ""
echo "File Location: $FILE_ERRORS errors, $FILE_WARNINGS warnings"
```

### 2. Check for WRONG Files (Critical)

```bash
echo ""
echo "=== PHASE 2: WRONG FILE DETECTION ==="
echo ""

WRONG_FILES=0

# Check for Claude Code config files (should NOT exist from DevContainer setup)
if [ -f ".claude/config.json" ]; then
  echo "❌ ERROR: .claude/config.json exists - THIS IS WRONG!"
  echo "   This is Claude Code's internal config, NOT DevContainer."
  echo "   Action: DELETE this file immediately."
  WRONG_FILES=$((WRONG_FILES + 1))
fi

if [ -f ".claude-code/settings.json" ]; then
  echo "❌ ERROR: .claude-code/settings.json exists - THIS IS WRONG!"
  echo "   This is Claude Code's settings, NOT DevContainer."
  echo "   Action: DELETE this file immediately."
  WRONG_FILES=$((WRONG_FILES + 1))
fi

if [ -f ".claude-code/config.json" ]; then
  echo "❌ ERROR: .claude-code/config.json exists - THIS IS WRONG!"
  echo "   This is Claude Code's config, NOT DevContainer."
  echo "   Action: DELETE this file immediately."
  WRONG_FILES=$((WRONG_FILES + 1))
fi

# Check home directory (should never create files there)
if [ -f "$HOME/.claude-code/settings.json" ]; then
  echo "❌ ERROR: ~/.claude-code/settings.json exists - THIS IS WRONG!"
  echo "   DevContainer files should be in project directory only."
  WRONG_FILES=$((WRONG_FILES + 1))
fi

if [ $WRONG_FILES -eq 0 ]; then
  echo "✓ No wrong files detected"
else
  echo ""
  echo "⚠️  $WRONG_FILES WRONG FILE(S) DETECTED!"
fi
```

### 3. JSON Syntax Validation

```bash
echo ""
echo "=== PHASE 3: JSON SYNTAX VALIDATION ==="
echo ""

JSON_ERRORS=0

# Validate devcontainer.json syntax
if [ -f ".devcontainer/devcontainer.json" ]; then
  if command -v jq >/dev/null 2>&1; then
    if jq empty .devcontainer/devcontainer.json 2>/dev/null; then
      echo "✓ devcontainer.json is valid JSON"
    else
      echo "❌ ERROR: devcontainer.json has invalid JSON syntax"
      echo "   Details:"
      jq empty .devcontainer/devcontainer.json 2>&1 | head -5
      JSON_ERRORS=$((JSON_ERRORS + 1))
    fi
  else
    # Fallback: use python if jq not available
    if command -v python3 >/dev/null 2>&1; then
      if python3 -c "import json; json.load(open('.devcontainer/devcontainer.json'))" 2>/dev/null; then
        echo "✓ devcontainer.json is valid JSON (python check)"
      else
        echo "❌ ERROR: devcontainer.json has invalid JSON syntax"
        JSON_ERRORS=$((JSON_ERRORS + 1))
      fi
    else
      echo "⚠️  WARNING: Cannot validate JSON (jq or python3 not available)"
    fi
  fi
fi

echo ""
echo "JSON Syntax: $JSON_ERRORS errors"
```

### 4. YAML Syntax Validation

```bash
echo ""
echo "=== PHASE 4: YAML SYNTAX VALIDATION ==="
echo ""

YAML_ERRORS=0

# Find docker-compose file
COMPOSE_FILE=""
if [ -f "docker-compose.yml" ]; then
  COMPOSE_FILE="docker-compose.yml"
elif [ -f "docker-compose.yaml" ]; then
  COMPOSE_FILE="docker-compose.yaml"
elif [ -f ".devcontainer/docker-compose.yml" ]; then
  COMPOSE_FILE=".devcontainer/docker-compose.yml"
fi

if [ -n "$COMPOSE_FILE" ]; then
  # Try docker compose config (best validation)
  if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    if docker compose -f "$COMPOSE_FILE" config >/dev/null 2>&1; then
      echo "✓ $COMPOSE_FILE is valid Docker Compose YAML"
    else
      echo "❌ ERROR: $COMPOSE_FILE has invalid YAML or Docker Compose syntax"
      echo "   Details:"
      docker compose -f "$COMPOSE_FILE" config 2>&1 | head -10
      YAML_ERRORS=$((YAML_ERRORS + 1))
    fi
  # Fallback: use python yaml
  elif command -v python3 >/dev/null 2>&1; then
    if python3 -c "import yaml; yaml.safe_load(open('$COMPOSE_FILE'))" 2>/dev/null; then
      echo "✓ $COMPOSE_FILE is valid YAML (python check)"
    else
      echo "❌ ERROR: $COMPOSE_FILE has invalid YAML syntax"
      YAML_ERRORS=$((YAML_ERRORS + 1))
    fi
  else
    echo "⚠️  WARNING: Cannot validate YAML (docker compose or python3 not available)"
  fi
else
  echo "⚠️  WARNING: No docker-compose file found to validate"
fi

echo ""
echo "YAML Syntax: $YAML_ERRORS errors"
```

### 5. Content Structure Validation

```bash
echo ""
echo "=== PHASE 5: CONTENT STRUCTURE VALIDATION ==="
echo ""

CONTENT_ERRORS=0
CONTENT_WARNINGS=0

# Validate devcontainer.json required fields
if [ -f ".devcontainer/devcontainer.json" ] && command -v jq >/dev/null 2>&1; then
  echo "Checking devcontainer.json structure..."

  # Check for name field
  NAME=$(jq -r '.name // empty' .devcontainer/devcontainer.json 2>/dev/null)
  if [ -n "$NAME" ]; then
    echo "  ✓ name: $NAME"
  else
    echo "  ⚠️  WARNING: 'name' field missing (recommended)"
    CONTENT_WARNINGS=$((CONTENT_WARNINGS + 1))
  fi

  # Check for image OR dockerComposeFile OR build
  HAS_IMAGE=$(jq -r '.image // empty' .devcontainer/devcontainer.json 2>/dev/null)
  HAS_COMPOSE=$(jq -r '.dockerComposeFile // empty' .devcontainer/devcontainer.json 2>/dev/null)
  HAS_BUILD=$(jq -r '.build // empty' .devcontainer/devcontainer.json 2>/dev/null)

  if [ -n "$HAS_IMAGE" ]; then
    echo "  ✓ image: $HAS_IMAGE"
  elif [ -n "$HAS_COMPOSE" ]; then
    echo "  ✓ dockerComposeFile: $HAS_COMPOSE"
  elif [ -n "$HAS_BUILD" ]; then
    echo "  ✓ build configuration present"
  else
    echo "  ❌ ERROR: Missing 'image', 'dockerComposeFile', or 'build' field"
    echo "     DevContainer needs one of these to know how to create the container"
    CONTENT_ERRORS=$((CONTENT_ERRORS + 1))
  fi

  # Check for unreplaced placeholders
  if grep -q '{{[A-Z_]*}}' .devcontainer/devcontainer.json 2>/dev/null; then
    echo "  ❌ ERROR: Unreplaced placeholders found:"
    grep -o '{{[A-Z_]*}}' .devcontainer/devcontainer.json | sort -u | sed 's/^/     /'
    CONTENT_ERRORS=$((CONTENT_ERRORS + 1))
  else
    echo "  ✓ No unreplaced placeholders"
  fi

  # Check workspaceFolder
  WORKSPACE=$(jq -r '.workspaceFolder // empty' .devcontainer/devcontainer.json 2>/dev/null)
  if [ -n "$WORKSPACE" ]; then
    echo "  ✓ workspaceFolder: $WORKSPACE"
  else
    echo "  ⚠️  WARNING: 'workspaceFolder' not set (will use default)"
    CONTENT_WARNINGS=$((CONTENT_WARNINGS + 1))
  fi

  # Check for extensions
  EXT_COUNT=$(jq -r '.customizations.vscode.extensions | length // 0' .devcontainer/devcontainer.json 2>/dev/null)
  if [ "$EXT_COUNT" -gt 0 ]; then
    echo "  ✓ VS Code extensions: $EXT_COUNT configured"
  else
    echo "  ⚠️  WARNING: No VS Code extensions configured"
    CONTENT_WARNINGS=$((CONTENT_WARNINGS + 1))
  fi
fi

# Validate docker-compose.yml content
if [ -n "$COMPOSE_FILE" ] && command -v docker >/dev/null 2>&1; then
  echo ""
  echo "Checking docker-compose.yml structure..."

  # Get services list
  SERVICES=$(docker compose -f "$COMPOSE_FILE" config --services 2>/dev/null)
  if [ -n "$SERVICES" ]; then
    echo "  ✓ Services defined:"
    echo "$SERVICES" | sed 's/^/     - /'

    # Check for app service (main dev container)
    if echo "$SERVICES" | grep -q "^app$"; then
      echo "  ✓ 'app' service present (main container)"
    else
      echo "  ⚠️  WARNING: No 'app' service found (expected for DevContainer)"
      CONTENT_WARNINGS=$((CONTENT_WARNINGS + 1))
    fi
  else
    echo "  ❌ ERROR: No services defined in docker-compose.yml"
    CONTENT_ERRORS=$((CONTENT_ERRORS + 1))
  fi

  # Check for unreplaced placeholders in compose file
  if grep -q '{{[A-Z_]*}}' "$COMPOSE_FILE" 2>/dev/null; then
    echo "  ❌ ERROR: Unreplaced placeholders found:"
    grep -o '{{[A-Z_]*}}' "$COMPOSE_FILE" | sort -u | sed 's/^/     /'
    CONTENT_ERRORS=$((CONTENT_ERRORS + 1))
  else
    echo "  ✓ No unreplaced placeholders"
  fi
fi

echo ""
echo "Content Structure: $CONTENT_ERRORS errors, $CONTENT_WARNINGS warnings"
```

### 6. Script Permission Validation

```bash
echo ""
echo "=== PHASE 6: SCRIPT PERMISSION VALIDATION ==="
echo ""

PERM_ERRORS=0

# Check executable permissions on shell scripts
for script in .devcontainer/*.sh; do
  if [ -f "$script" ]; then
    if [ -x "$script" ]; then
      echo "✓ $script is executable"
    else
      echo "❌ ERROR: $script is NOT executable"
      echo "   Fix: chmod +x $script"
      PERM_ERRORS=$((PERM_ERRORS + 1))
    fi
  fi
done

echo ""
echo "Script Permissions: $PERM_ERRORS errors"
```

### 7. Final Summary

```bash
echo ""
echo "==========================================="
echo "          VALIDATION SUMMARY"
echo "==========================================="
echo ""

TOTAL_ERRORS=$((FILE_ERRORS + WRONG_FILES + JSON_ERRORS + YAML_ERRORS + CONTENT_ERRORS + PERM_ERRORS))
TOTAL_WARNINGS=$((FILE_WARNINGS + CONTENT_WARNINGS))

echo "Phase Results:"
echo "  1. File Locations:    $FILE_ERRORS errors, $FILE_WARNINGS warnings"
echo "  2. Wrong Files:       $WRONG_FILES errors"
echo "  3. JSON Syntax:       $JSON_ERRORS errors"
echo "  4. YAML Syntax:       $YAML_ERRORS errors"
echo "  5. Content Structure: $CONTENT_ERRORS errors, $CONTENT_WARNINGS warnings"
echo "  6. Script Permissions: $PERM_ERRORS errors"
echo ""
echo "==========================================="

if [ $TOTAL_ERRORS -eq 0 ]; then
  if [ $TOTAL_WARNINGS -eq 0 ]; then
    echo "Status: ✅ PASSED - All validations passed"
  else
    echo "Status: ⚠️  PASSED WITH WARNINGS - $TOTAL_WARNINGS warning(s)"
  fi
  echo ""
  echo "Your DevContainer configuration is ready to use."
  echo "Open in VS Code and click 'Reopen in Container'."
else
  echo "Status: ❌ FAILED - $TOTAL_ERRORS error(s), $TOTAL_WARNINGS warning(s)"
  echo ""
  echo "Fix the errors above before using the DevContainer."
fi
echo "==========================================="
```

## Remediation Guidance

If errors are found, the agent provides specific guidance:

### JSON Syntax Errors
```
Fix: Edit .devcontainer/devcontainer.json
- Check for missing commas between properties
- Check for trailing commas (not allowed in JSON)
- Verify all quotes are properly closed
- Use a JSON validator: https://jsonlint.com/
```

### YAML Syntax Errors
```
Fix: Edit docker-compose.yml
- Check indentation (must use spaces, not tabs)
- Verify colons have spaces after them
- Check for unquoted special characters
- Use: docker compose config to validate
```

### Unreplaced Placeholders
```
Fix: Placeholders like {{PROJECT_NAME}} were not replaced
- Re-run the DevContainer generation command
- Or manually replace placeholders with actual values
- Check that sed commands executed successfully
```

### Script Permission Errors
```
Fix: Make scripts executable
chmod +x .devcontainer/*.sh
```

## Usage Notes

- This agent performs **comprehensive validation** (not just file locations)
- Requires `jq` for JSON validation (falls back to python3)
- Requires `docker compose` for YAML validation (falls back to python3)
- Uses haiku model for fast execution
- Orange color indicates validation/checking task
- Run after generating DevContainer files or when troubleshooting


