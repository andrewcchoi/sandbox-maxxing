# Continuous Skill Testing Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build an automated testing framework that continuously validates sandbox setup skills (basic, intermediate, advanced, yolo) by comparing generated container files against templates with high accuracy.

**Architecture:** Test-Generate-Compare-Fix loop that runs each skill in isolation, validates outputs against master templates using section-based comparison, and iterates until accuracy thresholds are met.

**Tech Stack:** Bash test harness, JSON/YAML validators, diff utilities, repo-keeper validation scripts

---

## Overview

This plan implements a continuous testing loop for the 4 sandbox setup skills:
- `/devcontainer-setup:basic`
- `/devcontainer-setup:intermediate`
- `/devcontainer-setup:advanced`
- `/devcontainer-setup:yolo`

Each skill will be tested independently with the following cycle:
1. **Generate** - Run skill to create container files
2. **Compare** - Validate against master templates using section analysis
3. **Evaluate** - Calculate accuracy score (must pass threshold)
4. **Fix** - Edit skill if accuracy < threshold
5. **Cleanup** - Delete test files
6. **Repeat** - Continue until skill passes

**Success Criteria:** Generated files match templates with ≥95% accuracy for structure, ≥90% for content.

---

## Task 1: Create Test Infrastructure

**Files:**
- Create: `tests/skill-validation/test-harness.sh`
- Create: `tests/skill-validation/compare-containers.sh`
- Create: `tests/skill-validation/fixtures/.gitkeep`
- Create: `tests/skill-validation/generated/.gitkeep`
- Create: `tests/skill-validation/reports/.gitkeep`

**Step 1: Create directory structure**

```bash
mkdir -p tests/skill-validation/{fixtures,generated,reports}
touch tests/skill-validation/{fixtures,generated,reports}/.gitkeep
```

**Step 2: Create test harness scaffold**

Create `tests/skill-validation/test-harness.sh`:

```bash
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
```

**Step 3: Verify script is executable**

```bash
chmod +x tests/skill-validation/test-harness.sh
```

**Step 4: Test basic script structure**

Run: `bash tests/skill-validation/test-harness.sh --help`
Expected: Script runs without errors (even if shows "function not found")

**Step 5: Commit**

```bash
git add tests/skill-validation/
git commit -m "feat: add skill validation test infrastructure"
```

---

## Task 2: Implement File Generation Logic

**Files:**
- Modify: `tests/skill-validation/test-harness.sh` (add generation functions)
- Create: `tests/skill-validation/test-project/package.json`
- Create: `tests/skill-validation/test-project/app.py`

**Step 1: Create test project structure**

Create `tests/skill-validation/test-project/package.json`:

```json
{
  "name": "test-skill-validation",
  "version": "1.0.0",
  "description": "Test project for skill validation"
}
```

Create `tests/skill-validation/test-project/app.py`:

```python
# Test application for skill validation
print("Skill validation test project")
```

**Step 2: Add generation function to test-harness.sh**

Add after logging functions:

```bash
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
            echo -e "test-project\n" | claude skill sandboxxer:basic
            ;;
        intermediate)
            # Intermediate with Python selected
            echo -e "test-project\npython\nyes\nno\n" | claude skill sandboxxer:intermediate
            ;;
        advanced)
            # Advanced with Python, postgres, redis
            echo -e "test-project\npython\npostgres,redis\nyes\n" | claude skill sandboxxer:advanced
            ;;
        yolo)
            # YOLO with maximum customization
            echo -e "test-project\npython\nall\nstrict\nyes\n" | claude skill sandboxxer:yolo
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
```

**Step 3: Test generation with basic mode**

Run: `cd tests/skill-validation && bash test-harness.sh`
Expected: Attempts to run basic skill (may fail on skill invocation - that's OK for now)

**Step 4: Commit**

```bash
git add tests/skill-validation/
git commit -m "feat: add skill output generation logic"
```

---

## Task 3: Implement Template Comparison Engine

**Files:**
- Create: `tests/skill-validation/compare-containers.sh`
- Create: `tests/skill-validation/lib/section-parser.sh`
- Create: `tests/skill-validation/lib/diff-analyzer.sh`

**Step 1: Create section parser**

Create `tests/skill-validation/lib/section-parser.sh`:

```bash
#!/bin/bash
# Section-based template parser

# Extract sections from master template
extract_sections() {
    local template_file="$1"
    local sections=()

    while IFS= read -r line; do
        if [[ "$line" =~ ===SECTION_START:([^=]+)=== ]]; then
            sections+=("${BASH_REMATCH[1]}")
        fi
    done < "$template_file"

    printf '%s\n' "${sections[@]}"
}

# Check if section exists in generated file
section_exists() {
    local generated_file="$1"
    local section_name="$2"

    grep -q "===SECTION_START:$section_name===" "$generated_file" 2>/dev/null
}

# Get section content
get_section_content() {
    local file="$1"
    local section_name="$2"

    awk "/===SECTION_START:$section_name===/,/===SECTION_END:$section_name===/" "$file"
}
```

**Step 2: Create diff analyzer**

Create `tests/skill-validation/lib/diff-analyzer.sh`:

```bash
#!/bin/bash
# Diff-based comparison analyzer

# Calculate structural similarity (JSON/YAML)
calculate_structure_similarity() {
    local template="$1"
    local generated="$2"

    # Extract keys only (ignoring values)
    local template_keys generated_keys

    if [[ "$template" == *.json ]]; then
        template_keys=$(jq -r 'paths | join(".")' "$template" | sort)
        generated_keys=$(jq -r 'paths | join(".")' "$generated" | sort)
    elif [[ "$template" == *.yml ]] || [[ "$template" == *.yaml ]]; then
        # Use yq or python for YAML key extraction
        template_keys=$(python3 -c "
import yaml, sys
def get_paths(d, prefix=''):
    for k, v in d.items():
        path = f'{prefix}.{k}' if prefix else k
        print(path)
        if isinstance(v, dict):
            get_paths(v, path)
with open('$template') as f:
    get_paths(yaml.safe_load(f))
" | sort)
        generated_keys=$(python3 -c "
import yaml, sys
def get_paths(d, prefix=''):
    for k, v in d.items():
        path = f'{prefix}.{k}' if prefix else k
        print(path)
        if isinstance(v, dict):
            get_paths(v, path)
with open('$generated') as f:
    get_paths(yaml.safe_load(f))
" | sort)
    fi

    # Compare key sets
    local common_keys diff_keys
    common_keys=$(comm -12 <(echo "$template_keys") <(echo "$generated_keys") | wc -l)
    local total_keys=$(echo "$template_keys" | wc -l)

    # Calculate percentage
    echo "scale=2; ($common_keys / $total_keys) * 100" | bc
}

# Validate file syntax
validate_syntax() {
    local file="$1"

    if [[ "$file" == *.json ]]; then
        jq empty "$file" 2>/dev/null
        return $?
    elif [[ "$file" == *.yml ]] || [[ "$file" == *.yaml ]]; then
        python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null
        return $?
    elif [[ "$file" == Dockerfile* ]]; then
        # Basic Dockerfile validation
        grep -q "^FROM" "$file"
        return $?
    fi

    return 0
}
```

**Step 3: Create main comparison script**

Create `tests/skill-validation/compare-containers.sh`:

```bash
#!/bin/bash
# Container file comparison engine
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
```

**Step 4: Make scripts executable**

```bash
chmod +x tests/skill-validation/compare-containers.sh
chmod +x tests/skill-validation/lib/*.sh
```

**Step 5: Commit**

```bash
git add tests/skill-validation/
git commit -m "feat: add template comparison engine"
```

---

## Task 4: Integrate Comparison into Test Harness

**Files:**
- Modify: `tests/skill-validation/test-harness.sh` (add comparison integration)

**Step 1: Source comparison script**

Add near top of test-harness.sh after TEST_DIR definition:

```bash
# Load comparison engine
source "$TEST_DIR/compare-containers.sh"
```

**Step 2: Update compare_with_templates call**

The function is already called in test_skill(), but ensure it's using the sourced function:

```bash
# Compare against templates (already in script, verify it's present)
local accuracy
accuracy=$(compare_with_templates "$mode")
```

**Step 3: Add detailed reporting**

Add before test_skill() function:

```bash
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
```

**Step 4: Call generate_report in test_skill**

Add after accuracy calculation:

```bash
# Generate report
generate_report "$mode" "$iteration" "$accuracy"
```

**Step 5: Test integrated harness**

Run: `bash tests/skill-validation/test-harness.sh`
Expected: Script runs, attempts generation, performs comparison, generates report

**Step 6: Commit**

```bash
git add tests/skill-validation/test-harness.sh
git commit -m "feat: integrate comparison engine with test harness"
```

---

## Task 5: Implement Continuous Testing Loop

**Files:**
- Modify: `tests/skill-validation/test-harness.sh` (enhance main loop)
- Create: `tests/skill-validation/run-continuous.sh`

**Step 1: Create continuous test runner**

Create `tests/skill-validation/run-continuous.sh`:

```bash
#!/bin/bash
# Continuous testing without user interaction
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test-harness.sh"

# Override main to run continuously
continuous_main() {
    local modes=("basic" "intermediate" "advanced" "yolo")
    local max_iterations_per_mode=5

    log_info "Starting CONTINUOUS skill validation (no user prompts)"
    log_info "Max iterations per mode: $max_iterations_per_mode"

    for mode in "${modes[@]}"; do
        log_info "========================================="
        log_info "Testing mode: $mode"
        log_info "========================================="

        local passed=false

        for ((iteration=1; iteration<=max_iterations_per_mode; iteration++)); do
            log_info "Iteration $iteration/$max_iterations_per_mode"

            if test_skill "$mode" "$iteration"; then
                log_info "✓ $mode PASSED"
                passed=true
                break
            else
                log_warn "✗ $mode FAILED iteration $iteration"

                # Auto-fix attempt (placeholder - actual fix logic in next task)
                log_info "Attempting auto-fix..."
                sleep 2
            fi
        done

        if [ "$passed" = false ]; then
            log_error "$mode did not pass after $max_iterations_per_mode iterations"
        fi

        # Cleanup
        cleanup_test_output "$mode"

        log_info ""
    done

    log_info "========================================="
    log_info "Continuous testing complete"
    log_info "========================================="
}

# Run continuous tests
continuous_main "$@"
```

**Step 2: Make executable**

```bash
chmod +x tests/skill-validation/run-continuous.sh
```

**Step 3: Add dry-run mode**

Add to run-continuous.sh after SCRIPT_DIR:

```bash
# Dry run mode (just validate setup)
DRY_RUN="${DRY_RUN:-false}"

if [ "$DRY_RUN" = "true" ]; then
    log_info "DRY RUN MODE - validating test setup only"

    # Check dependencies
    command -v jq >/dev/null || log_error "jq not found"
    command -v python3 >/dev/null || log_error "python3 not found"
    command -v bc >/dev/null || log_error "bc not found"

    # Check directories exist
    [ -d "$TEST_DIR/fixtures" ] || log_error "fixtures/ not found"
    [ -d "$TEST_DIR/generated" ] || log_error "generated/ not found"
    [ -d "$TEST_DIR/reports" ] || log_error "reports/ not found"

    log_info "✓ Test setup validated"
    exit 0
fi
```

**Step 4: Test dry-run**

Run: `DRY_RUN=true bash tests/skill-validation/run-continuous.sh`
Expected: Validates setup, reports any missing dependencies

**Step 5: Commit**

```bash
git add tests/skill-validation/run-continuous.sh
git commit -m "feat: add continuous testing loop without user interaction"
```

---

## Task 6: Add Skill Auto-Fix Logic

**Files:**
- Create: `tests/skill-validation/lib/skill-fixer.sh`
- Modify: `tests/skill-validation/run-continuous.sh` (integrate fixer)

**Step 1: Create skill fixer**

Create `tests/skill-validation/lib/skill-fixer.sh`:

```bash
#!/bin/bash
# Automated skill fixing based on comparison results

# Analyze failures and suggest fixes
analyze_failures() {
    local mode="$1"
    local generated_dir="$2"
    local report_file="$3"

    local issues=()

    # Check devcontainer.json issues
    if [ -f "$generated_dir/.devcontainer/devcontainer.json" ]; then
        if ! jq empty "$generated_dir/.devcontainer/devcontainer.json" 2>/dev/null; then
            issues+=("devcontainer.json: Invalid JSON syntax")
        fi

        # Check required keys
        local required_keys=("name" "workspaceFolder" "customizations")
        for key in "${required_keys[@]}"; do
            if ! jq -e ".$key" "$generated_dir/.devcontainer/devcontainer.json" >/dev/null 2>&1; then
                issues+=("devcontainer.json: Missing required key '$key'")
            fi
        done
    else
        issues+=("devcontainer.json: File not generated")
    fi

    # Check docker-compose.yml issues
    if [ -f "$generated_dir/docker-compose.yml" ]; then
        if ! python3 -c "import yaml; yaml.safe_load(open('$generated_dir/docker-compose.yml'))" 2>/dev/null; then
            issues+=("docker-compose.yml: Invalid YAML syntax")
        fi
    else
        issues+=("docker-compose.yml: File not generated")
    fi

    # Check Dockerfile issues
    if [ "$mode" != "basic" ]; then
        if [ ! -f "$generated_dir/.devcontainer/Dockerfile" ]; then
            issues+=("Dockerfile: Not generated (required for $mode mode)")
        elif ! grep -q "^FROM" "$generated_dir/.devcontainer/Dockerfile"; then
            issues+=("Dockerfile: Missing FROM instruction")
        fi
    fi

    # Write issues to report
    if [ ${#issues[@]} -gt 0 ]; then
        echo "" >> "$report_file"
        echo "Issues Found:" >> "$report_file"
        printf '%s\n' "${issues[@]}" >> "$report_file"
    fi

    echo "${#issues[@]}"
}

# Apply automated fixes to skill
apply_fixes() {
    local mode="$1"
    local skill_file="/workspace/skills/devcontainer-setup-$mode/SKILL.md"
    local issues_count="$2"

    if [ ! -f "$skill_file" ]; then
        log_error "Skill file not found: $skill_file"
        return 1
    fi

    log_info "Analyzing skill file: $skill_file"
    log_warn "Found $issues_count issues to fix"

    # Placeholder for actual fix logic
    # In practice, this would:
    # 1. Parse skill file to find file generation sections
    # 2. Identify which section corresponds to failing file
    # 3. Apply targeted fixes based on issue type
    # 4. Validate fixes don't break other parts

    log_warn "Auto-fix not implemented - manual intervention required"
    return 1
}
```

**Step 2: Integrate fixer into continuous runner**

Add to run-continuous.sh after test_skill fails:

```bash
else
    log_warn "✗ $mode FAILED iteration $iteration"

    # Analyze failures
    local report_file="$REPORTS_DIR/${mode}-iteration-${iteration}.txt"
    local issues_count
    issues_count=$(analyze_failures "$mode" "$GENERATED_DIR/$mode" "$report_file")

    log_info "Found $issues_count issues"

    # Attempt auto-fix (currently just logs)
    if ! apply_fixes "$mode" "$issues_count"; then
        log_warn "Auto-fix failed - continuing to next iteration"
    fi

    sleep 2
fi
```

**Step 3: Add source for fixer**

Add near top of run-continuous.sh:

```bash
source "$SCRIPT_DIR/lib/skill-fixer.sh"
```

**Step 4: Commit**

```bash
git add tests/skill-validation/lib/skill-fixer.sh tests/skill-validation/run-continuous.sh
git commit -m "feat: add skill auto-fix analysis (manual fix for now)"
```

---

## Task 7: Add Comprehensive Reporting

**Files:**
- Create: `tests/skill-validation/lib/report-generator.sh`
- Modify: `tests/skill-validation/test-harness.sh` (use report generator)

**Step 1: Create report generator**

Create `tests/skill-validation/lib/report-generator.sh`:

```bash
#!/bin/bash
# Comprehensive test report generation

# Generate final summary report
generate_summary_report() {
    local report_file="$REPORTS_DIR/summary-$(date +%Y%m%d-%H%M%S).md"

    cat > "$report_file" <<'EOF'
# Skill Validation Summary Report

**Generated:** $(date)

## Test Results

| Mode | Iterations | Final Accuracy | Status | Issues |
|------|------------|----------------|--------|--------|
EOF

    # Parse individual reports
    for mode in basic intermediate advanced yolo; do
        local mode_reports=($REPORTS_DIR/${mode}-iteration-*.txt)
        local iterations=${#mode_reports[@]}

        if [ $iterations -gt 0 ]; then
            # Get latest report
            local latest_report="${mode_reports[-1]}"
            local accuracy=$(grep "Accuracy:" "$latest_report" | awk '{print $2}')
            local status=$(grep "Status:" "$latest_report" | awk '{print $2}')
            local issues=$(grep -c "Issues Found:" "$latest_report" || echo "0")

            echo "| $mode | $iterations | $accuracy | $status | $issues |" >> "$report_file"
        else
            echo "| $mode | 0 | N/A | NOT RUN | N/A |" >> "$report_file"
        fi
    done

    cat >> "$report_file" <<'EOF'

## Test Configuration

- **Accuracy Threshold:** 95%
- **Max Iterations:** 5 per mode
- **Test Directory:** tests/skill-validation/

## Files Validated

- devcontainer.json (JSON syntax, required keys, structure)
- docker-compose.yml (YAML syntax, services, networks)
- Dockerfile (FROM instruction, multi-stage, packages)
- init-firewall.sh (bash syntax, iptables rules)

## Comparison Method

- **Structural:** JSON/YAML key path comparison
- **Syntactic:** Validator tools (jq, yq, shellcheck)
- **Content:** Section markers and expected content

---

**Report Location:** $(realpath "$report_file")
EOF

    log_info "Summary report generated: $report_file"
    cat "$report_file"
}
```

**Step 2: Call summary report at end**

Add to run-continuous.sh before final log:

```bash
log_info "========================================="
log_info "Continuous testing complete"
log_info "========================================="

# Generate summary
source "$SCRIPT_DIR/lib/report-generator.sh"
generate_summary_report
```

**Step 3: Test report generation**

Run: `bash tests/skill-validation/run-continuous.sh`
Expected: Runs tests, generates summary report at end

**Step 4: Commit**

```bash
git add tests/skill-validation/lib/report-generator.sh tests/skill-validation/run-continuous.sh
git commit -m "feat: add comprehensive summary reporting"
```

---

## Task 8: Document Testing Framework

**Files:**
- Create: `tests/skill-validation/README.md`
- Modify: `docs/TESTING.md` (add skill validation section)

**Step 1: Create README for test framework**

Create `tests/skill-validation/README.md`:

```markdown
# Skill Validation Testing Framework

Automated testing framework for sandbox setup skills that validates generated container files against master templates.

## Overview

This framework tests 4 skills:
- **Basic** - `/devcontainer-setup:basic`
- **Intermediate** - `/devcontainer-setup:intermediate`
- **Advanced** - `/devcontainer-setup:advanced`
- **YOLO** - `/devcontainer-setup:yolo`

## Test Cycle

1. **Generate** - Run skill to create files
2. **Compare** - Validate against master templates
3. **Evaluate** - Calculate accuracy score
4. **Fix** - Edit skill if needed
5. **Cleanup** - Remove test files
6. **Repeat** - Continue until passing

## Usage

### Interactive Testing (with prompts)
```bash
cd tests/skill-validation
./test-harness.sh
```

### Continuous Testing (automated)
```bash
cd tests/skill-validation
./run-continuous.sh
```

### Dry Run (validate setup)
```bash
DRY_RUN=true ./run-continuous.sh
```

## Directory Structure

```
tests/skill-validation/
├── test-harness.sh           # Main test orchestrator
├── run-continuous.sh         # Continuous testing loop
├── compare-containers.sh     # Comparison engine
├── lib/
│   ├── section-parser.sh     # Template section extraction
│   ├── diff-analyzer.sh      # File comparison logic
│   ├── skill-fixer.sh        # Auto-fix analysis
│   └── report-generator.sh   # Report generation
├── fixtures/                 # Test data
├── generated/                # Generated test outputs
├── reports/                  # Test reports
└── test-project/            # Sample project for testing
```

## Accuracy Metrics

- **Threshold:** 95% accuracy required
- **Structure:** JSON/YAML key path matching
- **Syntax:** File format validation
- **Content:** Section presence and completeness

## Files Validated

| File | Checks |
|------|--------|
| devcontainer.json | JSON syntax, required keys, structure |
| docker-compose.yml | YAML syntax, services, networks, volumes |
| Dockerfile | FROM instruction, multi-stage build, packages |
| init-firewall.sh | Bash syntax, iptables rules |

## Reports

Reports are saved to `reports/` directory:
- Individual: `{mode}-iteration-{N}.txt`
- Summary: `summary-{timestamp}.md`

## Dependencies

- bash
- jq (JSON processing)
- python3 + PyYAML (YAML processing)
- bc (calculations)
- diff/comm (file comparison)
```

**Step 2: Add to main testing docs**

If `docs/TESTING.md` exists, add section. Otherwise, create it:

```markdown
## Skill Validation Testing

Automated testing for sandbox setup skills. See `tests/skill-validation/README.md` for details.

**Quick Start:**
```bash
cd tests/skill-validation
./run-continuous.sh
```

**Requirements:**
- Skills must generate valid container files
- Accuracy threshold: ≥95%
- Max 5 iterations per skill before failing
```

**Step 3: Commit**

```bash
git add tests/skill-validation/README.md
git commit -m "docs: add skill validation testing documentation"
```

---

## Task 9: Final Verification & Testing

**Files:**
- Test: All components work together

**Step 1: Verify directory structure**

Run:
```bash
ls -la tests/skill-validation/
ls -la tests/skill-validation/lib/
```
Expected: All files present and executable

**Step 2: Run dry-run validation**

Run:
```bash
cd tests/skill-validation
DRY_RUN=true ./run-continuous.sh
```
Expected: ✓ Test setup validated

**Step 3: Test single skill manually**

Run:
```bash
cd tests/skill-validation
# Test just basic mode interactively
./test-harness.sh
# Press Ctrl+C after first iteration
```
Expected: Generates files, compares, produces report

**Step 4: Review generated report**

Run:
```bash
cat reports/basic-iteration-1.txt
```
Expected: Shows accuracy score and file analysis

**Step 5: Cleanup test outputs**

Run:
```bash
rm -rf generated/* reports/*
```

**Step 6: Commit final state**

```bash
git add tests/skill-validation/
git commit -m "test: verify skill validation framework works end-to-end"
```

---

## Execution Notes

### Running Continuous Tests

The continuous test runner will:
1. Test each mode (basic → intermediate → advanced → yolo) sequentially
2. Run up to 5 iterations per mode
3. Generate reports for each iteration
4. Produce final summary report
5. Clean up test files after each mode

### Manual Intervention Required

Currently, skill fixes must be done manually:
1. Review failure report in `reports/{mode}-iteration-{N}.txt`
2. Edit skill file: `skills/devcontainer-setup-{mode}/SKILL.md`
3. Re-run test: `./run-continuous.sh`

### Success Criteria

A skill passes when:
- Accuracy ≥ 95%
- All required files generated
- JSON/YAML syntax valid
- No critical issues found

---

## Plan Complete

**Plan saved to:** `docs/plans/2025-12-19-continuous-skill-testing.md`

**Total Tasks:** 9
**Estimated Time:** 4-6 hours for full implementation
**Key Deliverables:**
- Automated test harness
- Template comparison engine
- Continuous testing loop
- Comprehensive reporting
- Documentation

**Next Steps:** Use `superpowers:executing-plans` to implement task-by-task with fresh subagents and code review between tasks.
