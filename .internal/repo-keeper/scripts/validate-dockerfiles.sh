#!/bin/bash
# validate-dockerfiles.sh
# V14: Basic Dockerfile syntax validation

set -e

# Auto-detect repo root from script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Allow override via environment variable
if [[ -n "${REPO_ROOT_OVERRIDE:-}" ]]; then
    REPO_ROOT="$REPO_ROOT_OVERRIDE"
fi

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
    echo -e "${CYAN}=== Dockerfile Validator ===${NC}"
    echo ""
fi

WARNING_COUNT=0
ERROR_COUNT=0

# Find all Dockerfiles
DOCKERFILES=$(find "$REPO_ROOT" -type f \( -name "Dockerfile*" -o -name "*.dockerfile" \) ! -path "*/node_modules/*" ! -path "*/.git/*" 2>/dev/null)

TOTAL_DOCKERFILES=0
INVALID_DOCKERFILES=0

if [ "$QUIET" = false ]; then
    echo -e "${CYAN}Validating Dockerfile syntax...${NC}"
fi

for dockerfile in $DOCKERFILES; do
    [ -e "$dockerfile" ] || continue
    ((TOTAL_DOCKERFILES++))

    RELATIVE_PATH="${dockerfile#$REPO_ROOT/}"
    HAS_ISSUES=false

    # Check 1: Must start with FROM (or ARG before FROM)
    FIRST_INSTRUCTION=$(grep -v '^#' "$dockerfile" | grep -v '^$' | head -1)
    if [[ ! "$FIRST_INSTRUCTION" =~ ^(FROM|ARG) ]]; then
        echo -e "  ${RED}[ERROR] $RELATIVE_PATH - Must start with FROM or ARG${NC}"
        ((ERROR_COUNT++))
        ((INVALID_DOCKERFILES++))
        HAS_ISSUES=true
    fi

    # Check 2: Valid instruction keywords
    VALID_INSTRUCTIONS="FROM|RUN|CMD|LABEL|EXPOSE|ENV|ADD|COPY|ENTRYPOINT|VOLUME|USER|WORKDIR|ARG|ONBUILD|STOPSIGNAL|HEALTHCHECK|SHELL"

    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^# ]] && continue
        [[ -z "${line// }" ]] && continue

        # Extract instruction (first word)
        instruction=$(echo "$line" | awk '{print $1}')

        # Check if it's a known instruction
        if ! echo "$instruction" | grep -qiE "^($VALID_INSTRUCTIONS)$"; then
            # Could be a continuation line (starts with whitespace)
            if [[ ! "$line" =~ ^[[:space:]] ]]; then
                echo -e "  ${YELLOW}[WARNING] $RELATIVE_PATH - Unknown instruction: $instruction${NC}"
                ((WARNING_COUNT++))
                HAS_ISSUES=true
            fi
        fi
    done < <(grep -v '^#' "$dockerfile" | grep -v '^$')

    # Check 3: FROM uses valid base image format
    FROM_LINES=$(grep -i '^FROM' "$dockerfile" 2>/dev/null)
    while IFS= read -r from_line; do
        # Basic format check: FROM image[:tag] [AS name]
        if [[ ! "$from_line" =~ ^FROM[[:space:]]+[a-zA-Z0-9._/-]+(:[ a-zA-Z0-9._-]+)?([[:space:]]+AS[[:space:]]+[a-zA-Z0-9._-]+)?$ ]]; then
            if [ "$VERBOSE" = true ]; then
                echo -e "  ${GRAY}$RELATIVE_PATH - FROM: $from_line${NC}"
            fi
        fi
    done <<< "$FROM_LINES"

    # Check 4: No MAINTAINER (deprecated)
    if grep -qi '^MAINTAINER' "$dockerfile" 2>/dev/null; then
        echo -e "  ${YELLOW}[WARNING] $RELATIVE_PATH - MAINTAINER is deprecated, use LABEL instead${NC}"
        ((WARNING_COUNT++))
        HAS_ISSUES=true
    fi

    # Check 5: Warn about ADD when COPY should be used
    if grep -qi '^ADD[[:space:]]' "$dockerfile" 2>/dev/null; then
        ADD_COUNT=$(grep -ci '^ADD[[:space:]]' "$dockerfile")
        if [ "$VERBOSE" = true ]; then
            echo -e "  ${GRAY}[INFO] $RELATIVE_PATH - Uses ADD ($ADD_COUNT times). Consider COPY if not extracting archives.${NC}"
        fi
    fi

    if [ "$HAS_ISSUES" = false ] && [ "$VERBOSE" = true ]; then
        echo -e "  ${GRAY}[OK] $RELATIVE_PATH${NC}"
    fi
done

# Summary
if [ "$QUIET" = false ]; then
    echo ""
    echo -e "${CYAN}=== Summary ===${NC}"
    echo "Total Dockerfiles checked: $TOTAL_DOCKERFILES"
fi

if [ $ERROR_COUNT -eq 0 ] && [ $WARNING_COUNT -eq 0 ]; then
    if [ "$QUIET" = false ]; then
        echo -e "${GREEN}✓ All Dockerfiles are valid!${NC}"
    fi
    exit 0
elif [ $ERROR_COUNT -eq 0 ]; then
    if [ "$QUIET" = false ]; then
        echo -e "${YELLOW}⚠ Dockerfile validation passed with warnings${NC}"
        echo -e "${YELLOW}Warnings: $WARNING_COUNT${NC}"
    fi
    exit 0
else
    echo -e "${RED}✗ Dockerfile validation failed!${NC}"
    echo -e "${RED}Errors: $ERROR_COUNT${NC}"
    echo -e "${YELLOW}Warnings: $WARNING_COUNT${NC}"
    exit 1
fi
