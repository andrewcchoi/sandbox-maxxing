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

@test "data/allowable-domains.json: categories hold valid hostnames" {
  local file="${TEMPLATES_DIR}/data/allowable-domains.json"
  [ -f "$file" ] || skip "allowable-domains.json not found"

  run jq -r '.categories | type' "$file"
  assert_success
  [ "$output" = "object" ]

  # Every `domains` array, at any nesting level, holds hostnames (optionally *.wildcard)
  run jq -r '[.. | .domains? | arrays | .[]] | length' "$file"
  [ "$output" -gt 0 ]
  run jq -r '[.. | .domains? | arrays | .[]
              | select(test("^(\\*\\.)?[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?(\\.[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?)+$") | not)]
             | join(",")' "$file"
  [ -z "$output" ] || { echo "Invalid domains: $output" >&2; return 1; }
}

@test "data/azure-regions.json: every region has a code and a name" {
  local file="${TEMPLATES_DIR}/data/azure-regions.json"
  [ -f "$file" ] || skip "azure-regions.json not found"

  run jq -r '.regions | type' "$file"
  [ "$output" = "object" ]
  run jq -r '[.regions[][]] | length' "$file"
  [ "$output" -gt 0 ]
  run jq -r '[.regions[][] | select((.code // "" | test("^[a-z0-9]+$") | not) or ((.name // "") == "")) | .code // "?"] | join(",")' "$file"
  [ -z "$output" ] || { echo "Regions missing a valid code or name: $output" >&2; return 1; }
}

@test "data/mcp-servers.json: every server has a type and a command or URL" {
  local file="${TEMPLATES_DIR}/data/mcp-servers.json"
  [ -f "$file" ] || skip "mcp-servers.json not found"

  run jq -r '.servers | type' "$file"
  [ "$output" = "object" ]
  run jq -r '.servers | length' "$file"
  [ "$output" -gt 0 ]
  run jq -r '[.servers | to_entries[] | select((.value.type // "") == "" or ((.value.command // .value.url // "") == "")) | .key] | join(",")' "$file"
  [ -z "$output" ] || { echo "Servers missing type or command/url: $output" >&2; return 1; }
}

@test "data/vscode-extensions.json: every extension ID is publisher.name" {
  local file="${TEMPLATES_DIR}/data/vscode-extensions.json"
  [ -f "$file" ] || skip "vscode-extensions.json not found"

  run jq -r '[.. | objects | select(has("id")) | .id] | length' "$file"
  [ "$output" -gt 0 ]
  run jq -r '[.. | objects | select(has("id")) | .id | select(test("^[A-Za-z0-9-]+\\.[A-Za-z0-9-]+$") | not)] | join(",")' "$file"
  [ -z "$output" ] || { echo "Invalid extension IDs: $output" >&2; return 1; }
}

# ============================================================================
# YAML template validation
# ============================================================================

@test "all YAML files in templates are valid once placeholders are filled" {
  require_command yq

  local yaml_file rendered count=0
  while IFS= read -r yaml_file; do
    rendered="${BATS_TEST_TMPDIR}/$(basename "$yaml_file")"
    render_placeholders "$yaml_file" > "$rendered"
    assert_valid_yaml "$rendered" || { echo "(rendered from $yaml_file)" >&2; return 1; }
    count=$((count + 1))
  done < <(find "$TEMPLATES_DIR" -name "*.yml" -o -name "*.yaml")
  [ "$count" -gt 0 ]
}

@test "docker-compose.yml has an app service" {
  require_command yq

  local file="${TEMPLATES_DIR}/docker-compose.yml"
  [ -f "$file" ] || skip "docker-compose.yml not found"

  local rendered="${BATS_TEST_TMPDIR}/docker-compose.yml"
  render_placeholders "$file" > "$rendered"
  run yq eval '.services | type' "$rendered"
  assert_success
  [ "$output" = "!!map" ]
  run yq eval '.services.app | type' "$rendered"
  [ "$output" = "!!map" ]
}

@test "all docker-compose templates define services" {
  require_command yq

  local compose_file rendered services
  while IFS= read -r compose_file; do
    rendered="${BATS_TEST_TMPDIR}/$(basename "$compose_file")"
    render_placeholders "$compose_file" > "$rendered"
    services=$(yq eval '.services | type' "$rendered" 2>/dev/null)
    [ "$services" = "!!map" ] || {
      echo "Missing or invalid services section in: $compose_file" >&2
      return 1
    }
  done < <(find "$TEMPLATES_DIR" -name "docker-compose*.yml")
}

# ============================================================================
# Dockerfile validation
# ============================================================================

@test "all standalone Dockerfiles contain FROM instruction" {
  # Partials are fragments appended to base.dockerfile, so they are excluded here
  while IFS= read -r dockerfile; do
    grep -qi "^FROM " "$dockerfile" || {
      echo "Missing FROM instruction in: $dockerfile" >&2
      return 1
    }
  done < <(find "$TEMPLATES_DIR" \( -name "*.dockerfile" -o -name "Dockerfile" \) -not -path "*/partials/*")
}

@test "base.dockerfile has FROM instruction" {
  local file="${TEMPLATES_DIR}/base.dockerfile"
  [ -f "$file" ] || skip "base.dockerfile not found"

  grep -qi "^FROM " "$file"
}

@test "Dockerfile partials are fragments: no FROM, and only build instructions" {
  local partials_dir="${TEMPLATES_DIR}/partials"
  [ -d "$partials_dir" ] || skip "partials directory not found"

  while IFS= read -r dockerfile; do
    # A FROM would start a new stage and drop everything base.dockerfile built
    if grep -qi "^FROM " "$dockerfile"; then
      echo "Partial must not contain FROM (it is appended to base.dockerfile): $dockerfile" >&2
      return 1
    fi
    grep -qiE "^(RUN|COPY|ENV|WORKDIR|USER) " "$dockerfile" || {
      echo "No build instructions found in: $dockerfile" >&2
      return 1
    }
  done < <(find "$partials_dir" -name "*.dockerfile")
}

@test "Dockerfile partials only copy from stages defined in base.dockerfile" {
  local base="${TEMPLATES_DIR}/base.dockerfile"
  local stage
  while IFS= read -r stage; do
    grep -qiE "^FROM .* AS ${stage}$" "$base" || {
      echo "Partial uses --from=${stage}, but base.dockerfile defines no stage '${stage}'" >&2
      return 1
    }
  done < <(grep -ho -- '--from=[A-Za-z0-9_-]*' "${TEMPLATES_DIR}"/partials/*.dockerfile | cut -d= -f2 | sort -u)
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

@test "devcontainer.json is valid JSONC once placeholders are filled" {
  require_command python3
  local file="${TEMPLATES_DIR}/devcontainer.json"
  [ -f "$file" ] || skip "devcontainer.json not found"

  render_jsonc_template "$file" | jq empty || {
    echo "Invalid JSON in devcontainer.json (after removing comments and filling placeholders)" >&2
    return 1
  }
}

@test "devcontainer.json has required fields" {
  require_command python3
  local file="${TEMPLATES_DIR}/devcontainer.json"
  [ -f "$file" ] || skip "devcontainer.json not found"

  local rendered field value
  rendered=$(render_jsonc_template "$file")
  for field in name dockerComposeFile service workspaceFolder remoteUser; do
    value=$(echo "$rendered" | jq -r --arg f "$field" '.[$f] // empty')
    [ -n "$value" ] || { echo "devcontainer.json missing '$field'" >&2; return 1; }
  done
}

@test "all devcontainer.json variants are valid JSONC once placeholders are filled" {
  require_command jq
  require_command python3

  local count=0
  while IFS= read -r devcontainer_file; do
    render_jsonc_template "$devcontainer_file" | jq empty || {
      echo "Invalid JSON in: $devcontainer_file" >&2
      return 1
    }
    count=$((count + 1))
  done < <(find "$TEMPLATES_DIR" -name "devcontainer*.json")
  [ "$count" -gt 0 ]
}

@test "render_jsonc_template keeps // inside strings (URLs)" {
  require_command python3
  local tmp="${BATS_TEST_TMPDIR}/sample.jsonc"
  printf '{\n  // comment\n  "url": "https://example.com/a", /* block */\n  "port": {{APP_PORT}},\n}\n' > "$tmp"
  run bash -c "source '${PLUGIN_ROOT}/tests/helpers/test_helper.bash'; render_jsonc_template '$tmp' | jq -c ."
  [ "$status" -eq 0 ]
  [ "$output" = '{"url":"https://example.com/a","port":8000}' ]
}

# ============================================================================
# MCP configuration validation
# ============================================================================

@test "mcp.json is valid JSON" {
  local file="${TEMPLATES_DIR}/mcp.json"
  [ -f "$file" ] || skip "mcp.json not found"

  assert_valid_json "$file"
}

@test "mcp.json: every server under .servers has a command" {
  # NOTE: the template uses the `servers` key (VS Code mcp.json format), not
  # Claude Code's `.mcp.json` `mcpServers` key. Setup doesn't copy this file
  # anywhere today; see the issue linked in the #380 PR.
  local file="${TEMPLATES_DIR}/mcp.json"
  [ -f "$file" ] || skip "mcp.json not found"

  run jq -r '.servers | type' "$file"
  [ "$output" = "object" ]
  run jq -r '[.servers | to_entries[] | select((.value.command // .value.url // "") == "") | .key] | join(",")' "$file"
  [ -z "$output" ] || { echo "Servers without command/url: $output" >&2; return 1; }
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

@test "no template files contain leftover TODO/FIXME/XXX markers" {
  # Markers look like `TODO:` / `FIXME(...)`; product names such as the
  # "TODO Highlight" VS Code extension are not markers.
  local hits
  hits=$(grep -rnE '\b(TODO|FIXME|XXX)[:(]|\bPLACEHOLDER\b' "$TEMPLATES_DIR" \
    --include="*.json" --include="*.yml" --include="*.yaml" 2>/dev/null || true)
  [ -z "$hits" ] || { echo "Leftover markers in templates:" >&2; echo "$hits" >&2; return 1; }
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

# ============================================================================
# Placeholder consistency validation
# ============================================================================

@test "yolo-docker-maxxing.sh leaves no {{PLACEHOLDERS}} in generated files (normal and portless)" {
  # The sed step moved from commands/yolo-docker-maxxing.md to
  # scripts/yolo-docker-maxxing.sh, so run the real script instead of grepping.
  local mode dir leftover
  for mode in normal portless; do
    dir="${BATS_TEST_TMPDIR}/yolo-${mode}"
    mkdir -p "$dir"
    (cd "$dir" && git init -q)
    if [ "$mode" = portless ]; then
      run bash -c "cd '$dir' && CLAUDE_PLUGIN_ROOT='${PLUGIN_ROOT}' bash '${PLUGIN_ROOT}/scripts/yolo-docker-maxxing.sh' --portless placeholder-check"
    else
      run bash -c "cd '$dir' && CLAUDE_PLUGIN_ROOT='${PLUGIN_ROOT}' bash '${PLUGIN_ROOT}/scripts/yolo-docker-maxxing.sh' placeholder-check"
    fi
    [ "$status" -eq 0 ] || { echo "yolo ($mode) failed: $output" >&2; return 1; }

    leftover=$(grep -rnoE '\{\{[A-Z_]+\}\}' "$dir/.devcontainer" "$dir/docker-compose.yml" || true)
    [ -z "$leftover" ] || { echo "Unreplaced placeholders ($mode):" >&2; echo "$leftover" >&2; return 1; }
  done
}

@test "all placeholders in devcontainer.json have sed replacements in quickstart" {
  local template="${TEMPLATES_DIR}/devcontainer.json"
  local command="${PLUGIN_ROOT}/commands/quickstart.md"

  [ -f "$template" ] || skip "devcontainer.json not found"
  [ -f "$command" ] || skip "quickstart.md not found"

  # Extract placeholders from template
  local placeholders
  placeholders=$(grep -oh '{{[A-Z_]*}}' "$template" | sort -u)

  # quickstart handles all placeholders, either in sed or conditional injection
  # Expected: PROJECT_NAME, APP_PORT, FRONTEND_PORT, POSTGRES_PORT, REDIS_PORT
  # (KROKI placeholders were removed from template, handled conditionally in quickstart)
  local expected_placeholders=("PROJECT_NAME" "APP_PORT" "FRONTEND_PORT" "POSTGRES_PORT" "REDIS_PORT")

  for placeholder in "${expected_placeholders[@]}"; do
    grep -q "{{$placeholder}}" "$template" || continue

    # Check placeholder appears somewhere in quickstart command
    grep -q "$placeholder" "$command" || {
      echo "Missing reference to {{$placeholder}} in quickstart.md" >&2
      return 1
    }
  done
}

# ============================================================================
# AWS credentials mount validation
# ============================================================================

@test "devcontainer.json: includes AWS credentials mount" {
  local template="$PLUGIN_ROOT/skills/_shared/templates/devcontainer.json"
  [ -f "$template" ]

  # Check for AWS mount
  grep -q '\${localEnv:HOME}\${localEnv:USERPROFILE}/\.aws' "$template"
  grep -q 'target=/home/node/\.aws' "$template"
}

@test "devcontainer.portless.json: includes AWS credentials mount" {
  local template="$PLUGIN_ROOT/skills/_shared/templates/devcontainer.portless.json"
  [ -f "$template" ]

  # Check for AWS mount
  grep -q '\${localEnv:HOME}\${localEnv:USERPROFILE}/\.aws' "$template"
  grep -q 'target=/home/node/\.aws' "$template"
}
