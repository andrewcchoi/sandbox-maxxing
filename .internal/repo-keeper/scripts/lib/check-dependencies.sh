#!/bin/bash
# Reusable dependency checking functions for repo-keeper scripts
# Source this file: source "$(dirname "$0")/lib/check-dependencies.sh"

# Color codes
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

check_node() {
    if ! command -v node &>/dev/null; then
        echo -e "${RED}Error: Node.js is required but not installed${NC}"
        echo "Install with: https://nodejs.org/ or 'nvm install --lts'"
        exit 127
    fi

    # Check Node.js version (require 18+)
    local node_version=$(node -v | sed 's/v//' | cut -d. -f1)
    if [[ $node_version -lt 18 ]]; then
        echo -e "${YELLOW}Warning: Node.js 18+ recommended (found v$node_version)${NC}"
    fi

    # Check for ajv-cli
    if ! command -v ajv &>/dev/null; then
        echo -e "${YELLOW}Installing ajv-cli...${NC}"
        npm install -g ajv-cli ajv-formats 2>&1 | grep -v "npm WARN"
    fi

    echo -e "${GREEN}✓ Node.js dependencies OK${NC}"
}

check_curl() {
    if ! command -v curl &>/dev/null; then
        echo -e "${YELLOW}Warning: curl not installed (external link checking disabled)${NC}"
        return 1
    fi
    return 0
}

# Export functions
export -f check_node
export -f check_curl
