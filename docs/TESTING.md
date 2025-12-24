# Testing Documentation

This document describes the testing infrastructure for the Claude Code sandbox setup project.

## Overview

The project includes automated testing for sandbox setup skills to ensure they generate valid and accurate container configuration files.

## Skill Validation Testing

Automated testing for sandbox setup skills. The framework validates that skills generate correct DevContainer configurations by comparing outputs against master templates.

### Quick Start

```bash
cd tests/skill-validation
./run-continuous.sh
```

### What Gets Tested

The framework validates 4 sandbox setup modes:
- `devcontainer-setup-basic` - Simple Docker Compose setup
- `devcontainer-setup-advanced` - Custom network isolation
- `devcontainer-setup-yolo` - Full control with allowlists

### Requirements

**System Dependencies:**
- bash
- jq (JSON processing)
- python3 with PyYAML (YAML processing)
- bc (calculations)
- git

**Install on Ubuntu/Debian:**
```bash
sudo apt-get install -y jq python3 python3-yaml bc
```

**Success Criteria:**
- Skills must generate valid container files
- Accuracy threshold: ≥95%
- All required files present (devcontainer.json, docker-compose.yml, etc.)
- Valid JSON/YAML syntax
- Max 5 iterations per skill before manual intervention required

### Test Modes

#### Interactive Mode
Prompts for manual skill edits between failed iterations:
```bash
cd tests/skill-validation
./test-harness.sh
```

#### Continuous Mode
Runs all skills automatically without prompts:
```bash
cd tests/skill-validation
./run-continuous.sh
```

#### Dry Run Mode
Validates test setup without running skills:
```bash
cd tests/skill-validation
DRY_RUN=true ./run-continuous.sh
```

### Understanding Test Results

#### Reports Location
- Individual: `tests/skill-validation/reports/{mode}-iteration-{N}.txt`
- Summary: `tests/skill-validation/reports/summary-{timestamp}.md`

#### Accuracy Scores
- **95-100%**: Excellent match, skill passes
- **90-94%**: Good match, may need minor fixes
- **80-89%**: Moderate match, requires fixes
- **<80%**: Poor match, significant issues

#### Common Issues
- **Syntax Errors**: Invalid JSON/YAML formatting
- **Missing Keys**: Required configuration keys not present
- **Missing Files**: Expected files not generated
- **Structure Mismatch**: Key paths don't match template

### For More Details

See the comprehensive documentation: [`tests/skill-validation/README.md`](../.internal/tests/skill-validation/README.md)

Topics covered:
- Architecture and components
- How accuracy is calculated
- Extending the framework
- Troubleshooting guide
- Contributing guidelines

## Running Tests in CI/CD

The skill validation tests can be integrated into continuous integration pipelines:

```bash
#!/bin/bash
# CI test script example
cd tests/skill-validation

# Validate setup
DRY_RUN=true ./run-continuous.sh || exit 1

# Run tests
./run-continuous.sh

# Check results
if grep -q "FAIL" reports/summary-*.md; then
    echo "Some skills failed validation"
    exit 1
fi

echo "All skills passed validation"
exit 0
```

## Manual Testing

To manually test a skill:

1. Create a test project:
```bash
mkdir -p /tmp/test-sandbox
cd /tmp/test-sandbox
echo '{"name": "test"}' > package.json
```

2. Run the skill:
```bash
# Use the correct skill name (e.g., devcontainer-setup-basic)
```

3. Verify generated files:
```bash
ls -la .devcontainer/
cat .devcontainer/devcontainer.json | jq .
docker-compose config  # Validates docker-compose.yml
```

## Debugging Failed Tests

### Step 1: Review the Report
```bash
cat tests/skill-validation/reports/{mode}-iteration-{N}.txt
```

Look for:
- Accuracy percentage
- Issues found section
- List of generated files

### Step 2: Compare Generated vs Template
```bash
# View generated file
cat tests/skill-validation/generated/{mode}/.devcontainer/devcontainer.json

# View template
cat skills/_shared/templates/devcontainer.json.master
```

### Step 3: Check Syntax
```bash
# JSON validation
jq empty tests/skill-validation/generated/{mode}/.devcontainer/devcontainer.json

# YAML validation
python3 -c "import yaml; yaml.safe_load(open('tests/skill-validation/generated/{mode}/docker-compose.yml'))"
```

### Step 4: Fix the Skill
Edit the skill file:
```bash
vim commands/{quickstart,yolo-vibe-maxxing}.md
```

Focus on:
- Template content in code blocks
- Variable substitutions
- Required keys/sections

### Step 5: Re-run Test
```bash
cd tests/skill-validation
./test-harness.sh  # Or run-continuous.sh
```

## Test Development

### Adding New Test Cases

1. Create test fixture in `tests/skill-validation/fixtures/`
2. Add validation logic in `tests/skill-validation/compare-containers.sh`
3. Update accuracy calculation in comparison functions
4. Document changes in `tests/skill-validation/README.md`

### Testing Framework Components

The framework consists of:
- `test-harness.sh` - Main orchestrator
- `run-continuous.sh` - Automated runner
- `compare-containers.sh` - Comparison engine
- `lib/section-parser.sh` - Template parsing
- `lib/diff-analyzer.sh` - File comparison
- `lib/skill-fixer.sh` - Issue analysis
- `lib/report-generator.sh` - Report creation

Each component is independently testable:
```bash
# Test comparison engine
bash tests/skill-validation/compare-containers.sh

# Test with specific library component
cd tests/skill-validation
source lib/diff-analyzer.sh
validate_syntax "test-file.json"
```

## Best Practices

### When Adding New Skills
1. Create skill following template patterns
2. Run validation tests immediately
3. Iterate until reaching 95%+ accuracy
4. Document any special considerations

### When Modifying Templates
1. Update master templates in `skills/_shared/templates/`
2. Run full test suite: `./run-continuous.sh`
3. Update skills that fail new validation
4. Commit templates and skill updates together

### When Changing Tests
1. Test in dry-run mode first
2. Validate against known-good skills
3. Check that passing skills still pass
4. Update documentation if behavior changes

## Continuous Improvement

The testing framework tracks:
- Accuracy trends over time
- Common failure patterns
- Skill generation consistency

Use reports to identify:
- Skills needing improvement
- Template sections causing issues
- Validation rules that are too strict/lenient

## Support

For issues with testing:
1. Check `tests/skill-validation/README.md` troubleshooting section
2. Review recent test reports in `tests/skill-validation/reports/`
3. Verify dependencies are installed
4. Run in dry-run mode to validate setup

For skill-specific issues:
- Review skill file: `commands/{quickstart,yolo-vibe-maxxing}.md`
- Check skill documentation in skill frontmatter
- Test skill manually in isolation
- Compare with working skills for patterns


---

**Last Updated:** 2025-12-24
**Version:** 4.5.0
