#!/bin/bash
# validate-compose.sh
# V15: Validate docker-compose YAML structure

set -e

# Auto-detect repo root from script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Allow override via environment variable
if [[ -n "${REPO_ROOT_OVERRIDE:-}" ]]; then
    REPO_ROOT="$REPO_ROOT_OVERRIDE"
fi

# Source dependency checking library
source "$SCRIPT_DIR/lib/check-dependencies.sh"

# Check required dependencies
check_node

VERBOSE=false
QUIET=false
LOG_FILE=""

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -v|--verbose) VERBOSE=true ;;
        -q|--quiet) QUIET=true ;;
        --log) LOG_FILE="$2"; shift ;;
        *) echo "Unknown parameter: $1"; exit 128 ;;
    esac
    shift
done

if [ -n "$LOG_FILE" ]; then
    exec > >(tee -a "$LOG_FILE") 2>&1
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

if [ "$QUIET" = false ]; then
    echo -e "${CYAN}=== Docker Compose Validator ===${NC}"
    echo ""
fi

WARNING_COUNT=0
ERROR_COUNT=0

# Find all docker-compose files
COMPOSE_FILES=$(find "$REPO_ROOT" -type f \( -name "docker-compose*.yml" -o -name "docker-compose*.yaml" -o -name "compose*.yml" -o -name "compose*.yaml" \) ! -path "*/node_modules/*" ! -path "*/.git/*" 2>/dev/null)

TOTAL_COMPOSE=0
INVALID_COMPOSE=0

if [ "$QUIET" = false ]; then
    echo -e "${CYAN}Validating docker-compose files...${NC}"
fi

for compose_file in $COMPOSE_FILES; do
    [ -e "$compose_file" ] || continue
    ((TOTAL_COMPOSE++))

    RELATIVE_PATH="${compose_file#$REPO_ROOT/}"
    HAS_ISSUES=false

    # Check 1: Valid YAML syntax using Node.js
    YAML_VALID=$(node -e "
        const fs = require('fs');
        try {
            const content = fs.readFileSync('$compose_file', 'utf8');

            // Basic YAML syntax check
            const lines = content.split('\\n');
            let valid = true;

            // Check for basic YAML structure
            for (let i = 0; i < lines.length; i++) {
                const line = lines[i];

                // Skip empty lines and comments
                if (line.trim() === '' || line.trim().startsWith('#')) continue;

                // Check for tabs (YAML doesn't allow tabs for indentation)
                if (line.match(/^\\t/)) {
                    console.error('Line ' + (i+1) + ': YAML does not allow tabs for indentation');
                    valid = false;
                }
            }

            console.log(valid ? 'true' : 'false');
        } catch(e) {
            console.log('false');
        }
    " 2>/dev/null)

    if [ "$YAML_VALID" != "true" ]; then
        echo -e "  ${RED}[ERROR] $RELATIVE_PATH - Invalid YAML syntax${NC}"
        ((ERROR_COUNT++))
        ((INVALID_COMPOSE++))
        HAS_ISSUES=true
    fi

    # Check 2: Has required version or services key
    HAS_VERSION=$(grep -q '^version:' "$compose_file" 2>/dev/null && echo "true" || echo "false")
    HAS_SERVICES=$(grep -q '^services:' "$compose_file" 2>/dev/null && echo "true" || echo "false")

    if [ "$HAS_SERVICES" != "true" ]; then
        echo -e "  ${RED}[ERROR] $RELATIVE_PATH - Missing 'services:' key${NC}"
        ((ERROR_COUNT++))
        ((INVALID_COMPOSE++))
        HAS_ISSUES=true
    fi

    if [ "$HAS_VERSION" != "true" ]; then
        if [ "$VERBOSE" = true ]; then
            echo -e "  ${GRAY}[INFO] $RELATIVE_PATH - No 'version:' key (compose v2 format)${NC}"
        fi
    fi

    # Check 3: Common docker-compose keys
    KNOWN_KEYS="version|services|networks|volumes|configs|secrets|name"

    # Extract top-level keys
    TOP_LEVEL_KEYS=$(grep '^[a-z_]*:' "$compose_file" 2>/dev/null | sed 's/:.*//' | sort -u)

    while IFS= read -r key; do
        [ -z "$key" ] && continue

        if ! echo "$key" | grep -qiE "^($KNOWN_KEYS)$"; then
            echo -e "  ${YELLOW}[WARNING] $RELATIVE_PATH - Unknown top-level key: '$key'${NC}"
            ((WARNING_COUNT++))
            HAS_ISSUES=true
        fi
    done <<< "$TOP_LEVEL_KEYS"

    # Check 4: Service structure validation
    SERVICE_COUNT=$(grep -c '^  [a-z_-]*:' "$compose_file" 2>/dev/null || echo "0")
    if [ "$SERVICE_COUNT" -eq 0 ] && [ "$HAS_SERVICES" = "true" ]; then
        echo -e "  ${YELLOW}[WARNING] $RELATIVE_PATH - 'services:' defined but no services found${NC}"
        ((WARNING_COUNT++))
        HAS_ISSUES=true
    fi

    # Check 5: Verify service has either 'image' or 'build'
    if [ "$HAS_SERVICES" = "true" ]; then
        IN_SERVICES=false
        CURRENT_SERVICE=""

        while IFS= read -r line; do
            if [[ "$line" =~ ^services: ]]; then
                IN_SERVICES=true
                continue
            fi

            # Check for next top-level key (end of services)
            if [[ "$line" =~ ^[a-z_]+: ]] && [ "$IN_SERVICES" = true ]; then
                IN_SERVICES=false
            fi

            # Inside services section, find service names (2 space indent)
            if [ "$IN_SERVICES" = true ] && [[ "$line" =~ ^[[:space:]]{2}[a-z_-]+: ]]; then
                CURRENT_SERVICE=$(echo "$line" | sed 's/^  //; s/:.*//')

                # Check if this service has image or build
                SERVICE_BLOCK=$(awk "/^  $CURRENT_SERVICE:/,/^  [a-z]/" "$compose_file" 2>/dev/null)

                if ! echo "$SERVICE_BLOCK" | grep -qE '(image:|build:)'; then
                    if [ "$VERBOSE" = true ]; then
                        echo -e "  ${YELLOW}[WARNING] $RELATIVE_PATH - Service '$CURRENT_SERVICE' missing 'image' or 'build'${NC}"
                        ((WARNING_COUNT++))
                    fi
                fi
            fi
        done < "$compose_file"
    fi

    if [ "$HAS_ISSUES" = false ] && [ "$VERBOSE" = true ]; then
        echo -e "  ${GRAY}[OK] $RELATIVE_PATH ($SERVICE_COUNT services)${NC}"
    fi
done

# Summary
if [ "$QUIET" = false ]; then
    echo ""
    echo -e "${CYAN}=== Summary ===${NC}"
    echo "Total compose files checked: $TOTAL_COMPOSE"
fi

if [ $ERROR_COUNT -eq 0 ] && [ $WARNING_COUNT -eq 0 ]; then
    if [ "$QUIET" = false ]; then
        echo -e "${GREEN}✓ All docker-compose files are valid!${NC}"
    fi
    exit 0
elif [ $ERROR_COUNT -eq 0 ]; then
    if [ "$QUIET" = false ]; then
        echo -e "${YELLOW}⚠ Compose validation passed with warnings${NC}"
        echo -e "${YELLOW}Warnings: $WARNING_COUNT${NC}"
    fi
    exit 0
else
    echo -e "${RED}✗ Compose validation failed!${NC}"
    echo -e "${RED}Errors: $ERROR_COUNT${NC}"
    echo -e "${YELLOW}Warnings: $WARNING_COUNT${NC}"
    exit 1
fi
