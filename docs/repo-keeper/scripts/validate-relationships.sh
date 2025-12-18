#!/bin/bash
# validate-relationships.sh
# Validates INVENTORY.json relationships are accurate

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

echo -e "${CYAN}=== Relationship Validator ===${NC}"
echo ""

# Check for jq
if ! command -v jq &> /dev/null; then
    if [ -f "/tmp/bin/jq" ]; then
        export PATH="/tmp/bin:$PATH"
    else
        echo -e "${RED}Error: jq is required but not installed${NC}"
        exit 1
    fi
fi

INVENTORY="$REPO_ROOT/docs/repo-keeper/INVENTORY.json"
if [ ! -f "$INVENTORY" ]; then
    echo -e "${RED}Error: INVENTORY.json not found${NC}"
    exit 1
fi

ERROR_COUNT=0
TOTAL_CHECKS=0

# Check skill → template relationships
echo -e "${CYAN}Checking skill → template relationships...${NC}"

SKILL_COUNT=$(jq '.skills | length' "$INVENTORY")
for ((i=0; i<SKILL_COUNT; i++)); do
    SKILL_NAME=$(jq -r ".skills[$i].name" "$INVENTORY")
    SKILL_PATH=$(jq -r ".skills[$i].path" "$INVENTORY")

    # Check skill file exists
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if [ ! -f "$REPO_ROOT/$SKILL_PATH" ]; then
        echo -e "  ${RED}[ERROR] $SKILL_NAME: Skill file not found: $SKILL_PATH${NC}"
        ERROR_COUNT=$((ERROR_COUNT + 1))
    elif [ "$VERBOSE" = true ]; then
        echo -e "  ${GRAY}[OK] $SKILL_NAME: skill file exists${NC}"
    fi

    # Check related templates
    TEMPLATE_COUNT=$(jq ".skills[$i].related_templates | length // 0" "$INVENTORY")
    if [ "$TEMPLATE_COUNT" -gt 0 ]; then
        for ((j=0; j<TEMPLATE_COUNT; j++)); do
            TEMPLATE_PATH=$(jq -r ".skills[$i].related_templates[$j]" "$INVENTORY")
            TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

            if [ ! -f "$REPO_ROOT/$TEMPLATE_PATH" ]; then
                echo -e "  ${RED}[ERROR] $SKILL_NAME → $TEMPLATE_PATH (NOT FOUND)${NC}"
                ERROR_COUNT=$((ERROR_COUNT + 1))
            elif [ "$VERBOSE" = true ]; then
                echo -e "  ${GRAY}[OK] $SKILL_NAME → $TEMPLATE_PATH${NC}"
            fi
        done
    fi
done

if [ "$ERROR_COUNT" -eq 0 ]; then
    echo -e "  ${GREEN}[OK] All skill → template relationships valid${NC}"
fi

# Check skill ↔ command relationships
echo ""
echo -e "${CYAN}Checking skill ↔ command relationships...${NC}"

for ((i=0; i<SKILL_COUNT; i++)); do
    SKILL_NAME=$(jq -r ".skills[$i].name" "$INVENTORY")
    RELATED_COMMAND=$(jq -r ".skills[$i].related_command // empty" "$INVENTORY")

    if [ -n "$RELATED_COMMAND" ]; then
        TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

        # Check command file exists
        if [ ! -f "$REPO_ROOT/$RELATED_COMMAND" ]; then
            echo -e "  ${RED}[ERROR] $SKILL_NAME → $RELATED_COMMAND (NOT FOUND)${NC}"
            ERROR_COUNT=$((ERROR_COUNT + 1))
        else
            # Check command mentions skill (bidirectional)
            if grep -q "$SKILL_NAME" "$REPO_ROOT/$RELATED_COMMAND"; then
                if [ "$VERBOSE" = true ]; then
                    echo -e "  ${GRAY}[OK] $SKILL_NAME ↔ $RELATED_COMMAND (bidirectional)${NC}"
                fi
            else
                echo -e "  ${YELLOW}[WARNING] $RELATED_COMMAND doesn't mention $SKILL_NAME${NC}"
            fi
        fi
    fi
done

if [ "$ERROR_COUNT" -eq 0 ]; then
    echo -e "  ${GREEN}[OK] All skill ↔ command relationships valid${NC}"
fi

# Check command → skill relationships (reverse)
echo ""
echo -e "${CYAN}Checking command → skill relationships...${NC}"

COMMAND_COUNT=$(jq '.commands | length' "$INVENTORY")
for ((i=0; i<COMMAND_COUNT; i++)); do
    COMMAND_NAME=$(jq -r ".commands[$i].name" "$INVENTORY")
    COMMAND_PATH=$(jq -r ".commands[$i].path" "$INVENTORY")
    INVOKES_SKILL=$(jq -r ".commands[$i].invokes_skill" "$INVENTORY")

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    # Check if invoked skill exists
    SKILL_EXISTS=$(jq -r --arg skill "$INVOKES_SKILL" '.skills[] | select(.name == $skill) | .name' "$INVENTORY")

    if [ -z "$SKILL_EXISTS" ] && [ "$INVOKES_SKILL" != "interactive" ]; then
        echo -e "  ${RED}[ERROR] $COMMAND_NAME invokes non-existent skill: $INVOKES_SKILL${NC}"
        ERROR_COUNT=$((ERROR_COUNT + 1))
    elif [ "$VERBOSE" = true ]; then
        echo -e "  ${GRAY}[OK] $COMMAND_NAME → $INVOKES_SKILL${NC}"
    fi
done

if [ "$ERROR_COUNT" -eq 0 ]; then
    echo -e "  ${GREEN}[OK] All command → skill relationships valid${NC}"
fi

# Check skill → example relationships
echo ""
echo -e "${CYAN}Checking skill → example relationships...${NC}"

for ((i=0; i<SKILL_COUNT; i++)); do
    SKILL_NAME=$(jq -r ".skills[$i].name" "$INVENTORY")
    RELATED_EXAMPLE=$(jq -r ".skills[$i].related_example // empty" "$INVENTORY")

    if [ -n "$RELATED_EXAMPLE" ] && [ "$RELATED_EXAMPLE" != "null" ]; then
        TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

        if [ ! -d "$REPO_ROOT/$RELATED_EXAMPLE" ]; then
            echo -e "  ${RED}[ERROR] $SKILL_NAME → $RELATED_EXAMPLE (NOT FOUND)${NC}"
            ERROR_COUNT=$((ERROR_COUNT + 1))
        elif [ "$VERBOSE" = true ]; then
            echo -e "  ${GRAY}[OK] $SKILL_NAME → $RELATED_EXAMPLE${NC}"
        fi
    fi
done

if [ "$ERROR_COUNT" -eq 0 ]; then
    echo -e "  ${GREEN}[OK] All skill → example relationships valid${NC}"
fi

# Summary
echo ""
echo -e "${CYAN}=== Summary ===${NC}"
echo "Total relationships checked: $TOTAL_CHECKS"
if [ $ERROR_COUNT -eq 0 ]; then
    echo -e "${GREEN}✓ All relationships valid!${NC}"
    echo -e "${GREEN}Total errors: $ERROR_COUNT${NC}"
    exit 0
else
    echo -e "${RED}✗ Relationship validation failed!${NC}"
    echo -e "${RED}Total errors: $ERROR_COUNT${NC}"
    exit 1
fi
