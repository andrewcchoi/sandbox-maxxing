#!/bin/bash
# Direct generator for skill testing - bypasses Skill tool
# This script directly copies and customizes DevContainer templates from skill directories
# to enable automated testing without permission prompts.

# Colors for logging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Enhanced logging functions with timestamps
log_info() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [DIRECT-GEN] [INFO] $1"
    echo -e "${GREEN}${msg}${NC}"
    [ -n "${LOG_FILE:-}" ] && echo "$msg" >> "$LOG_FILE"
}

log_warn() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [DIRECT-GEN] [WARN] $1"
    echo -e "${YELLOW}${msg}${NC}"
    [ -n "${LOG_FILE:-}" ] && echo "$msg" >> "$LOG_FILE"
}

log_error() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [DIRECT-GEN] [ERROR] $1"
    echo -e "${RED}${msg}${NC}"
    [ -n "${LOG_FILE:-}" ] && echo "$msg" >> "$LOG_FILE"
}

log_debug() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [DIRECT-GEN] [DEBUG] $1"
    if [ "${DEBUG:-false}" = "true" ]; then
        echo -e "${BLUE}${msg}${NC}"
    fi
    [ -n "${LOG_FILE:-}" ] && echo "$msg" >> "$LOG_FILE"
}

# Create basic mode firewall placeholder script
create_basic_firewall_script() {
    local output_file="$1"

    log_debug "Creating basic mode firewall placeholder: $output_file"

    cat > "$output_file" << 'EOF'
#!/bin/bash
echo "=========================================="
echo "FIREWALL: BASIC MODE"
echo "=========================================="
echo "No firewall configured (Basic mode - relies on sandbox isolation)"
echo "=========================================="
exit 0
EOF

    chmod +x "$output_file"
    log_debug "Created and made executable: $output_file"
}

# Main generation function - copies templates and customizes them
generate_devcontainer_direct() {
    local mode="$1"           # basic, intermediate, advanced, yolo
    local project_name="$2"   # e.g., demo-app
    local language="$3"       # python, node
    local output_dir="$4"     # where to create files

    log_info "=== Starting direct generation for $mode mode ==="
    log_info "Project: $project_name, Language: $language, Output: $output_dir"

    # Determine skill templates directory
    local skill_dir="/workspace/skills/devcontainer-setup-$mode/templates"

    # Verify skill templates directory exists
    if [ ! -d "$skill_dir" ]; then
        log_error "Skill templates directory not found: $skill_dir"
        return 1
    fi

    log_info "Using templates from: $skill_dir"

    # Create .devcontainer directory
    mkdir -p "$output_dir/.devcontainer"
    log_debug "Created directory: $output_dir/.devcontainer"

    # Copy docker-compose.yml to root with customization
    if [ -f "$skill_dir/docker-compose.yml" ]; then
        log_info "Copying docker-compose.yml with customization..."
        sed "s/{{PROJECT_NAME}}/$project_name/g" "$skill_dir/docker-compose.yml" > "$output_dir/docker-compose.yml"
        log_debug "Created: $output_dir/docker-compose.yml"
    else
        log_warn "Template not found: $skill_dir/docker-compose.yml"
    fi

    # Copy devcontainer.json with customization
    if [ -f "$skill_dir/devcontainer.json" ]; then
        log_info "Copying devcontainer.json with customization..."
        sed "s/{{PROJECT_NAME}}/$project_name/g" "$skill_dir/devcontainer.json" > "$output_dir/.devcontainer/devcontainer.json"
        log_debug "Created: $output_dir/.devcontainer/devcontainer.json"
    else
        log_warn "Template not found: $skill_dir/devcontainer.json"
    fi

    # Copy appropriate Dockerfile based on language
    local dockerfile_src="$skill_dir/Dockerfile.$language"
    if [ -f "$dockerfile_src" ]; then
        log_info "Copying Dockerfile.$language..."
        cp "$dockerfile_src" "$output_dir/.devcontainer/Dockerfile"
        log_debug "Created: $output_dir/.devcontainer/Dockerfile (from Dockerfile.$language)"
    elif [ -f "$skill_dir/Dockerfile.python" ]; then
        # Default to python if language-specific not found
        log_warn "Dockerfile.$language not found, defaulting to Dockerfile.python"
        cp "$skill_dir/Dockerfile.python" "$output_dir/.devcontainer/Dockerfile"
        log_debug "Created: $output_dir/.devcontainer/Dockerfile (from Dockerfile.python)"
    else
        log_error "No Dockerfile found in templates"
    fi

    # Copy shell scripts
    local scripts_copied=0
    for script in setup-claude-credentials.sh init-firewall.sh; do
        if [ -f "$skill_dir/$script" ]; then
            log_info "Copying $script..."
            cp "$skill_dir/$script" "$output_dir/.devcontainer/"
            chmod +x "$output_dir/.devcontainer/$script"
            log_debug "Created and made executable: $output_dir/.devcontainer/$script"
            ((scripts_copied++))
        else
            log_debug "Template not found: $skill_dir/$script"
        fi
    done

    # Basic mode has no firewall in templates - create placeholder
    if [ "$mode" = "basic" ] && [ ! -f "$output_dir/.devcontainer/init-firewall.sh" ]; then
        log_info "Creating basic mode firewall placeder..."
        create_basic_firewall_script "$output_dir/.devcontainer/init-firewall.sh"
    fi

    # Copy optional template files if they exist
    for optional_file in extensions.json mcp.json variables.json .env.template; do
        if [ -f "$skill_dir/$optional_file" ]; then
            if [[ "$optional_file" == .* ]]; then
                # Hidden file - copy to root
                cp "$skill_dir/$optional_file" "$output_dir/"
                log_debug "Copied optional: $output_dir/$optional_file"
            else
                # Regular file - copy to .devcontainer
                cp "$skill_dir/$optional_file" "$output_dir/.devcontainer/"
                log_debug "Copied optional: $output_dir/.devcontainer/$optional_file"
            fi
        fi
    done

    log_info "DevContainer files generated successfully for $mode mode"

    # Run validation
    validate_generated_files "$output_dir" "$mode"
    local validation_result=$?

    return $validation_result
}

# Validate that all required files were generated
validate_generated_files() {
    local output_dir="$1"
    local mode="$2"
    local errors=0

    log_info "=== Validating generated files for $mode mode ==="

    # Check required files
    if [ ! -f "$output_dir/.devcontainer/devcontainer.json" ]; then
        log_error "Missing required file: devcontainer.json"
        ((errors++))
    else
        log_debug "✓ devcontainer.json exists"
    fi

    if [ ! -f "$output_dir/.devcontainer/Dockerfile" ]; then
        log_error "Missing required file: Dockerfile"
        ((errors++))
    else
        log_debug "✓ Dockerfile exists"
    fi

    if [ ! -f "$output_dir/docker-compose.yml" ]; then
        log_error "Missing required file: docker-compose.yml"
        ((errors++))
    else
        log_debug "✓ docker-compose.yml exists"
    fi

    if [ ! -f "$output_dir/.devcontainer/setup-claude-credentials.sh" ]; then
        log_error "Missing required file: setup-claude-credentials.sh"
        ((errors++))
    else
        log_debug "✓ setup-claude-credentials.sh exists"
    fi

    # Basic mode requires init-firewall.sh (even if it's just a placeholder)
    if [ ! -f "$output_dir/.devcontainer/init-firewall.sh" ]; then
        log_error "Missing required file: init-firewall.sh"
        ((errors++))
    else
        log_debug "✓ init-firewall.sh exists"
    fi

    # Verify Dockerfile has substantial content
    if [ -f "$output_dir/.devcontainer/Dockerfile" ]; then
        local lines=$(wc -l < "$output_dir/.devcontainer/Dockerfile" 2>/dev/null || echo "0")
        if [ "$lines" -lt 20 ]; then
            log_error "Dockerfile too short ($lines lines, expected >= 20)"
            ((errors++))
        else
            log_debug "✓ Dockerfile has $lines lines (>= 20)"
        fi
    fi

    # Summary
    if [ $errors -eq 0 ]; then
        log_info "✓ Validation passed: all required files present and valid"
        return 0
    else
        log_error "✗ Validation failed: $errors error(s) detected"
        return 1
    fi
}

# List files in output directory for debugging
list_generated_files() {
    local output_dir="$1"

    log_info "=== Generated files in $output_dir ==="

    if [ -f "$output_dir/docker-compose.yml" ]; then
        log_info "  ✓ docker-compose.yml ($(wc -l < "$output_dir/docker-compose.yml") lines)"
    fi

    if [ -d "$output_dir/.devcontainer" ]; then
        log_info "  ✓ .devcontainer/"
        for file in "$output_dir/.devcontainer"/*; do
            if [ -f "$file" ]; then
                local basename=$(basename "$file")
                local lines=$(wc -l < "$file" 2>/dev/null || echo "0")
                log_info "      ✓ $basename ($lines lines)"
            fi
        done
    else
        log_warn "  ✗ .devcontainer/ directory not found"
    fi
}

# Export functions for use in other scripts
export -f generate_devcontainer_direct
export -f validate_generated_files
export -f create_basic_firewall_script
export -f list_generated_files
export -f log_info
export -f log_warn
export -f log_error
export -f log_debug
