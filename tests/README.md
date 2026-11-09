# Sandbox-Maxxing Test Suite

This directory contains the test suite for the sandbox-maxxing Claude Code plugin.

## Prerequisites

### Install BATS (Bash Automated Testing System)

BATS must be installed system-wide due to npm sandbox restrictions.

#### Ubuntu/Debian/WSL2
```bash
sudo apt-get update
sudo apt-get install bats
```

#### macOS
```bash
brew install bats-core
```

#### Arch Linux
```bash
sudo pacman -S bats
```

#### Manual Installation (if not in package manager)
```bash
git clone https://github.com/bats-core/bats-core.git /tmp/bats-core
cd /tmp/bats-core
sudo ./install.sh /usr/local
```

### Verify Installation
```bash
bats --version
# Should output: Bats 1.x.x
```

## Running Tests

### Run All Tests
```bash
npm test
# or
bats tests/unit/
```

### Run Hook Tests Only
```bash
npm run test:hooks
# or
bats tests/unit/hooks/
```

### Run Validation Tests
```bash
npm run test:validation
# or
bats tests/unit/validation/
```

### Run Diagnostic Tests
```bash
npm run test:diagnostics
# or
bats tests/unit/diagnostics/
```

### Run Documentation Tests
```bash
bats tests/unit/documentation/
```

### Run Integration Tests
```bash
npm run test:integration
# or
bats tests/integration/
```

### Run All Tests (Unit + Integration)
```bash
npm run test:all
# or
bats tests/
```

### Run Tests with CI Format (TAP)
```bash
npm run test:ci
```

### Run Specific Test File
```bash
bats tests/unit/hooks/docker-safety-hook.test.sh
```

### Verbose Output
```bash
bats --verbose tests/unit/
```

### TAP Format (CI-friendly)
```bash
bats --tap tests/unit/
```

## Test Structure

```
tests/
├── README.md                                      # This file
├── unit/                                          # Unit tests
│   ├── hooks/                                     # Hook tests
│   │   ├── docker-safety-hook.test.sh             # Hook safety tests
│   │   ├── sudo-check.test.sh                     # Sudo detection tests
│   │   ├── package-install.test.sh                # Package install tests
│   │   └── run-hook-wrapper.test.sh               # Hook wrapper tests
│   ├── validation/                                # Validation tests (NEW)
│   │   ├── manifest-validation.test.sh            # plugin.json, marketplace.json, hooks.json
│   │   ├── frontmatter-validation.test.sh         # Command/agent/skill frontmatter
│   │   └── template-validation.test.sh            # JSON, YAML, Dockerfile, shell
│   ├── diagnostics/                               # Diagnostic tests (NEW)
│   │   └── troubleshoot-checks.test.sh            # Troubleshoot command validation
│   ├── documentation/                             # Documentation tests
│   │   ├── diagram-existence.test.sh              # File existence checks
│   │   ├── diagram-content.test.sh                # Content validation
│   │   └── version-consistency.test.sh            # Version synchronization
│   └── scripts/                                   # Script tests
│       └── common.test.sh                         # Common script utilities
├── integration/                                   # Integration tests
│   └── health-check.test.sh                       # Health check scripts
├── fixtures/                                      # Test fixtures and data
│   └── sudo-check-function.sh                     # Extracted sudo check logic
└── helpers/                                       # Test helper functions
    └── test_helper.bash                           # Common test utilities
```

## Writing Tests

### Test File Template

```bash
#!/usr/bin/env bats
#
# Description of what this test file tests

load '../../helpers/test_helper'

@test "descriptive test name" {
  # Arrange
  input="test data"

  # Act
  run command_to_test "$input"

  # Assert
  assert_success
  assert_output_contains "expected output"
}
```

### Available Assertions

From `test_helper.bash`:
- `assert_success` - Command exited with 0
- `assert_failure` - Command exited with non-zero
- `assert_output_contains "text"` - Output contains string
- `assert_output_matches "regex"` - Output matches pattern
- `assert_output_not_contains "text"` - Output doesn't contain string
- `assert_json_contains ".path" "value"` - JSON assertion with jq
- `assert_valid_json "file"` - Validate JSON file syntax
- `assert_valid_yaml "file"` - Validate YAML file syntax
- `assert_frontmatter_has "file" "field"` - Check YAML frontmatter field
- `assert_valid_shell "file"` - Validate bash syntax
- `assert_file_executable "file"` - Check execute permissions

### Helper Functions

- `create_hook_input "tool" "command"` - Create PreToolUse hook JSON
- `require_command "cmd"` - Skip test if command unavailable
- `skip_on_platform "Darwin"` - Skip test on specific OS

### Setup/Teardown

Tests automatically get:
- `$TEST_TEMP_DIR` - Isolated temporary directory
- `$PLUGIN_ROOT` - Path to plugin root
- `$ORIGINAL_DIR` - Original working directory

## Test Coverage Goals

### Phase 1: Core Functionality ✅ COMPLETE
- ✅ docker-safety-hook: All patterns (destructive, privileged, disruptive)
- ✅ Documentation: Diagram existence, version consistency, content validation
- ✅ Health checks: Script validation, inventory checks
- ✅ sudo-check: Passwordless, timeout, group checks
- ✅ package-install: apt operations, idempotency
- ✅ Windows stdin: CI workflow test

### Phase 2: Plugin Functionality ✅ COMPLETE
- ✅ Manifest validation: plugin.json, marketplace.json, hooks.json (~15 tests)
- ✅ Frontmatter validation: commands, agents, skills (~20 tests)
- ✅ Template validation: JSON, YAML, Dockerfile, shell scripts (~25 tests)
- ✅ Diagnostic checks: troubleshoot command validation (~15 tests)
- ✅ CI integration: BATS tests run in GitHub Actions

### Phase 3: Advanced (Future)
- Command execution patterns
- Port allocation logic
- Environment file merging
- Firewall initialization
- E2E container build tests

## CI Integration

Tests run automatically in CI via `.github/workflows/docs-validation.yml`:

**Three parallel jobs:**
1. **Documentation Validation** - Runs `doc-health-check.sh`
2. **Unit Tests** - Runs all unit tests (validation, diagnostics, hooks, documentation)
3. **Integration Tests** - Runs integration tests

```yaml
- name: Install dependencies
  run: |
    sudo apt-get update
    sudo apt-get install -y bats jq
    sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
    sudo chmod +x /usr/local/bin/yq

- name: Run Unit Tests
  run: bats tests/unit/ --tap

- name: Run Integration Tests
  run: bats tests/integration/ --tap
```

## Troubleshooting

### "bats: command not found"
Install BATS using instructions above.

### "jq: command not found" (in tests)
Install jq: `sudo apt-get install jq` (or `brew install jq` on macOS)

### Tests hang or timeout
Check if you're running privileged operations without proper mocking.

### Permission denied on test files
```bash
chmod +x tests/unit/**/*.test.sh
```

## Resources

- [BATS Documentation](https://bats-core.readthedocs.io/)
- [BATS GitHub](https://github.com/bats-core/bats-core)
- [Test-Driven Development Guide](https://testdriven.io/blog/modern-tdd/)
