#!/bin/bash
# Response feeder for automated skill testing
# Provides canned responses to skills for headless testing

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Logging functions
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Pre-pipe fallback: Feed default response sequences via stdin
# This is the Phase 1 implementation - simple and reliable
feed_responses_prepipe() {
    local mode="$1"

    log_info "Using pre-pipe fallback for $mode mode"

    # Fallback: Default response sequences
    case "$mode" in
        basic)
            echo -e "demo-app\npython\nyes\n" | claude skill sandbox-setup-basic
            ;;
        intermediate)
            echo -e "demo-app\npython\npostgres\nyes\n" | claude skill sandbox-setup-intermediate
            ;;
        advanced)
            echo -e "demo-app\npython\npostgres\n443,8080\nyes\n" | claude skill sandbox-setup-advanced
            ;;
        yolo)
            echo -e "demo-app\npython\nyes\n" | claude skill sandbox-setup-yolo
            ;;
        *)
            log_error "Unknown mode: $mode"
            return 1
            ;;
    esac

    return $?
}

# Parse YAML config file and extract response patterns and responses
# Returns lines in format: "pattern|||response" (using ||| as delimiter to avoid conflicts with regex OR)
parse_yaml_responses() {
    local config_file="$1"

    if [ ! -f "$config_file" ]; then
        log_error "Config file not found: $config_file"
        return 1
    fi

    # Parse YAML responses section manually
    # Format: extract prompt_pattern and response pairs
    local in_responses=false
    local current_pattern=""

    while IFS= read -r line; do
        # Check if we're entering responses section
        if [[ "$line" =~ ^responses: ]]; then
            in_responses=true
            continue
        fi

        # Stop if we hit another top-level key
        if [[ "$line" =~ ^[a-z_]+: ]] && [ "$in_responses" = true ]; then
            break
        fi

        if [ "$in_responses" = true ]; then
            # Extract prompt_pattern (with or without quotes)
            if [[ "$line" =~ prompt_pattern:[[:space:]]*\"(.+)\" ]]; then
                current_pattern="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ prompt_pattern:[[:space:]]*\'(.+)\' ]]; then
                current_pattern="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ prompt_pattern:[[:space:]]*([^[:space:]]+) ]]; then
                current_pattern="${BASH_REMATCH[1]}"
            fi

            # Extract response (with or without quotes)
            if [[ "$line" =~ response:[[:space:]]*\"(.+)\" ]]; then
                echo "$current_pattern|||${BASH_REMATCH[1]}"
                current_pattern=""
            elif [[ "$line" =~ response:[[:space:]]*\'(.+)\' ]]; then
                echo "$current_pattern|||${BASH_REMATCH[1]}"
                current_pattern=""
            elif [[ "$line" =~ response:[[:space:]]*([^[:space:]]+) ]]; then
                echo "$current_pattern|||${BASH_REMATCH[1]}"
                current_pattern=""
            fi
        fi
    done < "$config_file"
}

# Match a question against configured patterns and return response
# Args: question text, response_index (0-based), config_file
# Returns: response text or empty string if no match
match_pattern_get_response() {
    local question="$1"
    local response_index="$2"
    local config_file="$3"

    if [ ! -f "$config_file" ]; then
        log_error "Config file not found: $config_file"
        return 1
    fi

    # Convert question to lowercase for case-insensitive matching
    local question_lower=$(echo "$question" | tr '[:upper:]' '[:lower:]')

    # Parse all responses from config
    local patterns_responses=$(parse_yaml_responses "$config_file")

    # Try to match by index first (ordered matching)
    local current_index=0
    while IFS= read -r line; do
        # Split on ||| delimiter
        local pattern="${line%|||*}"
        local response="${line#*|||}"

        if [ $current_index -eq $response_index ]; then
            # Verify pattern matches the question
            if [[ "$question_lower" =~ $pattern ]]; then
                echo "$response"
                return 0
            else
                log_warn "Pattern mismatch at index $response_index" >&2
                log_warn "Expected pattern: $pattern" >&2
                log_warn "Got question: $question" >&2
                # Fall through to try any pattern match
            fi
        fi
        ((current_index++))
    done <<< "$patterns_responses"

    # If ordered match failed, try matching any pattern (resilience)
    while IFS= read -r line; do
        # Split on ||| delimiter
        local pattern="${line%|||*}"
        local response="${line#*|||}"

        if [[ "$question_lower" =~ $pattern ]]; then
            log_info "Matched out-of-order pattern: $pattern" >&2
            echo "$response"
            return 0
        fi
    done <<< "$patterns_responses"

    # No match found - provide safe default
    log_error "No response configured for question: $question" >&2

    # Safe defaults based on question type
    if [[ "$question_lower" =~ (confirm|proceed|continue|ok) ]]; then
        echo "yes"
    elif [[ "$question_lower" =~ (skip|none|no) ]]; then
        echo "none"
    else
        echo ""  # Let skill use defaults
    fi

    return 1  # Signal mismatch for reporting
}

# List all configured patterns from config file
list_configured_patterns() {
    local config_file="$1"

    if [ ! -f "$config_file" ]; then
        return 1
    fi

    log_info "Configured patterns in $config_file:"
    local patterns_responses=$(parse_yaml_responses "$config_file")

    while IFS= read -r line; do
        # Split on ||| delimiter
        local pattern="${line%|||*}"
        local response="${line#*|||}"
        echo "  Pattern: $pattern -> Response: $response"
    done <<< "$patterns_responses"
}

# Placeholder for Phase 3: Interactive monitoring with named pipes
# This will be implemented in a future phase
feed_responses_interactive() {
    local mode="$1"
    local config_file="$2"

    log_warn "Interactive monitoring not yet implemented (Phase 3)"
    log_info "Falling back to pre-pipe method"

    feed_responses_prepipe "$mode"
    return $?
}

# Main entry point: Try interactive first, fall back to pre-pipe
# Currently just uses pre-pipe (Phase 1)
feed_responses() {
    local mode="$1"
    local config_file="$2"

    # For Phase 1, always use pre-pipe
    # In future phases, this will check for config_file and use interactive
    feed_responses_prepipe "$mode"
    return $?
}
