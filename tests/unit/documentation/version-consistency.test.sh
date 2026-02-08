#!/usr/bin/env bats
# Unit tests for version consistency

setup() {
  export PLUGIN_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"
}

@test "plugin.json version field exists" {
  [ -f "$PLUGIN_ROOT/.claude-plugin/plugin.json" ]
  grep -q '"version"' "$PLUGIN_ROOT/.claude-plugin/plugin.json"
}

@test "marketplace.json version field exists" {
  [ -f "$PLUGIN_ROOT/.claude-plugin/marketplace.json" ]
  grep -q '"version"' "$PLUGIN_ROOT/.claude-plugin/marketplace.json"
}

@test "README.md version badge exists" {
  [ -f "$PLUGIN_ROOT/README.md" ]
  grep -q 'version-[0-9]\+\.[0-9]\+\.[0-9]\+' "$PLUGIN_ROOT/README.md"
}

@test "package.json version matches plugin.json" {
  if ! command -v jq &> /dev/null; then
    skip "jq not installed"
  fi

  local plugin_version=$(jq -r '.version' "$PLUGIN_ROOT/.claude-plugin/plugin.json")
  local package_version=$(jq -r '.version' "$PLUGIN_ROOT/package.json")

  [ "$plugin_version" = "$package_version" ]
}

@test "marketplace.json version matches plugin.json" {
  if ! command -v jq &> /dev/null; then
    skip "jq not installed"
  fi

  local plugin_version=$(jq -r '.version' "$PLUGIN_ROOT/.claude-plugin/plugin.json")
  local market_version=$(jq -r '.version' "$PLUGIN_ROOT/.claude-plugin/marketplace.json")

  [ "$plugin_version" = "$market_version" ]
}

@test "README.md badge version matches plugin.json" {
  if ! command -v jq &> /dev/null; then
    skip "jq not installed"
  fi

  local plugin_version=$(jq -r '.version' "$PLUGIN_ROOT/.claude-plugin/plugin.json")
  local readme_version=$(grep -oP 'version-\K[0-9]+\.[0-9]+\.[0-9]+' "$PLUGIN_ROOT/README.md" | head -1)

  [ "$plugin_version" = "$readme_version" ]
}

@test "All version sources are consistent (4.13.0)" {
  if ! command -v jq &> /dev/null; then
    skip "jq not installed"
  fi

  local plugin_version=$(jq -r '.version' "$PLUGIN_ROOT/.claude-plugin/plugin.json")
  local market_version=$(jq -r '.version' "$PLUGIN_ROOT/.claude-plugin/marketplace.json")
  local package_version=$(jq -r '.version' "$PLUGIN_ROOT/package.json")
  local readme_version=$(grep -oP 'version-\K[0-9]+\.[0-9]+\.[0-9]+' "$PLUGIN_ROOT/README.md" | head -1)

  [ "$plugin_version" = "$market_version" ]
  [ "$plugin_version" = "$package_version" ]
  [ "$plugin_version" = "$readme_version" ]
}
