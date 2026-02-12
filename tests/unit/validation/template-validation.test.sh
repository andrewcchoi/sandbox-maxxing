#!/usr/bin/env bats
#
# Template Validation Tests
# Validates templates for JSON, YAML, Dockerfile, and shell scripts
#

# Calculate plugin root from test file location
BATS_TEST_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
PLUGIN_ROOT="$(cd "$BATS_TEST_DIR/../../.." && pwd)"

load '../../helpers/test_helper'

# Test-specific constants
TEMPLATES_DIR="${PLUGIN_ROOT}/skills/_shared/templates"

# ============================================================================
# JSON template validation
# ============================================================================

@test "all JSON files in data directory are valid" {
  local data_dir="${TEMPLATES_DIR}/data"

  [ -d "$data_dir" ] || skip "data directory not found"

  while IFS= read -r json_file; do
    assert_valid_json "$json_file"
  done < <(find "$data_dir" -name "*.json")
}

@test "data/allowable-domains.json has expected structure" {
  local file="${TEMPLATES_DIR}/data/allowable-domains.json"

  [ -f "$file" ] || skip "allowable-domains.json not found"

  # Check it has domains array
  run jq -r '.domains | type' "$file"
  assert_success
  [ "$output" = "array" ]
}

@test "data/azure-regions.json has expected structure" {
  local file="${TEMPLATES_DIR}/data/azure-regions.json"

  [ -f "$file" ] || skip "azure-regions.json not found"

  # Check it has regions array
  run jq -r '.regions | type' "$file"
  assert_success
  [ "$output" = "array" ]
}

@test "data/mcp-servers.json has expected structure" {
  local file="${TEMPLATES_DIR}/data/mcp-servers.json"

  [ -f "$file" ] || skip "mcp-servers.json not found"

  # Check it has servers object
  run jq -r '.mcpServers | type' "$file"
  assert_success
  [ "$output" = "object" ]
}

@test "data/vscode-extensions.json has valid extension IDs" {
  local file="${TEMPLATES_DIR}/data/vscode-extensions.json"

  [ -f "$file" ] || skip "vscode-extensions.json not found"

  # Check each extension has publisher.name format
  local extensions
  extensions=$(jq -r '.extensions[]' "$file" 2>/dev/null)

  while IFS= read -r ext; do
    [[ "$ext" =~ ^[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+$ ]] || {
      echo "Invalid extension ID format: $ext" >&2
      return 1
    }
  done <<< "$extensions"
}

# ============================================================================
# YAML template validation
# ============================================================================

@test "all YAML files in templates are valid" {
  require_command yq

  while IFS= read -r yaml_file; do
    assert_valid_yaml "$yaml_file"
  done < <(find "$TEMPLATES_DIR" -name "*.yml" -o -name "*.yaml")
}

@test "docker-compose.yml has required services" {
  require_command yq

  local file="${TEMPLATES_DIR}/docker-compose.yml"
  [ -f "$file" ] || skip "docker-compose.yml not found"

  # Check it has services section
  run yq eval '.services | type' "$file"
  assert_success
  [ "$output" = "!!map" ]
}

@test "docker-compose.yml has version or services defined" {
  require_command yq

  local file="${TEMPLATES_DIR}/docker-compose.yml"
  [ -f "$file" ] || skip "docker-compose.yml not found"

  # Either version or services must be present
  local has_version
  local has_services

  has_version=$(yq eval '.version' "$file" 2>/dev/null)
  has_services=$(yq eval '.services' "$file" 2>/dev/null)

  [ "$has_version" != "null" ] || [ "$has_services" != "null" ] || {
    echo "docker-compose.yml must have version or services" >&2
    return 1
  }
}

@test "all docker-compose files use valid compose syntax" {
  require_command yq

  while IFS= read -r compose_file; do
    # Check basic structure
    local services
    services=$(yq eval '.services' "$compose_file" 2>/dev/null)

    [ "$services" != "null" ] || {
      echo "Missing services section in: $compose_file" >&2
      return 1
    }
  done < <(find "$TEMPLATES_DIR" -name "docker-compose*.yml")
}

# ============================================================================
# Dockerfile validation
# ============================================================================

@test "all Dockerfile files contain FROM instruction" {
  while IFS= read -r dockerfile; do
    # Check for FROM instruction (case-insensitive)
    grep -qi "^FROM " "$dockerfile" || {
      echo "Missing FROM instruction in: $dockerfile" >&2
      return 1
    }
  done < <(find "$TEMPLATES_DIR" -name "*.dockerfile" -o -name "Dockerfile")
}

@test "base.dockerfile has FROM instruction" {
  local file="${TEMPLATES_DIR}/base.dockerfile"
  [ -f "$file" ] || skip "base.dockerfile not found"

  grep -qi "^FROM " "$file"
}

@test "Dockerfile partials have valid syntax" {
  local partials_dir="${TEMPLATES_DIR}/partials"
  [ -d "$partials_dir" ] || skip "partials directory not found"

  while IFS= read -r dockerfile; do
    # Check for FROM instruction
    grep -qi "^FROM " "$dockerfile" || {
      echo "Missing FROM instruction in: $dockerfile" >&2
      return 1
    }

    # Check for basic RUN, COPY, or ENV instructions
    grep -qiE "^(RUN|COPY|ENV|WORKDIR|USER) " "$dockerfile" || {
      echo "No build instructions found in: $dockerfile" >&2
      return 1
    }
  done < <(find "$partials_dir" -name "*.dockerfile")
}

# ============================================================================
# Shell script validation
# ============================================================================

@test "all shell scripts in templates have valid syntax" {
  while IFS= read -r script; do
    assert_valid_shell "$script"
  done < <(find "$TEMPLATES_DIR" -name "*.sh")
}

@test "init-firewall.sh has valid bash syntax" {
  local file="${TEMPLATES_DIR}/init-firewall.sh"
  [ -f "$file" ] || skip "init-firewall.sh not found"

  assert_valid_shell "$file"
}

@test "setup-claude-credentials.sh has valid bash syntax" {
  local file="${TEMPLATES_DIR}/setup-claude-credentials.sh"
  [ -f "$file" ] || skip "setup-claude-credentials.sh not found"

  assert_valid_shell "$file"
}

@test "all shell scripts have shebang" {
  while IFS= read -r script; do
    # Check first line starts with #!
    local first_line
    first_line=$(head -n 1 "$script")

    [[ "$first_line" =~ ^#! ]] || {
      echo "Missing shebang in: $script" >&2
      return 1
    }
  done < <(find "$TEMPLATES_DIR" -name "*.sh")
}

# ============================================================================
# devcontainer.json validation
# ============================================================================

@test "devcontainer.json is valid JSON (ignoring comments)" {
  local file="${TEMPLATES_DIR}/devcontainer.json"
  [ -f "$file" ] || skip "devcontainer.json not found"

  # Strip // comments before validating
  local cleaned
  cleaned=$(sed 's|//.*||g' "$file")

  echo "$cleaned" | jq empty 2>&1 || {
    echo "Invalid JSON in devcontainer.json (after stripping comments)" >&2
    return 1
  }
}

@test "devcontainer.json has required fields" {
  local file="${TEMPLATES_DIR}/devcontainer.json"
  [ -f "$file" ] || skip "devcontainer.json not found"

  # Strip // comments
  local cleaned
  cleaned=$(sed 's|//.*||g' "$file")

  # Check for name field
  local name
  name=$(echo "$cleaned" | jq -r '.name' 2>/dev/null)

  [ "$name" != "null" ] || {
    echo "devcontainer.json missing 'name' field" >&2
    return 1
  }
}

@test "all devcontainer.json variants are valid" {
  require_command jq

  while IFS= read -r devcontainer_file; do
    # Strip // comments before validating
    local cleaned
    cleaned=$(sed 's|//.*||g' "$devcontainer_file")

    echo "$cleaned" | jq empty 2>&1 || {
      echo "Invalid JSON in: $devcontainer_file" >&2
      return 1
    }
  done < <(find "$TEMPLATES_DIR" -name "devcontainer*.json")
}

# ============================================================================
# MCP configuration validation
# ============================================================================

@test "mcp.json is valid JSON" {
  local file="${TEMPLATES_DIR}/mcp.json"
  [ -f "$file" ] || skip "mcp.json not found"

  assert_valid_json "$file"
}

@test "mcp.json has mcpServers object" {
  local file="${TEMPLATES_DIR}/mcp.json"
  [ -f "$file" ] || skip "mcp.json not found"

  run jq -r '.mcpServers | type' "$file"
  assert_success
  [ "$output" = "object" ]
}

# ============================================================================
# Azure template validation
# ============================================================================

@test "azure.yaml is valid YAML" {
  require_command yq

  local file="${TEMPLATES_DIR}/azure/azure.yaml"
  [ -f "$file" ] || skip "azure.yaml not found"

  assert_valid_yaml "$file"
}

@test "Azure Bicep files have valid syntax" {
  skip_on_platform "Windows"  # Bicep validation requires az cli

  # Just check basic structure for now
  while IFS= read -r bicep_file; do
    # Check file has resource or module keywords
    grep -qE "^(resource|module|param|var|output) " "$bicep_file" || {
      echo "No Bicep declarations found in: $bicep_file" >&2
      return 1
    }
  done < <(find "${TEMPLATES_DIR}/azure" -name "*.bicep" 2>/dev/null || true)
}

# ============================================================================
# General template file validation
# ============================================================================

@test "no template files contain placeholder tokens" {
  # Check for common unprocessed placeholders
  local placeholders=("TODO" "FIXME" "XXX" "PLACEHOLDER")

  for placeholder in "${placeholders[@]}"; do
    if grep -r "$placeholder" "$TEMPLATES_DIR" --include="*.json" --include="*.yml" --include="*.yaml" 2>/dev/null | grep -v "README" | grep -v "test" | grep -q .; then
      echo "Found $placeholder in template files:" >&2
      grep -r "$placeholder" "$TEMPLATES_DIR" --include="*.json" --include="*.yml" --include="*.yaml" 2>/dev/null | grep -v "README" | grep -v "test" || true
      return 1
    fi
  done
}

@test "template files have proper line endings" {
  # Check for CR characters (Windows line endings)
  while IFS= read -r template_file; do
    if file "$template_file" | grep -q "CRLF"; then
      echo "File has Windows line endings (CRLF): $template_file" >&2
      echo "Run: dos2unix $template_file" >&2
      return 1
    fi
  done < <(find "$TEMPLATES_DIR" -type f -name "*.json" -o -name "*.yml" -o -name "*.yaml" -o -name "*.sh")
}
