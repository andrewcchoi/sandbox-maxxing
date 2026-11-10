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
bats -r tests/unit/
```

### Run Hook Tests Only
```bash
npm run test:hooks
# or
bats -r tests/unit/hooks/
```

### Run Validation Tests
```bash
npm run test:validation
# or
bats -r tests/unit/validation/
```

### Run Diagnostic Tests
```bash
npm run test:diagnostics
# or
bats -r tests/unit/diagnostics/
```

### Run Documentation Tests
```bash
bats -r tests/unit/documentation/
```

### Run Integration Tests
```bash
npm run test:integration
# or
bats -r tests/integration/
```

### Run All Tests (Unit + Integration)
```bash
npm run test:all
# or
bats -r tests/
```

### Run Tests with CI Format (TAP)
```bash
npm run test:ci
```

### Run Specific Test File
```bash
bats tests/unit/hooks/docker-safety-hook.bats
```

### Verbose Output
```bash
bats -r --verbose tests/unit/
```

### TAP Format (CI-friendly)
```bash
bats -r --tap tests/unit/
```

## Test Structure

```
tests/
├── README.md                                      # This file
├── unit/                                          # Unit tests
│   ├── test_runner_coverage.bats                  # Guard: every @test file is run (#380)
│   ├── test_user_remap.bats                       # Host UID/GID wiring + .env helpers (#377)
│   ├── test_command_syntax.bats                   # Command file syntax
│   ├── test_enhanced_partials.bats                # Dockerfile partial contents
│   ├── fix-worktree-paths.bats                    # Worktree path fixer
│   ├── hooks/                                     # Hook tests
│   │   ├── docker-safety-hook.bats                # Hook safety tests
│   │   ├── sudo-check.bats                        # Sudo detection tests
│   │   ├── package-install.bats                   # Package install tests
│   │   ├── run-hook-wrapper.bats                  # Hook wrapper tests
│   │   └── sync-knowledge.bats                    # Volume → host knowledge sync
│   ├── validation/                                # Validation tests
│   │   ├── manifest-validation.bats               # plugin.json, marketplace.json, hooks.json
│   │   ├── frontmatter-validation.bats            # Command/agent/skill frontmatter (needs yq)
│   │   ├── template-validation.bats               # JSON(C), YAML, Dockerfile, shell, placeholders
│   │   └── line-endings.bats                      # LF/CRLF rules
│   ├── diagnostics/                               # Diagnostic tests
│   │   └── troubleshoot-checks.bats               # Troubleshoot command validation
│   ├── documentation/                             # Documentation tests
│   │   ├── diagram-existence.bats                 # File existence checks
│   │   ├── diagram-content.bats                   # Content validation
│   │   └── version-consistency.bats               # Version synchronization
│   └── scripts/                                   # Script tests
│       ├── common.bats                            # Common script utilities
│       └── yolo-docker-maxxing.bats               # yolo setup script
├── integration/                                   # Integration tests
│   ├── health-check.bats                          # Health check scripts
│   ├── test_yolo_docker_maxxing.bats              # yolo Dockerfile assembly
│   └── test_user_remap_build.bats                 # Docker build of the UID remap step (needs Docker)
├── fixtures/                                      # Test fixtures and data
│   └── sudo-check-function.sh                     # Extracted sudo check logic
└── helpers/                                       # Test helper functions
    └── test_helper.bash                           # Common test utilities
```

**Test files must end in `.bats`.** `bats -r` only runs `*.bats` files; a file named anything else is silently skipped (#380). `tests/unit/test_runner_coverage.bats` fails if that happens again.

**Optional tools:** tests that need `yq` call `require_yq` and are skipped without it (CI installs it, and so does this repo's dev container). Docker build tests skip when Docker isn't available, or when `SKIP_DOCKER_TESTS=1`.

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
  run: bats -r tests/unit/ --tap

- name: Run Integration Tests
  run: bats -r tests/integration/ --tap
```

## Troubleshooting

### "bats: command not found"
Install BATS using instructions above.

### "jq: command not found" (in tests)
Install jq: `sudo apt-get install jq` (or `brew install jq` on macOS)

### Tests hang or timeout
Check if you're running privileged operations without proper mocking.

### A new test file doesn't run
Make sure it ends in `.bats`. `bats -r` ignores other extensions.

## Resources

- [BATS Documentation](https://bats-core.readthedocs.io/)
- [BATS GitHub](https://github.com/bats-core/bats-core)
- [Test-Driven Development Guide](https://testdriven.io/blog/modern-tdd/)
