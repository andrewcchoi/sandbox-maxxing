#!/usr/bin/env bats
# ============================================================================
# Docker build of the user-remap step in base.dockerfile (#377)
#
# Extracts the block between `# >>> user-remap` and `# <<< user-remap` into a
# small Dockerfile on the same base image, builds it with different
# USER_UID/USER_GID values, and checks the resulting user.
# Skipped when Docker is not available. Set SKIP_DOCKER_TESTS=1 to skip.
# ============================================================================

load '../helpers/test_helper.bash'

ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
BASE_DOCKERFILE="$ROOT/skills/_shared/templates/base.dockerfile"
IMAGE_PREFIX="sandboxxer-test-user-remap"

setup_file() {
  if [ "${SKIP_DOCKER_TESTS:-0}" = "1" ] || ! docker info >/dev/null 2>&1; then
    export DOCKER_UNAVAILABLE=1
    return 0
  fi
  BUILD_DIR="$(mktemp -d)"
  export BUILD_DIR
  {
    grep -m1 '^FROM node:' "$BASE_DOCKERFILE"
    sed -n '/^# >>> user-remap/,/^# <<< user-remap/p' "$BASE_DOCKERFILE"
    # mirror a later chown in base.dockerfile to check group handling
    echo 'RUN mkdir -p /workspace && chown -R node: /workspace'
  } > "$BUILD_DIR/Dockerfile"
}

teardown_file() {
  [ -n "${BUILD_DIR:-}" ] && rm -rf "$BUILD_DIR"
  if [ -z "${DOCKER_UNAVAILABLE:-}" ]; then
    docker image ls --format '{{.Repository}}:{{.Tag}}' "$IMAGE_PREFIX" 2>/dev/null \
      | xargs -r docker rmi -f >/dev/null 2>&1 || true
  fi
}

setup() {
  [ -z "${DOCKER_UNAVAILABLE:-}" ] || skip "Docker not available"
}

# Override the shared helper teardown, which expects its own setup() to have run
teardown() {
  :
}

# build_remap UID GID -> sets $status/$output; tag is $IMAGE_PREFIX:UID-GID
build_remap() {
  run docker build --progress=plain -t "$IMAGE_PREFIX:$1-$2" \
    --build-arg "USER_UID=$1" --build-arg "USER_GID=$2" "$BUILD_DIR"
}

# assert_build_error TEXT -> TEXT was printed by the RUN step itself.
# Build logs also echo the Dockerfile source, so only lines with BuildKit's
# "#<step> <seconds>" runtime prefix count.
assert_build_error() {
  printf "%s\n" "$output" | grep -E "^#[0-9]+ [0-9.]+ ERROR: " | grep -qF -- "$1" || {
    echo "expected runtime error containing: $1" >&2
    echo "$output" | tail -20 >&2
    return 1
  }
}

# inspect UID GID -> prints "uid gid home_owner workspace_owner"
inspect_user() {
  docker run --rm "$IMAGE_PREFIX:$1-$2" sh -c \
    'echo "$(id -u node) $(id -g node) $(stat -c %u:%g /home/node) $(stat -c %u:%g /workspace)"'
}

@test "remap: defaults keep node at 1000:1000" {
  build_remap 1000 1000
  [ "$status" -eq 0 ] || { echo "$output" >&2; return 1; }
  [ "$(inspect_user 1000 1000)" = "1000 1000 1000:1000 1000:1000" ]
}

@test "remap: new UID and GID (1234:1234) update the user, its group and home" {
  build_remap 1234 1234
  [ "$status" -eq 0 ] || { echo "$output" >&2; return 1; }
  [ "$(inspect_user 1234 1234)" = "1234 1234 1234:1234 1234:1234" ]
}

@test "remap: macOS IDs (501:20) reuse the existing GID 20 group" {
  build_remap 501 20
  [ "$status" -eq 0 ] || { echo "$output" >&2; return 1; }
  [ "$(inspect_user 501 20)" = "501 20 501:20 501:20" ]
}

@test "remap: node resolves by name after a remap" {
  build_remap 1234 1234
  [ "$status" -eq 0 ]
  run docker run --rm --user 1234:1234 "$IMAGE_PREFIX:1234-1234" sh -c 'whoami; echo "$HOME"'
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "node" ]
  [ "${lines[1]}" = "/home/node" ]
}

@test "remap: UID 0 fails with a clear message" {
  build_remap 0 0
  [ "$status" -ne 0 ]
  assert_build_error "cannot be 0 (root)"
}

@test "remap: a UID used by another account (33 = www-data) fails with a clear message" {
  build_remap 33 33
  [ "$status" -ne 0 ]
  assert_build_error "UID 33 is already used by 'www-data'"
}

@test "remap: a non-numeric value fails with a clear message" {
  build_remap abc 1000
  [ "$status" -ne 0 ]
  assert_build_error "must be numeric, got 'abc:1000'"
}
