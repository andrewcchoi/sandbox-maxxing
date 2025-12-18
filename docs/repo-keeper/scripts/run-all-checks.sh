#!/bin/bash
# run-all-checks.sh
# Orchestrates all validation scripts in tiers

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

# Default settings
TIER="standard"  # quick, standard, full
VERBOSE=false
FIX_CRLF=false
QUIET=false
FAIL_FAST=false
LOG_FILE=""

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
        -q|--quiet) QUIET=true ;;
        -f|--fail-fast) FAIL_FAST=true ;;
        --log) LOG_FILE="$2"; shift ;;
        *) echo "Unknown parameter: $1"; echo "Usage: $0 [--quick|--full] [-v|--verbose] [--fix-crlf] [-q|--quiet] [-f|--fail-fast] [--log FILE]"; exit 128 ;;
    esac
    shift
done

if [ -n "$LOG_FILE" ]; then
    exec > >(tee -a "$LOG_FILE") 2>&1
fi

# Get version from plugin.json
VERSION=$(node -e "try { console.log(JSON.parse(require('fs').readFileSync('$REPO_ROOT/.claude-plugin/plugin.json')).version); } catch(e) { console.log('unknown'); }")

if [ "$QUIET" = false ]; then
    echo -e "${CYAN}=== Repository Validation Suite ===${NC}"
    echo "Version: $VERSION"
    echo "Date: $(date +%Y-%m-%d)"
    echo "Tier: $TIER"
    echo ""
fi

# Fix CRLF if requested
if [ "$FIX_CRLF" = true ]; then
    if [ "$QUIET" = false ]; then
        echo -e "${CYAN}Fixing line endings...${NC}"
    fi
    for file in "$SCRIPT_DIR"/*.sh; do
        if [ -f "$file" ]; then
            sed -i 's/\r$//' "$file" 2>/dev/null || true
        fi
    done
    if [ "$QUIET" = false ]; then
        echo -e "${GREEN}✓ Line endings fixed${NC}"
        echo ""
    fi
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
    if [ "$QUIET" = false ]; then
        printf "  [%d/%d] %-30s" "$check_num" "$total_in_tier" "$check_name"
    fi

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
        if [ "$QUIET" = false ]; then
            if [ $check_warnings -gt 0 ]; then
                echo -e " ${GREEN}✓ PASS${NC} ${YELLOW}($check_warnings warnings)${NC}"
            else
                echo -e " ${GREEN}✓ PASS${NC}"
            fi
        fi
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        if [ "$QUIET" = false ]; then
            echo -e " ${RED}✗ FAIL${NC} ${RED}($check_errors errors)${NC}"
        fi
        FAILED_CHECKS=$((FAILED_CHECKS + 1))

        # Show error details if not verbose (always show errors even in quiet mode)
        if [ "$VERBOSE" = false ]; then
            echo ""
            grep -E "\[ERROR\]|✗" "$output_file" 2>/dev/null | head -10 | while read -r line; do
                echo -e "    ${RED}$line${NC}"
            done
        fi

        # Exit immediately if fail-fast is enabled
        if [ "$FAIL_FAST" = true ]; then
            if [ "$QUIET" = false ]; then
                echo ""
                echo -e "${RED}Exiting due to --fail-fast flag${NC}"
                echo ""
            fi
            exit 1
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
if [ "$QUIET" = false ]; then
    echo -e "${CYAN}Running Tier 1: Structural Validation...${NC}"
fi

run_check 1 6 "Version sync" "check-version-sync.sh"
run_check 2 6 "Link integrity" "check-links.sh"
run_check 3 6 "Inventory accuracy" "validate-inventory.sh"
run_check 4 6 "Relationship validation" "validate-relationships.sh"
run_check 5 6 "Schema validation" "validate-schemas.sh"
run_check 6 6 "File permissions" "check-permissions.sh"

# Exit early if quick mode
if [ "$TIER" = "quick" ]; then
    if [ "$QUIET" = false ]; then
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
    fi

    exit $FAILED_CHECKS
fi

# Tier 2: Completeness Validation
if [ "$QUIET" = false ]; then
    echo ""
    echo -e "${CYAN}Running Tier 2: Completeness Validation...${NC}"
fi

run_check 6 6 "Feature coverage" "validate-completeness.sh"

# Exit if standard mode (not full)
if [ "$TIER" = "standard" ]; then
    if [ "$QUIET" = false ]; then
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
    fi

    exit $FAILED_CHECKS
fi

# Tier 3: Content Validation (full mode only)
if [ "$QUIET" = false ]; then
    echo ""
    echo -e "${CYAN}Running Tier 3: Content Validation...${NC}"
fi

run_check 7 8 "Required sections" "validate-content.sh"
run_check 8 8 "External links (slow)" "validate-content.sh" "--check-external"

# Final Summary
if [ "$QUIET" = false ]; then
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
fi

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
