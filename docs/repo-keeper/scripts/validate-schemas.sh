#!/bin/bash
# validate-schemas.sh
# Validates JSON files against their schemas

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

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -v|--verbose) VERBOSE=true ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

echo -e "${CYAN}=== JSON Schema Validator ===${NC}"
echo ""

ERROR_COUNT=0

# Function to validate a file against a schema using ajv-cli
validate_against_schema() {
    local data_file="$1"
    local schema_file="$2"
    local file_name=$(basename "$data_file")

    echo -e "${CYAN}Validating $file_name...${NC}"

    if [ ! -f "$data_file" ]; then
        echo -e "  ${RED}[ERROR] File not found: $data_file${NC}"
        ((ERROR_COUNT++))
        return 1
    fi

    if [ ! -f "$schema_file" ]; then
        echo -e "  ${YELLOW}[WARNING] Schema not found: $schema_file${NC}"
        return 0
    fi

    # Validate using ajv-cli
    if ajv validate -s "$schema_file" -d "$data_file" --spec=draft7 2>&1 | grep -q "valid"; then
        echo -e "  ${GREEN}✓ Schema validation passed${NC}"

        # Additional info using node
        if [ "$VERBOSE" = true ]; then
            local version=$(node -e "try { const data = JSON.parse(require('fs').readFileSync('$data_file')); console.log(data.version || 'N/A'); } catch(e) { console.log('N/A'); }")
            local desc=$(node -e "try { const data = JSON.parse(require('fs').readFileSync('$data_file')); console.log((data.description || 'N/A').substring(0, 60)); } catch(e) { console.log('N/A'); }")
            echo -e "  ${GRAY}  version: $version${NC}"
            echo -e "  ${GRAY}  description: $desc${NC}"
        fi
        return 0
    else
        echo -e "  ${RED}✗ Schema validation failed${NC}"
        # Show validation errors
        ajv validate -s "$schema_file" -d "$data_file" --spec=draft7 2>&1 | grep -v "valid" | head -10 | while read line; do
            echo -e "  ${RED}  $line${NC}"
        done
        ((ERROR_COUNT++))
        return 1
    fi
}

# Validate INVENTORY.json against schema
INVENTORY="$REPO_ROOT/docs/repo-keeper/INVENTORY.json"
INVENTORY_SCHEMA="$REPO_ROOT/docs/repo-keeper/schemas/inventory.schema.json"

validate_against_schema "$INVENTORY" "$INVENTORY_SCHEMA"

# Validate data files against generic data-file schema
echo ""
DATA_SCHEMA="$REPO_ROOT/docs/repo-keeper/schemas/data-file.schema.json"

for data_file in "$REPO_ROOT/data"/*.json; do
    [ -e "$data_file" ] || continue
    validate_against_schema "$data_file" "$DATA_SCHEMA"
done

# Summary
echo ""
echo -e "${CYAN}=== Summary ===${NC}"
if [ $ERROR_COUNT -eq 0 ]; then
    echo -e "${GREEN}✓ All schemas valid!${NC}"
    echo -e "${GREEN}Total errors: $ERROR_COUNT${NC}"
    exit 0
else
    echo -e "${RED}✗ Schema validation failed!${NC}"
    echo -e "${RED}Total errors: $ERROR_COUNT${NC}"
    exit 1
fi
