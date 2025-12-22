#!/bin/bash
# validate-templates.sh
# V13: Validates template variable syntax

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
    echo -e "${CYAN}=== Template Variable Validator ===${NC}"
    echo ""
fi

WARNING_COUNT=0
ERROR_COUNT=0

# V13: Check variable syntax in templates
if [ "$QUIET" = false ]; then
    echo -e "${CYAN}Checking variable syntax in template files...${NC}"
fi

# Find all template files
TEMPLATE_FILES=$(find "$REPO_ROOT/templates" -type f 2>/dev/null)

INVALID_SYNTAX=0
TOTAL_TEMPLATES=0

for template in $TEMPLATE_FILES; do
    [ -e "$template" ] || continue
    ((TOTAL_TEMPLATES++))

    RELATIVE_PATH="${template#$REPO_ROOT/}"

    # Check for malformed variable references
    # Valid: ${VAR}, {{VAR}}
    # Invalid: $VAR, {VAR}, ${VAR, ${{VAR}}

    # Check for bare $ not followed by {
    if grep -n '\$[A-Za-z_]' "$template" 2>/dev/null | grep -v '\${' >/dev/null; then
        if [ "$VERBOSE" = true ]; then
            echo -e "  ${YELLOW}[WARNING] $RELATIVE_PATH - Bare \$ variable (should use \${VAR})${NC}"
            grep -n '\$[A-Za-z_]' "$template" 2>/dev/null | grep -v '\${' | head -3 | while IFS=: read -r line_num line_content; do
                echo -e "    ${GRAY}Line $line_num: $(echo "$line_content" | cut -c1-60)${NC}"
            done
        fi
        ((INVALID_SYNTAX++))
        ((WARNING_COUNT++))
    fi

    # Check for unclosed variable references ${VAR without closing }
    if grep -n '\${[A-Za-z_][A-Za-z0-9_]*[^}]' "$template" 2>/dev/null | grep -v '\${[A-Za-z_][A-Za-z0-9_]*}' >/dev/null; then
        UNCLOSED=$(grep -o '\${[A-Za-z_][A-Za-z0-9_]*' "$template" 2>/dev/null | head -1)
        if [ -n "$UNCLOSED" ] && [ "$VERBOSE" = true ]; then
            echo -e "  ${YELLOW}[WARNING] $RELATIVE_PATH - Potentially unclosed variable: $UNCLOSED${NC}"
            ((INVALID_SYNTAX++))
            ((WARNING_COUNT++))
        fi
    fi
done

if [ "$QUIET" = false ]; then
    if [ $INVALID_SYNTAX -eq 0 ]; then
        echo -e "  ${GREEN}[OK] All template variable syntax is valid${NC}"
    else
        echo -e "  ${YELLOW}Templates with syntax issues: $INVALID_SYNTAX${NC}"
    fi
fi

# Check variables.*.json files for consistency
if [ "$QUIET" = false ]; then
    echo ""
    echo -e "${CYAN}Checking variables JSON files...${NC}"
fi

VAR_FILES=$(find "$REPO_ROOT/templates/variables" -name "variables.*.json" 2>/dev/null)
VAR_FILE_COUNT=0

for var_file in $VAR_FILES; do
    [ -e "$var_file" ] || continue
    ((VAR_FILE_COUNT++))

    RELATIVE_PATH="${var_file#$REPO_ROOT/}"

    # Validate JSON syntax using Node.js
    VALID_JSON=$(node -e "
        try {
            const data = JSON.parse(require('fs').readFileSync('$var_file', 'utf8'));
            console.log('true');
        } catch(e) {
            console.log('false');
        }
    " 2>/dev/null)

    if [ "$VALID_JSON" != "true" ]; then
        echo -e "  ${RED}[ERROR] $RELATIVE_PATH - Invalid JSON syntax${NC}"
        ((ERROR_COUNT++))
    elif [ "$VERBOSE" = true ]; then
        MODE=$(node -e "const data = JSON.parse(require('fs').readFileSync('$var_file')); console.log(data.mode || 'unknown');")
        echo -e "  ${GRAY}[OK] $RELATIVE_PATH (mode: $MODE)${NC}"
    fi

    # Check for ${VAR} references in derived_vars
    DERIVED_REFS=$(grep -o '\${[A-Za-z_][A-Za-z0-9_]*}' "$var_file" 2>/dev/null | sort -u)
    if [ -n "$DERIVED_REFS" ]; then
        # Validate referenced variables exist
        while IFS= read -r ref; do
            var_name=$(echo "$ref" | sed 's/\${//; s/}//')
            # Check if variable is defined in the file
            if ! grep -q "\"$var_name\"" "$var_file"; then
                echo -e "  ${YELLOW}[WARNING] $RELATIVE_PATH - References undefined variable: $var_name${NC}"
                ((WARNING_COUNT++))
            fi
        done <<< "$DERIVED_REFS"
    fi
done

if [ "$QUIET" = false ]; then
    echo -e "  ${GREEN}Checked $VAR_FILE_COUNT variables files${NC}"
fi

# Summary
if [ "$QUIET" = false ]; then
    echo ""
    echo -e "${CYAN}=== Summary ===${NC}"
    echo "Total template files checked: $TOTAL_TEMPLATES"
    echo "Variables files checked: $VAR_FILE_COUNT"
fi

if [ $ERROR_COUNT -eq 0 ] && [ $WARNING_COUNT -eq 0 ]; then
    if [ "$QUIET" = false ]; then
        echo -e "${GREEN}✓ All template validation checks passed!${NC}"
    fi
    exit 0
elif [ $ERROR_COUNT -eq 0 ]; then
    if [ "$QUIET" = false ]; then
        echo -e "${YELLOW}⚠ Template validation passed with warnings${NC}"
        echo -e "${YELLOW}Warnings: $WARNING_COUNT${NC}"
    fi
    exit 0
else
    echo -e "${RED}✗ Template validation failed!${NC}"
    echo -e "${RED}Errors: $ERROR_COUNT${NC}"
    echo -e "${YELLOW}Warnings: $WARNING_COUNT${NC}"
    exit 1
fi
