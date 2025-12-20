#!/bin/bash
# Test harness for continuous skill validation
set -e

# Configuration
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GENERATED_DIR="$TEST_DIR/generated"
REPORTS_DIR="$TEST_DIR/reports"
ACCURACY_THRESHOLD=95

# Load Python fallbacks for jq and bc if not available
if ! command -v jq >/dev/null 2>&1 || ! command -v bc >/dev/null 2>&1; then
    source "$TEST_DIR/lib/python-fallbacks.sh"
fi

# Load comparison engine
source "$TEST_DIR/compare-containers.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Logging
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Generate skill output
generate_skill_output() {
    local mode="$1"
    local test_project="$TEST_DIR/test-project"
    local output_dir="$GENERATED_DIR/$mode"

    # Create fresh test directory
    rm -rf "$output_dir"
    cp -r "$test_project" "$output_dir"
    cd "$output_dir"

    # Run skill with minimal interaction
    case "$mode" in
        basic)
            # Basic mode with defaults
            echo -e "test-project\n" | claude skill sandbox-setup-basic
            ;;
        intermediate)
            # Intermediate with Python selected
            echo -e "test-project\npython\nyes\nno\n" | claude skill sandbox-setup-intermediate
            ;;
        advanced)
            # Advanced with Python, postgres, redis
            echo -e "test-project\npython\npostgres,redis\nyes\n" | claude skill sandbox-setup-advanced
            ;;
        yolo)
            # YOLO with maximum customization
            echo -e "test-project\npython\nall\nstrict\nyes\n" | claude skill sandbox-setup-yolo
            ;;
    esac

    # Return to test directory
    cd "$TEST_DIR"

    # Verify key files exist
    if [ ! -f "$output_dir/.devcontainer/devcontainer.json" ]; then
        log_error "devcontainer.json not generated"
        return 1
    fi

    if [ ! -f "$output_dir/docker-compose.yml" ]; then
        log_error "docker-compose.yml not generated"
        return 1
    fi

    return 0
}

# Cleanup test output
cleanup_test_output() {
    local mode="$1"
    local output_dir="$GENERATED_DIR/$mode"

    log_info "Cleaning up test output for $mode"
    rm -rf "$output_dir"
}

# Generate detailed report
generate_report() {
    local mode="$1"
    local iteration="$2"
    local accuracy="$3"
    local report_file="$REPORTS_DIR/${mode}-iteration-${iteration}.txt"

    cat > "$report_file" <<EOF
Skill Validation Report
=======================
Mode: $mode
Iteration: $iteration
Timestamp: $(date)
Accuracy: ${accuracy}%
Threshold: ${ACCURACY_THRESHOLD}%
Status: $([ $(echo "$accuracy >= $ACCURACY_THRESHOLD" | bc -l) -eq 1 ] && echo "PASS" || echo "FAIL")

Generated Files:
EOF

    find "$GENERATED_DIR/$mode" -type f >> "$report_file"

    log_info "Report saved to $report_file"
}

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

    # Generate report
    generate_report "$mode" "$iteration" "$accuracy"

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
        local max_iterations=5

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

# Only run main if not being sourced
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
