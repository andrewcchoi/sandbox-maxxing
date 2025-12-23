#!/bin/bash
# ============================================================================
# Stop Hook: Verify DevContainer Setup Complete
# ============================================================================
# Called when Claude stops (end of conversation turn)
# Verifies all required DevContainer files exist and are valid
# Only runs validation if devcontainer files are present
# ============================================================================

# Check if this looks like a devcontainer setup task
if [ ! -d ".devcontainer" ] && [ ! -f "docker-compose.yml" ]; then
    # No devcontainer files present, skip validation
    exit 0
fi

echo "=== Stop Hook: DevContainer Validation ===" >&2

# ============================================================================
# Required Files Check
# ============================================================================

ERRORS=0
WARNINGS=0

echo "" >&2
echo "Checking required files..." >&2

# Core files (always required)
REQUIRED_FILES=(
    ".devcontainer/Dockerfile"
    ".devcontainer/devcontainer.json"
    "docker-compose.yml"
)

# Scripts (required for most setups)
SCRIPT_FILES=(
    ".devcontainer/setup-claude-credentials.sh"
    ".devcontainer/init-firewall.sh"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        SIZE=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
        if [ "$SIZE" -gt 0 ]; then
            echo "✓ $file exists ($SIZE bytes)" >&2
        else
            echo "❌ ERROR: $file is empty!" >&2
            ERRORS=$((ERRORS + 1))
        fi
    else
        echo "❌ ERROR: $file NOT found!" >&2
        ERRORS=$((ERRORS + 1))
    fi
done

for file in "${SCRIPT_FILES[@]}"; do
    if [ -f "$file" ]; then
        SIZE=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
        echo "✓ $file exists ($SIZE bytes)" >&2

        # Check if executable
        if [ ! -x "$file" ]; then
            echo "  ⚠️  WARNING: Script is not executable" >&2
            WARNINGS=$((WARNINGS + 1))
        fi
    else
        echo "⚠️  WARNING: $file NOT found (optional but recommended)" >&2
        WARNINGS=$((WARNINGS + 1))
    fi
done

# ============================================================================
# Content Validation
# ============================================================================

echo "" >&2
echo "Validating file contents..." >&2

# Check Dockerfile
if [ -f ".devcontainer/Dockerfile" ]; then
    if grep -q "^FROM" ".devcontainer/Dockerfile"; then
        echo "✓ Dockerfile has FROM statement" >&2
    else
        echo "❌ ERROR: Dockerfile missing FROM statement" >&2
        ERRORS=$((ERRORS + 1))
    fi

    if grep -q "claude-code" ".devcontainer/Dockerfile"; then
        echo "✓ Dockerfile includes Claude Code" >&2
    else
        echo "⚠️  WARNING: Dockerfile missing Claude Code installation" >&2
        WARNINGS=$((WARNINGS + 1))
    fi

    LINE_COUNT=$(wc -l < ".devcontainer/Dockerfile")
    if [ "$LINE_COUNT" -ge 50 ]; then
        echo "✓ Dockerfile has $LINE_COUNT lines" >&2
    else
        echo "⚠️  WARNING: Dockerfile only has $LINE_COUNT lines (expected >= 50)" >&2
        WARNINGS=$((WARNINGS + 1))
    fi
fi

# Check devcontainer.json
if [ -f ".devcontainer/devcontainer.json" ]; then
    if jq empty ".devcontainer/devcontainer.json" 2>/dev/null; then
        echo "✓ devcontainer.json is valid JSON" >&2

        NAME=$(jq -r '.name // empty' ".devcontainer/devcontainer.json")
        if [ -n "$NAME" ]; then
            echo "  Name: $NAME" >&2
        fi
    else
        echo "❌ ERROR: devcontainer.json is not valid JSON" >&2
        ERRORS=$((ERRORS + 1))
    fi
fi

# Check docker-compose.yml
if [ -f "docker-compose.yml" ]; then
    if grep -q "services:" "docker-compose.yml"; then
        echo "✓ docker-compose.yml has services section" >&2
    else
        echo "❌ ERROR: docker-compose.yml missing services section" >&2
        ERRORS=$((ERRORS + 1))
    fi

    if grep -q "app:" "docker-compose.yml"; then
        echo "✓ docker-compose.yml has app service" >&2
    else
        echo "⚠️  WARNING: docker-compose.yml missing app service" >&2
        WARNINGS=$((WARNINGS + 1))
    fi
fi

# ============================================================================
# Placeholder Check
# ============================================================================

echo "" >&2
echo "Checking for unreplaced placeholders..." >&2

PLACEHOLDER_FILES=(
    ".devcontainer/devcontainer.json"
    "docker-compose.yml"
)

PLACEHOLDER_FOUND=0

for file in "${PLACEHOLDER_FILES[@]}"; do
    if [ -f "$file" ]; then
        if grep -q "{{PROJECT_NAME}}" "$file"; then
            echo "❌ ERROR: $file has unreplaced {{PROJECT_NAME}} placeholder" >&2
            ERRORS=$((ERRORS + 1))
            PLACEHOLDER_FOUND=1
        fi

        if grep -q "{{NETWORK_NAME}}" "$file"; then
            echo "❌ ERROR: $file has unreplaced {{NETWORK_NAME}} placeholder" >&2
            ERRORS=$((ERRORS + 1))
            PLACEHOLDER_FOUND=1
        fi
    fi
done

if [ $PLACEHOLDER_FOUND -eq 0 ]; then
    echo "✓ No unreplaced placeholders found" >&2
fi

# ============================================================================
# Wrong Files Check
# ============================================================================

echo "" >&2
echo "Checking for wrong files (common mistakes)..." >&2

WRONG_FILES=(
    ".claude/config.json"
    ".claude-code/settings.json"
    ".claude-code/config.json"
)

WRONG_FOUND=0

for file in "${WRONG_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "❌ ERROR: $file exists - THIS IS WRONG!" >&2
        echo "   This is Claude Code config, not DevContainer. DELETE THIS FILE." >&2
        ERRORS=$((ERRORS + 1))
        WRONG_FOUND=1
    fi
done

if [ $WRONG_FOUND -eq 0 ]; then
    echo "✓ No wrong files detected" >&2
fi

# ============================================================================
# Summary
# ============================================================================

echo "" >&2
echo "============================================" >&2
echo "VALIDATION SUMMARY" >&2
echo "============================================" >&2
echo "Errors:   $ERRORS" >&2
echo "Warnings: $WARNINGS" >&2
echo "============================================" >&2

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "✓ DevContainer setup appears complete and valid" >&2
    echo "" >&2
    echo "Next steps:" >&2
    echo "  1. Review the generated files" >&2
    echo "  2. Test the DevContainer: docker compose up" >&2
    echo "  3. Connect to the container" >&2
elif [ $ERRORS -eq 0 ]; then
    echo "✓ DevContainer setup complete with $WARNINGS warning(s)" >&2
    echo "  Review warnings above and fix if necessary" >&2
else
    echo "❌ DevContainer setup has $ERRORS error(s)" >&2
    echo "  Review errors above and fix before proceeding" >&2
fi

echo "" >&2

# Always exit 0 (informational only - don't block)
exit 0
