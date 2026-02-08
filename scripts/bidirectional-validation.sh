#!/usr/bin/env bash
# bidirectional-validation.sh - Validates docs match diagram metadata (reverse validation)
# Part of documentation health check automation

set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIAGRAMS_DIR="$PLUGIN_ROOT/docs/diagrams"

cd "$DIAGRAMS_DIR"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║          Bidirectional Documentation Validation             ║"
echo "║         (Validating Docs Match Diagram Metadata)            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

ERRORS=0
WARNINGS=0
METADATA_FOUND=0

# ============================================================================
# PHASE 1: Extract and Validate Metadata
# ============================================================================
echo "🔍 PHASE 1: Metadata Extraction"
echo "────────────────────────────────────────────"

# Function to extract YAML metadata from HTML comments
extract_metadata() {
  local mmd_file="$1"
  local key="$2"

  # Extract value between <!-- and --> and find the key
  sed -n '/<!--/,/-->/p' "$mmd_file" | \
    grep "^${key}:" | \
    sed "s/^${key}: *//" | \
    head -1
}

# Function to extract numeric component value
extract_component() {
  local mmd_file="$1"
  local component="$2"

  # Extract component value (e.g., "commands: 8")
  sed -n '/<!--/,/-->/p' "$mmd_file" | \
    grep "^\s*${component}:" | \
    sed "s/^\s*${component}: *//" | \
    head -1
}

echo "Extracting metadata from all diagrams..."
declare -A DIAGRAM_METADATA

while IFS= read -r mmd; do
  basename="${mmd%.mmd}"

  # Check if file has metadata
  if grep -q '<!--' "$mmd" && grep -q 'title:' "$mmd"; then
    ((METADATA_FOUND++))

    # Extract key metadata fields
    title=$(extract_metadata "$mmd" "title")
    type=$(extract_metadata "$mmd" "type")
    components=$(sed -n '/^components:/,/^[a-z_]/p' "$mmd" | grep '^\s\+[a-z_]' | wc -l)

    echo "✅ $basename.mmd: $title (${components} component types)"
  else
    echo "⚠️  $basename.mmd: No metadata found"
    ((WARNINGS++))
  fi
done < <(find . -maxdepth 1 -name "*.mmd" -type f)

echo ""
echo "Metadata Summary:"
echo "  Diagrams with metadata: $METADATA_FOUND"
echo "  Diagrams without metadata: $(( $(find . -maxdepth 1 -name "*.mmd" -type f | wc -l) - METADATA_FOUND ))"
echo ""

# ============================================================================
# PHASE 2: Validate Component Counts
# ============================================================================
echo "🔍 PHASE 2: Component Count Validation"
echo "────────────────────────────────────────────"

# Count actual components
ACTUAL_COMMANDS=$(find "$PLUGIN_ROOT/commands" -name "*.md" -type f 2>/dev/null | wc -l)
ACTUAL_SKILLS=$(find "$PLUGIN_ROOT/skills" -maxdepth 1 -type d ! -name skills ! -name _shared 2>/dev/null | wc -l)
ACTUAL_AGENTS=$(find "$PLUGIN_ROOT/agents" -name "*.md" -type f 2>/dev/null | wc -l)

echo "Actual Component Counts:"
echo "  Commands: $ACTUAL_COMMANDS"
echo "  Skills:   $ACTUAL_SKILLS"
echo "  Agents:   $ACTUAL_AGENTS"
echo ""

# Validate plugin-architecture.mmd metadata
if [[ -f "plugin-architecture.mmd" ]]; then
  echo "Validating plugin-architecture.mmd component counts..."

  # Extract documented counts
  DOCUMENTED_COMMANDS=$(extract_component "plugin-architecture.mmd" "commands" | tr -d ' ')
  DOCUMENTED_SKILLS=$(extract_component "plugin-architecture.mmd" "skills" | tr -d ' ')
  DOCUMENTED_AGENTS=$(extract_component "plugin-architecture.mmd" "agents" | tr -d ' ')

  # Validate commands
  if [[ "$DOCUMENTED_COMMANDS" == "$ACTUAL_COMMANDS" ]]; then
    echo "✅ Commands: documented ($DOCUMENTED_COMMANDS) matches actual ($ACTUAL_COMMANDS)"
  else
    echo "❌ Commands: documented ($DOCUMENTED_COMMANDS) ≠ actual ($ACTUAL_COMMANDS)"
    ((ERRORS++))
  fi

  # Validate skills
  if [[ "$DOCUMENTED_SKILLS" == "$ACTUAL_SKILLS" ]]; then
    echo "✅ Skills: documented ($DOCUMENTED_SKILLS) matches actual ($ACTUAL_SKILLS)"
  else
    echo "❌ Skills: documented ($DOCUMENTED_SKILLS) ≠ actual ($ACTUAL_SKILLS)"
    ((ERRORS++))
  fi

  # Validate agents
  if [[ "$DOCUMENTED_AGENTS" == "$ACTUAL_AGENTS" ]]; then
    echo "✅ Agents: documented ($DOCUMENTED_AGENTS) matches actual ($ACTUAL_AGENTS)"
  else
    echo "❌ Agents: documented ($DOCUMENTED_AGENTS) ≠ actual ($ACTUAL_AGENTS)"
    ((ERRORS++))
  fi
else
  echo "⚠️  plugin-architecture.mmd not found - cannot validate component counts"
  ((WARNINGS++))
fi

echo ""

# ============================================================================
# PHASE 3: Validate Documentation References
# ============================================================================
echo "🔍 PHASE 3: Documentation Reference Validation"
echo "────────────────────────────────────────────"

echo "Validating 'documents' metadata matches actual files..."
REF_ERRORS=0
REF_CHECKED=0

while IFS= read -r mmd; do
  basename="${mmd%.mmd}"

  # Check if metadata exists
  if ! grep -q 'documents:' "$mmd"; then
    continue
  fi

  # Extract documented files
  while IFS= read -r doc_file; do
    [[ -z "$doc_file" ]] && continue
    ((REF_CHECKED++))

    # Resolve path relative to plugin root
    doc_path="$PLUGIN_ROOT/$doc_file"

    if [[ -f "$doc_path" ]]; then
      echo "✅ $basename → $doc_file (exists)"
    else
      echo "❌ $basename → $doc_file (NOT FOUND)"
      ((REF_ERRORS++))
      ((ERRORS++))
    fi
  done < <(sed -n '/<!--/,/-->/p' "$mmd" | sed -n '/^  documents:/,/^[a-z_]/p' | grep '^\s*-' | sed 's/^\s*- //')

done < <(find . -maxdepth 1 -name "*.mmd" -type f)

if [[ $REF_CHECKED -eq 0 ]]; then
  echo "ℹ️  No document references found in metadata"
elif [[ $REF_ERRORS -eq 0 ]]; then
  echo ""
  echo "✅ All referenced documentation files exist ($REF_CHECKED checked)"
else
  echo ""
  echo "❌ Found $REF_ERRORS missing referenced file(s)"
fi

echo ""

# ============================================================================
# PHASE 4: Validate Diagram Content vs Claims
# ============================================================================
echo "🔍 PHASE 4: Diagram Content vs Documentation Claims"
echo "────────────────────────────────────────────"

echo "Checking project type consistency..."

# Extract project types from quickstart-flow.mmd
if [[ -f "quickstart-flow.mmd" ]]; then
  PROJECT_TYPES_IN_DIAGRAM=$(grep -oP 'Q1 -->.*?\|' quickstart-flow.mmd | wc -l)
  echo "Project types in diagram: $PROJECT_TYPES_IN_DIAGRAM"

  # Check README.md claim
  if [[ -f "$PLUGIN_ROOT/README.md" ]]; then
    README_CLAIM=$(grep -oP 'Choose from \K[0-9]+(?= project types)' "$PLUGIN_ROOT/README.md" 2>/dev/null || echo "0")
    if [[ "$README_CLAIM" == "$PROJECT_TYPES_IN_DIAGRAM" ]]; then
      echo "✅ README.md claims $README_CLAIM project types (matches diagram)"
    else
      echo "⚠️  README.md claims $README_CLAIM project types (diagram shows $PROJECT_TYPES_IN_DIAGRAM)"
      ((WARNINGS++))
    fi
  fi
else
  echo "ℹ️  quickstart-flow.mmd not found - cannot validate project types"
fi

echo ""

# ============================================================================
# PHASE 5: Validate Metadata Completeness
# ============================================================================
echo "🔍 PHASE 5: Metadata Completeness Check"
echo "────────────────────────────────────────────"

echo "Checking required metadata fields..."
INCOMPLETE=0

while IFS= read -r mmd; do
  basename="${mmd%.mmd}"
  missing_fields=()

  # Check required fields
  grep -q 'title:' "$mmd" || missing_fields+=("title")
  grep -q 'type:' "$mmd" || missing_fields+=("type")
  grep -q 'version:' "$mmd" || missing_fields+=("version")
  grep -q 'documents:' "$mmd" || missing_fields+=("documents")
  grep -q 'purpose:' "$mmd" || missing_fields+=("purpose")
  grep -q 'last_updated:' "$mmd" || missing_fields+=("last_updated")

  if [[ ${#missing_fields[@]} -gt 0 ]]; then
    echo "⚠️  $basename.mmd: Missing fields: ${missing_fields[*]}"
    ((INCOMPLETE++))
    ((WARNINGS++))
  else
    echo "✅ $basename.mmd: All required fields present"
  fi
done < <(find . -maxdepth 1 -name "*.mmd" -type f)

echo ""

# ============================================================================
# SUMMARY
# ============================================================================
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                         SUMMARY                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Metadata Status:"
echo "  Diagrams with metadata:    $METADATA_FOUND / 12"
echo "  Complete metadata:         $(( 12 - INCOMPLETE )) / 12"
echo "  Incomplete metadata:       $INCOMPLETE"
echo ""
echo "Component Validation:"
echo "  Actual Commands:           $ACTUAL_COMMANDS"
echo "  Actual Skills:             $ACTUAL_SKILLS"
echo "  Actual Agents:             $ACTUAL_AGENTS"
echo ""
echo "Documentation References:"
echo "  References checked:        $REF_CHECKED"
echo "  Invalid references:        $REF_ERRORS"
echo ""
echo "Validation Results:"
echo "  Errors:                    $ERRORS ❌"
echo "  Warnings:                  $WARNINGS ⚠️"
echo ""

if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
  echo "🎉 EXCELLENT: All bidirectional validations passed!"
  exit 0
elif [[ $ERRORS -eq 0 ]]; then
  echo "⚠️  GOOD: No critical errors, but $WARNINGS warning(s) present"
  echo "   Review warnings to improve metadata quality"
  exit 0
else
  echo "❌ FAILED: $ERRORS critical error(s) found"
  echo "   Fix errors before proceeding"
  exit 1
fi
