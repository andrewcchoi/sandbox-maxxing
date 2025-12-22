#!/bin/bash
# Comprehensive test report generation

# Generate final summary report
generate_summary_report() {
    local report_file="$REPORTS_DIR/summary-$(date +%Y%m%d-%H%M%S).md"

    cat > "$report_file" <<EOF
# Skill Validation Summary Report

**Generated:** $(date)

## Test Results

| Mode | Iterations | Final Accuracy | Status | Issues |
|------|------------|----------------|--------|--------|
EOF

    # Parse individual reports
    for mode in basic intermediate advanced yolo; do
        local mode_reports=("$REPORTS_DIR"/${mode}-iteration-*.txt)

        # Check if any reports exist for this mode
        if [ -f "${mode_reports[0]}" ]; then
            local iterations=${#mode_reports[@]}

            # Get latest report
            local latest_report="${mode_reports[-1]}"
            local accuracy=$(grep "Accuracy:" "$latest_report" 2>/dev/null | awk '{print $2}' | tr -d '\r' || echo "N/A")
            local status=$(grep "Status:" "$latest_report" 2>/dev/null | awk '{print $2}' | tr -d '\r' || echo "UNKNOWN")
            local issues_found=$(grep "Issues Found:" "$latest_report" 2>/dev/null)
            local issues=0
            if [ -n "$issues_found" ]; then
                # Count the lines after "Issues Found:" until the next blank line or end of file
                issues=$(grep -A 999 "Issues Found:" "$latest_report" | tail -n +2 | grep -c "^[^[:space:]]" || echo "0")
            fi

            echo "| $mode | $iterations | $accuracy | $status | $issues |" >> "$report_file"
        else
            echo "| $mode | 0 | N/A | NOT RUN | N/A |" >> "$report_file"
        fi
    done

    cat >> "$report_file" <<EOF

## Test Configuration

- **Accuracy Threshold:** ${ACCURACY_THRESHOLD}%
- **Max Iterations:** 5 per mode
- **Test Directory:** tests/skill-validation/

## Files Validated

- devcontainer.json (JSON syntax, required keys, structure)
- docker-compose.yml (YAML syntax, services, networks)
- Dockerfile (FROM instruction, multi-stage, packages)

## Comparison Method

- **Structural:** JSON/YAML key path comparison
- **Syntactic:** Validator tools (jq, yq, shellcheck)
- **Content:** Section markers and expected content

## Summary Statistics

EOF

    # Calculate summary statistics
    local total_tests=0
    local passed_tests=0
    local failed_tests=0
    local not_run=0

    for mode in basic intermediate advanced yolo; do
        local mode_reports=("$REPORTS_DIR"/${mode}-iteration-*.txt)

        if [ -f "${mode_reports[0]}" ]; then
            total_tests=$((total_tests + 1))
            local latest_report="${mode_reports[-1]}"
            local status=$(grep "Status:" "$latest_report" 2>/dev/null | awk '{print $2}' | tr -d '\r' || echo "UNKNOWN")

            if [ "$status" = "PASS" ]; then
                passed_tests=$((passed_tests + 1))
            elif [ "$status" = "FAIL" ]; then
                failed_tests=$((failed_tests + 1))
            fi
        else
            not_run=$((not_run + 1))
        fi
    done

    cat >> "$report_file" <<EOF
- **Total Modes Tested:** $total_tests
- **Passed:** $passed_tests
- **Failed:** $failed_tests
- **Not Run:** $not_run

## Individual Reports

EOF

    # List all individual reports
    for mode in basic intermediate advanced yolo; do
        local mode_reports=("$REPORTS_DIR"/${mode}-iteration-*.txt)

        if [ -f "${mode_reports[0]}" ]; then
            echo "### $mode Mode" >> "$report_file"
            echo "" >> "$report_file"

            for report in "${mode_reports[@]}"; do
                local basename=$(basename "$report")
                echo "- \`$basename\`" >> "$report_file"
            done

            echo "" >> "$report_file"
        fi
    done

    cat >> "$report_file" <<EOF

---

**Report Location:** $(realpath "$report_file")
EOF

    log_info "Summary report generated: $report_file"
    echo ""
    echo "========================================="
    echo "FINAL SUMMARY REPORT"
    echo "========================================="
    cat "$report_file"
    echo ""
    echo "========================================="
}
