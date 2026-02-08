#!/usr/bin/env bats
# Integration tests for documentation health checks

setup() {
  export PLUGIN_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
}

@test "diagram-inventory.sh script exists and is executable" {
  [ -x "$PLUGIN_ROOT/scripts/diagram-inventory.sh" ]
}

@test "diagram-inventory-enhanced.sh script exists and is executable" {
  [ -x "$PLUGIN_ROOT/scripts/diagram-inventory-enhanced.sh" ]
}

@test "diagram-inventory.sh runs successfully" {
  run bash "$PLUGIN_ROOT/scripts/diagram-inventory.sh"
  [ "$status" -eq 0 ]
}

@test "diagram-inventory-enhanced.sh runs successfully" {
  run bash "$PLUGIN_ROOT/scripts/diagram-inventory-enhanced.sh"
  [ "$status" -eq 0 ]
}

@test "diagram-inventory.sh reports correct diagram counts" {
  run bash "$PLUGIN_ROOT/scripts/diagram-inventory.sh"
  [[ "$output" =~ "Mermaid source files (.mmd): 12" ]]
  [[ "$output" =~ "SVG output files (.svg):     12" ]]
}

@test "diagram-inventory.sh reports no missing SVGs" {
  run bash "$PLUGIN_ROOT/scripts/diagram-inventory.sh"
  [[ "$output" =~ "Missing SVGs:    0" ]]
}

@test "diagram-inventory.sh reports no orphaned SVGs" {
  run bash "$PLUGIN_ROOT/scripts/diagram-inventory.sh"
  [[ "$output" =~ "Orphaned SVGs:   0" ]] || [[ "$output" =~ "All diagrams have source files and outputs" ]]
}

@test "version-checker.sh script exists" {
  [ -f "$PLUGIN_ROOT/scripts/version-checker.sh" ]
}

@test "doc-health-check.sh script exists" {
  [ -f "$PLUGIN_ROOT/scripts/doc-health-check.sh" ]
}

@test "DIAGRAM_STATUS.md dashboard exists" {
  [ -f "$PLUGIN_ROOT/DIAGRAM_STATUS.md" ]
}

@test "DIAGRAM_STATUS.md contains all 12 diagrams" {
  local diagram_count=$(grep -c "^### [0-9]\+\." "$PLUGIN_ROOT/DIAGRAM_STATUS.md" || true)
  [ "$diagram_count" -eq 12 ]
}
