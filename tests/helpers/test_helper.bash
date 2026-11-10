#!/usr/bin/env bash
#
# BATS Test Helper Functions
# Provides common utilities for testing sandbox-maxxing plugin

# Setup function called before each test
setup() {
  # Create temporary directory for test isolation
  export TEST_TEMP_DIR="$(mktemp -d)"

  # Store original directory
  export ORIGINAL_DIR="$(pwd)"

  # Set up common test variables
  export PLUGIN_ROOT="${ORIGINAL_DIR}"
}

# Teardown function called after each test
teardown() {
  # Clean up temporary directory
  [ -n "${TEST_TEMP_DIR:-}" ] && rm -rf "${TEST_TEMP_DIR}"

  # Return to original directory
  [ -n "${ORIGINAL_DIR:-}" ] && cd "${ORIGINAL_DIR}"
}

# Assert a command succeeds (exit code 0)
assert_success() {
  if [ "$status" -ne 0 ]; then
    echo "Expected success (exit 0), got: $status" >&2
    echo "Output: $output" >&2
    return 1
  fi
}

# Assert a command fails (non-zero exit code)
assert_failure() {
  if [ "$status" -eq 0 ]; then
    echo "Expected failure (non-zero exit), got: $status" >&2
    echo "Output: $output" >&2
    return 1
  fi
}

# Assert output contains a string
assert_output_contains() {
  local expected="$1"
  if ! echo "$output" | grep -qF "$expected"; then
    echo "Expected output to contain: $expected" >&2
    echo "Actual output: $output" >&2
    return 1
  fi
}

# Assert output matches a regex pattern
assert_output_matches() {
  local pattern="$1"
  if ! echo "$output" | grep -qE "$pattern"; then
    echo "Expected output to match: $pattern" >&2
    echo "Actual output: $output" >&2
    return 1
  fi
}

# Assert output does NOT contain a string
assert_output_not_contains() {
  local unexpected="$1"
  if echo "$output" | grep -qF "$unexpected"; then
    echo "Expected output NOT to contain: $unexpected" >&2
    echo "Actual output: $output" >&2
    return 1
  fi
}

# Assert JSON contains a specific key-value pair
assert_json_contains() {
  local key="$1"
  local expected="$2"

  if ! command -v jq >/dev/null 2>&1; then
    echo "ERROR: jq is required for JSON assertions" >&2
    return 1
  fi

  local actual
  actual=$(echo "$output" | jq -r "$key" 2>/dev/null)

  if [ "$actual" != "$expected" ]; then
    echo "Expected JSON $key = '$expected', got: '$actual'" >&2
    echo "Full output: $output" >&2
    return 1
  fi
}

# Create a mock stdin JSON payload for hooks
create_hook_input() {
  local tool_name="${1:-Bash}"
  local command="${2:-echo hello}"

  cat <<EOF
{
  "tool_name": "$tool_name",
  "tool_input": {
    "command": "$command"
  }
}
EOF
}

# Skip test if command is not available
require_command() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    skip "$cmd is not installed"
  fi
}

# Skip test on specific platform
skip_on_platform() {
  local platform="$1"
  local current_platform
  current_platform="$(uname -s)"

  if [ "$current_platform" = "$platform" ]; then
    skip "Test not applicable on $platform"
  fi
}

# Assert a file contains valid JSON
assert_valid_json() {
  local file="$1"

  if [ ! -f "$file" ]; then
    echo "ERROR: File not found: $file" >&2
    return 1
  fi

  if ! command -v jq >/dev/null 2>&1; then
    echo "ERROR: jq is required for JSON validation" >&2
    return 1
  fi

  local error_output
  if ! error_output=$(jq empty "$file" 2>&1); then
    echo "ERROR: Invalid JSON in $file" >&2
    echo "$error_output" >&2
    return 1
  fi
}

# Assert a file contains valid YAML
assert_valid_yaml() {
  local file="$1"

  if [ ! -f "$file" ]; then
    echo "ERROR: File not found: $file" >&2
    return 1
  fi

  if ! command -v yq >/dev/null 2>&1; then
    echo "ERROR: yq is required for YAML validation" >&2
    return 1
  fi

  local error_output
  if ! error_output=$(yq eval '.' "$file" 2>&1 >/dev/null); then
    echo "ERROR: Invalid YAML in $file" >&2
    echo "$error_output" >&2
    return 1
  fi
}

# Assert YAML frontmatter contains a required field
# Print only the YAML frontmatter of a markdown file: the lines between a
# `---` on line 1 and the next `---`. Later `---` lines (markdown horizontal
# rules) are not frontmatter. Prints nothing when line 1 isn't `---`.
# Skip the current test when yq is missing (CI installs it).
require_yq() {
  command -v yq >/dev/null 2>&1 || skip "yq not installed (CI installs it; see tests/README.md)"
}

extract_frontmatter() {
  awk 'NR == 1 { if ($0 != "---") exit; next } $0 == "---" { exit } { print }' "$1"
}

assert_frontmatter_has() {
  local file="$1"
  local field="$2"

  if [ ! -f "$file" ]; then
    echo "ERROR: File not found: $file" >&2
    return 1
  fi

  if ! command -v yq >/dev/null 2>&1; then
    skip "yq not installed (CI installs it; see tests/README.md)"
  fi

  # Extract frontmatter (between --- delimiters) and check field
  local frontmatter
  frontmatter=$(extract_frontmatter "$file")

  if [ -z "$frontmatter" ]; then
    echo "ERROR: No frontmatter found in $file" >&2
    return 1
  fi

  local value
  value=$(echo "$frontmatter" | yq eval ".$field" - 2>/dev/null)

  if [ "$value" = "null" ] || [ -z "$value" ]; then
    echo "ERROR: Field '$field' not found in frontmatter of $file" >&2
    return 1
  fi
}

# Assert a shell script has valid bash syntax
assert_valid_shell() {
  local file="$1"

  if [ ! -f "$file" ]; then
    echo "ERROR: File not found: $file" >&2
    return 1
  fi

  local error_output
  if ! error_output=$(bash -n "$file" 2>&1); then
    echo "ERROR: Invalid shell syntax in $file" >&2
    echo "$error_output" >&2
    return 1
  fi
}

# Assert a file has execute permissions
assert_file_executable() {
  local file="$1"

  if [ ! -f "$file" ]; then
    echo "ERROR: File not found: $file" >&2
    return 1
  fi

  if [ ! -x "$file" ]; then
    echo "ERROR: File is not executable: $file" >&2
    return 1
  fi
}

# Assert a file has CRLF line endings (required for Windows batch files)
# Uses `file` command which is consistent across Linux, macOS, and Windows Git Bash
# Verified working in Alpine Linux Docker containers
assert_crlf_line_endings() {
  local file="$1"
  if [ ! -f "$file" ]; then
    echo "ERROR: File not found: $file" >&2
    return 1
  fi

  # Require file command (standard on all Unix systems)
  if ! command -v file >/dev/null 2>&1; then
    echo "ERROR: 'file' command required for line ending detection" >&2
    return 1
  fi

  local file_info
  file_info=$(file "$file")

  if ! echo "$file_info" | grep -q "CRLF"; then
    echo "ERROR: File should have CRLF line endings: $file" >&2
    echo "Actual: $file_info" >&2
    echo "Fix: unix2dos $file" >&2
    return 1
  fi
}

# Assert a file has LF line endings (required for shell scripts)
# Uses `file` command which is consistent across Linux, macOS, and Windows Git Bash
assert_lf_line_endings() {
  local file="$1"
  if [ ! -f "$file" ]; then
    echo "ERROR: File not found: $file" >&2
    return 1
  fi

  # Require file command (standard on all Unix systems)
  if ! command -v file >/dev/null 2>&1; then
    echo "ERROR: 'file' command required for line ending detection" >&2
    return 1
  fi

  local file_info
  file_info=$(file "$file")

  if echo "$file_info" | grep -q "CRLF"; then
    echo "ERROR: File should have LF line endings (not CRLF): $file" >&2
    echo "Actual: $file_info" >&2
    echo "Fix: dos2unix $file" >&2
    return 1
  fi
}

# Load bats-support and bats-assert if available (optional)
if [ -f "/usr/lib/bats-support/load.bash" ]; then
  load '/usr/lib/bats-support/load.bash'
fi
if [ -f "/usr/lib/bats-assert/load.bash" ]; then
  load '/usr/lib/bats-assert/load.bash'
fi

# Print a template with {{PLACEHOLDERS}} filled the way setup does
# ({{*_PORT}} -> 8000, anything else -> "placeholder"). Templates such as
# `container_name: {{PROJECT_NAME}}-app` are only valid YAML after this.
render_placeholders() {
  sed -E 's/\{\{[A-Z_]+_PORT\}\}/8000/g; s/\{\{[A-Z_]+\}\}/placeholder/g' "$1"
}

# Print a JSONC template (devcontainer.json style) as plain JSON:
# drops // and /* */ comments outside strings (URLs like https://... are kept),
# drops trailing commas, and fills {{PLACEHOLDERS}} the way setup does
# ({{*_PORT}} -> 8000, anything else -> "placeholder").
# Requires python3; callers should `require_command python3`.
render_jsonc_template() {
  python3 -I - "$1" <<'PYEOF'
import re, sys
text = open(sys.argv[1], encoding="utf-8").read()
out, i, n, in_str = [], 0, len(text), False
while i < n:
    c = text[i]
    if in_str:
        out.append(c)
        if c == "\\" and i + 1 < n:
            out.append(text[i + 1]); i += 2; continue
        if c == '"':
            in_str = False
        i += 1; continue
    if c == '"':
        in_str = True; out.append(c); i += 1; continue
    if text.startswith("//", i):
        while i < n and text[i] != "\n":
            i += 1
        continue
    if text.startswith("/*", i):
        end = text.find("*/", i + 2)
        i = n if end == -1 else end + 2
        continue
    out.append(c); i += 1
s = "".join(out)
s = re.sub(r",(\s*[}\]])", r"\1", s)
s = re.sub(r"\{\{[A-Z_]+_PORT\}\}", "8000", s)
s = re.sub(r"\{\{[A-Z_]+\}\}", "placeholder", s)
sys.stdout.write(s)
PYEOF
}
