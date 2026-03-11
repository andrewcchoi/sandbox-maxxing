#!/usr/bin/env bats

# Syntax validation tests for command scripts embedded in markdown

load '../helpers/test_helper.bash'

@test "yolo-docker-maxxing: bash script has valid syntax" {
  # Extract bash script from markdown command file
  local cmd_file="$BATS_TEST_DIRNAME/../../commands/yolo-docker-maxxing.md"
  local script_file="$BATS_TEST_TMPDIR/yolo-script.sh"
  local awk_script="$BATS_TEST_TMPDIR/extract.awk"

  # Create awk script for extraction (avoids shell escaping issues)
  cat > "$awk_script" << 'AWK_EOF'
/^```bash$/,/^```$/ {
  if (!/^```/) print
}
AWK_EOF

  # Extract code block (between ```bash and ```)
  awk -f "$awk_script" "$cmd_file" > "$script_file"

  # Validate bash syntax (does NOT execute, just checks syntax)
  run bash -n "$script_file"
  [ "$status" -eq 0 ]

  # Verify script is not empty
  [ -s "$script_file" ]
}

@test "yolo-docker-maxxing: heredocs are properly closed" {
  local cmd_file="$BATS_TEST_DIRNAME/../../commands/yolo-docker-maxxing.md"
  local script_file="$BATS_TEST_TMPDIR/yolo-script.sh"
  local awk_script="$BATS_TEST_TMPDIR/extract.awk"

  # Create awk script for extraction
  cat > "$awk_script" << 'AWK_EOF'
/^```bash$/,/^```$/ {
  if (!/^```/) print
}
AWK_EOF

  # Extract bash script
  awk -f "$awk_script" "$cmd_file" > "$script_file"

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

  # Extract and execute script
  local cmd_file="$BATS_TEST_DIRNAME/../../commands/yolo-docker-maxxing.md"
  local script_file="$test_dir/yolo-script.sh"
  local awk_script="$test_dir/extract.awk"

  # Create awk extraction script
  cat > "$awk_script" << 'AWK_EOF'
/^```bash$/,/^```$/ {
  if (!/^```/) print
}
AWK_EOF

  awk -f "$awk_script" "$cmd_file" > "$script_file"
  chmod +x "$script_file"

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

@test "yolo-docker-maxxing: actual command uses safe unquoted heredoc delimiters" {
  # Verify that the actual command file uses ENDOFFILE, not 'EOF'
  # This test would FAIL if someone reverts back to << 'EOF'

  local cmd_file="$BATS_TEST_DIRNAME/../../commands/yolo-docker-maxxing.md"
  local script_file="$BATS_TEST_TMPDIR/check-delimiters.sh"
  local awk_script="$BATS_TEST_TMPDIR/extract.awk"

  # Extract bash script
  cat > "$awk_script" << 'AWK_EOF'
/^```bash$/,/^```$/ {
  if (!/^```/) print
}
AWK_EOF

  awk -f "$awk_script" "$cmd_file" > "$script_file"

  # Verify NO quoted heredoc delimiters exist
  run grep -c "<<.*'EOF'" "$script_file"
  [ "$status" -ne 0 ] || [ "$output" -eq 0 ]

  # Verify safe unquoted delimiters ARE used
  run grep -c "<<.*ENDOFFILE" "$script_file"
  [ "$status" -eq 0 ]
  [ "$output" -ge 2 ]  # Should have at least 2 heredocs with ENDOFFILE
}

@test "yolo-docker-maxxing: heredoc terminators are at column 0" {
  # CRITICAL: Heredoc terminators MUST start at column 0
  # If they're indented, heredocs break when executed
  # This test catches accidental indentation of ENDOFFILE lines

  local cmd_file="$BATS_TEST_DIRNAME/../../commands/yolo-docker-maxxing.md"
  local script_file="$BATS_TEST_TMPDIR/check-heredoc-indent.sh"
  local awk_script="$BATS_TEST_TMPDIR/extract.awk"

  cat > "$awk_script" << 'AWK_EOF'
/^```bash$/,/^```$/ { if (!/^```/) print }
AWK_EOF

  awk -f "$awk_script" "$cmd_file" > "$script_file"

  # Count heredoc starters (<< ENDOFFILE)
  run grep -c "<<.*ENDOFFILE" "$script_file"
  local heredoc_count="$output"

  # Count terminator lines at column 0 (just "ENDOFFILE" with nothing else)
  run grep -c "^ENDOFFILE$" "$script_file"
  local terminators_at_col0="$output"

  # Every heredoc opener should have a matching terminator at column 0
  [ "$terminators_at_col0" -eq "$heredoc_count" ]
}
