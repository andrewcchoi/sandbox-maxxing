#!/usr/bin/env bats
# ============================================================================
# Host UID/GID matching for the container user (#377)
# Covers the build-arg wiring in the templates and the .env helpers.
# The Docker build of the remap step itself is in
# tests/integration/test_user_remap_build.bats.
# ============================================================================

load '../helpers/test_helper.bash'

ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
TEMPLATES="$ROOT/skills/_shared/templates"

setup() {
  TEST_DIR="$(mktemp -d)"
  ENV_FILE="$TEST_DIR/.env"
  # shellcheck source=/dev/null
  source "$ROOT/scripts/common.sh"
}

teardown() {
  rm -rf "$TEST_DIR"
}

# Compose templates that build the image from .devcontainer/Dockerfile
building_compose_templates() {
  grep -l 'dockerfile: .devcontainer/Dockerfile' "$TEMPLATES"/docker-compose*.yml
}

# ----------------------------------------------------------------------------
# Template wiring
# ----------------------------------------------------------------------------

@test "base.dockerfile: declares USER_UID/USER_GID (default 1000) inside the remap block" {
  local block
  block=$(sed -n '/^# >>> user-remap/,/^# <<< user-remap/p' "$TEMPLATES/base.dockerfile")
  [ -n "$block" ]
  echo "$block" | grep -qx 'ARG USER_UID=1000'
  echo "$block" | grep -qx 'ARG USER_GID=1000'
  echo "$block" | grep -q 'usermod -u "$USER_UID" node'
}

@test "base.dockerfile: remap block runs before the first chown" {
  # a chown before the block would leave files with the old IDs
  local remap_line first_chown
  remap_line=$(grep -n '^# >>> user-remap' "$TEMPLATES/base.dockerfile" | head -1 | cut -d: -f1)
  first_chown=$(grep -n 'chown' "$TEMPLATES/base.dockerfile" | head -1 | cut -d: -f1)
  [ -n "$remap_line" ]
  [ "$first_chown" -gt "$remap_line" ]
}

@test "base.dockerfile + partials: no chown uses the literal node:node group" {
  # After a GID remap the node group may not be node's primary group
  # (macOS GID 20 reuses Debian's dialout), so chowns must use `node:`.
  run grep -n 'node:node' "$TEMPLATES/base.dockerfile" "$TEMPLATES"/partials/*.dockerfile
  [ "$status" -eq 1 ]
}

@test "compose templates: every template that builds passes USER_UID/USER_GID from CONTAINER_UID/GID" {
  local templates f
  templates=$(building_compose_templates)
  [ -n "$templates" ]
  for f in $templates; do
    grep -qF -- '- USER_UID=${CONTAINER_UID:-1000}' "$f" || { echo "missing USER_UID arg: $f" >&2; return 1; }
    grep -qF -- '- USER_GID=${CONTAINER_GID:-1000}' "$f" || { echo "missing USER_GID arg: $f" >&2; return 1; }
    # the runtime user must use the same variables and defaults
    grep -qF 'user: "${CONTAINER_UID:-1000}:${CONTAINER_GID:-1000}"' "$f" || { echo "user: line mismatch: $f" >&2; return 1; }
  done
}

@test "compose templates: at least four templates build the image" {
  [ "$(building_compose_templates | wc -l)" -ge 4 ]
}

# ----------------------------------------------------------------------------
# set_env_if_missing
# ----------------------------------------------------------------------------

@test "set_env_if_missing: adds a key that is not present" {
  printf 'APP_PORT=8000\n' > "$ENV_FILE"
  set_env_if_missing CONTAINER_UID 501 "$ENV_FILE"
  grep -qx 'CONTAINER_UID=501' "$ENV_FILE"
  grep -qx 'APP_PORT=8000' "$ENV_FILE"
}

@test "set_env_if_missing: keeps an existing value" {
  printf 'CONTAINER_UID=4242\n' > "$ENV_FILE"
  set_env_if_missing CONTAINER_UID 501 "$ENV_FILE"
  grep -qx 'CONTAINER_UID=4242' "$ENV_FILE"
  [ "$(grep -c '^CONTAINER_UID=' "$ENV_FILE")" -eq 1 ]
}

@test "set_env_if_missing: handles a file without a trailing newline" {
  printf 'APP_PORT=8000' > "$ENV_FILE"
  set_env_if_missing CONTAINER_UID 501 "$ENV_FILE"
  grep -qx 'APP_PORT=8000' "$ENV_FILE"
  grep -qx 'CONTAINER_UID=501' "$ENV_FILE"
}

@test "set_env_if_missing: creates the file when it does not exist" {
  set_env_if_missing CONTAINER_UID 501 "$ENV_FILE"
  grep -qx 'CONTAINER_UID=501' "$ENV_FILE"
}

# ----------------------------------------------------------------------------
# write_host_ids (id/uname mocked as shell functions)
# ----------------------------------------------------------------------------

mock_host() {
  # $1 = uname -s, $2 = uid, $3 = gid
  MOCK_UNAME="$1"; MOCK_UID="$2"; MOCK_GID="$3"
  uname() { echo "$MOCK_UNAME"; }
  id() {
    case "$1" in
      -u) echo "$MOCK_UID" ;;
      -g) echo "$MOCK_GID" ;;
    esac
  }
}

@test "write_host_ids: writes the host UID/GID on macOS-style IDs" {
  mock_host Darwin 501 20
  touch "$ENV_FILE"
  write_host_ids "$ENV_FILE"
  grep -qx 'CONTAINER_UID=501' "$ENV_FILE"
  grep -qx 'CONTAINER_GID=20' "$ENV_FILE"
}

@test "write_host_ids: writes 1000:1000 on a standard Linux host (no behaviour change)" {
  mock_host Linux 1000 1000
  touch "$ENV_FILE"
  write_host_ids "$ENV_FILE"
  grep -qx 'CONTAINER_UID=1000' "$ENV_FILE"
  grep -qx 'CONTAINER_GID=1000' "$ENV_FILE"
}

@test "write_host_ids: keeps values the user already set" {
  mock_host Linux 1234 1234
  printf 'CONTAINER_UID=1000\nCONTAINER_GID=1000\n' > "$ENV_FILE"
  write_host_ids "$ENV_FILE"
  grep -qx 'CONTAINER_UID=1000' "$ENV_FILE"
  grep -qx 'CONTAINER_GID=1000' "$ENV_FILE"
}

@test "write_host_ids: skips Git Bash / MSYS / Cygwin" {
  local shell_name
  for shell_name in MINGW64_NT-10.0 MSYS_NT-10.0 CYGWIN_NT-10.0; do
    mock_host "$shell_name" 197609 197121
    : > "$ENV_FILE"
    run write_host_ids "$ENV_FILE"
    [ "$status" -eq 0 ]
    run grep -q '^CONTAINER_' "$ENV_FILE"; [ "$status" -eq 1 ]
  done
}

@test "write_host_ids: skips when running as root" {
  mock_host Linux 0 0
  touch "$ENV_FILE"
  run write_host_ids "$ENV_FILE"
  [ "$status" -eq 0 ]
  run grep -q '^CONTAINER_' "$ENV_FILE"; [ "$status" -eq 1 ]
}

@test "write_host_ids: writes the UID but keeps the default GID when the host GID is 0" {
  mock_host Linux 1234 0
  touch "$ENV_FILE"
  write_host_ids "$ENV_FILE"
  grep -qx 'CONTAINER_UID=1234' "$ENV_FILE"
  run grep -q '^CONTAINER_GID=' "$ENV_FILE"; [ "$status" -eq 1 ]
}

# ----------------------------------------------------------------------------
# Setup paths call the helper
# ----------------------------------------------------------------------------

@test "yolo-docker-maxxing.sh: writes host IDs to .env" {
  grep -qx 'write_host_ids .env' "$ROOT/scripts/yolo-docker-maxxing.sh"
}

@test "quickstart.md: writes host IDs to .env after generating or restoring it" {
  grep -qx 'write_host_ids .env' "$ROOT/commands/quickstart.md"
  # the .env step is in its own bash block, so it must load common.sh itself
  grep -qF 'type write_host_ids >/dev/null 2>&1 || source "${CLAUDE_PLUGIN_ROOT}/scripts/common.sh"' "$ROOT/commands/quickstart.md"
}
