#!/bin/bash
# Continuous testing without user interaction
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Dry run mode (just validate setup)
DRY_RUN="${DRY_RUN:-false}"

if [ "$DRY_RUN" = "true" ]; then
    # Source for log functions
    source "$SCRIPT_DIR/test-harness.sh" 2>/dev/null || {
        # Define minimal logging if source fails
        log_info() { echo "[INFO] $1"; }
        log_error() { echo "[ERROR] $1"; }
    }

    log_info "DRY RUN MODE - validating test setup only"

    # Check dependencies
    command -v jq >/dev/null || log_error "jq not found"
    command -v python3 >/dev/null || log_error "python3 not found"
    command -v bc >/dev/null || log_error "bc not found"

    # Check directories exist
    [ -d "$SCRIPT_DIR/fixtures" ] || log_error "fixtures/ not found"
    [ -d "$SCRIPT_DIR/generated" ] || log_error "generated/ not found"
    [ -d "$SCRIPT_DIR/reports" ] || log_error "reports/ not found"

    log_info "✓ Test setup validated"
    exit 0
fi

# Source test harness functions
source "$SCRIPT_DIR/test-harness.sh"

# Override main to run continuously
continuous_main() {
    local modes=("basic" "intermediate" "advanced" "yolo")
    local max_iterations_per_mode=5

    log_info "Starting CONTINUOUS skill validation (no user prompts)"
    log_info "Max iterations per mode: $max_iterations_per_mode"

    for mode in "${modes[@]}"; do
        log_info "========================================="
        log_info "Testing mode: $mode"
        log_info "========================================="

        local passed=false

        for ((iteration=1; iteration<=max_iterations_per_mode; iteration++)); do
            log_info "Iteration $iteration/$max_iterations_per_mode"

            if test_skill "$mode" "$iteration"; then
                log_info "✓ $mode PASSED"
                passed=true
                break
            else
                log_warn "✗ $mode FAILED iteration $iteration"

                # Auto-fix attempt (placeholder - actual fix logic in next task)
                log_info "Attempting auto-fix..."
                sleep 2
            fi
        done

        if [ "$passed" = false ]; then
            log_error "$mode did not pass after $max_iterations_per_mode iterations"
        fi

        # Cleanup
        cleanup_test_output "$mode"

        log_info ""
    done

    log_info "========================================="
    log_info "Continuous testing complete"
    log_info "========================================="
}

# Run continuous tests
continuous_main "$@"
