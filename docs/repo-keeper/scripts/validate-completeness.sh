#!/bin/bash
# validate-completeness.sh
# Ensures every feature has documentation and all modes have full coverage

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
    echo -e "${CYAN}=== Completeness Validator ===${NC}"
    echo ""
fi

INVENTORY="$REPO_ROOT/docs/repo-keeper/INVENTORY.json"
if [ ! -f "$INVENTORY" ]; then
    echo -e "${RED}Error: INVENTORY.json not found${NC}"
    exit 1
fi

ERROR_COUNT=0

# Feature Documentation Check
if [ "$QUIET" = false ]; then
    echo -e "${CYAN}Checking feature documentation...${NC}"
fi

# Check skills have SKILL.md
SKILL_COUNT=$(node -e "const d=JSON.parse(require('fs').readFileSync('$INVENTORY')); console.log((d.skills || []).length)")
SKILLS_WITH_DOCS=0
for ((i=0; i<SKILL_COUNT; i++)); do
    SKILL_NAME=$(node -e "const d=JSON.parse(require('fs').readFileSync('$INVENTORY')); console.log(d.skills[$i]?.name || '')")
    SKILL_PATH=$(node -e "const d=JSON.parse(require('fs').readFileSync('$INVENTORY')); console.log(d.skills[$i]?.path || '')")

    if [ -f "$REPO_ROOT/$SKILL_PATH" ]; then
        ((SKILLS_WITH_DOCS++)) || true
    else
        echo -e "  ${RED}[ERROR] Missing SKILL.md for: $SKILL_NAME${NC}"
        ((ERROR_COUNT++)) || true
    fi
done
if [ "$QUIET" = false ]; then
    echo -e "  ${GREEN}[OK] $SKILLS_WITH_DOCS/$SKILL_COUNT skills have SKILL.md${NC}"
fi

# Check commands documented in README
COMMAND_COUNT=$(node -e "const d=JSON.parse(require('fs').readFileSync('$INVENTORY')); console.log((d.commands || []).length)")
COMMANDS_README="$REPO_ROOT/commands/README.md"
COMMANDS_DOCUMENTED=0

if [ -f "$COMMANDS_README" ]; then
    for ((i=0; i<COMMAND_COUNT; i++)); do
        COMMAND_NAME=$(node -e "const d=JSON.parse(require('fs').readFileSync('$INVENTORY')); console.log(d.commands[$i]?.name || '')")

        if grep -q "$COMMAND_NAME" "$COMMANDS_README"; then
            ((COMMANDS_DOCUMENTED++)) || true
        else
            echo -e "  ${RED}[ERROR] Command not in README: $COMMAND_NAME${NC}"
            ((ERROR_COUNT++)) || true
        fi
    done
    if [ "$QUIET" = false ]; then
        echo -e "  ${GREEN}[OK] $COMMANDS_DOCUMENTED/$COMMAND_COUNT commands documented in README${NC}"
    fi
else
    echo -e "  ${RED}[ERROR] commands/README.md not found${NC}"
    ((ERROR_COUNT++)) || true
fi

# Check data files in README
DATA_README="$REPO_ROOT/data/README.md"
if [ -f "$DATA_README" ]; then
    DATA_COUNT=$(node -e "const d=JSON.parse(require('fs').readFileSync('$INVENTORY')); console.log((d.data_files || []).length)")
    DATA_DOCUMENTED=0

    for ((i=0; i<DATA_COUNT; i++)); do
        FILE_NAME=$(node -e "const d=JSON.parse(require('fs').readFileSync('$INVENTORY')); console.log(d.data_files[$i]?.name || '')")

        if grep -q "$FILE_NAME" "$DATA_README"; then
            ((DATA_DOCUMENTED++)) || true
        else
            echo -e "  ${RED}[ERROR] Data file not in README: $FILE_NAME${NC}"
            ((ERROR_COUNT++)) || true
        fi
    done
    if [ "$QUIET" = false ]; then
        echo -e "  ${GREEN}[OK] $DATA_DOCUMENTED/$DATA_COUNT data files documented${NC}"
    fi
else
    echo -e "  ${YELLOW}[WARNING] data/README.md not found${NC}"
fi

# Mode Coverage Check
if [ "$QUIET" = false ]; then
    echo ""
    echo -e "${CYAN}Checking mode coverage...${NC}"
fi

MODES=("basic" "intermediate" "advanced" "yolo")
for mode in "${MODES[@]}"; do
    MISSING_COUNT=0

    # Check for skill
    SKILL_EXISTS=$(node -e "const d=JSON.parse(require('fs').readFileSync('$INVENTORY')); const skill = (d.skills || []).find(s => s.mode === '$mode'); console.log(skill?.name || '')")
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

    if [ "$QUIET" = false ]; then
        if [ $MISSING_COUNT -eq 0 ]; then
            echo -e "  ${GREEN}[OK] $mode: 9/9 components${NC}"
        else
            echo -e "  ${RED}[ERROR] $mode: Missing $MISSING_COUNT components${NC}"
        fi
    fi
done

# Summary
if [ "$QUIET" = false ]; then
    echo ""
    echo -e "${CYAN}=== Summary ===${NC}"
fi
if [ $ERROR_COUNT -eq 0 ]; then
    if [ "$QUIET" = false ]; then
        echo -e "${GREEN}✓ All completeness checks passed!${NC}"
        echo -e "${GREEN}Total errors: $ERROR_COUNT${NC}"
    fi
    exit 0
else
    echo -e "${RED}✗ Completeness validation failed!${NC}"
    echo -e "${RED}Total errors: $ERROR_COUNT${NC}"
    exit 1
fi
