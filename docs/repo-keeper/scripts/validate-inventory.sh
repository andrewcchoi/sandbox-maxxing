#!/bin/bash
# validate-inventory.sh
# Validates INVENTORY.json against actual repository filesystem

REPO_ROOT="/workspace"
VERBOSE=false
FIND_ORPHANS=false

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -v|--verbose) VERBOSE=true ;;
        --find-orphans) FIND_ORPHANS=true ;;
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

echo -e "${CYAN}=== Repository Inventory Validator ===${NC}"
echo ""

# Check for Python
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Error: python3 is required but not installed${NC}"
    exit 1
fi

INVENTORY="$REPO_ROOT/docs/repo-keeper/INVENTORY.json"
if [ ! -f "$INVENTORY" ]; then
    echo -e "${RED}Error: INVENTORY.json not found${NC}"
    exit 1
fi

# Get inventory metadata
VERSION=$(python3 -c "import json; data=json.load(open('$INVENTORY')); print(data.get('version', 'unknown'))")
LAST_UPDATED=$(python3 -c "import json; data=json.load(open('$INVENTORY')); print(data.get('last_updated', 'unknown'))")

echo -e "${GREEN}Inventory version: $VERSION${NC}"
echo -e "${GREEN}Last updated: $LAST_UPDATED${NC}"
echo ""

TOTAL_PATHS=0
VALID_PATHS=0
MISSING_PATHS=0
declare -a ERRORS

# Function to validate a path
validate_path() {
    local path=$1
    local category=$2

    ((TOTAL_PATHS++))

    if [ -e "$REPO_ROOT/$path" ]; then
        ((VALID_PATHS++))
        if [ "$VERBOSE" = true ]; then
            echo -e "  ${GRAY}[OK] $path${NC}"
        fi
        return 0
    else
        ((MISSING_PATHS++))
        ERRORS+=("$category|$path|NOT FOUND")
        echo -e "  ${RED}[MISSING] $path${NC}"
        return 1
    fi
}

# Validate Skills
echo -e "${CYAN}Validating skills...${NC}"
while IFS= read -r line; do
    if [[ $line == SKILL:* ]]; then
        validate_path "${line#SKILL:}" "Skill"
    elif [[ $line == REF:* ]]; then
        validate_path "${line#REF:}" "Skill Reference"
    fi
done < <(python3 << 'PYEOF'
import json
data = json.load(open('/workspace/docs/repo-keeper/INVENTORY.json'))
for skill in data.get('skills', []):
    print(f"SKILL:{skill['path']}")
    for ref in skill.get('references', []):
        print(f"REF:{ref}")
PYEOF
)

# Validate Commands
echo -e "${CYAN}Validating commands...${NC}"
while IFS= read -r path; do
    [ -n "$path" ] && validate_path "$path" "Command"
done < <(python3 << 'PYEOF'
import json
data = json.load(open('/workspace/docs/repo-keeper/INVENTORY.json'))
for command in data.get('commands', []):
    print(command['path'])
PYEOF
)

# Validate Templates
echo -e "${CYAN}Validating templates...${NC}"

# Master templates
while IFS= read -r path; do
    [ -n "$path" ] && validate_path "$path" "Master Template"
done < <(python3 << 'PYEOF'
import json
data = json.load(open('/workspace/docs/repo-keeper/INVENTORY.json'))
for template in data.get('templates', {}).get('master', []):
    print(template['path'])
PYEOF
)

# Other template categories
for category in dockerfiles compose firewall extensions mcp variables env; do
    while IFS= read -r path; do
        [ -n "$path" ] && validate_path "$path" "Template ($category)"
    done < <(python3 << PYEOF
import json
data = json.load(open('/workspace/docs/repo-keeper/INVENTORY.json'))
for template in data.get('templates', {}).get('$category', []):
    print(template['path'])
PYEOF
    )
done

# Validate Examples
echo -e "${CYAN}Validating examples...${NC}"
while IFS= read -r line; do
    if [[ $line == EXAMPLE:* ]]; then
        validate_path "${line#EXAMPLE:}" "Example"
    elif [[ $line == DEVCONTAINER:* ]]; then
        validate_path "${line#DEVCONTAINER:}" "DevContainer"
    elif [[ $line == DOCKERFILE:* ]]; then
        validate_path "${line#DOCKERFILE:}" "Dockerfile"
    elif [[ $line == COMPOSE:* ]]; then
        validate_path "${line#COMPOSE:}" "Compose"
    fi
done < <(python3 << 'PYEOF'
import json
data = json.load(open('/workspace/docs/repo-keeper/INVENTORY.json'))
for example in data.get('examples', []):
    print(f"EXAMPLE:{example['path']}")
    if 'devcontainer_path' in example and example['devcontainer_path']:
        print(f"DEVCONTAINER:{example['devcontainer_path']}")
    if 'dockerfile_path' in example and example['dockerfile_path']:
        print(f"DOCKERFILE:{example['dockerfile_path']}")
    if 'compose_path' in example and example['compose_path']:
        print(f"COMPOSE:{example['compose_path']}")
PYEOF
)

# Validate Data Files
echo -e "${CYAN}Validating data files...${NC}"
while IFS= read -r path; do
    [ -n "$path" ] && validate_path "$path" "Data File"
done < <(python3 << 'PYEOF'
import json
data = json.load(open('/workspace/docs/repo-keeper/INVENTORY.json'))
for datafile in data.get('data_files', []):
    print(datafile['path'])
PYEOF
)

# Validate Documentation
echo -e "${CYAN}Validating documentation...${NC}"
for category in root docs commands skills templates examples data tests repo-keeper; do
    while IFS= read -r path; do
        [ -n "$path" ] && validate_path "$path" "Documentation ($category)"
    done < <(python3 << PYEOF
import json
data = json.load(open('/workspace/docs/repo-keeper/INVENTORY.json'))
for doc in data.get('documentation', {}).get('$category', []):
    print(doc['path'])
PYEOF
    )
done

# Validate DevContainers
echo -e "${CYAN}Validating devcontainers...${NC}"
while IFS= read -r line; do
    if [[ $line == DEVCONTAINER:* ]]; then
        validate_path "${line#DEVCONTAINER:}" "DevContainer"
    elif [[ $line == DOCKERFILE:* ]]; then
        validate_path "${line#DOCKERFILE:}" "DevContainer Dockerfile"
    elif [[ $line == FIREWALL:* ]]; then
        validate_path "${line#FIREWALL:}" "Firewall Script"
    fi
done < <(python3 << 'PYEOF'
import json
data = json.load(open('/workspace/docs/repo-keeper/INVENTORY.json'))
for devcontainer in data.get('devcontainers', []):
    print(f"DEVCONTAINER:{devcontainer['path']}")
    if 'dockerfile_path' in devcontainer and devcontainer['dockerfile_path']:
        print(f"DOCKERFILE:{devcontainer['dockerfile_path']}")
    if 'firewall_path' in devcontainer and devcontainer['firewall_path']:
        print(f"FIREWALL:{devcontainer['firewall_path']}")
PYEOF
)

# Validate Dependencies
echo -e "${CYAN}Validating dependencies...${NC}"
while IFS= read -r path; do
    [ -n "$path" ] && validate_path "$path" "Python Requirements"
done < <(python3 << 'PYEOF'
import json
data = json.load(open('/workspace/docs/repo-keeper/INVENTORY.json'))
for req in data.get('dependencies', {}).get('python_requirements', []):
    print(req)
PYEOF
)

while IFS= read -r path; do
    [ -n "$path" ] && validate_path "$path" "Node Package"
done < <(python3 << 'PYEOF'
import json
data = json.load(open('/workspace/docs/repo-keeper/INVENTORY.json'))
for pkg in data.get('dependencies', {}).get('node_packages', []):
    print(pkg)
PYEOF
)

# Validate Test Files
echo -e "${CYAN}Validating test files...${NC}"
while IFS= read -r path; do
    [ -n "$path" ] && validate_path "$path" "Manual Test"
done < <(python3 << 'PYEOF'
import json
data = json.load(open('/workspace/docs/repo-keeper/INVENTORY.json'))
for test in data.get('test_files', {}).get('manual_tests', []):
    print(test)
PYEOF
)

# Find orphaned files (if requested)
if [ "$FIND_ORPHANS" = true ]; then
    echo ""
    echo -e "${CYAN}Searching for orphaned files...${NC}"
    echo -e "${YELLOW}(Not implemented in bash version yet)${NC}"
fi

# Summary
echo ""
echo -e "${CYAN}=== Summary ===${NC}"
echo "Total paths in inventory: $TOTAL_PATHS"
echo -e "${GREEN}Valid paths:              $VALID_PATHS${NC}"
if [ $MISSING_PATHS -eq 0 ]; then
    echo -e "${GREEN}Missing paths:            $MISSING_PATHS${NC}"
else
    echo -e "${RED}Missing paths:            $MISSING_PATHS${NC}"
fi

# Detailed error report
if [ ${#ERRORS[@]} -gt 0 ]; then
    echo ""
    echo -e "${CYAN}=== Missing Paths Details ===${NC}"
    echo ""

    # Write errors to temp file and process with Python
    TMP_FILE=$(mktemp)
    printf '%s\n' "${ERRORS[@]}" > "$TMP_FILE"

    python3 << PYEOF
from collections import defaultdict

errors = defaultdict(list)
with open('$TMP_FILE', 'r') as f:
    for line in f:
        line = line.strip()
        if '|' in line:
            parts = line.split('|')
            category = parts[0]
            path = parts[1]
            errors[category].append(path)

for category in sorted(errors.keys()):
    paths = errors[category]
    print(f"\033[1;33m{category} ({len(paths)} missing):\033[0m")
    for path in paths:
        print(f"  {path}")
    print()
PYEOF

    rm -f "$TMP_FILE"
fi

# Check version consistency
echo ""
echo -e "${CYAN}=== Version Checks ===${NC}"

KNOWN_ISSUES=$(python3 << 'PYEOF'
import json
data = json.load(open('/workspace/docs/repo-keeper/INVENTORY.json'))
issues = data.get('known_issues', {}).get('outdated_versions', [])
for issue in issues:
    print(issue)
PYEOF
)

if [ -n "$KNOWN_ISSUES" ]; then
    echo -e "${YELLOW}Known version issues:${NC}"
    echo "$KNOWN_ISSUES" | while read -r issue; do
        [ -n "$issue" ] && echo -e "  ${YELLOW}$issue${NC}"
    done
    HAS_ISSUES=true
else
    HAS_ISSUES=false
fi

echo ""

# Exit with appropriate code for CI/CD
EXIT_CODE=0

if [ $MISSING_PATHS -gt 0 ]; then
    echo -e "${RED}✗ Inventory validation failed! ($MISSING_PATHS missing paths)${NC}"
    EXIT_CODE=1
elif [ "$HAS_ISSUES" = true ]; then
    echo -e "${YELLOW}⚠ Inventory valid but version issues found${NC}"
    echo -e "${YELLOW}  Run version sync check to fix these issues${NC}"
    EXIT_CODE=0  # Don't fail on version issues, just warn
else
    echo -e "${GREEN}✓ Inventory is valid and all paths exist!${NC}"
    EXIT_CODE=0
fi

if [ "$FIND_ORPHANS" = true ]; then
    echo ""
    echo -e "${CYAN}ℹ Orphan detection not yet implemented in bash version${NC}"
    echo -e "${CYAN}  Use PowerShell version for this feature${NC}"
fi

exit $EXIT_CODE
