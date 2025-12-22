#!/bin/bash
# check-permissions.sh
# Validates that shell scripts have execute permissions

# Don't exit on errors (we want to report warnings gracefully)
set +e

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

# Detect Windows/WSL
IS_WSL=false
if grep -qi microsoft /proc/version 2>/dev/null; then
    IS_WSL=true
fi

# Check if core.filemode is false
FILEMODE_DISABLED=false
if git config core.filemode | grep -q "false"; then
    FILEMODE_DISABLED=true
fi

if [ "$QUIET" = false ]; then
    echo -e "${CYAN}=== File Permissions Validator ===${NC}"
    if [ "$IS_WSL" = true ] || [ "$FILEMODE_DISABLED" = true ]; then
        echo -e "${YELLOW}Note: Running on WSL or with core.filemode=false${NC}"
        echo -e "${YELLOW}Permissions check is informational only${NC}"
    fi
    echo ""
fi

WARNING_COUNT=0
TOTAL_SCRIPTS=0

# Check script permissions in scripts directory
if [ "$QUIET" = false ]; then
    echo -e "${CYAN}Checking script permissions...${NC}"
fi

for script in "$SCRIPT_DIR"/*.sh; do
    [ -e "$script" ] || continue
    ((TOTAL_SCRIPTS++)) || true

    script_name=$(basename "$script")

    if [ ! -x "$script" ]; then
        echo -e "  ${YELLOW}[WARNING] Not executable: $script_name${NC}"
        ((WARNING_COUNT++)) || true
    elif [ "$VERBOSE" = true ]; then
        echo -e "  ${GRAY}[OK] $script_name is executable${NC}"
    fi
done

# Check scripts in lib directory
if [ -d "$SCRIPT_DIR/lib" ]; then
    for script in "$SCRIPT_DIR/lib"/*.sh; do
        [ -e "$script" ] || continue
        ((TOTAL_SCRIPTS++)) || true

            script_name="lib/$(basename "$script")"

        if [ ! -x "$script" ]; then
            echo -e "  ${YELLOW}[WARNING] Not executable: $script_name${NC}"
            ((WARNING_COUNT++)) || true
        elif [ "$VERBOSE" = true ]; then
            echo -e "  ${GRAY}[OK] $script_name is executable${NC}"
        fi
    done
fi

# Summary
if [ "$QUIET" = false ]; then
    echo ""
    echo -e "${CYAN}=== Summary ===${NC}"
    echo "Total shell scripts checked: $TOTAL_SCRIPTS"
fi
if [ $WARNING_COUNT -eq 0 ]; then
    if [ "$QUIET" = false ]; then
        echo -e "${GREEN}All scripts are executable!${NC}"
        echo -e "${GREEN}Warnings: $WARNING_COUNT${NC}"
    fi
    exit 0
else
    if [ "$QUIET" = false ]; then
        echo -e "${YELLOW}Scripts with permission issues: $WARNING_COUNT${NC}"
        echo ""
        if [ "$IS_WSL" = true ] || [ "$FILEMODE_DISABLED" = true ]; then
            echo -e "${YELLOW}Note: On WSL/Windows, permissions may not work as expected.${NC}"
            echo -e "${YELLOW}Scripts can still be run with: bash script.sh${NC}"
            echo ""
            echo "On Linux systems, to fix permission issues run:"
        else
            echo "To fix permission issues, run:"
        fi
        echo "  chmod +x \$SCRIPT_DIR/*.sh"
        echo "  chmod +x \$SCRIPT_DIR/lib/*.sh"
    fi
    exit 0  # Don't fail on warnings (informational only)
fi
