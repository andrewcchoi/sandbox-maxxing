#!/usr/bin/env bash
# regenerate-diagrams.sh - Regenerates SVG diagrams from Mermaid source files
# Requires: npx (Node.js package runner) and internet connection for mermaid-cli

set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIAGRAMS_DIR="$PLUGIN_ROOT/docs/diagrams"
SVG_DIR="$DIAGRAMS_DIR/svg"

cd "$DIAGRAMS_DIR"

echo "═══════════════════════════════════════════════════════════════"
echo "              Diagram Regeneration Utility"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Check if npx is available
if ! command -v npx &> /dev/null; then
  echo "❌ ERROR: npx not found"
  echo ""
  echo "This script requires Node.js to run mermaid-cli."
  echo ""
  echo "Install Node.js:"
  echo "  - Ubuntu/Debian: curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && sudo apt-get install -y nodejs"
  echo "  - macOS: brew install node"
  echo "  - Windows: Download from https://nodejs.org/"
  echo ""
  exit 1
fi

# Check if SVG directory exists
if [[ ! -d "$SVG_DIR" ]]; then
  echo "Creating SVG output directory: $SVG_DIR"
  mkdir -p "$SVG_DIR"
fi

# Count Mermaid files
MMD_COUNT=$(find . -maxdepth 1 -name "*.mmd" -type f | wc -l)

if [[ $MMD_COUNT -eq 0 ]]; then
  echo "⚠️  No Mermaid source files (.mmd) found in $DIAGRAMS_DIR"
  echo "Nothing to regenerate."
  exit 0
fi

echo "Found $MMD_COUNT Mermaid diagram(s) to regenerate"
echo ""

REGENERATED=0
FAILED=0

# Process each .mmd file
while IFS= read -r mmd_file; do
  basename="$(basename "$mmd_file" .mmd)"
  svg_file="$SVG_DIR/${basename}.svg"

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Processing: $basename.mmd → svg/$basename.svg"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Run mermaid-cli with error handling
  if npx -y @mermaid-js/mermaid-cli@latest -i "$mmd_file" -o "$svg_file" -b transparent 2>&1; then
    if [[ -f "$svg_file" ]]; then
      SIZE=$(du -h "$svg_file" | cut -f1)
      echo "✅ Success: $svg_file ($SIZE)"
      ((REGENERATED++))
    else
      echo "❌ Failed: SVG file not created"
      ((FAILED++))
    fi
  else
    echo "❌ Failed: Mermaid compilation error"
    ((FAILED++))
  fi

  echo ""
done < <(find . -maxdepth 1 -name "*.mmd" -type f)

# Summary
echo "═══════════════════════════════════════════════════════════════"
echo "                     REGENERATION SUMMARY"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Total diagrams:    $MMD_COUNT"
echo "Regenerated:       $REGENERATED ✅"
echo "Failed:            $FAILED ❌"
echo ""

if [[ $FAILED -eq 0 ]]; then
  echo "🎉 SUCCESS: All diagrams regenerated successfully!"
  echo ""
  echo "Next steps:"
  echo "  1. Review the generated SVGs in docs/diagrams/svg/"
  echo "  2. Commit both .mmd and .svg files together"
  echo "  3. Run: git add docs/diagrams/*.mmd docs/diagrams/svg/*.svg"
  exit 0
else
  echo "⚠️  WARNING: Some diagrams failed to regenerate"
  echo ""
  echo "Common issues:"
  echo "  - Syntax errors in .mmd file (check Mermaid syntax)"
  echo "  - Network issues (mermaid-cli downloads dependencies)"
  echo "  - Permissions (check write access to svg/ directory)"
  echo ""
  echo "Manual fix:"
  echo "  1. Open the .mmd file in https://mermaid.live"
  echo "  2. Fix any syntax errors"
  echo "  3. Export as SVG and save to docs/diagrams/svg/"
  exit 1
fi
