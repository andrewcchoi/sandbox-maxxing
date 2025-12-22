#!/bin/bash
# Container file comparison engine
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Logging
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Load Python fallbacks for jq and bc if not available
if ! command -v jq >/dev/null 2>&1 || ! command -v bc >/dev/null 2>&1; then
    source "$SCRIPT_DIR/lib/python-fallbacks.sh"
fi

source "$SCRIPT_DIR/lib/section-parser.sh"
source "$SCRIPT_DIR/lib/diff-analyzer.sh"

# Compare JSON files (devcontainer.json)
compare_json_files() {
    local generated="$1"
    local reference="$2"

    if [ ! -f "$generated" ]; then
        echo "0"
        return 1
    fi

    if [ ! -f "$reference" ]; then
        echo "0"
        return 1
    fi

    # Validate syntax
    if ! validate_syntax "$generated"; then
        echo "0"
        return 1
    fi

    # Calculate structural similarity
    local score
    score=$(calculate_structure_similarity "$reference" "$generated")
    echo "$score"
}

# Compare YAML files (docker-compose.yml)
compare_yaml_files() {
    local generated="$1"
    local reference="$2"

    if [ ! -f "$generated" ]; then
        echo "0"
        return 1
    fi

    if [ ! -f "$reference" ]; then
        echo "0"
        return 1
    fi

    # Validate syntax
    if ! validate_syntax "$generated"; then
        echo "0"
        return 1
    fi

    # Calculate structural similarity
    local score
    score=$(calculate_structure_similarity "$reference" "$generated")
    echo "$score"
}

# Compare Dockerfiles
compare_dockerfiles() {
    local generated="$1"
    local reference="$2"

    if [ ! -f "$generated" ]; then
        echo "0"
        return 1
    fi

    if [ ! -f "$reference" ]; then
        echo "0"
        return 1
    fi

    # Validate syntax
    if ! validate_syntax "$generated"; then
        echo "0"
        return 1
    fi

    # Count FROM stages
    local generated_stages reference_stages
    generated_stages=$(grep -c "^FROM" "$generated" || echo "0")
    reference_stages=$(grep -c "^FROM" "$reference" || echo "0")

    # Check key instructions exist
    local has_workdir has_copy has_run
    has_workdir=$(grep -c "^WORKDIR" "$generated" || echo "0")
    has_copy=$(grep -c "^COPY" "$generated" || echo "0")
    has_run=$(grep -c "^RUN" "$generated" || echo "0")

    # Calculate score based on structure
    local score=0

    # FROM stages similarity (40 points)
    if [ "$generated_stages" -eq "$reference_stages" ]; then
        score=$((score + 40))
    elif [ "$generated_stages" -gt 0 ]; then
        score=$((score + 20))
    fi

    # Required instructions (60 points total)
    [ "$has_workdir" -gt 0 ] && score=$((score + 20))
    [ "$has_copy" -gt 0 ] && score=$((score + 20))
    [ "$has_run" -gt 0 ] && score=$((score + 20))

    echo "$score"
}

# Compare shell scripts
compare_shell_scripts() {
    local generated="$1"
    local reference="$2"

    if [ ! -f "$generated" ]; then
        echo "0"
        return 1
    fi

    if [ ! -f "$reference" ]; then
        echo "0"
        return 1
    fi

    # Check if executable
    local score=0
    [ -x "$generated" ] && score=$((score + 20))

    # Check for shebang
    if head -1 "$generated" | grep -q "^#!"; then
        score=$((score + 20))
    fi

    # Compare line counts (rough similarity)
    local generated_lines reference_lines
    generated_lines=$(wc -l < "$generated")
    reference_lines=$(wc -l < "$reference")

    # Calculate line count similarity (60 points)
    if [ "$reference_lines" -gt 0 ]; then
        local line_ratio
        line_ratio=$(echo "scale=2; $generated_lines / $reference_lines" | bc)

        # Score based on how close to 1.0 the ratio is
        if (( $(echo "$line_ratio >= 0.8 && $line_ratio <= 1.2" | bc -l) )); then
            score=$((score + 60))
        elif (( $(echo "$line_ratio >= 0.5 && $line_ratio <= 1.5" | bc -l) )); then
            score=$((score + 40))
        else
            score=$((score + 20))
        fi
    fi

    echo "$score"
}

# Compare generated files with examples (preferred)
compare_with_examples() {
    local mode="$1"
    local generated_dir="$SCRIPT_DIR/generated/$mode"
    local example_dir="/workspace/examples/demo-app-sandbox-$mode"

    log_info "Comparing generated files against examples for $mode..."

    # Check if example exists
    if [ ! -d "$example_dir" ]; then
        log_warn "No example for $mode, falling back to template comparison"
        compare_with_templates "$mode"
        return $?
    fi

    local total_score=0
    local file_count=0

    # Compare devcontainer.json
    if [ -f "$example_dir/.devcontainer/devcontainer.json" ]; then
        local score
        score=$(compare_json_files \
            "$generated_dir/.devcontainer/devcontainer.json" \
            "$example_dir/.devcontainer/devcontainer.json")
        total_score=$(echo "$total_score + $score" | bc)
        ((file_count++))
        log_info "devcontainer.json similarity: $score%"
    fi

    # Compare docker-compose.yml
    if [ -f "$example_dir/docker-compose.yml" ]; then
        local score
        score=$(compare_yaml_files \
            "$generated_dir/docker-compose.yml" \
            "$example_dir/docker-compose.yml")
        total_score=$(echo "$total_score + $score" | bc)
        ((file_count++))
        log_info "docker-compose.yml similarity: $score%"
    fi

    # Compare Dockerfile
    if [ -f "$example_dir/.devcontainer/Dockerfile" ]; then
        local score
        score=$(compare_dockerfiles \
            "$generated_dir/.devcontainer/Dockerfile" \
            "$example_dir/.devcontainer/Dockerfile")
        total_score=$(echo "$total_score + $score" | bc)
        ((file_count++))
        log_info "Dockerfile similarity: $score%"
    fi

    # Compare shell scripts
    for script in init-firewall.sh setup-claude-credentials.sh; do
        if [ -f "$example_dir/.devcontainer/$script" ]; then
            local score
            score=$(compare_shell_scripts \
                "$generated_dir/.devcontainer/$script" \
                "$example_dir/.devcontainer/$script")
            total_score=$(echo "$total_score + $score" | bc)
            ((file_count++))
            log_info "$script similarity: $score%"
        fi
    done

    # Calculate average
    if [ $file_count -eq 0 ]; then
        log_error "No files compared"
        echo "0"
        return 1
    fi

    local avg_score
    avg_score=$(echo "scale=2; $total_score / $file_count" | bc)
    log_info "Average similarity for $mode: $avg_score%"
    echo "$avg_score"
}

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
