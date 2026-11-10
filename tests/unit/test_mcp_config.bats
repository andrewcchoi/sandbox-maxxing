#!/usr/bin/env bats
# ============================================================================
# MCP template, catalog and docs match how Claude Code loads MCP config (#386)
#
# The template used VS Code's `servers` key, the docs pointed at
# .devcontainer/mcp.json (read by nothing), and the catalog listed archived or
# nonexistent npm packages. MCP is opt-in: nothing installs the template, and
# users copy entries into .mcp.json at the project root. No network needed.
# ============================================================================

load '../helpers/test_helper.bash'

ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
TEMPLATE="$ROOT/skills/_shared/templates/mcp.json"
CATALOG="$ROOT/skills/_shared/templates/data/mcp-servers.json"
DOC="$ROOT/docs/features/MCP.md"

setup() {
  command -v jq >/dev/null || skip "jq not installed"
  TEST_DIR="$(mktemp -d)"
}

teardown() {
  rm -rf "${TEST_DIR:-}"
}

# Strip catalog-only fields so an entry is exactly what goes into .mcp.json
catalog_as_mcp_json() {
  jq '{mcpServers: (.servers | map_values(del(.description, .mode_minimum, .category, .requires)))}' "$CATALOG"
}

@test "template: the starter .mcp.json in MCP.md is the template, byte for byte (as JSON)" {
  # First ```json block after "## Quick start"
  awk '/^## Quick start/{q=1} q&&/^```json$/{f=1;next} f&&/^```$/{exit} f' "$DOC" > "$TEST_DIR/doc.json"
  [ -s "$TEST_DIR/doc.json" ]
  diff <(jq -S . "$TEMPLATE") <(jq -S . "$TEST_DIR/doc.json")
}

@test "template: copying it to .mcp.json gives a valid Claude Code project config" {
  cp "$TEMPLATE" "$TEST_DIR/.mcp.json"
  run jq -e '.mcpServers | type == "object" and length > 0' "$TEST_DIR/.mcp.json"
  [ "$status" -eq 0 ]
  # stdio entries need a command, http/sse entries a url
  run jq -r '[.mcpServers | to_entries[] | select(
      ((.value.type // "stdio") == "stdio" and (.value.command // "") == "") or
      ((.value.type // "stdio") != "stdio" and (.value.url // "") == "")) | .key] | join(",")' "$TEST_DIR/.mcp.json"
  [ -z "$output" ] || { echo "Invalid entries: $output" >&2; return 1; }
}

@test "template: filesystem server is scoped to the project root, not all of /workspace" {
  run jq -r '.mcpServers.filesystem.args[-1]' "$TEMPLATE"
  [ "$output" = "." ]
}

@test "catalog: every entry converts to a valid .mcp.json entry" {
  catalog_as_mcp_json > "$TEST_DIR/.mcp.json"
  run jq -r '[.mcpServers | to_entries[] | select(
      (.value.type | IN("stdio","http","sse") | not) or
      (.value.type == "stdio" and (.value.command // "") == "") or
      (.value.type != "stdio" and (.value.url // "") == "")) | .key] | join(",")' "$TEST_DIR/.mcp.json"
  [ -z "$output" ] || { echo "Invalid entries: $output" >&2; return 1; }
}

@test "catalog and template: no VS Code-only syntax (inputs, \${input:}, \${localEnv:})" {
  for f in "$TEMPLATE" "$CATALOG"; do
    run grep -nE '\$\{(input|localEnv):' "$f"
    [ "$status" -eq 1 ] || { echo "$f: $output" >&2; return 1; }
    run jq -r '[.. | objects | select(has("inputs"))] | length' "$f"
    [ "$output" = "0" ] || { echo "$f has VS Code 'inputs'" >&2; return 1; }
  done
}

@test "catalog: no archived, deprecated or unpublished reference packages" {
  # Checked 2026-11-10 with `npm view`: sqlite/fetch are not on npm; the rest
  # are archived (servers-archived) or deprecated.
  run grep -nE '@modelcontextprotocol/server-(sqlite|fetch|postgres|github|puppeteer|brave-search|slack|gdrive)"' "$CATALOG" "$TEMPLATE"
  [ "$status" -eq 1 ] || { echo "$output" >&2; return 1; }
}

@test "catalog: mode_defaults only name servers that exist" {
  run jq -r '[.mode_defaults[].servers | arrays | .[]] - (.servers | keys) | join(",")' "$CATALOG"
  [ -z "$output" ] || { echo "Unknown servers in mode_defaults: $output" >&2; return 1; }
}

@test "docs: no instructions to edit .devcontainer/mcp.json or use the servers key" {
  # Mentions are fine only to say Claude Code doesn't read it
  run bash -c "grep -rnF '.devcontainer/mcp.json' '$ROOT/docs/features' '$ROOT/README.md' '$ROOT/commands' '$ROOT/skills' | grep -vF 'does **not** read'"
  [ "$status" -eq 1 ] || { echo "$output" >&2; return 1; }
  # Every JSON example in MCP.md uses mcpServers
  run grep -nE '^\s*"servers"\s*:' "$DOC"
  [ "$status" -eq 1 ] || { echo "$output" >&2; return 1; }
}

@test "scaffolders don't install MCP servers (MCP is opt-in)" {
  run grep -nE 'mcp\.json|mcp-servers\.json' "$ROOT/scripts/yolo-docker-maxxing.sh" "$ROOT/commands/quickstart.md"
  [ "$status" -eq 1 ] || { echo "$output" >&2; return 1; }
}
