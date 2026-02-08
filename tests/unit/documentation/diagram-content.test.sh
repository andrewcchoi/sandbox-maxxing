#!/usr/bin/env bats
# Unit tests for diagram content validation

setup() {
  export PLUGIN_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"
  export DIAGRAMS_DIR="$PLUGIN_ROOT/docs/diagrams"
}

@test "All .mmd files contain valid Mermaid diagram declarations" {
  local invalid=0

  while IFS= read -r mmd; do
    if ! grep -qE "graph|flowchart|sequenceDiagram|classDiagram|stateDiagram|erDiagram|gantt|pie" "$mmd"; then
      ((invalid++))
    fi
  done < <(find "$DIAGRAMS_DIR" -maxdepth 1 -name "*.mmd" -type f)

  [ "$invalid" -eq 0 ]
}

@test "plugin-architecture.mmd exists and is not empty" {
  [ -f "$DIAGRAMS_DIR/plugin-architecture.mmd" ]
  [ -s "$DIAGRAMS_DIR/plugin-architecture.mmd" ]
}

@test "All .mmd files are at least 50 bytes (not stub files)" {
  while IFS= read -r mmd; do
    local size=$(stat -f%z "$mmd" 2>/dev/null || stat -c%s "$mmd" 2>/dev/null)
    [ "$size" -gt 50 ]
  done < <(find "$DIAGRAMS_DIR" -maxdepth 1 -name "*.mmd" -type f)
}

@test "All .svg files are at least 500 bytes (valid renders)" {
  while IFS= read -r svg; do
    local size=$(stat -f%z "$svg" 2>/dev/null || stat -c%s "$svg" 2>/dev/null)
    [ "$size" -gt 500 ]
  done < <(find "$DIAGRAMS_DIR/svg" -name "*.svg" -type f)
}

@test "All .svg files contain SVG root element" {
  while IFS= read -r svg; do
    grep -q '<svg' "$svg"
  done < <(find "$DIAGRAMS_DIR/svg" -name "*.svg" -type f)
}

@test "docs/diagrams/README.md documents all diagrams" {
  [ -f "$DIAGRAMS_DIR/README.md" ]

  # Check that all .mmd files are mentioned in README
  while IFS= read -r mmd; do
    local basename=$(basename "$mmd")
    grep -q "$basename" "$DIAGRAMS_DIR/README.md"
  done < <(find "$DIAGRAMS_DIR" -maxdepth 1 -name "*.mmd" -type f)
}
