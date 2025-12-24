#!/usr/bin/env bash
# ============================================================================
# PostToolUse Hook: Verify Template Match
# ============================================================================
# Called after Write or Edit operations during DevContainer setup
# Verifies that files match expected template patterns
# ============================================================================

# Read hook input (JSON from stdin)
INPUT=$(cat)

# Extract file path from tool input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# If no file path, nothing to verify
if [ -z "$FILE_PATH" ]; then
    exit 0
fi

# Only validate DevContainer-related files
if ! echo "$FILE_PATH" | grep -qE '\.devcontainer/|docker-compose\.yml'; then
    # Not a DevContainer file, skip validation
    exit 0
fi

# ============================================================================
# Validation Rules
# ============================================================================

echo "=== PostToolUse: Verifying $FILE_PATH ===" >&2

ERRORS=0

# Check 1: Verify file exists
if [ ! -f "$FILE_PATH" ]; then
    echo "❌ ERROR: File does not exist: $FILE_PATH" >&2
    exit 0  # Don't block - file might be in progress
fi

# Check 2: Verify file is not empty
if [ ! -s "$FILE_PATH" ]; then
    echo "⚠️  WARNING: File is empty: $FILE_PATH" >&2
    ERRORS=$((ERRORS + 1))
fi

# Check 3: Verify placeholders were replaced
if grep -q "{{PROJECT_NAME}}" "$FILE_PATH" 2>/dev/null; then
    echo "⚠️  WARNING: Unreplaced {{PROJECT_NAME}} placeholder in $FILE_PATH" >&2
    ERRORS=$((ERRORS + 1))
fi

if grep -q "{{NETWORK_NAME}}" "$FILE_PATH" 2>/dev/null; then
    echo "⚠️  WARNING: Unreplaced {{NETWORK_NAME}} placeholder in $FILE_PATH" >&2
    ERRORS=$((ERRORS + 1))
fi

# Check 4: File-specific validations
case "$FILE_PATH" in
    *.devcontainer/Dockerfile)
        echo "Validating Dockerfile..." >&2

        # Check for multi-stage build
        if ! grep -q "^FROM.*AS" "$FILE_PATH"; then
            echo "⚠️  WARNING: Dockerfile missing multi-stage build pattern" >&2
            ERRORS=$((ERRORS + 1))
        fi

        # Check for core utilities
        if ! grep -q "git vim nano" "$FILE_PATH"; then
            echo "⚠️  WARNING: Dockerfile missing core utilities installation" >&2
            ERRORS=$((ERRORS + 1))
        fi

        # Check for Claude Code
        if ! grep -q "claude-code" "$FILE_PATH"; then
            echo "⚠️  WARNING: Dockerfile missing Claude Code installation" >&2
            ERRORS=$((ERRORS + 1))
        fi

        # Check line count
        LINE_COUNT=$(wc -l < "$FILE_PATH")
        if [ "$LINE_COUNT" -lt 50 ]; then
            echo "⚠️  WARNING: Dockerfile only has $LINE_COUNT lines (expected >= 50)" >&2
            ERRORS=$((ERRORS + 1))
        fi

        # Check for language partials marker
        if ! grep -q "# === LANGUAGE PARTIALS ===" "$FILE_PATH"; then
            echo "⚠️  WARNING: Dockerfile missing language partials marker" >&2
            ERRORS=$((ERRORS + 1))
        fi
        ;;

    *.devcontainer/devcontainer.json)
        echo "Validating devcontainer.json..." >&2

        # Check valid JSON
        if ! jq empty "$FILE_PATH" 2>/dev/null; then
            echo "❌ ERROR: devcontainer.json is not valid JSON" >&2
            ERRORS=$((ERRORS + 1))
        fi

        # Check required fields
        if ! jq -e '.name' "$FILE_PATH" >/dev/null 2>&1; then
            echo "⚠️  WARNING: devcontainer.json missing 'name' field" >&2
            ERRORS=$((ERRORS + 1))
        fi

        if ! jq -e '.dockerComposeFile' "$FILE_PATH" >/dev/null 2>&1; then
            echo "⚠️  WARNING: devcontainer.json missing 'dockerComposeFile' field" >&2
            ERRORS=$((ERRORS + 1))
        fi
        ;;

    *docker-compose.yml)
        echo "Validating docker-compose.yml..." >&2

        # Check for app service
        if ! grep -q "services:" "$FILE_PATH"; then
            echo "❌ ERROR: docker-compose.yml missing 'services' section" >&2
            ERRORS=$((ERRORS + 1))
        fi

        if ! grep -q "app:" "$FILE_PATH"; then
            echo "⚠️  WARNING: docker-compose.yml missing 'app' service" >&2
            ERRORS=$((ERRORS + 1))
        fi
        ;;

    *.devcontainer/init-firewall.sh|*.devcontainer/setup-claude-credentials.sh)
        echo "Validating script: $(basename "$FILE_PATH")..." >&2

        # Check shebang
        if ! head -n 1 "$FILE_PATH" | grep -qE "^#!/(usr/bin/env )?bash"; then
            echo "⚠️  WARNING: Script missing portable bash shebang" >&2
            ERRORS=$((ERRORS + 1))
        fi

        # Check executable permission
        if [ ! -x "$FILE_PATH" ]; then
            echo "⚠️  WARNING: Script is not executable: $FILE_PATH" >&2
            echo "   Run: chmod +x $FILE_PATH" >&2
        fi
        ;;
esac

# ============================================================================
# Output
# ============================================================================

if [ $ERRORS -eq 0 ]; then
    echo "✓ Validation passed for $FILE_PATH" >&2
else
    echo "⚠️  $ERRORS validation issue(s) found in $FILE_PATH" >&2
fi

# Always approve (warnings only - don't block)
exit 0
