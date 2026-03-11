#!/usr/bin/env bash
#
# session-end-hook.sh
# Runs when a Claude session ends
#
# Purpose:
# - Performs final sync of knowledge files from Docker volumes to host
# - Logs session completion for debugging
# - Provides extensibility point for future cleanup tasks

set -euo pipefail

# Validate HOME is set
if [ -z "${HOME:-}" ]; then
    echo "[session-end-hook] ERROR: HOME environment variable not set" >&2
    exit 1
fi

# Logging configuration
LOG_DIR="${HOME}/.claude/state"
LOG_FILE="${LOG_DIR}/hook.log"

# Ensure log directory exists (with error handling)
mkdir -p "${LOG_DIR}" || {
    echo "[session-end-hook] FATAL: Cannot create log directory: ${LOG_DIR}" >&2
    exit 1
}

# Rotate log if > 1MB (1048576 bytes) with timestamped backup
if [ -f "${LOG_FILE}" ]; then
    # Use stat with fallback for Linux/macOS compatibility
    LOG_SIZE=$(stat -f%z "${LOG_FILE}" 2>/dev/null || stat -c%s "${LOG_FILE}" 2>/dev/null || echo "0")
    if [ "${LOG_SIZE}" -gt 1048576 ]; then
        # Create timestamped backup to preserve history
        TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
        mv "${LOG_FILE}" "${LOG_FILE}.${TIMESTAMP}" 2>/dev/null || {
            # Fallback to .old if timestamp rename fails
            mv "${LOG_FILE}" "${LOG_FILE}.old" 2>/dev/null || true
        }
    fi
fi

# Log session end
echo "[$(date '+%Y-%m-%dT%H:%M:%S%z')] SessionEnd hook triggered" >> "${LOG_FILE}"

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Sanitize SCRIPT_DIR for safe logging (prevent log injection via newlines)
SCRIPT_DIR_SAFE="${SCRIPT_DIR//$'\n'/ }"

# Run final sync using sync-knowledge.sh
if [[ -f "${SCRIPT_DIR}/sync-knowledge.sh" ]]; then
    echo "[$(date '+%Y-%m-%dT%H:%M:%S%z')] Running final knowledge sync..." >> "${LOG_FILE}"

    # Run with timeout to prevent hanging
    if command -v timeout >/dev/null 2>&1; then
        timeout 30 bash "${SCRIPT_DIR}/sync-knowledge.sh" >> "${LOG_FILE}" 2>&1 || {
            echo "[$(date '+%Y-%m-%dT%H:%M:%S%z')] WARNING: Final sync failed or timed out" >> "${LOG_FILE}"
        }
    else
        bash "${SCRIPT_DIR}/sync-knowledge.sh" >> "${LOG_FILE}" 2>&1 || {
            echo "[$(date '+%Y-%m-%dT%H:%M:%S%z')] WARNING: Final sync failed" >> "${LOG_FILE}"
        }
    fi
else
    echo "[$(date '+%Y-%m-%dT%H:%M:%S%z')] WARNING: sync-knowledge.sh not found at ${SCRIPT_DIR_SAFE}/sync-knowledge.sh" >> "${LOG_FILE}"
fi

# Log completion
echo "[$(date '+%Y-%m-%dT%H:%M:%S%z')] SessionEnd hook completed" >> "${LOG_FILE}"

# Future cleanup tasks can be added here
# Examples:
# - Archive session logs
# - Clean up temporary files
# - Send telemetry data
# - Backup important files

exit 0
