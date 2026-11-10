#!/usr/bin/env bash
#
# session-end-hook.sh
# Runs when a Claude session ends (SessionEnd event).
#
# Scope: the CURRENT session only (#369). It never scans other volumes, so a
# concurrent sandbox's state is never touched. The host-wide recovery scan
# stays on SessionStart (sync-knowledge.sh with no arguments).
#
# Two modes:
#   local  (default) The session's Claude config dir is on this filesystem:
#          ${CLAUDE_CONFIG_DIR:-$HOME/.claude}. Inside a sandboxxer container
#          that directory is the Claude data volume. Writes the clean-shutdown
#          manifest there and runs sync(1). Needs no Docker.
#   volume SANDBOXXER_SESSION_VOLUME names the Docker volume holding this
#          session's Claude data (Claude running on the host against one
#          sandbox volume). Writes the manifest into that volume, runs sync(1),
#          then copies that one volume to ~/.claude via sync-knowledge.sh.
#
# Clean-shutdown manifest: <claude dir>/state/session-end/<session_id>.json
#   {"session_id", "ended_at", "reason", "hook_version", "mode"}
# A session with no manifest ended dirty (crash, kill, harness timeout).
#
# Timeouts: every blocking step runs under `timeout`, and the step budgets add
# up to less than the 15000 ms SessionEnd timeout in hooks.json, so the harness
# never kills the hook mid-write under normal load.
# tests/unit/hooks/session-end-hook.bats checks this.

set -euo pipefail

HOOK_VERSION="2"
# Per-step budgets (seconds). Sum must stay below the hooks.json timeout (15 s).
MANIFEST_TIMEOUT=4
COPY_TIMEOUT=8

if [ -z "${HOME:-}" ]; then
    echo "[session-end-hook] ERROR: HOME environment variable not set" >&2
    exit 1
fi

LOG_DIR="${HOME}/.claude/state"
LOG_FILE="${LOG_DIR}/hook.log"
mkdir -p "${LOG_DIR}" || {
    echo "[session-end-hook] FATAL: Cannot create log directory: ${LOG_DIR}" >&2
    exit 1
}

# Rotate log if > 1MB with timestamped backup
if [ -f "${LOG_FILE}" ]; then
    LOG_SIZE=$(stat -f%z "${LOG_FILE}" 2>/dev/null || stat -c%s "${LOG_FILE}" 2>/dev/null || echo "0")
    if [ "${LOG_SIZE}" -gt 1048576 ]; then
        mv "${LOG_FILE}" "${LOG_FILE}.$(date '+%Y%m%d_%H%M%S')" 2>/dev/null \
            || mv "${LOG_FILE}" "${LOG_FILE}.old" 2>/dev/null || true
    fi
fi

log() { echo "[$(date '+%Y-%m-%dT%H:%M:%S%z')] $*" >> "${LOG_FILE}"; }

# Run a command under a time budget when `timeout` exists.
with_timeout() {
    local secs="$1"; shift
    if command -v timeout >/dev/null 2>&1; then
        timeout "$secs" "$@"
    else
        "$@"
    fi
}

# --- Hook input (JSON on stdin: session_id, reason, ...) ---------------------
INPUT=""
if [ ! -t 0 ]; then
    INPUT=$(with_timeout 2 cat 2>/dev/null || true)
fi

json_field() {
    local key="$1" val=""
    if command -v jq >/dev/null 2>&1; then
        val=$(printf '%s' "$INPUT" | jq -r --arg k "$key" '.[$k] // empty' 2>/dev/null || true)
    else
        val=$(printf '%s' "$INPUT" | sed -n "s/.*\"${key}\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -n1)
    fi
    printf '%s' "$val"
}

# Keep ids and reasons to a safe charset: they become a filename and JSON values.
SESSION_ID=$(json_field session_id | tr -cd 'A-Za-z0-9_-' | cut -c1-128)
REASON=$(json_field reason | tr -cd 'A-Za-z0-9_-' | cut -c1-64)
[ -n "$SESSION_ID" ] || SESSION_ID="unknown-$(date '+%Y%m%dT%H%M%S')-$$"
[ -n "$REASON" ] || REASON="unknown"
ENDED_AT=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

log "SessionEnd hook triggered (session=${SESSION_ID} reason=${REASON})"

manifest_json() {
    printf '{"session_id":"%s","ended_at":"%s","reason":"%s","hook_version":"%s","mode":"%s"}\n' \
        "$SESSION_ID" "$ENDED_AT" "$REASON" "$HOOK_VERSION" "$1"
}

SESSION_VOLUME="${SANDBOXXER_SESSION_VOLUME:-}"

if [ -n "$SESSION_VOLUME" ]; then
    # --- volume mode ---------------------------------------------------------
    if ! [[ "$SESSION_VOLUME" =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]{0,199}$ ]]; then
        log "WARNING: invalid SANDBOXXER_SESSION_VOLUME, skipping flush"
        exit 0
    fi
    if ! command -v docker >/dev/null 2>&1; then
        log "WARNING: SANDBOXXER_SESSION_VOLUME set but docker not found, skipping flush"
        exit 0
    fi
    log "Flushing session volume ${SESSION_VOLUME}"

    # Write the manifest atomically (tmp + mv), then sync(1). sync is
    # kernel-wide, so it also flushes writes the session's container made.
    if with_timeout "$MANIFEST_TIMEOUT" docker run --rm -i --user "$(id -u):$(id -g)" \
        -v "${SESSION_VOLUME}:/v" alpine:3.19 sh -c '
            mkdir -p /v/state/session-end &&
            cat > "/v/state/session-end/.$1.tmp" &&
            mv "/v/state/session-end/.$1.tmp" "/v/state/session-end/$1.json" &&
            sync' _ "$SESSION_ID" <<< "$(manifest_json volume)" >> "${LOG_FILE}" 2>&1; then
        log "Wrote clean-shutdown manifest to ${SESSION_VOLUME}:/state/session-end/${SESSION_ID}.json"
    else
        log "WARNING: manifest write/sync failed or timed out for ${SESSION_VOLUME}"
    fi

    # Copy only this session's volume to the host (never a host-wide scan).
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "${SCRIPT_DIR}/sync-knowledge.sh" ]; then
        SANDBOXXER_SYNC_VOLUMES="$SESSION_VOLUME" \
            with_timeout "$COPY_TIMEOUT" bash "${SCRIPT_DIR}/sync-knowledge.sh" >> "${LOG_FILE}" 2>&1 \
            || log "WARNING: scoped knowledge copy failed or timed out"
    else
        log "WARNING: sync-knowledge.sh not found next to session-end-hook.sh"
    fi
else
    # --- local mode ----------------------------------------------------------
    CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}"
    MANIFEST_DIR="${CLAUDE_DIR}/state/session-end"
    if mkdir -p "$MANIFEST_DIR" 2>/dev/null; then
        TMP="${MANIFEST_DIR}/.${SESSION_ID}.tmp"
        if manifest_json local > "$TMP" && mv "$TMP" "${MANIFEST_DIR}/${SESSION_ID}.json"; then
            log "Wrote clean-shutdown manifest to ${MANIFEST_DIR}/${SESSION_ID}.json"
        else
            rm -f "$TMP" 2>/dev/null || true
            log "WARNING: could not write manifest in ${MANIFEST_DIR}"
        fi
    else
        log "WARNING: cannot create ${MANIFEST_DIR}"
    fi
    if command -v sync >/dev/null 2>&1; then
        with_timeout "$MANIFEST_TIMEOUT" sync 2>/dev/null || log "WARNING: sync failed or timed out"
    fi
fi

log "SessionEnd hook completed"
exit 0
