#!/bin/bash
# check-links.sh
# Validates markdown links across the repository

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
SKIP_EXTERNAL=true
QUIET=false
LOG_FILE=""

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -v|--verbose) VERBOSE=true ;;
        --check-external) SKIP_EXTERNAL=false ;;
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
    echo -e "${CYAN}=== Repository Link Checker ===${NC}"
    echo ""
fi

# Temporary files for tracking
ERROR_FILE=$(mktemp)
LINKS_FILE=$(mktemp)
ANCHOR_ERROR_FILE=$(mktemp)
IMAGE_ERROR_FILE=$(mktemp)
trap "rm -f $ERROR_FILE $LINKS_FILE $ANCHOR_ERROR_FILE $IMAGE_ERROR_FILE" EXIT

# Find all markdown files
mapfile -t MD_FILES < <(find "$REPO_ROOT" -name "*.md" -type f ! -path "*/node_modules/*" ! -path "*/.git/*" 2>/dev/null)

FILE_COUNT=${#MD_FILES[@]}
if [ "$QUIET" = false ]; then
    echo -e "${CYAN}Scanning $FILE_COUNT markdown files...${NC}"
    echo ""
fi

# Process each file
for file in "${MD_FILES[@]}"; do
    RELATIVE_PATH="${file#$REPO_ROOT/}"
    FILE_DIR=$(dirname "$file")

    # Extract all links with line numbers using grep -n
    grep -n '\[[^]]*\]([^)]*)' "$file" 2>/dev/null | while IFS=: read -r line_num line_content; do
        # Extract all markdown links from this line
        while [[ "$line_content" =~ \[([^\]]*)\]\(([^\)]*)\) ]]; do
            link_text="${BASH_REMATCH[1]}"
            link_url="${BASH_REMATCH[2]}"

            # Record this link
            echo "LINK|$RELATIVE_PATH|$line_num|$link_text|$link_url" >> "$LINKS_FILE"

            # Skip anchor links
            if [[ "$link_url" =~ ^# ]]; then
                echo "ANCHOR|$RELATIVE_PATH|$line_num|$link_url" >> "$LINKS_FILE"
                # Remove processed link and continue
                line_content="${line_content#*\]\(}"
                line_content="${line_content#*\)}"
                continue
            fi

            # Check if external link
            if [[ "$link_url" =~ ^https?:// ]]; then
                echo "EXTERNAL|$RELATIVE_PATH|$line_num|$link_url" >> "$LINKS_FILE"
                if [ "$VERBOSE" = true ]; then
                    echo -e "  ${GRAY}[EXTERNAL] $RELATIVE_PATH:$line_num - $link_url${NC}"
                fi
                # Remove processed link and continue
                line_content="${line_content#*\]\(}"
                line_content="${line_content#*\)}"
                continue
            fi

            # Internal link - validate it exists
            # Remove fragment identifier
            LINK_PATH="${link_url%%#*}"

            # Resolve relative path
            if [[ "$LINK_PATH" =~ ^/ ]]; then
                # Absolute path from repo root
                RESOLVED_PATH="$REPO_ROOT${LINK_PATH}"
            else
                # Relative path from current file's directory
                RESOLVED_PATH="$FILE_DIR/$LINK_PATH"
            fi

            # Normalize path using realpath
            if command -v realpath >/dev/null 2>&1; then
                RESOLVED_PATH=$(realpath -m "$RESOLVED_PATH" 2>/dev/null || echo "$RESOLVED_PATH")
            fi

            # Check if target exists
            if [ -e "$RESOLVED_PATH" ]; then
                echo "VALID|$RELATIVE_PATH|$line_num|$link_url" >> "$LINKS_FILE"
                if [ "$VERBOSE" = true ]; then
                    echo -e "  ${GREEN}[OK] $RELATIVE_PATH:$line_num - $link_url${NC}"
                fi
            else
                RESOLVED_REL="${RESOLVED_PATH#$REPO_ROOT/}"

                echo "BROKEN|$RELATIVE_PATH|$line_num|$link_text|$link_url|$RESOLVED_REL" >> "$LINKS_FILE"
                echo "$RELATIVE_PATH|$line_num|$link_text|$link_url|$RESOLVED_REL" >> "$ERROR_FILE"

                echo -e "  ${RED}[BROKEN] $RELATIVE_PATH:$line_num${NC}"
                echo -e "    ${RED}Text: $link_text${NC}"
                echo -e "    ${RED}URL: $link_url${NC}"
                echo -e "    ${RED}Resolved to: $RESOLVED_REL (NOT FOUND)${NC}"
                echo ""
            fi

            # Remove processed link and continue
            line_content="${line_content#*\]\(}"
            line_content="${line_content#*\)}"
        done
    done
done

# V8: Check anchor links
ANCHOR_ERRORS=0
if [ "$QUIET" = false ]; then
    echo ""
    echo -e "${CYAN}Validating anchor links...${NC}"
fi
for file in "${MD_FILES[@]}"; do
    RELATIVE_PATH="${file#$REPO_ROOT/}"
    FILE_DIR=$(dirname "$file")

    # Find links with anchors
    grep -n '\[[^]]*\](#[^)]*)' "$file" 2>/dev/null | while IFS=: read -r line_num line_content; do
        if [[ "$line_content" =~ \[([^\]]*)\]\(([^#]*)(#[^\)]*)\) ]]; then
            link_path="${BASH_REMATCH[2]}"
            anchor="${BASH_REMATCH[3]}"

            # Resolve target file
            if [ -z "$link_path" ]; then
                target_file="$file"
            elif [[ "$link_path" =~ ^/ ]]; then
                target_file="$REPO_ROOT${link_path}"
            else
                target_file="$FILE_DIR/$link_path"
            fi

            # Check if anchor exists in target
            if [ -f "$target_file" ]; then
                anchor_text="${anchor#\#}"
                anchor_slug=$(echo "$anchor_text" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
                if ! grep -qi "$anchor_text" "$target_file" 2>/dev/null; then
                    echo "ANCHOR_ERROR|$RELATIVE_PATH|$line_num|$anchor_slug" >> "$ANCHOR_ERROR_FILE"
                fi
            fi
        fi
    done
done
ANCHOR_ERRORS=$(wc -l < "$ANCHOR_ERROR_FILE" 2>/dev/null || echo 0)

# V9: Check image references
IMAGE_ERRORS=0
if [ "$QUIET" = false ]; then
    echo -e "${CYAN}Validating image references...${NC}"
fi
for file in "${MD_FILES[@]}"; do
    RELATIVE_PATH="${file#$REPO_ROOT/}"
    FILE_DIR=$(dirname "$file")

    # Find image references
    grep -n '!\[[^]]*\]([^)]*)' "$file" 2>/dev/null | while IFS=: read -r line_num line_content; do
        if [[ "$line_content" =~ !\[([^\]]*)\]\(([^\)]*)\) ]]; then
            img_path="${BASH_REMATCH[2]}"

            # Skip URLs
            if [[ "$img_path" =~ ^https?:// ]]; then
                continue
            fi

            # Resolve image path
            if [[ "$img_path" =~ ^/ ]]; then
                resolved_img="$REPO_ROOT${img_path}"
            else
                resolved_img="$FILE_DIR/$img_path"
            fi

            # Check if image exists
            if [ ! -f "$resolved_img" ]; then
                echo "IMAGE_ERROR|$RELATIVE_PATH|$line_num|$img_path" >> "$IMAGE_ERROR_FILE"
            fi
        fi
    done
done
IMAGE_ERRORS=$(wc -l < "$IMAGE_ERROR_FILE" 2>/dev/null || echo 0)

# Count results from temp file
TOTAL_LINKS=$(grep -c '^LINK|' "$LINKS_FILE" 2>/dev/null || echo 0)
EXTERNAL_LINKS=$(grep -c '^EXTERNAL|' "$LINKS_FILE" 2>/dev/null || echo 0)
VALID_LINKS=$(grep -c '^VALID|' "$LINKS_FILE" 2>/dev/null || echo 0)
BROKEN_LINKS=$(grep -c '^BROKEN|' "$LINKS_FILE" 2>/dev/null || echo 0)

# Summary
if [ "$QUIET" = false ]; then
    echo ""
    echo -e "${CYAN}=== Summary ===${NC}"
    echo "Total markdown files:  $FILE_COUNT"
    echo "Total links found:     $TOTAL_LINKS"
    echo -e "${GREEN}Valid internal links:  $VALID_LINKS${NC}"
    echo -e "${GRAY}External links:        $EXTERNAL_LINKS${NC}"
    if [ $BROKEN_LINKS -eq 0 ]; then
        echo -e "${GREEN}Broken links:          $BROKEN_LINKS${NC}"
    else
        echo -e "${RED}Broken links:          $BROKEN_LINKS${NC}"
    fi
    if [ $ANCHOR_ERRORS -eq 0 ]; then
        echo -e "${GREEN}Broken anchors:        $ANCHOR_ERRORS${NC}"
    else
        echo -e "${YELLOW}Broken anchors:        $ANCHOR_ERRORS${NC}"
    fi
    if [ $IMAGE_ERRORS -eq 0 ]; then
        echo -e "${GREEN}Missing images:        $IMAGE_ERRORS${NC}"
    else
        echo -e "${YELLOW}Missing images:        $IMAGE_ERRORS${NC}"
    fi
fi

# Detailed error report
if [ $BROKEN_LINKS -gt 0 ] && [ -s "$ERROR_FILE" ]; then
    echo ""
    echo -e "${RED}=== Broken Links Details ===${NC}"
    echo ""

    # Group errors by file
    sort "$ERROR_FILE" | while IFS='|' read -r file line_num link_text link_url resolved_path; do
        [ -z "$file" ] && continue

        # Track current file for grouping
        if [ "$file" != "$CURRENT_FILE" ]; then
            if [ -n "$CURRENT_FILE" ]; then
                echo ""
            fi

            # Count broken links in this file
            COUNT=$(grep -c "^$file|" "$ERROR_FILE" || echo "0")
            echo -e "${YELLOW}$file ($COUNT broken links):${NC}"
            CURRENT_FILE="$file"
        fi

        echo "  Line $line_num: [$link_text]($link_url)"
        echo -e "    ${RED}-> Resolved to: $resolved_path (NOT FOUND)${NC}"
    done
fi

if [ "$QUIET" = false ]; then
    echo ""
fi

# Exit with appropriate code for CI/CD
if [ $BROKEN_LINKS -eq 0 ]; then
    if [ "$QUIET" = false ]; then
        echo -e "${GREEN}✓ All internal links are valid!${NC}"
    fi
    exit 0
else
    echo -e "${RED}✗ Link check failed!${NC}"
    if [ "$QUIET" = false ]; then
        echo ""
        echo "To fix broken links:"
        echo "  1. Update relative paths to match actual file locations"
        echo "  2. Use relative paths (../path) instead of absolute (/workspace/path)"
        echo "  3. Ensure linked files exist in the repository"
        echo "  4. Run this script again to verify"
    fi
    exit 1
fi
