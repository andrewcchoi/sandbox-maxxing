#!/bin/bash
# validate-completeness.sh
# Ensures every feature has documentation and all modes have full coverage

set -e

REPO_ROOT="/workspace"
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

echo -e "${CYAN}=== Completeness Validator ===${NC}"
echo ""

# Check for jq
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is required but not installed${NC}"
    exit 1
fi

INVENTORY="$REPO_ROOT/docs/repo-keeper/INVENTORY.json"
if [ ! -f "$INVENTORY" ]; then
    echo -e "${RED}Error: INVENTORY.json not found${NC}"
    exit 1
fi

ERROR_COUNT=0

# Feature Documentation Check
echo -e "${CYAN}Checking feature documentation...${NC}"

# Check skills have SKILL.md
SKILL_COUNT=$(jq '.skills | length' "$INVENTORY")
SKILLS_WITH_DOCS=0
for ((i=0; i<SKILL_COUNT; i++)); do
    SKILL_NAME=$(jq -r ".skills[$i].name" "$INVENTORY")
    SKILL_PATH=$(jq -r ".skills[$i].path" "$INVENTORY")

    if [ -f "$REPO_ROOT/$SKILL_PATH" ]; then
        ((SKILLS_WITH_DOCS++)) || true
    else
        echo -e "  ${RED}[ERROR] Missing SKILL.md for: $SKILL_NAME${NC}"
        ((ERROR_COUNT++)) || true
    fi
done
echo -e "  ${GREEN}[OK] $SKILLS_WITH_DOCS/$SKILL_COUNT skills have SKILL.md${NC}"

# Check commands documented in README
COMMAND_COUNT=$(jq '.commands | length' "$INVENTORY")
COMMANDS_README="$REPO_ROOT/commands/README.md"
COMMANDS_DOCUMENTED=0

if [ -f "$COMMANDS_README" ]; then
    for ((i=0; i<COMMAND_COUNT; i++)); do
        COMMAND_NAME=$(jq -r ".commands[$i].name" "$INVENTORY")

        if grep -q "$COMMAND_NAME" "$COMMANDS_README"; then
            ((COMMANDS_DOCUMENTED++)) || true
        else
            echo -e "  ${RED}[ERROR] Command not in README: $COMMAND_NAME${NC}"
            ((ERROR_COUNT++)) || true
        fi
    done
    echo -e "  ${GREEN}[OK] $COMMANDS_DOCUMENTED/$COMMAND_COUNT commands documented in README${NC}"
else
    echo -e "  ${RED}[ERROR] commands/README.md not found${NC}"
    ((ERROR_COUNT++)) || true
fi

# Check data files in README
DATA_README="$REPO_ROOT/data/README.md"
if [ -f "$DATA_README" ]; then
    DATA_COUNT=$(jq '.data_files | length' "$INVENTORY")
    DATA_DOCUMENTED=0

    for ((i=0; i<DATA_COUNT; i++)); do
        FILE_NAME=$(jq -r ".data_files[$i].name" "$INVENTORY")

        if grep -q "$FILE_NAME" "$DATA_README"; then
            ((DATA_DOCUMENTED++)) || true
        else
            echo -e "  ${RED}[ERROR] Data file not in README: $FILE_NAME${NC}"
            ((ERROR_COUNT++)) || true
        fi
    done
    echo -e "  ${GREEN}[OK] $DATA_DOCUMENTED/$DATA_COUNT data files documented${NC}"
else
    echo -e "  ${YELLOW}[WARNING] data/README.md not found${NC}"
fi

# Mode Coverage Check
echo ""
echo -e "${CYAN}Checking mode coverage...${NC}"

MODES=("basic" "intermediate" "advanced" "yolo")
for mode in "${MODES[@]}"; do
    MISSING_COUNT=0

    # Check for skill
    SKILL_EXISTS=$(jq -r --arg mode "$mode" '.skills[] | select(.mode == $mode) | .name' "$INVENTORY")
    if [ -z "$SKILL_EXISTS" ]; then
        echo -e "  ${RED}[ERROR] $mode: No skill found${NC}"
        ((ERROR_COUNT++)) || true
        ((MISSING_COUNT++)) || true
    fi

    # Check for command
    COMMAND_FILE="$REPO_ROOT/commands/${mode}.md"
    if [ ! -f "$COMMAND_FILE" ]; then
        echo -e "  ${RED}[ERROR] $mode: Command file missing${NC}"
        ((ERROR_COUNT++)) || true
        ((MISSING_COUNT++)) || true
    fi

    # Check for templates
    TEMPLATE_TYPES=("compose/docker-compose" "firewall" "extensions/extensions" "mcp/mcp" "variables/variables" "env/.env")
    for type in "${TEMPLATE_TYPES[@]}"; do
        # Handle different naming patterns
        if [[ "$type" == "firewall" ]]; then
            TEMPLATE_FILE=$(find "$REPO_ROOT/templates/firewall" -name "*${mode}*" -type f 2>/dev/null | head -1)
        elif [[ "$type" == "env/.env" ]]; then
            TEMPLATE_FILE="$REPO_ROOT/templates/env/.env.${mode}.template"
        else
            TEMPLATE_FILE="$REPO_ROOT/templates/${type}.${mode}."*
            TEMPLATE_FILE=$(ls $TEMPLATE_FILE 2>/dev/null | head -1)
        fi

        if [ -z "$TEMPLATE_FILE" ] || [ ! -f "$TEMPLATE_FILE" ]; then
            ((MISSING_COUNT++)) || true
        fi
    done

    # Check for example
    EXAMPLE_DIR="$REPO_ROOT/examples/demo-app-sandbox-${mode}"
    if [ ! -d "$EXAMPLE_DIR" ]; then
        echo -e "  ${RED}[ERROR] $mode: Example directory missing${NC}"
        ((ERROR_COUNT++)) || true
        ((MISSING_COUNT++)) || true
    fi

    if [ $MISSING_COUNT -eq 0 ]; then
        echo -e "  ${GREEN}[OK] $mode: 9/9 components${NC}"
    else
        echo -e "  ${RED}[ERROR] $mode: Missing $MISSING_COUNT components${NC}"
    fi
done

# Summary
echo ""
echo -e "${CYAN}=== Summary ===${NC}"
if [ $ERROR_COUNT -eq 0 ]; then
    echo -e "${GREEN}✓ All completeness checks passed!${NC}"
    echo -e "${GREEN}Total errors: $ERROR_COUNT${NC}"
    exit 0
else
    echo -e "${RED}✗ Completeness validation failed!${NC}"
    echo -e "${RED}Total errors: $ERROR_COUNT${NC}"
    exit 1
fi
