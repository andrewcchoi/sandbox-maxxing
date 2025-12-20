#!/bin/bash
# Container file comparison engine
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load Python fallbacks for jq and bc if not available
if ! command -v jq >/dev/null 2>&1 || ! command -v bc >/dev/null 2>&1; then
    source "$SCRIPT_DIR/lib/python-fallbacks.sh"
fi

source "$SCRIPT_DIR/lib/section-parser.sh"
source "$SCRIPT_DIR/lib/diff-analyzer.sh"

# Compare generated files with templates
compare_with_templates() {
    local mode="$1"
    local generated_dir="$SCRIPT_DIR/generated/$mode"
    local templates_dir="/workspace/templates/master"

    local total_score=0
    local file_count=0

    # Compare devcontainer.json
    if [ -f "$generated_dir/.devcontainer/devcontainer.json" ]; then
        local score
        score=$(compare_devcontainer "$generated_dir/.devcontainer/devcontainer.json" "$templates_dir/devcontainer.json.master" "$mode")
        total_score=$(echo "$total_score + $score" | bc)
        ((file_count++))
    fi

    # Compare docker-compose.yml
    if [ -f "$generated_dir/docker-compose.yml" ]; then
        local score
        score=$(compare_compose "$generated_dir/docker-compose.yml" "$templates_dir/docker-compose.master.yml" "$mode")
        total_score=$(echo "$total_score + $score" | bc)
        ((file_count++))
    fi

    # Compare Dockerfile
    if [ -f "$generated_dir/.devcontainer/Dockerfile" ]; then
        local score
        score=$(compare_dockerfile "$generated_dir/.devcontainer/Dockerfile" "$templates_dir/Dockerfile.master" "$mode")
        total_score=$(echo "$total_score + $score" | bc)
        ((file_count++))
    fi

    # Calculate average
    if [ $file_count -gt 0 ]; then
        echo "scale=2; $total_score / $file_count" | bc
    else
        echo "0"
    fi
}

# Compare devcontainer.json files
compare_devcontainer() {
    local generated="$1"
    local template="$2"
    local mode="$3"

    # Validate syntax
    if ! validate_syntax "$generated"; then
        echo "0"
        return
    fi

    # Calculate structural similarity
    local structure_score
    structure_score=$(calculate_structure_similarity "$template" "$generated")

    echo "$structure_score"
}

# Compare docker-compose.yml files
compare_compose() {
    local generated="$1"
    local template="$2"
    local mode="$3"

    # Validate syntax
    if ! validate_syntax "$generated"; then
        echo "0"
        return
    fi

    # Calculate structural similarity
    local structure_score
    structure_score=$(calculate_structure_similarity "$template" "$generated")

    echo "$structure_score"
}

# Compare Dockerfile files
compare_dockerfile() {
    local generated="$1"
    local template="$2"
    local mode="$3"

    # Validate syntax
    if ! validate_syntax "$generated"; then
        echo "0"
        return
    fi

    # Count FROM stages
    local generated_stages template_stages
    generated_stages=$(grep -c "^FROM" "$generated" || echo "0")

    # Basic mode should have fewer stages
    case "$mode" in
        basic)
            # 1-2 stages acceptable
            if [ $generated_stages -ge 1 ] && [ $generated_stages -le 2 ]; then
                echo "90"
            else
                echo "50"
            fi
            ;;
        intermediate|advanced|yolo)
            # 2-3 stages expected
            if [ $generated_stages -ge 2 ] && [ $generated_stages -le 3 ]; then
                echo "95"
            else
                echo "60"
            fi
            ;;
    esac
}

# Export functions
export -f compare_with_templates
export -f compare_devcontainer
export -f compare_compose
export -f compare_dockerfile
