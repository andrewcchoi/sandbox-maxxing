#!/usr/bin/env bash
# diagram-inventory-enhanced.sh - Enhanced diagram validation with content checks
# Part of documentation health check automation

set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIAGRAMS_DIR="$PLUGIN_ROOT/docs/diagrams"
SVG_DIR="$DIAGRAMS_DIR/svg"

cd "$DIAGRAMS_DIR"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║         Enhanced Diagram Inventory & Content Check          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

ERRORS=0
WARNINGS=0
MMD_COUNT=0
SVG_COUNT=0

# Check that SVG directory exists
if [[ ! -d "$SVG_DIR" ]]; then
  echo "❌ ERROR: SVG directory not found: $SVG_DIR"
  exit 1
fi

# Count Mermaid source files
MMD_COUNT=$(find . -maxdepth 1 -name "*.mmd" -type f | wc -l)
echo "📊 Diagram Files:"
echo "  Mermaid source files (.mmd): $MMD_COUNT"

# Count SVG output files
SVG_COUNT=$(find "$SVG_DIR" -name "*.svg" -type f | wc -l)
echo "  SVG output files (.svg):     $SVG_COUNT"
echo ""

# ============================================================================
# PHASE 1: File Existence & Pairing
# ============================================================================
echo "🔍 PHASE 1: File Existence & Pairing"
echo "────────────────────────────────────────"

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
      # Check file sizes
      mmd_size=$(stat -f%z "$DIAGRAMS_DIR/$mmd" 2>/dev/null || stat -c%s "$DIAGRAMS_DIR/$mmd" 2>/dev/null || echo "0")
      svg_size=$(stat -f%z "$svg" 2>/dev/null || stat -c%s "$svg" 2>/dev/null || echo "0")

      if [[ $mmd_size -lt 50 ]]; then
        echo "⚠️  $basename.mmd → $basename.svg (mmd suspiciously small: ${mmd_size}B)"
        ((WARNINGS++))
      elif [[ $svg_size -lt 500 ]]; then
        echo "⚠️  $basename.mmd → $basename.svg (svg suspiciously small: ${svg_size}B)"
        ((WARNINGS++))
      else
        echo "✅ $basename.mmd → $basename.svg"
      fi
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
    ((WARNINGS++))
  fi
done < <(find "$SVG_DIR" -name "*.svg" -type f)

echo ""

# ============================================================================
# PHASE 2: Content Validation
# ============================================================================
echo "🔍 PHASE 2: Content Validation"
echo "────────────────────────────────────────"

# Check Mermaid syntax validity
echo "Validating Mermaid syntax..."
SYNTAX_ERRORS=0
while IFS= read -r mmd; do
  basename="${mmd%.mmd}"

  # Basic syntax checks
  if ! grep -q "graph\|flowchart\|sequenceDiagram\|classDiagram" "$mmd" 2>/dev/null; then
    echo "⚠️  $basename.mmd: No valid Mermaid diagram type found"
    ((SYNTAX_ERRORS++))
    ((WARNINGS++))
  fi

  # Check for common syntax errors
  if grep -q "^\s*graph\s*$" "$mmd" 2>/dev/null; then
    echo "⚠️  $basename.mmd: Incomplete 'graph' declaration (missing direction)"
    ((SYNTAX_ERRORS++))
    ((WARNINGS++))
  fi
done < <(find . -maxdepth 1 -name "*.mmd" -type f)

if [[ $SYNTAX_ERRORS -eq 0 ]]; then
  echo "✅ All .mmd files have valid Mermaid syntax declarations"
else
  echo "⚠️  Found $SYNTAX_ERRORS potential syntax issue(s)"
fi
echo ""

# Validate SVG files are valid XML
echo "Validating SVG file integrity..."
SVG_ERRORS=0
if command -v xmllint &> /dev/null; then
  while IFS= read -r svg; do
    basename="$(basename "$svg" .svg)"

    if ! xmllint --noout "$svg" 2>/dev/null; then
      echo "❌ $basename.svg: Invalid XML structure"
      ((SVG_ERRORS++))
      ((ERRORS++))
    fi
  done < <(find "$SVG_DIR" -name "*.svg" -type f)

  if [[ $SVG_ERRORS -eq 0 ]]; then
    echo "✅ All SVG files have valid XML structure"
  else
    echo "❌ Found $SVG_ERRORS invalid SVG file(s)"
  fi
else
  echo "ℹ️  xmllint not installed - skipping SVG validation"
  echo "   Install: apt-get install libxml2-utils (Ubuntu) or brew install libxml2 (macOS)"
fi
echo ""

# ============================================================================
# PHASE 3: Component Count Validation
# ============================================================================
echo "🔍 PHASE 3: Component Count Validation"
echo "────────────────────────────────────────"

# Count actual commands
ACTUAL_COMMANDS=$(find "$PLUGIN_ROOT/commands" -name "*.md" -type f 2>/dev/null | wc -l)
echo "Actual commands in /commands/: $ACTUAL_COMMANDS"

# Check plugin-architecture.mmd for documented command count
if [[ -f "plugin-architecture.mmd" ]]; then
  # This is a basic check - enhance based on actual diagram structure
  echo "✅ plugin-architecture.mmd exists"
  echo "   (Manual review recommended to verify component counts)"
else
  echo "⚠️  plugin-architecture.mmd not found"
  ((WARNINGS++))
fi

# Count actual skills
ACTUAL_SKILLS=$(find "$PLUGIN_ROOT/skills" -maxdepth 1 -type d ! -name skills ! -name _shared 2>/dev/null | wc -l)
echo "Actual skills in /skills/: $ACTUAL_SKILLS"

# Count actual agents
ACTUAL_AGENTS=$(find "$PLUGIN_ROOT/agents" -name "*.md" -type f 2>/dev/null | wc -l)
echo "Actual agents in /agents/: $ACTUAL_AGENTS"

echo ""

# ============================================================================
# PHASE 4: Documentation Reference Validation
# ============================================================================
echo "🔍 PHASE 4: Documentation Reference Validation"
echo "────────────────────────────────────────"

echo "Checking diagram references in documentation..."
REF_ERRORS=0

# Check if diagrams referenced in docs/diagrams/README.md exist
if [[ -f "$DIAGRAMS_DIR/README.md" ]]; then
  # Extract .mmd file references
  while IFS= read -r diagram_file; do
    [[ -z "$diagram_file" ]] && continue

    if [[ ! -f "$DIAGRAMS_DIR/$diagram_file" ]]; then
      echo "❌ Referenced but missing: $diagram_file"
      ((REF_ERRORS++))
      ((ERRORS++))
    fi
  done < <(grep -oP '\[`\K[^`]+\.mmd' "$DIAGRAMS_DIR/README.md" 2>/dev/null || true)

  if [[ $REF_ERRORS -eq 0 ]]; then
    echo "✅ All referenced diagrams in README.md exist"
  else
    echo "❌ Found $REF_ERRORS missing referenced diagram(s)"
  fi
else
  echo "⚠️  docs/diagrams/README.md not found"
  ((WARNINGS++))
fi

echo ""

# ============================================================================
# SUMMARY
# ============================================================================
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                         SUMMARY                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Diagram Files:"
echo "  Mermaid sources: $MMD_COUNT"
echo "  SVG outputs:     $SVG_COUNT"
echo "  Missing SVGs:    $ERRORS"
echo "  Orphaned SVGs:   $ORPHANED"
echo ""
echo "Component Inventory:"
echo "  Commands:        $ACTUAL_COMMANDS"
echo "  Skills:          $ACTUAL_SKILLS"
echo "  Agents:          $ACTUAL_AGENTS"
echo ""
echo "Validation Results:"
echo "  Errors:          $ERRORS ❌"
echo "  Warnings:        $WARNINGS ⚠️"
echo ""

if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
  echo "🎉 EXCELLENT: All diagrams validated successfully!"
  exit 0
elif [[ $ERRORS -eq 0 ]]; then
  echo "⚠️  GOOD: No critical errors, but $WARNINGS warning(s) present"
  echo "   Review warnings and consider addressing them"
  exit 0
else
  echo "❌ FAILED: $ERRORS critical error(s) found"
  echo "   Fix errors before proceeding"
  exit 1
fi
