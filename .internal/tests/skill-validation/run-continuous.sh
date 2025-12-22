#!/bin/bash
# Continuous testing without user interaction
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load Python fallbacks for jq and bc if not available
if ! command -v jq >/dev/null 2>&1 || ! command -v bc >/dev/null 2>&1; then
    source "$SCRIPT_DIR/lib/python-fallbacks.sh"
fi

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

    # Check dependencies (jq and bc can use Python fallbacks)
    if ! command -v jq >/dev/null && ! declare -f jq >/dev/null; then
        log_error "jq not found and Python fallback not loaded"
    else
        log_info "jq available (native or Python fallback)"
    fi

    if ! command -v python3 >/dev/null; then
        log_error "python3 not found"
    else
        log_info "python3 available"
    fi

    if ! command -v bc >/dev/null && ! declare -f bc >/dev/null; then
        log_error "bc not found and Python fallback not loaded"
    else
        log_info "bc available (native or Python fallback)"
    fi

    # Check directories exist
    [ -d "$SCRIPT_DIR/fixtures" ] || log_error "fixtures/ not found"
    [ -d "$SCRIPT_DIR/generated" ] || log_error "generated/ not found"
    [ -d "$SCRIPT_DIR/reports" ] || log_error "reports/ not found"

    log_info "✓ Test setup validated"
    exit 0
fi

# Source test harness functions
source "$SCRIPT_DIR/test-harness.sh"

# Source skill fixer functions
source "$SCRIPT_DIR/lib/skill-fixer.sh"

# Source report generator functions
source "$SCRIPT_DIR/lib/report-generator.sh"

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

                # Analyze failures
                local report_file="$REPORTS_DIR/${mode}-iteration-${iteration}.txt"
                local issues_count
                issues_count=$(analyze_failures "$mode" "$GENERATED_DIR/$mode" "$report_file")

                log_info "Found $issues_count issues"

                # Attempt auto-fix (currently just logs)
                if ! apply_fixes "$mode" "$issues_count"; then
                    log_warn "Auto-fix failed - continuing to next iteration"
                fi

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

    # Generate summary report
    generate_summary_report
}

# Run continuous tests
continuous_main "$@"
