#!/bin/bash
# exclusions.sh
# Library for handling .repokeeper-ignore file patterns

# Auto-detect repo root
if [[ -z "${REPO_ROOT:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
fi

# Allow override via environment variable
if [[ -n "${REPO_ROOT_OVERRIDE:-}" ]]; then
    REPO_ROOT="$REPO_ROOT_OVERRIDE"
fi

# Path to ignore file (can be overridden via env var)
IGNORE_FILE="${REPOKEEPER_IGNORE_FILE:-$REPO_ROOT/.repokeeper-ignore}"

# Flag to disable exclusions (can be set via --no-ignore flag)
NO_IGNORE="${REPOKEEPER_NO_IGNORE:-false}"

# Cache for exclusion patterns
declare -a EXCLUSION_PATTERNS
declare -a NEGATION_PATTERNS
PATTERNS_LOADED=false

# Load exclusion patterns from .repokeeper-ignore
# Populates EXCLUSION_PATTERNS and NEGATION_PATTERNS arrays
load_exclusions() {
    if [ "$PATTERNS_LOADED" = true ]; then
        return 0
    fi

    # If --no-ignore flag is set, don't load any patterns
    if [ "$NO_IGNORE" = true ]; then
        PATTERNS_LOADED=true
        return 0
    fi

    # Check if ignore file exists
    if [ ! -f "$IGNORE_FILE" ]; then
        # No ignore file, just use built-in exclusions
        EXCLUSION_PATTERNS=("node_modules/" ".git/")
        PATTERNS_LOADED=true
        return 0
    fi

    # Read patterns from file
    while IFS= read -r line; do
        # Skip empty lines
        [ -z "$line" ] && continue

        # Skip comments
        [[ "$line" =~ ^[[:space:]]*# ]] && continue

        # Trim whitespace
        line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        [ -z "$line" ] && continue

        # Check for negation pattern (starts with !)
        if [[ "$line" =~ ^\! ]]; then
            # Remove ! prefix and add to negation patterns
            pattern="${line:1}"
            NEGATION_PATTERNS+=("$pattern")
        else
            # Regular exclusion pattern
            EXCLUSION_PATTERNS+=("$line")
        fi
    done < "$IGNORE_FILE"

    # Always exclude node_modules and .git (built-in)
    EXCLUSION_PATTERNS+=("node_modules/" ".git/")

    PATTERNS_LOADED=true
    return 0
}

# Generate find command exclusion string
# Returns: String like "! -path '*/pattern/*' ! -path '*/other/*'"
# Usage: find "$REPO_ROOT" $(get_find_exclusions) -name "*.md" -type f
get_find_exclusions() {
    load_exclusions

    local exclusion_string=""

    # Add exclusion clauses
    for pattern in "${EXCLUSION_PATTERNS[@]}"; do
        # Convert pattern to find -path format
        # If pattern ends with /, it's a directory
        if [[ "$pattern" =~ /$ ]]; then
            # Directory pattern: match any path containing this directory
            exclusion_string="$exclusion_string ! -path '*/${pattern}*'"
        elif [[ "$pattern" =~ \* ]]; then
            # Wildcard pattern: use as-is with path match
            exclusion_string="$exclusion_string ! -path '*/$pattern'"
        else
            # File pattern: match exact filename
            exclusion_string="$exclusion_string ! -name '$pattern'"
        fi
    done

    echo "$exclusion_string"
}

# Check if a path should be excluded
# Usage: if should_exclude "$filepath"; then continue; fi
# Returns: 0 if should exclude, 1 if should not exclude
should_exclude() {
    local filepath="$1"
    load_exclusions

    # If --no-ignore, never exclude
    if [ "$NO_IGNORE" = true ]; then
        return 1
    fi

    # Make path relative to repo root
    local relative_path="${filepath#$REPO_ROOT/}"

    # Check negation patterns first (if pattern matches negation, don't exclude)
    for pattern in "${NEGATION_PATTERNS[@]}"; do
        if [[ "$relative_path" == $pattern ]] || [[ "$relative_path" == *"/$pattern"* ]]; then
            return 1  # Don't exclude (negation matched)
        fi
    done

    # Check exclusion patterns
    for pattern in "${EXCLUSION_PATTERNS[@]}"; do
        # Directory pattern (ends with /)
        if [[ "$pattern" =~ /$ ]]; then
            # Check if path contains this directory
            if [[ "$relative_path" == "${pattern}"* ]] || [[ "$relative_path" == *"/${pattern}"* ]]; then
                return 0  # Should exclude
            fi
        # Wildcard pattern
        elif [[ "$pattern" =~ \* ]]; then
            if [[ "$relative_path" == $pattern ]]; then
                return 0  # Should exclude
            fi
        # Exact filename match
        else
            local filename=$(basename "$filepath")
            if [[ "$filename" == "$pattern" ]]; then
                return 0  # Should exclude
            fi
        fi
    done

    return 1  # Don't exclude
}

# Get count of loaded exclusion patterns (for verbose output)
get_exclusion_count() {
    load_exclusions
    echo "${#EXCLUSION_PATTERNS[@]}"
}
