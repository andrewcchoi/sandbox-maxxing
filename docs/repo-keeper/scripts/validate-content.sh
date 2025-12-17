#!/bin/bash
# validate-content.sh
# Checks that documents contain expected sections and correct references

set -e

REPO_ROOT="/workspace"
VERBOSE=false
CHECK_EXTERNAL=false

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -v|--verbose) VERBOSE=true ;;
        --check-external) CHECK_EXTERNAL=true ;;
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

echo -e "${CYAN}=== Content Validator ===${NC}"
echo ""

ERROR_COUNT=0

# Check SKILL.md files for required sections
echo -e "${CYAN}Checking required sections in SKILL.md files...${NC}"

SKILL_FILES=$(find "$REPO_ROOT/skills" -name "SKILL.md" -type f 2>/dev/null)
for skill_file in $SKILL_FILES; do
    SKILL_NAME=$(basename $(dirname "$skill_file"))

    # Check for required sections
    HAS_OVERVIEW=false
    HAS_USAGE=false
    HAS_EXAMPLES=false
    HAS_FOOTER=false

    if grep -qi "overview" "$skill_file"; then
        HAS_OVERVIEW=true
    fi

    if grep -qi "usage" "$skill_file"; then
        HAS_USAGE=true
    fi

    if grep -qi "example" "$skill_file"; then
        HAS_EXAMPLES=true
    fi

    if grep -q '\*\*Version:\*\*' "$skill_file"; then
        HAS_FOOTER=true
    fi

    MISSING_SECTIONS=()
    [ "$HAS_OVERVIEW" = false ] && MISSING_SECTIONS+=("Overview")
    [ "$HAS_USAGE" = false ] && MISSING_SECTIONS+=("Usage")
    [ "$HAS_EXAMPLES" = false ] && MISSING_SECTIONS+=("Examples")
    [ "$HAS_FOOTER" = false ] && MISSING_SECTIONS+=("Footer")

    if [ ${#MISSING_SECTIONS[@]} -gt 0 ]; then
        echo -e "  ${RED}[ERROR] $SKILL_NAME missing: ${MISSING_SECTIONS[*]}${NC}"
        ERROR_COUNT=$((ERROR_COUNT + 1))
    elif [ "$VERBOSE" = true ]; then
        echo -e "  ${GRAY}[OK] $SKILL_NAME has all sections${NC}"
    fi
done

# Check mode consistency
echo ""
echo -e "${CYAN}Checking mode consistency...${NC}"

MODE_FILES=$(find "$REPO_ROOT" -type f \( -name "*basic*" -o -name "*intermediate*" -o -name "*advanced*" -o -name "*yolo*" \) \( -name "*.md" -o -name "SKILL.md" \) 2>/dev/null)

MODE_CONSISTENT=0
MODE_CHECKED=0
for file in $MODE_FILES; do
    MODE_CHECKED=$((MODE_CHECKED + 1))

    # Determine expected mode from filename
    if [[ "$file" =~ basic ]]; then
        EXPECTED_MODE="basic"
    elif [[ "$file" =~ intermediate ]]; then
        EXPECTED_MODE="intermediate"
    elif [[ "$file" =~ advanced ]]; then
        EXPECTED_MODE="advanced"
    elif [[ "$file" =~ yolo ]]; then
        EXPECTED_MODE="yolo"
    else
        continue
    fi

    # Check if file content mentions the mode
    if grep -qi "$EXPECTED_MODE" "$file"; then
        MODE_CONSISTENT=$((MODE_CONSISTENT + 1))
        if [ "$VERBOSE" = true ]; then
            echo -e "  ${GRAY}[OK] $(basename $file) references $EXPECTED_MODE${NC}"
        fi
    else
        echo -e "  ${YELLOW}[WARNING] $(basename $file) doesn't mention '$EXPECTED_MODE'${NC}"
    fi
done

echo -e "  ${GREEN}[OK] $MODE_CONSISTENT/$MODE_CHECKED files reference correct mode${NC}"

# Check step sequences
echo ""
echo -e "${CYAN}Checking step sequences...${NC}"

MD_FILES=$(find "$REPO_ROOT" -name "*.md" -type f ! -path "*/node_modules/*" ! -path "*/.git/*" 2>/dev/null | head -50)

BROKEN_SEQUENCES=0
for md_file in $MD_FILES; do
    # Extract numbered steps (1., 2., 3., etc.)
    STEPS=$(grep -oP '^\s*\d+\.' "$md_file" 2>/dev/null | grep -oP '\d+' | sort -n)

    if [ -n "$STEPS" ]; then
        # Check for gaps in sequence
        PREV=0
        while IFS= read -r step; do
            if [ "$PREV" -ne 0 ] && [ $((step - PREV)) -gt 1 ]; then
                echo -e "  ${YELLOW}[WARNING] $(basename $md_file): Gap in steps ($PREV -> $step)${NC}"
                BROKEN_SEQUENCES=$((BROKEN_SEQUENCES + 1))
                break
            fi
            PREV=$step
        done <<< "$STEPS"
    fi
done

if [ $BROKEN_SEQUENCES -eq 0 ]; then
    echo -e "  ${GREEN}[OK] No broken step sequences found${NC}"
else
    echo -e "  ${YELLOW}[WARNING] Found $BROKEN_SEQUENCES files with step gaps${NC}"
fi

# External link checking (optional)
if [ "$CHECK_EXTERNAL" = true ]; then
    echo ""
    echo -e "${CYAN}Checking external links (slow)...${NC}"

    EXTERNAL_LINKS=$(grep -rhoP 'https?://[^)]+' "$REPO_ROOT" --include="*.md" 2>/dev/null | sort -u | head -20)

    CHECKED=0
    FAILED=0
    for link in $EXTERNAL_LINKS; do
        CHECKED=$((CHECKED + 1))

        if curl -sSf -o /dev/null --head --max-time 5 "$link" 2>/dev/null; then
            if [ "$VERBOSE" = true ]; then
                echo -e "  ${GRAY}[OK] $link${NC}"
            fi
        else
            echo -e "  ${RED}[ERROR] $link (unreachable)${NC}"
            FAILED=$((FAILED + 1))
            ERROR_COUNT=$((ERROR_COUNT + 1))
        fi
    done

    echo -e "  ${GREEN}Checked $CHECKED external links, $FAILED failed${NC}"
fi

# Summary
echo ""
echo -e "${CYAN}=== Summary ===${NC}"
if [ $ERROR_COUNT -eq 0 ]; then
    echo -e "${GREEN}✓ All content checks passed!${NC}"
    echo -e "${GREEN}Total errors: $ERROR_COUNT${NC}"
    exit 0
else
    echo -e "${RED}✗ Content validation failed!${NC}"
    echo -e "${RED}Total errors: $ERROR_COUNT${NC}"
    exit 1
fi
