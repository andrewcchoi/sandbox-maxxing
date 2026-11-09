#!/usr/bin/env bats
#
# Frontmatter Validation Tests
# Validates YAML frontmatter in commands, agents, and skills
#

# Calculate plugin root from test file location
BATS_TEST_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
PLUGIN_ROOT="$(cd "$BATS_TEST_DIR/../../.." && pwd)"

load '../../helpers/test_helper'

# ============================================================================
# Commands frontmatter validation
# ============================================================================

@test "all command files have frontmatter" {
  local commands_dir="${PLUGIN_ROOT}/commands"

  # Find all .md files except README
  while IFS= read -r cmd_file; do
    # Check for frontmatter delimiters
    local frontmatter_count
    frontmatter_count=$(grep -c '^---$' "$cmd_file" || true)

    [ "$frontmatter_count" -ge 2 ] || {
      echo "Missing frontmatter in: $cmd_file" >&2
      return 1
    }
  done < <(find "$commands_dir" -name "*.md" -not -name "README.md")
}

@test "all command files have required field: description" {
  local commands_dir="${PLUGIN_ROOT}/commands"

  while IFS= read -r cmd_file; do
    assert_frontmatter_has "$cmd_file" "description"
  done < <(find "$commands_dir" -name "*.md" -not -name "README.md")
}

@test "command files have valid allowed-tools array format" {
  local commands_dir="${PLUGIN_ROOT}/commands"

  while IFS= read -r cmd_file; do
    # Extract frontmatter and check if allowed-tools exists
    local frontmatter
    frontmatter=$(sed -n '/^---$/,/^---$/p' "$cmd_file" | sed '1d;$d')

    if echo "$frontmatter" | grep -q "allowed-tools:"; then
      # Validate it's an array
      local tools_value
      tools_value=$(echo "$frontmatter" | yq eval '.["allowed-tools"] | type' - 2>/dev/null)

      if [ "$tools_value" != "null" ]; then
        [ "$tools_value" = "!!seq" ] || {
          echo "allowed-tools must be an array in: $cmd_file" >&2
          return 1
        }
      fi
    fi
  done < <(find "$commands_dir" -name "*.md" -not -name "README.md")
}

# ============================================================================
# Agents frontmatter validation
# ============================================================================

@test "all agent files have frontmatter" {
  local agents_dir="${PLUGIN_ROOT}/agents"

  while IFS= read -r agent_file; do
    local frontmatter_count
    frontmatter_count=$(grep -c '^---$' "$agent_file" || true)

    [ "$frontmatter_count" -ge 2 ] || {
      echo "Missing frontmatter in: $agent_file" >&2
      return 1
    }
  done < <(find "$agents_dir" -name "*.md" -not -name "README.md")
}

@test "all agent files have required field: name" {
  local agents_dir="${PLUGIN_ROOT}/agents"

  while IFS= read -r agent_file; do
    assert_frontmatter_has "$agent_file" "name"
  done < <(find "$agents_dir" -name "*.md" -not -name "README.md")
}

@test "all agent files have required field: role" {
  local agents_dir="${PLUGIN_ROOT}/agents"

  while IFS= read -r agent_file; do
    assert_frontmatter_has "$agent_file" "role"
  done < <(find "$agents_dir" -name "*.md" -not -name "README.md")
}

@test "all agent files have required field: model" {
  local agents_dir="${PLUGIN_ROOT}/agents"

  while IFS= read -r agent_file; do
    assert_frontmatter_has "$agent_file" "model"
  done < <(find "$agents_dir" -name "*.md" -not -name "README.md")
}

@test "all agent files have required field: tools array" {
  local agents_dir="${PLUGIN_ROOT}/agents"

  while IFS= read -r agent_file; do
    # Extract frontmatter
    local frontmatter
    frontmatter=$(sed -n '/^---$/,/^---$/p' "$agent_file" | sed '1d;$d')

    # Check tools field exists
    local tools_value
    tools_value=$(echo "$frontmatter" | yq eval '.tools | type' - 2>/dev/null)

    [ "$tools_value" = "!!seq" ] || {
      echo "Missing or invalid tools array in: $agent_file" >&2
      return 1
    }
  done < <(find "$agents_dir" -name "*.md" -not -name "README.md")
}

@test "agent model values are valid" {
  local agents_dir="${PLUGIN_ROOT}/agents"
  local valid_models="sonnet opus haiku"

  while IFS= read -r agent_file; do
    local frontmatter
    frontmatter=$(sed -n '/^---$/,/^---$/p' "$agent_file" | sed '1d;$d')

    local model
    model=$(echo "$frontmatter" | yq eval '.model' - 2>/dev/null)

    if [ "$model" != "null" ]; then
      if ! echo "$valid_models" | grep -qw "$model"; then
        echo "Invalid model '$model' in: $agent_file" >&2
        echo "Valid models: $valid_models" >&2
        return 1
      fi
    fi
  done < <(find "$agents_dir" -name "*.md" -not -name "README.md")
}

@test "agent color values are valid if specified" {
  local agents_dir="${PLUGIN_ROOT}/agents"
  local valid_colors="blue green yellow red purple orange pink gray"

  while IFS= read -r agent_file; do
    local frontmatter
    frontmatter=$(sed -n '/^---$/,/^---$/p' "$agent_file" | sed '1d;$d')

    local color
    color=$(echo "$frontmatter" | yq eval '.color' - 2>/dev/null)

    if [ "$color" != "null" ]; then
      if ! echo "$valid_colors" | grep -qw "$color"; then
        echo "Invalid color '$color' in: $agent_file" >&2
        echo "Valid colors: $valid_colors" >&2
        return 1
      fi
    fi
  done < <(find "$agents_dir" -name "*.md" -not -name "README.md")
}

# ============================================================================
# Skills frontmatter validation
# ============================================================================

@test "all skill SKILL.md files have frontmatter" {
  local skills_dir="${PLUGIN_ROOT}/skills"

  while IFS= read -r skill_file; do
    local frontmatter_count
    frontmatter_count=$(grep -c '^---$' "$skill_file" || true)

    [ "$frontmatter_count" -ge 2 ] || {
      echo "Missing frontmatter in: $skill_file" >&2
      return 1
    }
  done < <(find "$skills_dir" -name "SKILL.md")
}

@test "all skill files have required field: name" {
  local skills_dir="${PLUGIN_ROOT}/skills"

  while IFS= read -r skill_file; do
    assert_frontmatter_has "$skill_file" "name"
  done < <(find "$skills_dir" -name "SKILL.md")
}

@test "all skill files have required field: description" {
  local skills_dir="${PLUGIN_ROOT}/skills"

  while IFS= read -r skill_file; do
    assert_frontmatter_has "$skill_file" "description"
  done < <(find "$skills_dir" -name "SKILL.md")
}

@test "all skill files have required field: whenToUse" {
  local skills_dir="${PLUGIN_ROOT}/skills"

  while IFS= read -r skill_file; do
    assert_frontmatter_has "$skill_file" "whenToUse"
  done < <(find "$skills_dir" -name "SKILL.md")
}

@test "skill name matches directory name" {
  local skills_dir="${PLUGIN_ROOT}/skills"

  while IFS= read -r skill_file; do
    # Get directory name
    local dir_name
    dir_name=$(basename "$(dirname "$skill_file")")

    # Skip _shared directory
    [ "$dir_name" = "_shared" ] && continue

    # Extract skill name from frontmatter
    local frontmatter
    frontmatter=$(sed -n '/^---$/,/^---$/p' "$skill_file" | sed '1d;$d')

    local skill_name
    skill_name=$(echo "$frontmatter" | yq eval '.name' - 2>/dev/null)

    [ "$skill_name" = "$dir_name" ] || {
      echo "Skill name '$skill_name' doesn't match directory '$dir_name' in: $skill_file" >&2
      return 1
    }
  done < <(find "$skills_dir" -name "SKILL.md")
}

# ============================================================================
# General frontmatter format validation
# ============================================================================

@test "all frontmatter blocks are valid YAML" {
  local components=("commands" "agents")

  for component in "${components[@]}"; do
    local component_dir="${PLUGIN_ROOT}/${component}"

    while IFS= read -r file; do
      # Extract frontmatter
      local frontmatter
      frontmatter=$(sed -n '/^---$/,/^---$/p' "$file" | sed '1d;$d')

      # Validate YAML syntax
      if [ -n "$frontmatter" ]; then
        echo "$frontmatter" | yq eval '.' - >/dev/null 2>&1 || {
          echo "Invalid YAML frontmatter in: $file" >&2
          return 1
        }
      fi
    done < <(find "$component_dir" -name "*.md" -not -name "README.md")
  done

  # Validate skills separately
  local skills_dir="${PLUGIN_ROOT}/skills"
  while IFS= read -r skill_file; do
    local frontmatter
    frontmatter=$(sed -n '/^---$/,/^---$/p' "$skill_file" | sed '1d;$d')

    if [ -n "$frontmatter" ]; then
      echo "$frontmatter" | yq eval '.' - >/dev/null 2>&1 || {
        echo "Invalid YAML frontmatter in: $skill_file" >&2
        return 1
      }
    fi
  done < <(find "$skills_dir" -name "SKILL.md")
}
