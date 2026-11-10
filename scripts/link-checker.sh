#!/usr/bin/env bash
# link-checker.sh - Validates internal markdown links
# Part of documentation health check automation

set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PLUGIN_ROOT"

echo "=== Internal Link Validation ==="
echo ""

BROKEN=0
CHECKED=0
TEMP_LINKS="/tmp/claude/sandboxxer-links-$$"
TEMP_BROKEN="/tmp/claude/sandboxxer-broken-$$"

# Extract all links from markdown files with source file context
# Format: ./path/to/file.md:link-target
find . -name "*.md" -type f ! -path "./.git/*" ! -path "./node_modules/*" -exec \
  grep -H -oP '\]\(\K[^)]+(?=\))' {} + 2>/dev/null > "$TEMP_LINKS" || true

if [[ ! -s "$TEMP_LINKS" ]]; then
  echo "No links found to check"
  rm -f "$TEMP_LINKS"
  exit 0
fi

> "$TEMP_BROKEN"  # Clear broken links file

# Process each link with its source file context
while IFS=: read -r source_file link; do
  [[ -z "$link" ]] && continue

  # Skip external URLs
  [[ "$link" =~ ^https?:// ]] && continue
  [[ "$link" =~ ^mailto: ]] && continue

  # Skip pure anchors (links starting with #)
  [[ "$link" =~ ^# ]] && continue

  # Remove anchor part (file.md#section → file.md)
  target_file="${link%%#*}"

  # Skip if just an anchor was removed (link was purely #anchor)
  [[ -z "$target_file" ]] && continue

  CHECKED=$((CHECKED + 1))

  # Get directory of source file for relative path resolution
  source_dir="$(dirname "$source_file")"

  # Resolve the target path relative to source file's directory
  if [[ "$target_file" == /* ]]; then
    # Absolute path from plugin root
    resolved_path=".$target_file"
  else
    # Relative path - resolve from source file's directory
    resolved_path="$source_dir/$target_file"
  fi

  # Check if file or directory exists
  if [[ ! -f "$resolved_path" && ! -d "$resolved_path" ]]; then
    echo "❌ BROKEN: $link" >> "$TEMP_BROKEN"
    echo "   Source: $source_file" >> "$TEMP_BROKEN"
    echo "   Resolved: $resolved_path" >> "$TEMP_BROKEN"
    echo "" >> "$TEMP_BROKEN"
    BROKEN=$((BROKEN + 1))
  fi
done < "$TEMP_LINKS"

rm -f "$TEMP_LINKS"

echo "Checked: $CHECKED internal links"
echo ""

if [[ $BROKEN -eq 0 ]]; then
  rm -f "$TEMP_BROKEN"
  echo "✅ All internal links are valid"
  exit 0
else
  echo "❌ Found $BROKEN broken link(s):"
  echo ""
  cat "$TEMP_BROKEN"
  rm -f "$TEMP_BROKEN"
  exit 1
fi
