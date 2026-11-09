#!/usr/bin/env bats
# Unit tests for diagram file existence

setup() {
  export PLUGIN_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"
  export DIAGRAMS_DIR="$PLUGIN_ROOT/docs/diagrams"
}

@test "All 18 expected .mmd source files exist" {
  local expected_diagrams=(
    "azure-deployment-flow"
    "bubblewrap-architecture"
    "bubblewrap-explained"
    "cicd-integration"
    "file-generation"
    "firewall-resolution"
    "health-check-flow"
    "linux-setup-flow"
    "mode-selection"
    "plugin-architecture"
    "quickstart-flow"
    "sandbox-explained"
    "secrets-flow"
    "security-audit-flow"
    "security-layers"
    "service-connectivity"
    "setup-comparison"
    "troubleshooting-flow"
  )

  for diagram in "${expected_diagrams[@]}"; do
    [ -f "$DIAGRAMS_DIR/${diagram}.mmd" ]
  done
}

@test "All 18 expected .svg output files exist" {
  local expected_diagrams=(
    "azure-deployment-flow"
    "bubblewrap-architecture"
    "bubblewrap-explained"
    "cicd-integration"
    "file-generation"
    "firewall-resolution"
    "health-check-flow"
    "linux-setup-flow"
    "mode-selection"
    "plugin-architecture"
    "quickstart-flow"
    "sandbox-explained"
    "secrets-flow"
    "security-audit-flow"
    "security-layers"
    "service-connectivity"
    "setup-comparison"
    "troubleshooting-flow"
  )

  for diagram in "${expected_diagrams[@]}"; do
    [ -f "$DIAGRAMS_DIR/svg/${diagram}.svg" ]
  done
}

@test "No .mmd files are empty" {
  while IFS= read -r mmd; do
    [ -s "$mmd" ]
  done < <(find "$DIAGRAMS_DIR" -maxdepth 1 -name "*.mmd" -type f)
}

@test "No .svg files are empty" {
  while IFS= read -r svg; do
    [ -s "$svg" ]
  done < <(find "$DIAGRAMS_DIR/svg" -name "*.svg" -type f)
}

@test "SVG directory exists" {
  [ -d "$DIAGRAMS_DIR/svg" ]
}

@test "Diagram count matches expected (18 pairs)" {
  local mmd_count=$(find "$DIAGRAMS_DIR" -maxdepth 1 -name "*.mmd" -type f | wc -l)
  local svg_count=$(find "$DIAGRAMS_DIR/svg" -name "*.svg" -type f | wc -l)

  [ "$mmd_count" -eq 18 ]
  [ "$svg_count" -eq 18 ]
}
