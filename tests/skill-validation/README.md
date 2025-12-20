# Skill Validation Testing Framework

Automated testing framework for sandbox setup skills that validates generated container files against master templates.

## Overview

This framework tests 4 skills:
- **Basic** - `/sandboxxer:basic`
- **Intermediate** - `/sandboxxer:intermediate`
- **Advanced** - `/sandboxxer:advanced`
- **YOLO** - `/sandboxxer:yolo`

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

## Architecture

### Test Harness (`test-harness.sh`)
The main orchestrator that:
- Coordinates test execution across all modes
- Manages test iterations and retries
- Handles user interaction for manual fixes
- Generates per-iteration reports

### Continuous Runner (`run-continuous.sh`)
Automated test execution without user interaction:
- Runs all modes sequentially
- Executes up to 5 iterations per mode
- Attempts auto-fix analysis between iterations
- Produces summary reports

### Comparison Engine (`compare-containers.sh`)
Core validation logic that:
- Compares generated files against master templates
- Calculates accuracy scores
- Validates file syntax (JSON/YAML/Dockerfile)
- Analyzes structural similarity

### Library Components

#### Section Parser (`lib/section-parser.sh`)
- Extracts sections from master templates
- Validates section markers in generated files
- Retrieves section content for comparison

#### Diff Analyzer (`lib/diff-analyzer.sh`)
- Calculates structural similarity for JSON/YAML files
- Validates file syntax using `jq`, `python3+PyYAML`
- Performs key path matching to measure structure accuracy
- Provides Dockerfile-specific validation

#### Skill Fixer (`lib/skill-fixer.sh`)
- Analyzes test failures to identify issues
- Checks for missing files, invalid syntax, missing keys
- Reports issues in test reports
- Placeholder for future automated fix application

#### Report Generator (`lib/report-generator.sh`)
- Creates per-iteration detailed reports
- Generates final summary reports in Markdown
- Aggregates results across all modes
- Provides test metrics and configuration details

## Accuracy Metrics

- **Threshold:** 95% accuracy required to pass
- **Structure:** JSON/YAML key path matching
- **Syntax:** File format validation (must be valid)
- **Content:** Section presence and completeness

### How Accuracy is Calculated

1. **JSON/YAML Files (devcontainer.json, docker-compose.yml)**
   - Extract all key paths from template and generated file
   - Compare key sets to find common keys
   - Accuracy = (common_keys / total_template_keys) × 100

2. **Dockerfile**
   - Count `FROM` instructions (multi-stage builds)
   - Validate against expected stages for mode:
     - Basic: 1-2 stages (90% if met)
     - Intermediate/Advanced/YOLO: 2-3 stages (95% if met)

3. **Overall Score**
   - Average of all file scores
   - All files must pass syntax validation first

## Files Validated

| File | Checks |
|------|--------|
| devcontainer.json | JSON syntax, required keys (name, workspaceFolder, customizations), structure |
| docker-compose.yml | YAML syntax, services, networks, volumes |
| Dockerfile | FROM instruction, multi-stage build, packages |
| init-firewall.sh | Bash syntax, iptables rules |

## Reports

Reports are saved to `reports/` directory:

### Individual Iteration Reports
Format: `{mode}-iteration-{N}.txt`

Example:
```
Skill Validation Report
=======================
Mode: basic
Iteration: 1
Timestamp: 2025-12-20 03:00:00
Accuracy: 87.50%
Threshold: 95%
Status: FAIL

Generated Files:
/workspace/tests/skill-validation/generated/basic/.devcontainer/devcontainer.json
/workspace/tests/skill-validation/generated/basic/docker-compose.yml
...
```

### Summary Reports
Format: `summary-{timestamp}.md`

Contains:
- Test results table for all modes
- Test configuration details
- Files validated and methods used
- Final pass/fail status

## Dependencies

Required tools:
- **bash** - Test harness execution
- **jq** - JSON processing and validation
- **python3** - YAML processing (requires PyYAML)
- **bc** - Floating point calculations
- **diff/comm** - File comparison utilities
- **git** - Version control (for skill file access)

Install dependencies on Ubuntu/Debian:
```bash
sudo apt-get install -y jq python3 python3-yaml bc diffutils git
```

## Extending the Framework

### Adding New Validation Checks

Edit `compare-containers.sh` to add new comparison functions:

```bash
# Compare new file type
compare_newfile() {
    local generated="$1"
    local template="$2"
    local mode="$3"

    # Your validation logic
    # Return score 0-100
    echo "95"
}
```

Then add to `compare_with_templates()`:
```bash
if [ -f "$generated_dir/newfile.ext" ]; then
    score=$(compare_newfile "$generated_dir/newfile.ext" "$templates_dir/newfile.master" "$mode")
    total_score=$(echo "$total_score + $score" | bc)
    ((file_count++))
fi
```

### Adding New Skills to Test

Edit `run-continuous.sh` or `test-harness.sh`:

```bash
local modes=("basic" "intermediate" "advanced" "yolo" "newmode")
```

Ensure the skill follows naming convention: `sandboxxer:{mode}`

### Customizing Accuracy Thresholds

Edit `test-harness.sh`:

```bash
ACCURACY_THRESHOLD=95  # Change to desired percentage
```

Or set per-mode:
```bash
case "$mode" in
    basic) THRESHOLD=90 ;;
    advanced) THRESHOLD=95 ;;
esac
```

### Adding Auto-Fix Logic

Edit `lib/skill-fixer.sh` in the `apply_fixes()` function:

```bash
apply_fixes() {
    local mode="$1"
    local skill_file="/workspace/skills/sandbox-setup-$mode/SKILL.md"

    # Add your fix logic here
    # 1. Parse skill file
    # 2. Identify problematic sections
    # 3. Apply targeted fixes
    # 4. Validate changes
}
```

## Troubleshooting

### Tests Fail with "command not found"
**Issue:** Missing dependencies
**Solution:** Install required tools (see Dependencies section)

### Accuracy Always 0%
**Issue:** Generated files have syntax errors
**Solution:** Check individual reports for syntax validation failures

### Skills Not Running
**Issue:** Skill invocation fails or hangs
**Solution:**
- Verify skills exist in `skills/` directory
- Check skill frontmatter for correct triggering
- Test skill manually: `claude skill sandboxxer:basic`

### Template Comparison Fails
**Issue:** Master templates not found
**Solution:** Verify templates exist at `/workspace/templates/master/`

### Reports Not Generated
**Issue:** Reports directory not writable or doesn't exist
**Solution:** `mkdir -p tests/skill-validation/reports`

## Contributing

When adding new tests or validation logic:

1. Follow existing patterns in library components
2. Add comprehensive error handling
3. Update this README with new features
4. Test changes with `DRY_RUN=true` first
5. Commit with descriptive messages following convention:
   - `feat:` for new features
   - `fix:` for bug fixes
   - `docs:` for documentation changes
   - `test:` for test changes

## Future Enhancements

Planned improvements:
- [ ] Full automated fix application (currently manual)
- [ ] Parallel test execution for faster runs
- [ ] HTML report generation with visual diffs
- [ ] Integration with CI/CD pipelines
- [ ] Template versioning support
- [ ] Custom validation rule definitions
- [ ] Performance benchmarking of skills
- [ ] Historical trend analysis

## License

Part of the Claude Code sandbox setup project.
