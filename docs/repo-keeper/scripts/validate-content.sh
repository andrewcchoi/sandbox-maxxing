#!/bin/bash
# validate-content.sh
# Checks that documents contain expected sections and correct references

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
CHECK_EXTERNAL=false
QUIET=false
LOG_FILE=""

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -v|--verbose) VERBOSE=true ;;
        --check-external) CHECK_EXTERNAL=true ;;
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
    echo -e "${CYAN}=== Content Validator ===${NC}"
    echo ""
fi

ERROR_COUNT=0
WARNING_COUNT=0

# Check for UTF-8 BOM
if [ "$QUIET" = false ]; then
    echo -e "${CYAN}Checking for UTF-8 BOM...${NC}"
fi

BOM_COUNT=0
while IFS= read -r -d '' file; do
    if head -c3 "$file" 2>/dev/null | grep -q $'\xef\xbb\xbf'; then
        RELATIVE_PATH="${file#$REPO_ROOT/}"
        echo -e "  ${YELLOW}[WARNING] UTF-8 BOM detected: $RELATIVE_PATH${NC}"
        ((BOM_COUNT++))
        ((WARNING_COUNT++))
    fi
done < <(find "$REPO_ROOT" \( -name "*.md" -o -name "*.json" -o -name "*.sh" \) ! -path "*/node_modules/*" ! -path "*/.git/*" -print0 2>/dev/null)

if [ "$QUIET" = false ]; then
    if [ $BOM_COUNT -eq 0 ]; then
        echo -e "  ${GREEN}[OK] No UTF-8 BOM detected in files${NC}"
    elif [ "$VERBOSE" = false ]; then
        echo -e "  ${YELLOW}Total files with BOM: $BOM_COUNT${NC}"
    fi

    echo ""

    # Check SKILL.md files for required sections
    echo -e "${CYAN}Checking required sections in SKILL.md files...${NC}"
fi

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
if [ "$QUIET" = false ]; then
    echo ""
    echo -e "${CYAN}Checking mode consistency...${NC}"
fi

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

if [ "$QUIET" = false ]; then
    echo -e "  ${GREEN}[OK] $MODE_CONSISTENT/$MODE_CHECKED files reference correct mode${NC}"

    # Check step sequences
    echo ""
    echo -e "${CYAN}Checking step sequences...${NC}"
fi

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

if [ "$QUIET" = false ]; then
    if [ $BROKEN_SEQUENCES -eq 0 ]; then
        echo -e "  ${GREEN}[OK] No broken step sequences found${NC}"
    else
        echo -e "  ${YELLOW}[WARNING] Found $BROKEN_SEQUENCES files with step gaps${NC}"
    fi

    # V10: Check code block syntax
    echo ""
    echo -e "${CYAN}Checking code block syntax...${NC}"
fi

# Common valid language tags
VALID_LANGS="bash|sh|shell|python|py|javascript|js|typescript|ts|json|yaml|yml|markdown|md|html|css|dockerfile|sql|go|rust|java|c|cpp|ruby|php|perl|powershell|ps1|text|txt|plaintext"

INVALID_CODE_BLOCKS=0
MD_FILES_SUBSET=$(find "$REPO_ROOT" -name "*.md" -type f ! -path "*/node_modules/*" ! -path "*/.git/*" 2>/dev/null | head -100)

for md_file in $MD_FILES_SUBSET; do
    RELATIVE_PATH="${md_file#$REPO_ROOT/}"

    # Find fenced code blocks with language tags
    grep -n '^```[a-zA-Z]' "$md_file" 2>/dev/null | while IFS=: read -r line_num line_content; do
        # Extract language tag
        lang=$(echo "$line_content" | sed 's/^```\([a-zA-Z0-9_-]*\).*/\1/')

        # Check if language is valid
        if ! echo "$lang" | grep -qiE "^($VALID_LANGS)$"; then
            if [ "$VERBOSE" = true ]; then
                echo -e "  ${YELLOW}[WARNING] $RELATIVE_PATH:$line_num - Unknown language tag: '$lang'${NC}"
            fi
            ((INVALID_CODE_BLOCKS++))
            ((WARNING_COUNT++))
        fi
    done
done

if [ "$QUIET" = false ]; then
    if [ $INVALID_CODE_BLOCKS -eq 0 ]; then
        echo -e "  ${GREEN}[OK] All code block language tags are valid${NC}"
    elif [ "$VERBOSE" = false ]; then
        echo -e "  ${YELLOW}Total code blocks with unknown languages: $INVALID_CODE_BLOCKS${NC}"
    fi

    # V11: Check YAML frontmatter
    echo ""
    echo -e "${CYAN}Checking YAML frontmatter...${NC}"
fi

INVALID_FRONTMATTER=0
MD_FILES_WITH_FM=$(find "$REPO_ROOT" -name "*.md" -type f ! -path "*/node_modules/*" ! -path "*/.git/*" 2>/dev/null | head -100)

for md_file in $MD_FILES_WITH_FM; do
    RELATIVE_PATH="${md_file#$REPO_ROOT/}"

    # Check if file starts with YAML frontmatter (---)
    FIRST_LINE=$(head -n 1 "$md_file" 2>/dev/null)
    if [ "$FIRST_LINE" = "---" ]; then
        # Extract frontmatter
        FRONTMATTER=$(awk '/^---$/{if(++n==2) exit} n>=1' "$md_file")

        # Check if frontmatter is properly closed
        CLOSING_COUNT=$(echo "$FRONTMATTER" | grep -c '^---$')
        if [ "$CLOSING_COUNT" -lt 2 ]; then
            echo -e "  ${YELLOW}[WARNING] $RELATIVE_PATH - YAML frontmatter not properly closed${NC}"
            ((INVALID_FRONTMATTER++))
            ((WARNING_COUNT++))
            continue
        fi

        # Basic YAML syntax validation using Node.js
        YAML_VALID=$(node -e "
            const fs = require('fs');
            const content = fs.readFileSync('$md_file', 'utf8');
            const lines = content.split('\\n');

            if (lines[0] !== '---') {
                console.log('false');
                process.exit(0);
            }

            let endIdx = -1;
            for (let i = 1; i < lines.length; i++) {
                if (lines[i] === '---') {
                    endIdx = i;
                    break;
                }
            }

            if (endIdx === -1) {
                console.log('false');
                process.exit(0);
            }

            const yamlLines = lines.slice(1, endIdx);

            // Basic YAML validation: check for key: value format
            let valid = true;
            for (const line of yamlLines) {
                if (line.trim() === '') continue;
                if (line.startsWith(' ') || line.startsWith('\t')) continue; // indented lines
                if (!line.includes(':') && line.trim() !== '') {
                    valid = false;
                    break;
                }
            }

            console.log(valid ? 'true' : 'false');
        " 2>/dev/null)

        if [ "$YAML_VALID" != "true" ]; then
            echo -e "  ${YELLOW}[WARNING] $RELATIVE_PATH - Invalid YAML frontmatter syntax${NC}"
            ((INVALID_FRONTMATTER++))
            ((WARNING_COUNT++))
        elif [ "$VERBOSE" = true ]; then
            echo -e "  ${GRAY}[OK] $RELATIVE_PATH - Valid YAML frontmatter${NC}"
        fi
    fi
done

if [ "$QUIET" = false ]; then
    if [ $INVALID_FRONTMATTER -eq 0 ]; then
        echo -e "  ${GREEN}[OK] All YAML frontmatter is valid${NC}"
    else
        echo -e "  ${YELLOW}Files with invalid frontmatter: $INVALID_FRONTMATTER${NC}"
    fi
fi

# External link checking (optional)
if [ "$CHECK_EXTERNAL" = true ]; then
    if [ "$QUIET" = false ]; then
        echo ""
        echo -e "${CYAN}Checking external links (slow)...${NC}"
    fi

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

    if [ "$QUIET" = false ]; then
        echo -e "  ${GREEN}Checked $CHECKED external links, $FAILED failed${NC}"
    fi
fi

# Summary
if [ "$QUIET" = false ]; then
    echo ""
    echo -e "${CYAN}=== Summary ===${NC}"
fi
if [ $ERROR_COUNT -eq 0 ]; then
    if [ "$QUIET" = false ]; then
        echo -e "${GREEN}✓ All content checks passed!${NC}"
        echo -e "${GREEN}Total errors: $ERROR_COUNT${NC}"
        if [ $WARNING_COUNT -gt 0 ]; then
            echo -e "${YELLOW}Total warnings: $WARNING_COUNT${NC}"
        fi
    fi
    exit 0
else
    echo -e "${RED}✗ Content validation failed!${NC}"
    echo -e "${RED}Total errors: $ERROR_COUNT${NC}"
    if [ $WARNING_COUNT -gt 0 ]; then
        echo -e "${YELLOW}Total warnings: $WARNING_COUNT${NC}"
    fi
    exit 1
fi
