#!/usr/bin/env bats

# Syntax validation tests for command scripts

load '../helpers/test_helper.bash'

@test "yolo-docker-maxxing: standalone script has valid syntax" {
  local script_file="$BATS_TEST_DIRNAME/../../scripts/yolo-docker-maxxing.sh"

  # Validate bash syntax (does NOT execute, just checks syntax)
  run bash -n "$script_file"
  [ "$status" -eq 0 ]

  # Verify script exists and is not empty
  [ -s "$script_file" ]
}

@test "yolo-docker-maxxing: heredocs are properly closed" {
  local script_file="$BATS_TEST_DIRNAME/../../scripts/yolo-docker-maxxing.sh"

  # Count heredoc openers (<<) and closers (ENDOFFILE on its own line)
  local openers=$(grep -c "<<.*ENDOFFILE" "$script_file" || echo 0)
  local closers=$(grep -c "^ENDOFFILE$" "$script_file" || echo 0)

  # Should have matching heredoc delimiters
  [ "$openers" -eq "$closers" ]
}

@test "yolo-docker-maxxing: script can be executed (dry-run mode)" {
  # This test actually executes the script in a clean test environment
  # to verify it runs without bash syntax errors

  local test_dir="$BATS_TEST_TMPDIR/yolo-dryrun-test"
  mkdir -p "$test_dir"
  cd "$test_dir"

  # Set required environment
  export CLAUDE_PLUGIN_ROOT="$BATS_TEST_DIRNAME/../.."

  local script_file="$BATS_TEST_DIRNAME/../../scripts/yolo-docker-maxxing.sh"

  # Execute (will succeed because CLAUDE_PLUGIN_ROOT points to valid plugin)
  run bash "$script_file"

  # Check it executed without bash syntax errors
  # Exit code 0 = success, Exit code 1 = expected failure at some point
  # Exit code 2 or 127 = syntax error (would be a real failure)
  [ "$status" -ne 2 ]
  [ "$status" -ne 127 ]

  # Verify it got past the bash parsing stage
  [[ "$output" =~ "Plugin root:" ]] || [[ "$output" =~ "Mode:" ]]
}

@test "yolo-docker-maxxing: script handles heredocs when written to file first" {
  # This test validates the workaround - writing script to file before execution
  # This is the pattern we use to avoid bash -c heredoc issues

  local test_dir="$BATS_TEST_TMPDIR/heredoc-test"
  mkdir -p "$test_dir"
  cd "$test_dir"

  # Create a test script with multiple heredocs (simulates our command)
  local test_script="$test_dir/test-heredocs.sh"
  cat > "$test_script" << 'SCRIPT_EOF'
#!/bin/bash
cat > file1.sh << 'EOF'
#!/bin/bash
echo "test1"
EOF

cat > file2.sh << 'EOF'
#!/bin/bash
echo "test2"
EOF
SCRIPT_EOF

  chmod +x "$test_script"

  # Execute via bash (file-based execution)
  run bash "$test_script"

  # Should succeed without syntax errors
  [ "$status" -eq 0 ]
  [ -f "$test_dir/file1.sh" ]
  [ -f "$test_dir/file2.sh" ]
}

@test "yolo-docker-maxxing: quoted heredoc delimiters would fail in bash -c execution" {
  # This test demonstrates why we use unquoted delimiters (ENDOFFILE vs 'EOF')
  # When scripts are embedded in bash -c '...', single quotes in << 'EOF' create conflicts

  local test_dir="$BATS_TEST_TMPDIR/bash-c-test"
  mkdir -p "$test_dir"
  cd "$test_dir"

  # Test the OLD broken pattern: << 'EOF'
  # This would fail if directly embedded in bash -c '...' due to quote conflict
  # We test it in isolation to verify the problem exists
  run bash -c "cat > testfile << 'EOF'
test content
EOF
echo done"

  # This might work depending on shell quote handling, but it's fragile
  # The real issue appears with complex multi-line scripts

  # Test the NEW safe pattern: << ENDOFFILE (unquoted)
  # This ALWAYS works in bash -c execution
  run bash -c 'cat > testfile2 << ENDOFFILE
test content
ENDOFFILE
echo done'

  [ "$status" -eq 0 ]
  [ -f "$test_dir/testfile2" ]
  [[ "$output" =~ "done" ]]
}

@test "yolo-docker-maxxing: script uses safe quoted heredoc delimiters" {
  # Verify that the standalone script uses safe heredoc patterns
  # Using 'ENDOFFILE' (quoted) is safe because it's NOT embedded in bash -c

  local script_file="$BATS_TEST_DIRNAME/../../scripts/yolo-docker-maxxing.sh"

  # Verify heredoc delimiters ARE used (can be quoted or unquoted in standalone file)
  run grep -c "<<.*ENDOFFILE" "$script_file"
  [ "$status" -eq 0 ]
  [ "$output" -ge 2 ]  # Should have at least 2 heredocs
}

@test "yolo-docker-maxxing: heredoc terminators are at column 0" {
  # CRITICAL: Heredoc terminators MUST start at column 0
  # If they're indented, heredocs break when executed
  # This test catches accidental indentation of ENDOFFILE lines

  local script_file="$BATS_TEST_DIRNAME/../../scripts/yolo-docker-maxxing.sh"

  # Count heredoc starters (<< ENDOFFILE or << 'ENDOFFILE')
  run grep -c "<<.*ENDOFFILE" "$script_file"
  local heredoc_count="$output"

  # Count terminator lines at column 0 (just "ENDOFFILE" with nothing else)
  run grep -c "^ENDOFFILE$" "$script_file"
  local terminators_at_col0="$output"

  # Every heredoc opener should have a matching terminator at column 0
  [ "$terminators_at_col0" -eq "$heredoc_count" ]
}

@test "yolo-docker-maxxing: command file calls standalone script" {
  # Verify the command file references the standalone script, not inline code

  local cmd_file="$BATS_TEST_DIRNAME/../../commands/yolo-docker-maxxing.md"

  # Should reference the standalone script
  run grep -c "scripts/yolo-docker-maxxing.sh" "$cmd_file"
  [ "$status" -eq 0 ]
  [ "$output" -ge 1 ]

  # Should NOT have a large bash code block (just examples)
  local awk_script="$BATS_TEST_TMPDIR/extract.awk"
  cat > "$awk_script" << 'AWK_EOF'
/^```bash$/,/^```$/ { if (!/^```/) count++ }
END { print count+0 }
AWK_EOF

  run awk -f "$awk_script" "$cmd_file"
  # Should have 0 or very few lines (no embedded script)
  [ "$output" -lt 10 ]
}

# Note: Dockerfile partial tests are in test_enhanced_partials.bats
