#!/bin/bash
# check-version-sync.sh
# Validates version consistency across the repository

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
NC='\033[0m' # No Color

if [ "$QUIET" = false ]; then
    echo -e "${CYAN}=== Repository Version Sync Checker ===${NC}"
    echo ""
fi

# Read version from plugin.json
PLUGIN_JSON="$REPO_ROOT/.claude-plugin/plugin.json"
if [ ! -f "$PLUGIN_JSON" ]; then
    echo -e "${RED}Error: plugin.json not found${NC}"
    exit 1
fi

EXPECTED_VERSION=$(grep -oP '"version"\s*:\s*"\K[^"]+' "$PLUGIN_JSON" | head -1)

# Validate semver format
if ! [[ "$EXPECTED_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?(\+[a-zA-Z0-9.]+)?$ ]]; then
    echo -e "${RED}[ERROR] Invalid semver format in plugin.json: $EXPECTED_VERSION${NC}"
    echo -e "${RED}Expected format: MAJOR.MINOR.PATCH[-prerelease][+build]${NC}"
    echo -e "${YELLOW}  How to fix: Update version in .claude-plugin/plugin.json to valid semver format (e.g., 1.0.0)${NC}"
    exit 1
fi

if [ "$QUIET" = false ]; then
    echo -e "${GREEN}Expected version (from plugin.json): $EXPECTED_VERSION${NC}"
    echo ""
fi

# Read version from marketplace.json
MARKETPLACE_JSON="$REPO_ROOT/.claude-plugin/marketplace.json"
MARKETPLACE_VERSION=$(grep -oP '"version"\s*:\s*"\K[^"]+' "$MARKETPLACE_JSON" | head -1)

# Read version from INVENTORY.json
INVENTORY_JSON="$REPO_ROOT/docs/repo-keeper/INVENTORY.json"
INVENTORY_VERSION="unknown"
if [ -f "$INVENTORY_JSON" ]; then
    INVENTORY_VERSION=$(grep -oP '"version"\s*:\s*"\K[^"]+' "$INVENTORY_JSON" | head -1)
fi

# Initialize counters
TOTAL_FILES=0
MATCHING_FILES=0
MISSING_FOOTERS=0
WRONG_VERSIONS=0
ERROR_COUNT=0

declare -a ERRORS=()

# Check marketplace.json
if [ "$MARKETPLACE_VERSION" != "$EXPECTED_VERSION" ]; then
    ERRORS+=(".claude-plugin/marketplace.json|$MARKETPLACE_VERSION|Config")
    ((ERROR_COUNT++)) || true
    echo -e "${RED}[ERROR] marketplace.json version mismatch: $MARKETPLACE_VERSION${NC}"
    echo -e "${YELLOW}  How to fix: Update version field in .claude-plugin/marketplace.json to $EXPECTED_VERSION${NC}"
else
    if [ "$QUIET" = false ]; then
        echo -e "${GREEN}[OK] marketplace.json version matches: $MARKETPLACE_VERSION${NC}"
    fi
fi

# Check INVENTORY.json
if [ "$INVENTORY_VERSION" != "$EXPECTED_VERSION" ]; then
    ERRORS+=("docs/repo-keeper/INVENTORY.json|$INVENTORY_VERSION|Inventory")
    ((ERROR_COUNT++)) || true
    echo -e "${RED}[ERROR] INVENTORY.json version mismatch: $INVENTORY_VERSION${NC}"
    echo -e "${YELLOW}  How to fix: Update version field in docs/repo-keeper/INVENTORY.json to $EXPECTED_VERSION${NC}"
else
    if [ "$QUIET" = false ]; then
        echo -e "${GREEN}[OK] INVENTORY.json version matches: $INVENTORY_VERSION${NC}"
    fi
fi

if [ "$QUIET" = false ]; then
    echo ""
    echo -e "${CYAN}Checking documentation footers...${NC}"
fi

# Find all markdown files (excluding node_modules, .git, and CHANGELOG.md)
while IFS= read -r -d '' file; do
    ((TOTAL_FILES++)) || true
    RELATIVE_PATH="${file#$REPO_ROOT/}"

    # Check for version footer pattern: **Version:** X.Y.Z
    if grep -q '\*\*Version:\*\*' "$file"; then
        FOUND_VERSION=$(grep -oP '\*\*Version:\*\*\s+\K[\d\.]+' "$file" | head -1)

        if [ "$FOUND_VERSION" = "$EXPECTED_VERSION" ]; then
            ((MATCHING_FILES++)) || true
            if [ "$VERBOSE" = true ]; then
                echo -e "  ${GRAY}[OK] $RELATIVE_PATH${NC}"
            fi
        else
            ((WRONG_VERSIONS++)) || true
            ((ERROR_COUNT++)) || true
            ERRORS+=("$RELATIVE_PATH|$FOUND_VERSION|Footer")
            echo -e "  ${YELLOW}[MISMATCH] $RELATIVE_PATH - Found: $FOUND_VERSION${NC}"
            echo -e "    ${YELLOW}How to fix: Update **Version:** footer in $RELATIVE_PATH to $EXPECTED_VERSION${NC}"
        fi
    else
        ((MISSING_FOOTERS++)) || true
        if [ "$VERBOSE" = true ]; then
            echo -e "  ${GRAY}[NO FOOTER] $RELATIVE_PATH${NC}"
        fi
    fi
done < <(find "$REPO_ROOT" -name "*.md" -type f \
    ! -path "*/node_modules/*" \
    ! -path "*/.git/*" \
    ! -path "*/docs/archive/*" \
    ! -name "CHANGELOG.md" \
    -print0)

# Check data files with version fields
if [ "$QUIET" = false ]; then
    echo ""
    echo -e "${CYAN}Checking data files...${NC}"
fi

check_data_file() {
    local file_path="$1"
    local full_path="$REPO_ROOT/$file_path"

    if [ -f "$full_path" ]; then
        DATA_VERSION=$(grep -oP '"version"\s*:\s*"\K[^"]+' "$full_path" | head -1)

        if [ "$DATA_VERSION" != "$EXPECTED_VERSION" ]; then
            ERRORS+=("$file_path|$DATA_VERSION|Data")
            ((ERROR_COUNT++)) || true
            echo -e "  ${RED}[ERROR] $file_path version mismatch: $DATA_VERSION${NC}"
            echo -e "    ${YELLOW}How to fix: Update version field in $file_path to $EXPECTED_VERSION${NC}"
        else
            if [ "$QUIET" = false ]; then
                echo -e "  ${GREEN}[OK] $file_path version matches: $DATA_VERSION${NC}"
            fi
        fi
    fi
}

check_data_file "data/secrets.json"
check_data_file "data/variables.json"

# Summary
if [ "$QUIET" = false ]; then
    echo ""
    echo -e "${CYAN}=== Summary ===${NC}"
    echo "Total markdown files checked: $TOTAL_FILES"
    echo -e "${GREEN}Files with matching footers:  $MATCHING_FILES${NC}"
    echo -e "${YELLOW}Files with wrong versions:    $WRONG_VERSIONS${NC}"
    echo -e "${GRAY}Files missing footers:        $MISSING_FOOTERS${NC}"
    if [ $ERROR_COUNT -eq 0 ]; then
        echo -e "${GREEN}Total errors found:           $ERROR_COUNT${NC}"
    else
        echo -e "${RED}Total errors found:           $ERROR_COUNT${NC}"
    fi
fi

# Detailed error report
if [ $ERROR_COUNT -gt 0 ]; then
    echo ""
    echo -e "${RED}=== Error Details ===${NC}"
    echo ""

    # Group errors by type
    declare -a CONFIG_ERRORS=()
    declare -a INVENTORY_ERRORS=()
    declare -a FOOTER_ERRORS=()
    declare -a DATA_ERRORS=()

    for error in "${ERRORS[@]}"; do
        IFS='|' read -r file version type <<< "$error"
        case $type in
            Config) CONFIG_ERRORS+=("$file|$version") ;;
            Inventory) INVENTORY_ERRORS+=("$file|$version") ;;
            Footer) FOOTER_ERRORS+=("$file|$version") ;;
            Data) DATA_ERRORS+=("$file|$version") ;;
        esac
    done

    if [ ${#CONFIG_ERRORS[@]} -gt 0 ]; then
        echo -e "${YELLOW}Configuration Files:${NC}"
        for error in "${CONFIG_ERRORS[@]}"; do
            IFS='|' read -r file version <<< "$error"
            echo "  $file: $version -> $EXPECTED_VERSION"
        done
        echo ""
    fi

    if [ ${#INVENTORY_ERRORS[@]} -gt 0 ]; then
        echo -e "${YELLOW}Inventory:${NC}"
        for error in "${INVENTORY_ERRORS[@]}"; do
            IFS='|' read -r file version <<< "$error"
            echo "  $file: $version -> $EXPECTED_VERSION"
        done
        echo ""
    fi

    if [ ${#DATA_ERRORS[@]} -gt 0 ]; then
        echo -e "${YELLOW}Data Files:${NC}"
        for error in "${DATA_ERRORS[@]}"; do
            IFS='|' read -r file version <<< "$error"
            echo "  $file: $version -> $EXPECTED_VERSION"
        done
        echo ""
    fi

    if [ ${#FOOTER_ERRORS[@]} -gt 0 ]; then
        echo -e "${YELLOW}Documentation Footers (${#FOOTER_ERRORS[@]} files):${NC}"
        for error in "${FOOTER_ERRORS[@]}"; do
            IFS='|' read -r file version <<< "$error"
            echo "  $file: $version -> $EXPECTED_VERSION"
        done
    fi
fi

if [ "$QUIET" = false ]; then
    echo ""
fi

# Exit with appropriate code for CI/CD
if [ $ERROR_COUNT -eq 0 ]; then
    if [ "$QUIET" = false ]; then
        echo -e "${GREEN}✓ All versions are in sync!${NC}"
    fi
    exit 0
else
    echo -e "${RED}✗ Version sync check failed!${NC}"
    if [ "$QUIET" = false ]; then
        echo ""
        echo "To fix version mismatches:"
        echo "  1. Update all files to version $EXPECTED_VERSION"
        echo "  2. Use search/replace across the repository"
        echo "  3. Run this script again to verify"
    fi
    exit 1
fi
