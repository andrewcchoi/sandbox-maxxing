#!/usr/bin/env bash
# diagram-inventory.sh - Validates diagram source files and SVG outputs
# Part of documentation health check automation

set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIAGRAMS_DIR="$PLUGIN_ROOT/docs/diagrams"
SVG_DIR="$DIAGRAMS_DIR/svg"

cd "$DIAGRAMS_DIR"

echo "=== Diagram Inventory Check ==="
echo ""

ERRORS=0
MMD_COUNT=0
SVG_COUNT=0

# Check that SVG directory exists
if [[ ! -d "$SVG_DIR" ]]; then
  echo "❌ ERROR: SVG directory not found: $SVG_DIR"
  exit 1
fi

# Count Mermaid source files
MMD_COUNT=$(find . -maxdepth 1 -name "*.mmd" -type f | wc -l)
echo "Mermaid source files (.mmd): $MMD_COUNT"

# Count SVG output files
SVG_COUNT=$(find "$SVG_DIR" -name "*.svg" -type f | wc -l)
echo "SVG output files (.svg):     $SVG_COUNT"
echo ""

# Check each .mmd file has corresponding .svg
if [[ $MMD_COUNT -gt 0 ]]; then
  echo "Checking .mmd → .svg pairs..."
  while IFS= read -r mmd; do
    basename="${mmd%.mmd}"
    svg="$SVG_DIR/${basename}.svg"

    if [[ ! -f "$svg" ]]; then
      echo "❌ MISSING: $basename.svg (source: $mmd)"
      ((ERRORS++))
    else
      echo "✅ $basename.mmd → $basename.svg"
    fi
  done < <(find . -maxdepth 1 -name "*.mmd" -type f -exec basename {} \;)
  echo ""
fi

# Check for orphaned SVGs (no corresponding .mmd source)
echo "Checking for orphaned SVGs..."
ORPHANED=0
while IFS= read -r svg; do
  basename="$(basename "$svg" .svg)"
  mmd="$DIAGRAMS_DIR/${basename}.mmd"

  if [[ ! -f "$mmd" ]]; then
    echo "⚠️  WARNING: ${basename}.svg has no source .mmd file"
    echo "   This SVG cannot be regenerated if lost!"
    ((ORPHANED++))
  fi
done < <(find "$SVG_DIR" -name "*.svg" -type f)

echo ""
echo "Summary:"
echo "  Mermaid sources: $MMD_COUNT"
echo "  SVG outputs:     $SVG_COUNT"
echo "  Missing SVGs:    $ERRORS"
echo "  Orphaned SVGs:   $ORPHANED"
echo ""

if [[ $ERRORS -eq 0 && $ORPHANED -eq 0 ]]; then
  echo "✅ All diagrams have source files and outputs"
  exit 0
elif [[ $ERRORS -eq 0 ]]; then
  echo "⚠️  Warnings present: $ORPHANED orphaned SVG(s)"
  echo "   Consider recreating .mmd source files for these diagrams"
  exit 0
else
  echo "❌ Missing $ERRORS SVG output file(s)"
  echo "   Run: npx -y @mermaid-js/mermaid-cli -i <file>.mmd -o svg/<file>.svg"
  exit 1
fi
