#!/bin/bash
# Validate test-config.yml files for all sandbox modes
# This script checks that configs are properly formatted and patterns work

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Logging
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Load response feeder for parsing functions
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$TEST_DIR/lib/response-feeder.sh"

# Validate a single config file
validate_config() {
    local mode="$1"
    local config_file="/workspace/examples/demo-app-sandbox-$mode/test-config.yml"
    local errors=0

    log_info "Validating $mode mode config..."

    # Check file exists
    if [ ! -f "$config_file" ]; then
        log_error "Config file not found: $config_file"
        return 1
    fi

    # Check YAML can be parsed
    local parsed_responses=$(parse_yaml_responses "$config_file")
    if [ -z "$parsed_responses" ]; then
        log_error "Failed to parse YAML or no responses found"
        ((errors++))
    else
        local response_count=$(echo "$parsed_responses" | wc -l)
        log_info "Found $response_count response patterns"
    fi

    # Check expected_files exist
    log_info "Checking expected files..."
    local example_dir="/workspace/examples/demo-app-sandbox-$mode"

    # Extract expected files from metadata section
    local in_expected=false
    while IFS= read -r line; do
        # Strip comments
        line=$(echo "$line" | sed 's/#.*$//')

        # Check if entering expected_files section
        if [[ "$line" =~ expected_files: ]]; then
            in_expected=true
            continue
        fi

        # Stop if we hit responses section
        if [[ "$line" =~ ^responses: ]] && [ "$in_expected" = true ]; then
            break
        fi

        # Extract file path from list item
        if [ "$in_expected" = true ] && [[ "$line" =~ ^[[:space:]]*-[[:space:]]*(.+)$ ]]; then
            local file_path="${BASH_REMATCH[1]}"
            if [ -f "$example_dir/$file_path" ]; then
                log_info "  ✓ $file_path"
            else
                log_error "  ✗ $file_path NOT FOUND"
                ((errors++))
            fi
        fi
    done < "$config_file"

    # Test pattern matching with sample questions
    log_info "Testing pattern matching..."

    # Test project name pattern
    local response=$(match_pattern_get_response "What is your project name?" 0 "$config_file" 2>/dev/null)
    if [ -n "$response" ]; then
        log_info "  ✓ Project name pattern matches: '$response'"
    else
        log_error "  ✗ Project name pattern failed"
        ((errors++))
    fi

    # Test language pattern
    response=$(match_pattern_get_response "Choose a language or stack:" 1 "$config_file" 2>/dev/null)
    if [ -n "$response" ]; then
        log_info "  ✓ Language pattern matches: '$response'"
    else
        log_error "  ✗ Language pattern failed"
        ((errors++))
    fi

    # Mode-specific pattern tests
    case "$mode" in
        intermediate|advanced)
            response=$(match_pattern_get_response "Do you want database services?" 2 "$config_file" 2>/dev/null)
            if [ -n "$response" ]; then
                log_info "  ✓ Database pattern matches: '$response'"
            else
                log_error "  ✗ Database pattern failed"
                ((errors++))
            fi
            ;;
    esac

    if [ "$mode" = "advanced" ]; then
        response=$(match_pattern_get_response "Which firewall ports should be allowed?" 3 "$config_file" 2>/dev/null)
        if [ -n "$response" ]; then
            log_info "  ✓ Firewall port pattern matches: '$response'"
        else
            log_error "  ✗ Firewall port pattern failed"
            ((errors++))
        fi
    fi

    # Test confirmation pattern (should be last in all modes)
    response=$(match_pattern_get_response "Do you want to proceed?" 99 "$config_file" 2>/dev/null)
    if [ -n "$response" ]; then
        log_info "  ✓ Confirmation pattern matches: '$response'"
    else
        log_error "  ✗ Confirmation pattern failed"
        ((errors++))
    fi

    if [ $errors -eq 0 ]; then
        log_info "✓ $mode mode config is VALID"
        return 0
    else
        log_error "✗ $mode mode config has $errors error(s)"
        return 1
    fi
}

# Main
main() {
    local modes=("basic" "intermediate" "advanced" "yolo")
    local total_errors=0

    log_info "Starting config validation for all modes"
    echo

    for mode in "${modes[@]}"; do
        if ! validate_config "$mode"; then
            ((total_errors++))
        fi
        echo
    done

    if [ $total_errors -eq 0 ]; then
        log_info "================================================"
        log_info "✓ ALL CONFIGS VALID - Ready for testing"
        log_info "================================================"
        return 0
    else
        log_error "================================================"
        log_error "✗ $total_errors mode(s) have invalid configs"
        log_error "================================================"
        return 1
    fi
}

main "$@"
