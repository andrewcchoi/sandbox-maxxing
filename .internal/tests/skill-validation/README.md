# Skill Validation Test System

Automated testing framework for continuous validation of Claude Code skills, specifically designed for the devcontainer-setup plugin (v3.0.0) sandbox setup skills.

## Overview

This test system provides:

- **Automated skill execution** with pre-configured responses
- **Container comparison** between generated and reference examples
- **Continuous testing** with iterative refinement
- **Comprehensive reporting** with accuracy metrics
- **Dry-run validation** for configuration testing

## Architecture

```
tests/skill-validation/
├── test-harness.sh              # Main test orchestrator
├── compare-containers.sh        # Container comparison engine
├── run-continuous.sh            # Continuous testing wrapper
├── lib/
│   ├── response-feeder.sh      # Automated response feeding
│   ├── python-fallbacks.sh     # Python alternatives for missing tools
│   └── comparison-utils.sh     # Shared comparison utilities
├── test-project/               # Minimal test project structure
├── generated/                  # Generated skill outputs
├── reports/                    # Test reports and logs
├── docs/
│   └── TEST_CONFIG_FORMAT.md  # Configuration format documentation
└── README.md                   # This file
```

## Quick Start

### Basic Usage

Run all skill tests:
```bash
cd /workspace/tests/skill-validation
./test-harness.sh
```

### Dry-Run Mode

Validate configuration without executing:
```bash
./test-harness.sh --dry-run
```

### Test Specific Mode

Test only one skill mode:
```bash
./test-harness.sh --mode basic
```

### Enable Debug Logging

See detailed execution information:
```bash
DEBUG=true ./test-harness.sh
```

## Test Modes

The test harness validates four sandbox setup modes:

1. **basic** - Minimal setup with single language
2. **intermediate** - Standard setup with services (database, etc.)
3. **advanced** - Full setup with custom firewall rules
4. **yolo** - Maximum flexibility, no restrictions

## Configuration

### Test Configuration Files

Each mode has a `test-config.yml` defining automated responses:

```yaml
# /workspace/examples/demo-app-sandbox-basic/test-config.yml
metadata:
  mode: basic
  description: "Basic mode with Python backend, minimal setup"

responses:
  - prompt_pattern: "project.*name"
    response: "demo-app"
  - prompt_pattern: "language|stack"
    response: "python"
  - prompt_pattern: "confirm|proceed"
    response: "yes"
```

See [TEST_CONFIG_FORMAT.md](docs/TEST_CONFIG_FORMAT.md) for complete documentation.

### Environment Variables

Configure behavior via environment variables:

```bash
# Dry-run mode - validate without executing
DRY_RUN=true ./test-harness.sh

# Debug mode - verbose logging
DEBUG=true ./test-harness.sh

# Custom log file location
LOG_FILE=/tmp/my-test.log ./test-harness.sh

# Custom accuracy threshold (default: 95%)
ACCURACY_THRESHOLD=90 ./test-harness.sh
```

### Command-Line Options

```bash
Usage: ./test-harness.sh [OPTIONS]

OPTIONS:
    -h, --help              Show help message
    -d, --dry-run          Run in dry-run mode
    -m, --mode MODE        Test specific mode (basic|intermediate|advanced|yolo)
    -t, --threshold NUM    Set accuracy threshold (default: 95)
    --debug                Enable debug logging
    --log-file FILE        Specify log file location
```

## Features

### 1. Pre-Flight Validation

Before running tests, the harness validates:

- Example directories exist and contain required files
- Test config files are valid YAML
- Response patterns are well-formed
- Response counts are reasonable (1-20 entries)
- Pattern and response counts match

### 2. Dry-Run Mode

Test configuration without execution:

```bash
./test-harness.sh --dry-run
```

Shows what would happen:
- Which files would be checked
- Which configs would be used
- What validation would occur
- No actual skill execution

### 3. Enhanced Logging

All operations are logged with timestamps:

```
[2025-12-20 10:30:45] [INFO] Starting test for basic mode
[2025-12-20 10:30:45] [INFO] Running pre-flight checks for basic mode...
[2025-12-20 10:30:45] [DEBUG] Validating config file: test-config.yml
[2025-12-20 10:30:45] [INFO] Pre-flight checks passed for basic mode
```

Logs are written to:
- Console (with colors)
- Log file (default: `reports/test-harness.log`)

### 4. Cleanup on Failure

When tests fail, the system:

- Kills any background processes
- Preserves failed output for debugging
- Saves logs to timestamped directories
- Cleans up temporary files

Failed outputs saved to:
```
reports/failed-{mode}-{timestamp}/
```

### 5. Container Comparison

Compares generated containers against examples:

- **Structural comparison**: Files, directories, permissions
- **Content comparison**: Line-by-line diff with fuzzy matching
- **Semantic comparison**: Docker Compose services, DevContainer features
- **Scoring**: Weighted accuracy percentage

### 6. Continuous Testing

Run tests continuously with skill refinement:

```bash
./run-continuous.sh
```

After each failure:
1. Review the output and logs
2. Edit the skill to fix issues
3. Press Enter to retry
4. Or type 'skip' to move to next mode

## Test Workflow

### Standard Test Flow

1. **Pre-flight checks**
   - Validate example directory exists
   - Validate test config is well-formed
   - Check test project structure

2. **Skill execution**
   - Copy test project to generated directory
   - Load response feeder with config
   - Execute skill with automated responses
   - Monitor for completion or timeout

3. **Validation**
   - Check expected files were generated
   - Validate file contents are reasonable

4. **Comparison**
   - Compare against example directory
   - Calculate accuracy score
   - Generate detailed diff report

5. **Reporting**
   - Save accuracy metrics
   - Log pass/fail status
   - Preserve artifacts for debugging

### Error Handling

The test harness handles various failure modes:

**Timeout (1 minute per skill)**
- Kills skill process
- Logs timeout error
- Preserves partial output
- Reports timeout in failure log

**Skill Errors**
- Captures stderr to error.log
- Detects non-zero exit codes
- Reports "Generation failed"
- Skips comparison phase

**Missing Files**
- Detects expected files not generated
- Logs specific missing files
- Triggers cleanup routine
- Preserves output for debugging

**Configuration Errors**
- Validates config before use
- Falls back to pre-piped defaults
- Logs configuration issues
- Continues with warnings

## Response Feeding

### Two Feeding Strategies

**1. Pre-pipe (Phase 1)**

Feeds all responses at once via stdin:
```bash
echo -e "demo-app\npython\nyes\n" | claude skill devcontainer-setup-basic
```

Pros:
- Simple and reliable
- Works in all environments
- No complex monitoring needed

Cons:
- Can't adapt to unexpected questions
- No visibility into skill prompts
- Fixed response sequence

**2. Interactive (Phase 3+)**

Monitors skill output and responds dynamically:
```bash
# Creates named pipes for bidirectional communication
# Watches for questions in real-time
# Matches questions against patterns
# Feeds appropriate responses
```

Pros:
- Adapts to question order changes
- Provides detailed logging
- Detects unexpected questions
- Can validate skill behavior

Cons:
- More complex implementation
- Requires named pipe support
- Currently uses fallback to pre-pipe

### Pattern Matching

Questions are matched using:

1. **Ordered matching**: Try response at expected index
2. **Pattern verification**: Ensure pattern matches question
3. **Fallback matching**: Try any pattern if ordered fails
4. **Safe defaults**: Provide reasonable fallback responses

See [TEST_CONFIG_FORMAT.md](docs/TEST_CONFIG_FORMAT.md) for pattern syntax.

## Reports

### Report Directory Structure

```
reports/
├── test-harness.log              # Main log file
├── basic-iteration-1.txt         # Per-mode, per-iteration reports
├── intermediate-iteration-1.txt
├── failed-basic-20251220-103045/ # Failed run artifacts
│   ├── test-harness.log
│   └── basic/                    # Generated files
└── comparison-reports/           # Detailed comparison diffs
    └── basic-vs-example.txt
```

### Report Contents

Each iteration report includes:
- Mode and iteration number
- Timestamp
- Accuracy percentage
- Threshold (pass/fail criteria)
- Status (PASS/FAIL)
- List of generated files

### Reading Reports

**Check overall status:**
```bash
tail -20 reports/test-harness.log
```

**Review specific mode:**
```bash
cat reports/basic-iteration-1.txt
```

**Analyze failures:**
```bash
ls -la reports/failed-*/
cat reports/failed-basic-*/test-harness.log
```

## Troubleshooting

### Tests Fail Immediately

**Symptom:** Pre-flight checks fail

**Solutions:**
- Verify example directories exist: `ls /workspace/examples/demo-app-sandbox-*`
- Check test configs are present: `ls /workspace/examples/*/test-config.yml`
- Validate YAML syntax: `python3 -c "import yaml; yaml.safe_load(open('test-config.yml'))"`

### Skills Don't Execute

**Symptom:** Skill times out or hangs

**Solutions:**
- Check skill is accessible: `claude skill --list`
- Verify response patterns match questions: `DEBUG=true ./test-harness.sh`
- Review conversation log for unexpected questions
- Try manual execution with same responses

### Low Accuracy Scores

**Symptom:** Tests complete but accuracy < threshold

**Solutions:**
- Review comparison report: `cat reports/comparison-reports/*`
- Check for file differences: `diff -r generated/basic examples/demo-app-sandbox-basic/`
- Identify discrepancies in generated files
- Update skill or adjust expectations

### Configuration Errors

**Symptom:** "Config validation failed"

**Solutions:**
- Check response count: `grep -c "prompt_pattern:" test-config.yml`
- Verify balanced pairs: patterns should equal responses
- Validate YAML syntax (indentation, colons, quotes)
- See [TEST_CONFIG_FORMAT.md](docs/TEST_CONFIG_FORMAT.md)

### Pattern Mismatches

**Symptom:** "No response configured for question"

**Solutions:**
- Enable debug logging: `DEBUG=true ./test-harness.sh`
- Review actual question text in logs
- Update pattern to match variations
- Use broader patterns with wildcards

## Development

### Adding New Test Modes

1. Create example directory:
   ```bash
   mkdir -p /workspace/examples/demo-app-sandbox-newmode
   ```

2. Generate reference files:
   ```bash
   cd /workspace/examples/demo-app-sandbox-newmode
   claude skill devcontainer-setup-newmode
   # Answer questions manually to create reference
   ```

3. Create test config:
   ```bash
   cat > test-config.yml << 'EOF'
   metadata:
     mode: newmode
     description: "Description of new mode"

   responses:
     - prompt_pattern: "pattern1"
       response: "response1"
   EOF
   ```

4. Add to test harness:
   ```bash
   # Edit test-harness.sh, update modes array
   local modes=("basic" "intermediate" "advanced" "yolo" "newmode")
   ```

### Testing the Test System

Run with dry-run to validate:
```bash
./test-harness.sh --dry-run
```

Test specific components:
```bash
# Test config validation
./lib/response-feeder.sh --validate test-config.yml

# Test comparison engine
./compare-containers.sh generated/basic examples/demo-app-sandbox-basic

# Test with debug logging
DEBUG=true ./test-harness.sh --mode basic
```

### Extending Comparison Logic

Edit `compare-containers.sh` to add new comparison types:

```bash
# Add new comparison function
compare_new_aspect() {
    local generated="$1"
    local example="$2"

    # Your comparison logic

    echo "score_percentage"
}

# Add to compare_with_examples()
local new_score=$(compare_new_aspect "$generated_dir" "$example_dir")
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Skill Validation
on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run skill validation tests
        run: |
          cd tests/skill-validation
          ./test-harness.sh
      - name: Upload reports
        if: always()
        uses: actions/upload-artifact@v2
        with:
          name: test-reports
          path: tests/skill-validation/reports/
```

### Pre-commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit

echo "Running skill validation tests..."
cd tests/skill-validation
./test-harness.sh --dry-run

if [ $? -ne 0 ]; then
    echo "Skill validation dry-run failed"
    exit 1
fi
```

## Performance

### Execution Time

Typical execution times (per mode):
- Pre-flight checks: <1 second
- Skill execution: 30-60 seconds
- Comparison: 5-10 seconds
- Total per mode: ~1 minute

All 4 modes: ~5 minutes total

### Optimization Tips

1. **Use dry-run for config validation** (instant)
2. **Test single modes during development** (`--mode basic`)
3. **Run full suite before commits** (all modes)
4. **Cache comparison results** for repeated runs
5. **Parallelize mode testing** (future enhancement)

## Version History

- **v1.0.0** - Initial release (Phase 1-2)
  - Basic test harness
  - Pre-pipe response feeding
  - Container comparison

- **v1.1.0** - Enhanced validation (Phase 3-5)
  - Interactive response feeding
  - Pattern-based matching
  - Response feeder library

- **v2.0.0** - Production ready (Phase 6)
  - Dry-run mode
  - Pre-flight validation
  - Enhanced logging with timestamps
  - Cleanup on failure
  - Comprehensive documentation

## Support

### Getting Help

1. Check this README for common scenarios
2. Review [TEST_CONFIG_FORMAT.md](docs/TEST_CONFIG_FORMAT.md) for config issues
3. Enable debug logging: `DEBUG=true ./test-harness.sh`
4. Check logs: `cat reports/test-harness.log`
5. Review failed output: `ls -la reports/failed-*/`

### Reporting Issues

When reporting issues, include:
- Command used to run tests
- Full log output (with DEBUG=true)
- Test config being used
- Expected vs actual behavior
- Failed output directory contents

### Contributing

Contributions welcome! Areas for enhancement:

- [ ] Parallel test execution
- [ ] More sophisticated comparison algorithms
- [ ] Visual diff reports (HTML)
- [ ] Test result database/history
- [ ] Performance benchmarking
- [ ] Additional skill modes
- [ ] Integration with external CI systems

## License

Part of the devcontainer-setup plugin (v3.0.0) for Claude Code.

## See Also

- [Automated Skill Testing Design](../../docs/archive/2025-12-20-automated-skill-testing-design.md)
- [Sandboxxer Plugin Documentation](../../skills/README.md)
- [Claude Code Documentation](https://docs.anthropic.com/claude-code)


---

**Last Updated:** 2025-12-21
**Version:** 3.0.0
