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

# Extract all internal links from markdown files
find . -name "*.md" -type f ! -path "./.git/*" ! -path "./node_modules/*" -exec \
  grep -oP '\]\(\K[^)]+(?=\))' {} + 2>/dev/null | \
  grep -v '^https\?://' | \
  grep -v '^mailto:' | \
  grep -v '^#' | \
  sort -u > "$TEMP_LINKS" || true

if [[ ! -s "$TEMP_LINKS" ]]; then
  echo "No internal links found to check"
  rm -f "$TEMP_LINKS"
  exit 0
fi

# Check each unique link
while IFS= read -r link; do
  [[ -z "$link" ]] && continue
  ((CHECKED++))

  # Remove anchor part (file.md#section → file.md)
  target_file="${link%%#*}"

  # Check if file exists (trying both from root and as-is)
  if [[ ! -f "$target_file" && ! -d "$target_file" && ! -f "$PLUGIN_ROOT/$target_file" ]]; then
    echo "❌ BROKEN: $link"
    ((BROKEN++))
  fi
done < "$TEMP_LINKS"

rm -f "$TEMP_LINKS"

echo ""
echo "Checked: $CHECKED unique internal links"
echo ""

if [[ $BROKEN -eq 0 ]]; then
  echo "✅ All internal links are valid"
  exit 0
else
  echo "❌ Found $BROKEN broken link(s)"
  echo ""
  echo "Note: Some links may be valid but use relative paths from different locations."
  echo "Manual verification recommended for reported broken links."
  exit 1
fi
