#!/bin/bash
# Test harness for continuous skill validation
set -e

# Configuration
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GENERATED_DIR="$TEST_DIR/generated"
REPORTS_DIR="$TEST_DIR/reports"
ACCURACY_THRESHOLD=95

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Logging
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Test a single skill
test_skill() {
    local mode="$1"
    local iteration="$2"

    log_info "Testing skill: $mode (iteration $iteration)"

    # Generate files
    if ! generate_skill_output "$mode"; then
        log_error "Generation failed for $mode"
        return 1
    fi

    # Compare against templates
    local accuracy
    accuracy=$(compare_with_templates "$mode")

    log_info "Accuracy: ${accuracy}%"

    # Check threshold
    if (( $(echo "$accuracy >= $ACCURACY_THRESHOLD" | bc -l) )); then
        log_info "✓ PASS - $mode skill meets accuracy threshold"
        return 0
    else
        log_warn "✗ FAIL - $mode skill below threshold (${accuracy}% < ${ACCURACY_THRESHOLD}%)"
        return 1
    fi
}

# Main loop
main() {
    local modes=("basic" "intermediate" "advanced" "yolo")

    for mode in "${modes[@]}"; do
        log_info "Starting continuous test for: $mode"

        local iteration=1
        local max_iterations=10

        while [ $iteration -le $max_iterations ]; do
            if test_skill "$mode" "$iteration"; then
                log_info "✓ $mode skill PASSED - moving to next mode"
                break
            else
                log_warn "Iteration $iteration/$max_iterations failed - will retry after fix"

                # Prompt for skill edits
                read -p "Edit skill and press Enter to retry (or 'skip' to move to next): " input
                if [ "$input" = "skip" ]; then
                    log_warn "Skipping $mode mode"
                    break
                fi

                ((iteration++))
            fi
        done

        # Cleanup
        cleanup_test_output "$mode"
    done

    log_info "All skill testing complete"
}

main "$@"
