#!/bin/bash
# run-all-checks.sh
# Orchestrates all validation scripts in tiers

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="/workspace"

# Default settings
TIER="standard"  # quick, standard, full
VERBOSE=false
FIX_CRLF=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --quick) TIER="quick" ;;
        --full) TIER="full" ;;
        -v|--verbose) VERBOSE=true ;;
        --fix-crlf) FIX_CRLF=true ;;
        *) echo "Unknown parameter: $1"; echo "Usage: $0 [--quick|--full] [-v|--verbose] [--fix-crlf]"; exit 1 ;;
    esac
    shift
done

# Get version from plugin.json
if command -v jq >/dev/null 2>&1; then
    VERSION=$(jq -r '.version' "$REPO_ROOT/.claude-plugin/plugin.json" 2>/dev/null || echo "unknown")
else
    # Fallback if jq is not available
    VERSION=$(grep -oP '"version"\s*:\s*"\K[^"]+' "$REPO_ROOT/.claude-plugin/plugin.json" 2>/dev/null || echo "unknown")
fi

echo -e "${CYAN}=== Repository Validation Suite ===${NC}"
echo "Version: $VERSION"
echo "Date: $(date +%Y-%m-%d)"
echo "Tier: $TIER"
echo ""

# Fix CRLF if requested
if [ "$FIX_CRLF" = true ]; then
    echo -e "${CYAN}Fixing line endings...${NC}"
    for file in "$SCRIPT_DIR"/*.sh; do
        if [ -f "$file" ]; then
            sed -i 's/\r$//' "$file" 2>/dev/null || true
        fi
    done
    echo -e "${GREEN}✓ Line endings fixed${NC}"
    echo ""
fi

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNINGS=0
ERRORS=0

# Temporary files for output capture
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Function to run a check
run_check() {
    local check_num=$1
    local total_in_tier=$2
    local check_name=$3
    local script_name=$4
    shift 4
    local args=("$@")

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    # Build verbose flag if needed
    local verbose_flag=""
    if [ "$VERBOSE" = true ]; then
        verbose_flag="-v"
    fi

    # Prepare display name with padding
    printf "  [%d/%d] %-30s" "$check_num" "$total_in_tier" "$check_name"

    # Capture output and exit code
    local output_file="$TEMP_DIR/check_$TOTAL_CHECKS.out"
    local exit_code=0

    if bash "$SCRIPT_DIR/$script_name" $verbose_flag "${args[@]}" > "$output_file" 2>&1; then
        exit_code=0
    else
        exit_code=$?
    fi

    # Parse output for warnings/errors
    local check_warnings=$(grep -ci "warning" "$output_file" 2>/dev/null | head -1 || echo "0")
    local check_errors=$(grep -ci "error" "$output_file" 2>/dev/null | head -1 || echo "0")

    # Ensure we have numbers
    check_warnings=${check_warnings//[^0-9]/}
    check_errors=${check_errors//[^0-9]/}
    [ -z "$check_warnings" ] && check_warnings=0
    [ -z "$check_errors" ] && check_errors=0

    # Override error count if script exited with non-zero
    if [ $exit_code -ne 0 ]; then
        [ $check_errors -eq 0 ] && check_errors=1
    fi

    WARNINGS=$((WARNINGS + check_warnings))
    ERRORS=$((ERRORS + check_errors))

    # Display result
    if [ $exit_code -eq 0 ]; then
        if [ $check_warnings -gt 0 ]; then
            echo -e " ${GREEN}✓ PASS${NC} ${YELLOW}($check_warnings warnings)${NC}"
        else
            echo -e " ${GREEN}✓ PASS${NC}"
        fi
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo -e " ${RED}✗ FAIL${NC} ${RED}($check_errors errors)${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))

        # Show error details if not verbose
        if [ "$VERBOSE" = false ]; then
            echo ""
            grep -E "\[ERROR\]|✗" "$output_file" 2>/dev/null | head -10 | while read -r line; do
                echo -e "    ${RED}$line${NC}"
            done
        fi
    fi

    # Always show full output in verbose mode
    if [ "$VERBOSE" = true ]; then
        echo ""
        cat "$output_file" | sed 's/^/    /'
        echo ""
    fi
}

# Tier 1: Structural Validation
echo -e "${CYAN}Running Tier 1: Structural Validation...${NC}"

run_check 1 5 "Version sync" "check-version-sync.sh"
run_check 2 5 "Link integrity" "check-links.sh"
run_check 3 5 "Inventory accuracy" "validate-inventory.sh"
run_check 4 5 "Relationship validation" "validate-relationships.sh"
run_check 5 5 "Schema validation" "validate-schemas.sh"

# Exit early if quick mode
if [ "$TIER" = "quick" ]; then
    echo ""
    echo -e "${CYAN}=== Summary (Quick Mode) ===${NC}"

    if [ $FAILED_CHECKS -eq 0 ]; then
        echo -e "${GREEN}Status: PASSED${NC}"
    else
        echo -e "${RED}Status: FAILED${NC}"
    fi

    echo "Checks run: $TOTAL_CHECKS"
    echo -e "${GREEN}Passed: $PASSED_CHECKS${NC}"
    echo -e "${RED}Failed: $FAILED_CHECKS${NC}"
    echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
    echo -e "${RED}Errors: $ERRORS${NC}"
    echo ""

    exit $FAILED_CHECKS
fi

# Tier 2: Completeness Validation
echo ""
echo -e "${CYAN}Running Tier 2: Completeness Validation...${NC}"

run_check 6 6 "Feature coverage" "validate-completeness.sh"

# Exit if standard mode (not full)
if [ "$TIER" = "standard" ]; then
    echo ""
    echo -e "${CYAN}=== Summary (Standard Mode) ===${NC}"

    if [ $FAILED_CHECKS -eq 0 ]; then
        echo -e "${GREEN}Status: PASSED${NC}"
    else
        echo -e "${RED}Status: FAILED${NC}"
    fi

    echo "Checks run: $TOTAL_CHECKS"
    echo -e "${GREEN}Passed: $PASSED_CHECKS${NC}"
    echo -e "${RED}Failed: $FAILED_CHECKS${NC}"
    echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
    echo -e "${RED}Errors: $ERRORS${NC}"
    echo ""

    exit $FAILED_CHECKS
fi

# Tier 3: Content Validation (full mode only)
echo ""
echo -e "${CYAN}Running Tier 3: Content Validation...${NC}"

run_check 7 8 "Required sections" "validate-content.sh"
run_check 8 8 "External links (slow)" "validate-content.sh" "--check-external"

# Final Summary
echo ""
echo -e "${CYAN}=== Summary (Full Mode) ===${NC}"

if [ $FAILED_CHECKS -eq 0 ]; then
    echo -e "${GREEN}Status: PASSED${NC}"
else
    echo -e "${RED}Status: FAILED${NC}"
fi

echo "Checks run: $TOTAL_CHECKS"
echo -e "${GREEN}Passed: $PASSED_CHECKS${NC}"
echo -e "${RED}Failed: $FAILED_CHECKS${NC}"
echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
echo -e "${RED}Errors: $ERRORS${NC}"
echo ""

if [ $FAILED_CHECKS -gt 0 ]; then
    echo -e "${RED}Some checks failed. Review the output above for details.${NC}"
    echo ""
    echo "To fix issues:"
    echo "  1. Review error messages above"
    echo "  2. Run individual scripts with -v for more details"
    echo "  3. Fix reported issues"
    echo "  4. Re-run this script"
    echo ""
fi

exit $FAILED_CHECKS
