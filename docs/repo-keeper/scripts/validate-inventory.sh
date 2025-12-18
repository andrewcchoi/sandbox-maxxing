#!/bin/bash
# validate-inventory.sh
# Validates INVENTORY.json against actual repository filesystem

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
FIND_ORPHANS=false
QUIET=false
LOG_FILE=""

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -v|--verbose) VERBOSE=true ;;
        --find-orphans) FIND_ORPHANS=true ;;
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
    echo -e "${CYAN}=== Repository Inventory Validator ===${NC}"
    echo ""
fi

INVENTORY="$REPO_ROOT/docs/repo-keeper/INVENTORY.json"
if [ ! -f "$INVENTORY" ]; then
    echo -e "${RED}Error: INVENTORY.json not found${NC}"
    exit 1
fi

# Get inventory metadata
VERSION=$(node -e "const d=JSON.parse(require('fs').readFileSync('$INVENTORY')); console.log(d.version || 'unknown')")
LAST_UPDATED=$(node -e "const d=JSON.parse(require('fs').readFileSync('$INVENTORY')); console.log(d.last_updated || 'unknown')")

if [ "$QUIET" = false ]; then
    echo -e "${GREEN}Inventory version: $VERSION${NC}"
    echo -e "${GREEN}Last updated: $LAST_UPDATED${NC}"
fi

# Check timestamp not in future
CURRENT_DATE=$(date +%Y-%m-%d)
if [[ "$LAST_UPDATED" > "$CURRENT_DATE" ]]; then
    echo -e "${YELLOW}[WARNING] last_updated is in the future: $LAST_UPDATED (current: $CURRENT_DATE)${NC}"
fi

if [ "$QUIET" = false ]; then
    echo ""
fi

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
        echo -e "    ${YELLOW}How to fix: Create the file at $path or remove it from INVENTORY.json${NC}"
        return 1
    fi
}

# Validate Skills
if [ "$QUIET" = false ]; then
    echo -e "${CYAN}Validating skills...${NC}"
fi
while IFS= read -r line; do
    if [[ $line == SKILL:* ]]; then
        validate_path "${line#SKILL:}" "Skill"
    elif [[ $line == REF:* ]]; then
        validate_path "${line#REF:}" "Skill Reference"
    fi
done < <(node -e "
const data = JSON.parse(require('fs').readFileSync('$INVENTORY'));
(data.skills || []).forEach(skill => {
    console.log(\`SKILL:\${skill.path}\`);
    (skill.references || []).forEach(ref => {
        console.log(\`REF:\${ref}\`);
    });
});
")

# Validate Commands
if [ "$QUIET" = false ]; then
    echo -e "${CYAN}Validating commands...${NC}"
fi
while IFS= read -r path; do
    [ -n "$path" ] && validate_path "$path" "Command"
done < <(node -e "
const data = JSON.parse(require('fs').readFileSync('$INVENTORY'));
(data.commands || []).forEach(command => {
    console.log(command.path);
});
")

# Validate Templates
if [ "$QUIET" = false ]; then
    echo -e "${CYAN}Validating templates...${NC}"
fi

# Master templates
while IFS= read -r path; do
    [ -n "$path" ] && validate_path "$path" "Master Template"
done < <(node -e "
const data = JSON.parse(require('fs').readFileSync('$INVENTORY'));
((data.templates || {}).master || []).forEach(template => {
    console.log(template.path);
});
")

# Other template categories
for category in dockerfiles compose firewall extensions mcp variables env; do
    while IFS= read -r path; do
        [ -n "$path" ] && validate_path "$path" "Template ($category)"
    done < <(node -e "
const data = JSON.parse(require('fs').readFileSync('$INVENTORY'));
((data.templates || {})['$category'] || []).forEach(template => {
    console.log(template.path);
});
")
done

# Validate Examples
if [ "$QUIET" = false ]; then
    echo -e "${CYAN}Validating examples...${NC}"
fi
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
done < <(node -e "
const data = JSON.parse(require('fs').readFileSync('$INVENTORY'));
(data.examples || []).forEach(example => {
    console.log(\`EXAMPLE:\${example.path}\`);
    if (example.devcontainer_path) {
        console.log(\`DEVCONTAINER:\${example.devcontainer_path}\`);
    }
    if (example.dockerfile_path) {
        console.log(\`DOCKERFILE:\${example.dockerfile_path}\`);
    }
    if (example.compose_path) {
        console.log(\`COMPOSE:\${example.compose_path}\`);
    }
});
")

# Validate Data Files
if [ "$QUIET" = false ]; then
    echo -e "${CYAN}Validating data files...${NC}"
fi
while IFS= read -r path; do
    [ -n "$path" ] && validate_path "$path" "Data File"
done < <(node -e "
const data = JSON.parse(require('fs').readFileSync('$INVENTORY'));
(data.data_files || []).forEach(datafile => {
    console.log(datafile.path);
});
")

# Validate Documentation
if [ "$QUIET" = false ]; then
    echo -e "${CYAN}Validating documentation...${NC}"
fi
for category in root docs commands skills templates examples data tests repo-keeper; do
    while IFS= read -r path; do
        [ -n "$path" ] && validate_path "$path" "Documentation ($category)"
    done < <(node -e "
const data = JSON.parse(require('fs').readFileSync('$INVENTORY'));
((data.documentation || {})['$category'] || []).forEach(doc => {
    console.log(doc.path);
});
")
done

# Validate DevContainers
if [ "$QUIET" = false ]; then
    echo -e "${CYAN}Validating devcontainers...${NC}"
fi
while IFS= read -r line; do
    if [[ $line == DEVCONTAINER:* ]]; then
        validate_path "${line#DEVCONTAINER:}" "DevContainer"
    elif [[ $line == DOCKERFILE:* ]]; then
        validate_path "${line#DOCKERFILE:}" "DevContainer Dockerfile"
    elif [[ $line == FIREWALL:* ]]; then
        validate_path "${line#FIREWALL:}" "Firewall Script"
    fi
done < <(node -e "
const data = JSON.parse(require('fs').readFileSync('$INVENTORY'));
(data.devcontainers || []).forEach(devcontainer => {
    console.log(\`DEVCONTAINER:\${devcontainer.path}\`);
    if (devcontainer.dockerfile_path) {
        console.log(\`DOCKERFILE:\${devcontainer.dockerfile_path}\`);
    }
    if (devcontainer.firewall_path) {
        console.log(\`FIREWALL:\${devcontainer.firewall_path}\`);
    }
});
")

# Validate Dependencies
if [ "$QUIET" = false ]; then
    echo -e "${CYAN}Validating dependencies...${NC}"
fi
while IFS= read -r path; do
    [ -n "$path" ] && validate_path "$path" "Python Requirements"
done < <(node -e "
const data = JSON.parse(require('fs').readFileSync('$INVENTORY'));
((data.dependencies || {}).python_requirements || []).forEach(req => {
    console.log(req);
});
")

while IFS= read -r path; do
    [ -n "$path" ] && validate_path "$path" "Node Package"
done < <(node -e "
const data = JSON.parse(require('fs').readFileSync('$INVENTORY'));
((data.dependencies || {}).node_packages || []).forEach(pkg => {
    console.log(pkg);
});
")

# Validate Test Files
if [ "$QUIET" = false ]; then
    echo -e "${CYAN}Validating test files...${NC}"
fi
while IFS= read -r path; do
    [ -n "$path" ] && validate_path "$path" "Manual Test"
done < <(node -e "
const data = JSON.parse(require('fs').readFileSync('$INVENTORY'));
((data.test_files || {}).manual_tests || []).forEach(test => {
    console.log(test);
});
")

# Find orphaned files (if requested)
ORPHAN_COUNT=0
if [ "$FIND_ORPHANS" = true ]; then
    if [ "$QUIET" = false ]; then
        echo ""
        echo -e "${CYAN}Searching for orphaned files...${NC}"
    fi

    # Build list of all paths in INVENTORY.json using Node.js
    INVENTORY_PATHS=$(node -e "
        const inv = JSON.parse(require('fs').readFileSync('$INVENTORY_FILE'));
        const paths = [];

        // Collect all paths from inventory
        inv.skills?.forEach(s => {
            paths.push(s.path);
            (s.references || []).forEach(r => paths.push(r));
        });
        inv.commands?.forEach(c => paths.push(c.path));
        Object.values(inv.templates || {}).flat().forEach(t => paths.push(t.path));
        inv.examples?.forEach(e => {
            paths.push(e.path);
            e.devcontainer_path && paths.push(e.devcontainer_path);
            e.dockerfile_path && paths.push(e.dockerfile_path);
            e.compose_path && paths.push(e.compose_path);
        });
        inv.data_files?.forEach(d => paths.push(d.path));
        Object.values(inv.documentation || {}).flat().forEach(d => paths.push(d.path));
        inv.devcontainers?.forEach(d => {
            paths.push(d.path);
            d.dockerfile_path && paths.push(d.dockerfile_path);
            d.firewall_path && paths.push(d.firewall_path);
        });

        console.log(JSON.stringify(paths));
    ")

    # Directories to scan for orphans
    DIRS_TO_SCAN=(".claude-plugin" "commands" "skills" "templates" "examples" "data" "docs")

    for dir in "${DIRS_TO_SCAN[@]}"; do
        if [[ -d "$REPO_ROOT/$dir" ]]; then
            while IFS= read -r -d '' file; do
                local_file="$file"
                rel_path="${local_file#$REPO_ROOT/}"

                # Check if path is in inventory
                if ! echo "$INVENTORY_PATHS" | grep -qF "\"$rel_path\""; then
                    echo -e "  ${YELLOW}[ORPHAN]${NC} $rel_path"
                    ((ORPHAN_COUNT++)) || true
                fi
            done < <(find "$REPO_ROOT/$dir" -type f -print0 2>/dev/null)
        fi
    done

    if [ "$QUIET" = false ]; then
        echo ""
        echo -e "Orphaned files found: $ORPHAN_COUNT"
    fi
fi

# Summary
if [ "$QUIET" = false ]; then
    echo ""
    echo -e "${CYAN}=== Summary ===${NC}"
    echo "Total paths in inventory: $TOTAL_PATHS"
    echo -e "${GREEN}Valid paths:              $VALID_PATHS${NC}"
    if [ $MISSING_PATHS -eq 0 ]; then
        echo -e "${GREEN}Missing paths:            $MISSING_PATHS${NC}"
    else
        echo -e "${RED}Missing paths:            $MISSING_PATHS${NC}"
    fi
fi

# Detailed error report
if [ ${#ERRORS[@]} -gt 0 ]; then
    echo ""
    echo -e "${CYAN}=== Missing Paths Details ===${NC}"
    echo ""

    # Write errors to temp file and process with Node.js
    TMP_FILE=$(mktemp)
    printf '%s\n' "${ERRORS[@]}" > "$TMP_FILE"

    node << NODEOF
const fs = require('fs');
const errors = {};

const lines = fs.readFileSync('$TMP_FILE', 'utf8').split('\n');
lines.forEach(line => {
    line = line.trim();
    if (line.includes('|')) {
        const parts = line.split('|');
        const category = parts[0];
        const path = parts[1];
        if (!errors[category]) errors[category] = [];
        errors[category].push(path);
    }
});

Object.keys(errors).sort().forEach(category => {
    const paths = errors[category];
    console.log(\`\x1b[1;33m\${category} (\${paths.length} missing):\x1b[0m\`);
    paths.forEach(path => {
        console.log(\`  \${path}\`);
    });
    console.log();
});
NODEOF

    rm -f "$TMP_FILE"
fi

# Check for duplicate paths
if [ "$QUIET" = false ]; then
    echo ""
    echo -e "${CYAN}=== Duplicate Path Check ===${NC}"
fi

DUPLICATES=$(node -e "
const data = JSON.parse(require('fs').readFileSync('$INVENTORY'));
const paths = [];

// Collect all paths from all sections
(data.skills || []).forEach(s => {
    paths.push({path: s.path, type: 'Skill'});
    (s.references || []).forEach(r => paths.push({path: r, type: 'Skill Reference'}));
});
(data.commands || []).forEach(c => paths.push({path: c.path, type: 'Command'}));
Object.entries(data.templates || {}).forEach(([category, templates]) => {
    (templates || []).forEach(t => paths.push({path: t.path, type: \`Template (\${category})\`}));
});
(data.examples || []).forEach(e => {
    paths.push({path: e.path, type: 'Example'});
    if (e.devcontainer_path) paths.push({path: e.devcontainer_path, type: 'Example DevContainer'});
    if (e.dockerfile_path) paths.push({path: e.dockerfile_path, type: 'Example Dockerfile'});
    if (e.compose_path) paths.push({path: e.compose_path, type: 'Example Compose'});
});
(data.data_files || []).forEach(d => paths.push({path: d.path, type: 'Data File'}));
Object.entries(data.documentation || {}).forEach(([category, docs]) => {
    (docs || []).forEach(d => paths.push({path: d.path, type: \`Documentation (\${category})\`}));
});
(data.devcontainers || []).forEach(d => {
    paths.push({path: d.path, type: 'DevContainer'});
    if (d.dockerfile_path) paths.push({path: d.dockerfile_path, type: 'DevContainer Dockerfile'});
    if (d.firewall_path) paths.push({path: d.firewall_path, type: 'Firewall Script'});
});

// Find duplicates
const pathMap = {};
paths.forEach(({path, type}) => {
    if (!pathMap[path]) pathMap[path] = [];
    pathMap[path].push(type);
});

const duplicates = [];
Object.entries(pathMap).forEach(([path, types]) => {
    if (types.length > 1) {
        duplicates.push(\`\${path}|\${types.join(', ')}\`);
    }
});

if (duplicates.length > 0) {
    console.log(duplicates.join('\n'));
}
")

if [ -n "$DUPLICATES" ]; then
    echo -e "${RED}Found duplicate paths in INVENTORY.json:${NC}"
    echo ""
    while IFS='|' read -r path types; do
        echo -e "  ${RED}[DUPLICATE] $path${NC}"
        echo -e "    ${YELLOW}Used in: $types${NC}"
    done <<< "$DUPLICATES"
    if [ "$QUIET" = false ]; then
        echo ""
    fi
    echo -e "${RED}Each path should appear only once in INVENTORY.json${NC}"
else
    if [ "$QUIET" = false ]; then
        echo -e "${GREEN}✓ No duplicate paths found${NC}"
    fi
fi

# Check version consistency
if [ "$QUIET" = false ]; then
    echo ""
    echo -e "${CYAN}=== Version Checks ===${NC}"
fi

KNOWN_ISSUES=$(node -e "
const data = JSON.parse(require('fs').readFileSync('$INVENTORY'));
const issues = (data.known_issues || {}).outdated_versions || [];
issues.forEach(issue => console.log(issue));
")

if [ -n "$KNOWN_ISSUES" ]; then
    echo -e "${YELLOW}Known version issues:${NC}"
    echo "$KNOWN_ISSUES" | while read -r issue; do
        [ -n "$issue" ] && echo -e "  ${YELLOW}$issue${NC}"
    done
    HAS_ISSUES=true
else
    HAS_ISSUES=false
fi

if [ "$QUIET" = false ]; then
    echo ""
fi

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

if [ "$FIND_ORPHANS" = true ] && [ $ORPHAN_COUNT -gt 0 ]; then
    if [ "$QUIET" = false ]; then
        echo ""
        echo -e "${CYAN}ℹ Found $ORPHAN_COUNT orphaned files not in inventory${NC}"
        echo -e "${CYAN}  Consider adding them to INVENTORY.json${NC}"
    fi
fi

exit $EXIT_CODE
