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
