#!/usr/bin/env bash
#
# Common utility functions for sandbox-maxxing plugin commands
# Source this file in command scripts: source "${PLUGIN_ROOT}/scripts/common.sh"
#
# Extracted from duplicate code in:
# - commands/yolo-docker-maxxing.md (normal + portless modes)
# - commands/quickstart.md
#

# ============================================================================
# Project Name Sanitization
# ============================================================================
# Converts project names to Docker-safe format:
# - Lowercase only
# - Replace non-alphanumeric with hyphens
# - Strip leading/trailing hyphens
# - Collapse multiple hyphens
# - Default to "sandbox-app" if empty
#
# Usage: PROJECT_NAME=$(sanitize_project_name "$RAW_NAME")
# ============================================================================
sanitize_project_name() {
  local name="$1"
  local sanitized

  # Convert to lowercase, replace non-alphanumeric with hyphens
  sanitized=$(echo "$name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')

  # Strip leading/trailing hyphens, collapse multiple hyphens
  sanitized=$(echo "$sanitized" | sed 's/^-*//;s/-*$//;s/--*/-/g')

  # Default if empty
  [ -z "$sanitized" ] && sanitized="sandbox-app"

  echo "$sanitized"
}

# ============================================================================
# Environment File Merging
# ============================================================================
# Safely updates or adds key=value pairs in .env files
# Handles special characters (|, &, \, etc.) correctly using awk
# If key exists: updates value
# If key missing: appends key=value
#
# Usage: merge_env_value "KEY" "value" ".env"
#
# Returns: 0 on success, 1 on failure
# ============================================================================
merge_env_value() {
  local key="$1"
  local value="$2"
  local target_file="$3"

  # Escape key for regex matching
  local escaped_key
  escaped_key=$(printf '%s' "$key" | sed 's/[.[\*^$()+?{|\\]/\\&/g')

  # Check if key exists in file
  if grep -q "^${escaped_key}=" "$target_file" 2>/dev/null; then
    # Update existing key
    awk -v key="$key" -v val="$value" '
      BEGIN { FS="="; OFS="=" }
      $1 == key { $0 = key "=" val }
      { print }
    ' "$target_file" > "${target_file}.tmp"

    # Validate output and replace
    if [ -s "${target_file}.tmp" ]; then
      mv "${target_file}.tmp" "$target_file"
    else
      rm -f "${target_file}.tmp"
      return 1
    fi
  else
    # Append new key
    # Ensure trailing newline before appending (handles CRLF and edge cases)
    if [ -f "$target_file" ] && [ -s "$target_file" ]; then
      # Check if file ends with newline (works for both LF and CRLF)
      if [ "$(tail -c 1 "$target_file" | wc -l)" -eq 0 ]; then
        echo "" >> "$target_file"
      fi
    fi
    printf '%s=%s\n' "$key" "$value" >> "$target_file"
  fi
}

# ============================================================================
# Port Availability Check
# ============================================================================
# Checks if a TCP port is in use on the local system
# Uses multiple tools with fallback: lsof > ss > netstat
#
# Usage: if port_in_use 8000; then echo "busy"; fi
#
# Returns: 0 if port is in use, 1 if port is free
# ============================================================================
port_in_use() {
  local port=$1

  # Validate port is numeric
  if ! [[ "$port" =~ ^[0-9]+$ ]]; then
    echo "ERROR: port_in_use: invalid port '$port' (must be numeric)" >&2
    return 2
  fi

  # Try lsof first (most reliable)
  if command -v lsof >/dev/null 2>&1; then
    lsof -i ":$port" >/dev/null 2>&1 && return 0
  fi

  # Try ss (modern netstat replacement)
  if command -v ss >/dev/null 2>&1; then
    ss -tuln 2>/dev/null | grep -q ":$port " && return 0
  fi

  # Try netstat (legacy but widely available)
  if command -v netstat >/dev/null 2>&1; then
    netstat -tuln 2>/dev/null | grep -q ":$port " && return 0
  fi

  # Can't determine, assume free (fail-safe)
  return 1
}

# ============================================================================
# Find Available Port
# ============================================================================
# Finds the next available TCP port starting from a given port
# Excludes already-assigned ports to avoid conflicts
#
# Usage: APP_PORT=$(find_available_port 8000)
#        POSTGRES_PORT=$(find_available_port 5432 "$APP_PORT" "$FRONTEND_PORT")
#
# Args:
#   $1: Starting port number
#   $@: List of ports to exclude (already assigned)
#
# Returns: Prints available port number, exits 1 if none found
# ============================================================================
find_available_port() {
  local port=$1
  shift
  local exclude=("$@")
  local max_port=65535

  while [ $port -le $max_port ]; do
    # Skip excluded ports
    local skip=false
    for ex in "${exclude[@]}"; do
      [ "$port" = "$ex" ] && { skip=true; break; }
    done
    $skip && { port=$((port + 1)); continue; }

    # Check if port is available
    if ! port_in_use "$port"; then
      echo "$port"
      return 0
    fi

    port=$((port + 1))
  done

  echo "ERROR: No available port found starting from $1" >&2
  return 1
}

# ============================================================================
# Find Plugin Root Directory
# ============================================================================
# Locates the plugin root directory by searching for plugin.json
# Handles both development (current dir) and installed (~/.claude/plugins) cases
# Supports .claude-plugin/ subdirectory structure
# Handles Windows paths (backslash to forward slash conversion)
#
# Usage: PLUGIN_ROOT=$(find_plugin_root) || { echo "ERROR"; exit 1; }
#
# Environment Variables:
#   CLAUDE_PLUGIN_ROOT: If set, uses this path directly
#
# Returns: Prints plugin root path, exits 1 if not found
# ============================================================================
find_plugin_root() {
  local plugin_root=""

  # Disable history expansion (fixes ! in Windows paths)
  set +H 2>/dev/null || true

  # 1. Check CLAUDE_PLUGIN_ROOT environment variable
  if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ]; then
    # Handle Windows paths - convert backslashes to forward slashes
    plugin_root="${CLAUDE_PLUGIN_ROOT//\\//}"
    echo "Using CLAUDE_PLUGIN_ROOT: $plugin_root" >&2
    echo "$plugin_root"
    return 0
  fi

  # 2. Check if running from plugin directory (development mode)
  if [ -f "skills/_shared/templates/base.dockerfile" ]; then
    plugin_root="."
    echo "Using current directory as plugin root" >&2
    echo "$plugin_root"
    return 0
  fi

  # 3. Search ~/.claude/plugins for installed plugin
  if [ -d "$HOME/.claude/plugins" ]; then
    echo "Searching ~/.claude/plugins..." >&2

    # Find plugin.json with correct plugin name
    local plugin_json
    plugin_json=$(find "$HOME/.claude/plugins" -type f -name "plugin.json" \
      -exec grep -l '"name".*:.*"sandboxxer"' {} \; 2>/dev/null | head -1)

    if [ -n "$plugin_json" ]; then
      local plugin_dir
      plugin_dir=$(dirname "$plugin_json")

      # Handle both root plugin.json and .claude-plugin/plugin.json
      if [ "$(basename "$plugin_dir")" = ".claude-plugin" ]; then
        plugin_root=$(dirname "$plugin_dir")
      else
        plugin_root="$plugin_dir"
      fi

      echo "Found installed plugin: $plugin_root" >&2
      echo "$plugin_root"
      return 0
    fi
  fi

  # 4. Not found
  echo "ERROR: Cannot locate plugin root directory" >&2
  echo "  Searched:" >&2
  echo "    - CLAUDE_PLUGIN_ROOT environment variable" >&2
  echo "    - Current directory (development mode)" >&2
  echo "    - ~/.claude/plugins (installed mode)" >&2
  return 1
}

# ============================================================================
# Validate Plugin Templates
# ============================================================================
# Verifies all required template files exist in the plugin
# Should be called after find_plugin_root()
#
# Usage: validate_templates "$PLUGIN_ROOT" || exit 1
#
# Args:
#   $1: Plugin root directory
#   $@: List of required template filenames (relative to templates dir)
#
# Returns: 0 if all templates exist, 1 if any missing
# ============================================================================
validate_templates() {
  local plugin_root="$1"
  shift
  local templates_dir="${plugin_root}/skills/_shared/templates"
  local missing=0

  for tmpl in "$@"; do
    if [ ! -f "${templates_dir}/${tmpl}" ]; then
      echo "ERROR: Missing template: ${templates_dir}/${tmpl}" >&2
      missing=1
    fi
  done

  return $missing
}

# ============================================================================
# Read Plugin Settings
# ============================================================================
# Reads a setting from .claude/sandboxxer.local.md
# Settings are stored in YAML frontmatter format
#
# Usage: VALUE=$(read_setting "default_firewall" "disabled")
#
# Args:
#   $1: Setting name (e.g., "default_firewall")
#   $2: Default value if setting not found
#
# Returns: Prints setting value, or default if not found
# ============================================================================
read_setting() {
  local setting_name="$1"
  local default_value="${2:-}"
  local settings_file=".claude/sandboxxer.local.md"

  # Check if settings file exists
  if [ ! -f "$settings_file" ]; then
    echo "$default_value"
    return 0
  fi

  # Extract YAML frontmatter (between --- markers) and find setting
  local value
  value=$(sed -n '/^---$/,/^---$/p' "$settings_file" 2>/dev/null | \
          grep "^${setting_name}:" | \
          head -1 | \
          cut -d: -f2- | \
          sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | \
          tr -d '"'"'")

  # Return value or default
  if [ -n "$value" ]; then
    echo "$value"
  else
    echo "$default_value"
  fi
}

# ============================================================================
# Read Nested Plugin Settings
# ============================================================================
# Reads a nested setting from .claude/sandboxxer.local.md
# For settings like default_ports.app
#
# Usage: PORT=$(read_nested_setting "default_ports" "app" "8000")
#
# Args:
#   $1: Parent setting name
#   $2: Child setting name
#   $3: Default value if setting not found
#
# Returns: Prints setting value, or default if not found
# ============================================================================
read_nested_setting() {
  local parent="$1"
  local child="$2"
  local default_value="${3:-}"
  local settings_file=".claude/sandboxxer.local.md"

  if [ ! -f "$settings_file" ]; then
    echo "$default_value"
    return 0
  fi

  # Look for indented child setting under parent
  local value
  value=$(sed -n '/^---$/,/^---$/p' "$settings_file" 2>/dev/null | \
          sed -n "/^${parent}:/,/^[a-z]/p" | \
          grep "^[[:space:]]*${child}:" | \
          head -1 | \
          cut -d: -f2- | \
          sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | \
          tr -d '"'"'")

  if [ -n "$value" ]; then
    echo "$value"
  else
    echo "$default_value"
  fi
}

# ============================================================================
# Read Plugin Settings List (Issue #271)
# ============================================================================
# Reads a comma-separated list setting from .claude/sandboxxer.local.md
# Handles both "a,b,c" and "[a,b,c]" YAML formats
#
# Usage: TOOLS=$(read_setting_list "default_tools" "")
#
# Args:
#   $1: Setting name (e.g., "default_tools")
#   $2: Default value if setting not found
#
# Returns: Prints comma-separated values (spaces removed)
# ============================================================================
read_setting_list() {
  local setting_name="$1"
  local default_value="${2:-}"
  local settings_file=".claude/sandboxxer.local.md"

  # Check if settings file exists
  if [ ! -f "$settings_file" ]; then
    echo "$default_value"
    return 0
  fi

  # Extract YAML frontmatter and find setting
  local value
  value=$(sed -n '/^---$/,/^---$/p' "$settings_file" 2>/dev/null | \
          grep "^${setting_name}:" | \
          head -1 | \
          cut -d: -f2- | \
          sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | \
          tr -d '"'"'" | \
          tr -d '[]' | \
          tr -d ' ')  # Remove spaces around commas

  # Return value or default
  if [ -n "$value" ]; then
    echo "$value"
  else
    echo "$default_value"
  fi
}

# ============================================================================
# Profile to Tools Mapping (Issue #271)
# ============================================================================
# Maps quickstart profile names to comma-separated tool lists
# Used by the consolidated quickstart command for preset profiles
#
# Usage: TOOLS=$(get_profile_tools "backend")
#
# Profiles:
#   minimal   - Base only (Python 3.12 + Node 20)
#   backend   - Backend development (+ Go, PostgreSQL)
#   fullstack - Full stack (+ Go, Rust, PostgreSQL)
#   custom    - Pass-through (returns input as-is)
#
# Returns: Comma-separated tool list
# ============================================================================
get_profile_tools() {
  local profile="$1"

  case "$profile" in
    minimal|Minimal|"Minimal (Python 3.12 + Node 20)")
      echo ""
      ;;
    backend|Backend|"Backend Developer"|"Backend Developer (+ Go, PostgreSQL)")
      echo "go,postgres"
      ;;
    fullstack|"Full Stack"|"Full Stack (+ Go, Rust, PostgreSQL)")
      echo "go,rust,postgres"
      ;;
    *)
      # Custom: pass through the input (allows "go,ruby,php")
      echo "$profile"
      ;;
  esac
}

# ============================================================================
# Firewall Category Mapping (Issue #271)
# ============================================================================
# Maps firewall preset names to domain category lists
# Categories match keys in allowable-domains.json
#
# Usage: CATEGORIES=$(get_firewall_categories "essentials")
#
# Presets:
#   essentials - Package managers, version control, container registries
#   cloud      - Essentials + cloud platforms (AWS, GCP, Azure)
#   all        - All categories including analytics
#   custom     - Pass-through (returns input as-is)
#
# Returns: Comma-separated category list
# ============================================================================
get_firewall_categories() {
  local preset="$1"

  case "$preset" in
    essentials|"Development essentials"|"Development essentials (npm, PyPI, GitHub, Docker Hub)")
      echo "package_managers,version_control,container_registries,anthropic_services,linux_distributions"
      ;;
    cloud|"+ Cloud services"|"+ Cloud services (AWS, GCP, Azure)")
      echo "package_managers,version_control,container_registries,cloud_platforms,anthropic_services,linux_distributions"
      ;;
    all|"+ All categories")
      echo "package_managers,version_control,container_registries,cloud_platforms,development_tools,vscode,analytics_telemetry,anthropic_services,linux_distributions"
      ;;
    *)
      # Custom: pass through the input
      echo "$preset"
      ;;
  esac
}

# ============================================================================
# Version Information
# ============================================================================
COMMON_SH_VERSION="1.2.0"

# If sourced directly (for testing), print version
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  echo "sandbox-maxxing common.sh v${COMMON_SH_VERSION}"
  echo "This file should be sourced, not executed directly."
  echo "Usage: source ${BASH_SOURCE[0]}"
  exit 1
fi
