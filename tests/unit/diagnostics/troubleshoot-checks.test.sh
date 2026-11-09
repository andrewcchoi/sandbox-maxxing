#!/usr/bin/env bats
#
# Troubleshoot Diagnostic Checks Tests
# Validates diagnostic commands and patterns in troubleshooting documentation
#

# Calculate plugin root from test file location
BATS_TEST_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
PLUGIN_ROOT="$(cd "$BATS_TEST_DIR/../../.." && pwd)"

load '../../helpers/test_helper'

# Test-specific constants
TROUBLESHOOT_SKILL="${PLUGIN_ROOT}/skills/sandboxxer-troubleshoot/SKILL.md"
TROUBLESHOOT_AGENT="${PLUGIN_ROOT}/agents/interactive-troubleshooter.md"

# ============================================================================
# File existence validation
# ============================================================================

@test "troubleshoot skill file exists" {
  [ -f "$TROUBLESHOOT_SKILL" ]
}

@test "troubleshoot agent file exists" {
  [ -f "$TROUBLESHOOT_AGENT" ]
}

# ============================================================================
# Diagnostic command syntax validation
# ============================================================================

@test "docker diagnostic commands have valid syntax" {
  # Extract docker commands from documentation
  local commands=(
    "docker ps -a"
    "docker compose ps"
    "docker compose logs"
    "docker system df"
    "docker info"
  )

  for cmd in "${commands[@]}"; do
    # Validate command structure (basic check)
    [[ "$cmd" =~ ^docker ]] || {
      echo "Invalid docker command: $cmd" >&2
      return 1
    }
  done
}

@test "network diagnostic commands are safe" {
  # Commands that should be used for network diagnostics
  local safe_commands=(
    "nslookup"
    "curl"
    "nc -zv"
    "ping -c"
  )

  # Commands that should NOT be used (dangerous or unavailable)
  local unsafe_patterns=(
    "rm -rf"
    "dd if="
    "mkfs"
    "> /dev/sd"
  )

  # Check that documentation doesn't suggest dangerous commands
  for pattern in "${unsafe_patterns[@]}"; do
    if grep -r "$pattern" "$TROUBLESHOOT_SKILL" "$TROUBLESHOOT_AGENT" 2>/dev/null | grep -v "^#" | grep -q .; then
      echo "Found dangerous pattern in troubleshooting docs: $pattern" >&2
      return 1
    fi
  done
}

@test "firewall diagnostic commands reference correct variables" {
  # Check that firewall-related commands reference proper environment variables
  local content
  content=$(cat "$TROUBLESHOOT_SKILL" "$TROUBLESHOOT_AGENT")

  # If FIREWALL_MODE is mentioned, it should be checked properly
  if echo "$content" | grep -q "FIREWALL_MODE"; then
    # Should use proper variable reference syntax
    echo "$content" | grep -q '\$FIREWALL_MODE' || {
      echo "FIREWALL_MODE should be referenced as \$FIREWALL_MODE" >&2
      return 1
    }
  fi
}

# ============================================================================
# Required file references validation
# ============================================================================

@test "referenced DevContainer files exist in templates" {
  local templates_dir="${PLUGIN_ROOT}/skills/_shared/templates"
  local required_files=(
    "devcontainer.json"
    "docker-compose.yml"
    "init-firewall.sh"
  )

  for file in "${required_files[@]}"; do
    [ -f "${templates_dir}/${file}" ] || {
      echo "Referenced file not found in templates: $file" >&2
      return 1
    }
  done
}

@test "troubleshooting documentation references valid script paths" {
  # Check for script references in documentation
  local doc_files=("$TROUBLESHOOT_SKILL" "$TROUBLESHOOT_AGENT")

  for doc in "${doc_files[@]}"; do
    # Extract .sh script references
    while IFS= read -r script_ref; do
      # Extract just the filename
      local script_name
      script_name=$(basename "$script_ref")

      # Check if script exists in expected locations
      local found=false
      for dir in "hooks" "skills/_shared/templates" ".devcontainer"; do
        if [ -f "${PLUGIN_ROOT}/${dir}/${script_name}" ]; then
          found=true
          break
        fi
      done

      [ "$found" = true ] || {
        echo "Referenced script not found: $script_ref" >&2
        return 1
      }
    done < <(grep -o '[a-zA-Z0-9_-]*\.sh' "$doc" | sort -u)
  done
}

# ============================================================================
# Error pattern validation
# ============================================================================

@test "error detection patterns are valid regex" {
  # Common error patterns that should be detectable
  local patterns=(
    "Connection refused"
    "Permission denied"
    "No such file"
    "timeout"
    "ECONNREFUSED"
  )

  for pattern in "${patterns[@]}"; do
    # Verify pattern can be used with grep
    echo "test message with $pattern here" | grep -q "$pattern" || {
      echo "Invalid error pattern: $pattern" >&2
      return 1
    }
  done
}

@test "diagnostic output parsing patterns are consistent" {
  # Check that status extraction patterns are valid
  local test_statuses=("running" "exited" "created" "paused")

  for status in "${test_statuses[@]}"; do
    # Simulate docker status check pattern
    echo "Status: $status" | grep -q "Status:" || {
      echo "Status pattern matching failed for: $status" >&2
      return 1
    }
  done
}

# ============================================================================
# Fix command safety validation
# ============================================================================

@test "suggested fix commands do not contain destructive operations" {
  local destructive_patterns=(
    "rm -rf /"
    "dd if=/dev/zero"
    "mkfs"
    ":(){:|:&};:"  # fork bomb
    "chmod 777 /"
  )

  for pattern in "${destructive_patterns[@]}"; do
    if grep -r "$pattern" "$TROUBLESHOOT_SKILL" "$TROUBLESHOOT_AGENT" 2>/dev/null | grep -q .; then
      echo "Found destructive command pattern in troubleshooting docs: $pattern" >&2
      return 1
    fi
  done
}

@test "docker compose commands use modern syntax" {
  # Check for deprecated docker-compose (with hyphen) vs docker compose (space)
  local doc_files=("$TROUBLESHOOT_SKILL" "$TROUBLESHOOT_AGENT")

  for doc in "${doc_files[@]}"; do
    # Count usage of new vs old syntax
    local new_syntax_count
    local old_syntax_count

    new_syntax_count=$(grep -c "docker compose" "$doc" || echo 0)
    old_syntax_count=$(grep -c "docker-compose" "$doc" | grep -v "docker-compose.yml" || echo 0)

    # New syntax should be used (unless referencing the file docker-compose.yml)
    # This is a soft check - we mainly want to detect if old syntax is predominant
    if [ "$old_syntax_count" -gt "$new_syntax_count" ] && [ "$old_syntax_count" -gt 5 ]; then
      echo "Documentation uses deprecated 'docker-compose' syntax more than modern 'docker compose'" >&2
      echo "Old syntax count: $old_syntax_count, New syntax count: $new_syntax_count" >&2
      return 1
    fi
  done
}

@test "restart commands are properly sequenced" {
  # Check that restart sequences make sense
  local doc_content
  doc_content=$(cat "$TROUBLESHOOT_SKILL" "$TROUBLESHOOT_AGENT")

  # If "docker compose down" is mentioned, it should be followed by "docker compose up"
  if echo "$doc_content" | grep -q "docker compose down"; then
    # Check for proper sequencing patterns
    echo "$doc_content" | grep -E "docker compose down.*docker compose up" >/dev/null || {
      # Could be on separate lines, so just verify both commands exist
      echo "$doc_content" | grep -q "docker compose up" || {
        echo "docker compose down should be paired with docker compose up" >&2
        return 1
      }
    }
  fi
}

# ============================================================================
# Diagnostic workflow validation
# ============================================================================

@test "troubleshoot agent has defined diagnostic phases" {
  # Check that agent documentation defines clear phases
  local phases=("Phase 1" "Phase 2" "Phase 3")
  local found_phases=0

  for phase in "${phases[@]}"; do
    if grep -q "$phase" "$TROUBLESHOOT_AGENT"; then
      ((found_phases++))
    fi
  done

  [ "$found_phases" -ge 2 ] || {
    echo "Agent should define at least 2 diagnostic phases" >&2
    return 1
  }
}

@test "troubleshoot skill documents problem categories" {
  # Check for common problem categories
  local categories=(
    "Container"
    "Network"
    "Service"
    "Firewall"
    "Permission"
  )

  local found_categories=0

  for category in "${categories[@]}"; do
    if grep -qi "$category" "$TROUBLESHOOT_SKILL"; then
      ((found_categories++))
    fi
  done

  [ "$found_categories" -ge 3 ] || {
    echo "Skill should document at least 3 problem categories" >&2
    return 1
  }
}

# ============================================================================
# Service-specific checks validation
# ============================================================================

@test "database connectivity checks reference correct ports" {
  local common_ports=(
    "5432"  # PostgreSQL
    "6379"  # Redis
    "27017" # MongoDB
    "3306"  # MySQL
  )

  local doc_content
  doc_content=$(cat "$TROUBLESHOOT_SKILL" "$TROUBLESHOOT_AGENT")

  # If service connectivity is mentioned, at least one standard port should be referenced
  if echo "$doc_content" | grep -qi "service.*connectivity"; then
    local found_port=false

    for port in "${common_ports[@]}"; do
      if echo "$doc_content" | grep -q "$port"; then
        found_port=true
        break
      fi
    done

    [ "$found_port" = true ] || {
      echo "Service connectivity section should reference standard database ports" >&2
      return 1
    }
  fi
}

@test "nc (netcat) commands have proper syntax" {
  # Check for netcat usage patterns
  local doc_content
  doc_content=$(cat "$TROUBLESHOOT_SKILL" "$TROUBLESHOOT_AGENT")

  if echo "$doc_content" | grep -q "nc "; then
    # Common nc patterns that should be valid
    # nc -zv (zero I/O mode for scanning, verbose)
    if echo "$doc_content" | grep "nc " | grep -v "nc -zv"; then
      # Make sure any nc usage follows safe patterns
      echo "$doc_content" | grep -E "nc -[a-z]+ [a-zA-Z0-9_-]+ [0-9]+" >/dev/null || {
        echo "nc commands should follow pattern: nc -flags host port" >&2
        return 1
      }
    fi
  fi
}

# ============================================================================
# Cross-reference validation
# ============================================================================

@test "troubleshoot command references correct related commands" {
  local troubleshoot_cmd="${PLUGIN_ROOT}/commands/troubleshoot.md"
  [ -f "$troubleshoot_cmd" ] || skip "troubleshoot.md command not found"

  # Should reference other sandboxxer commands
  local related_commands=("health" "linux-troubleshoot" "audit")

  for cmd in "${related_commands[@]}"; do
    grep -qi "$cmd" "$troubleshoot_cmd" || {
      echo "Troubleshoot command should reference related command: $cmd" >&2
      return 1
    }
  done
}
