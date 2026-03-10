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

  # Count heredoc openers (<<) and closers (EOF on its own line)
  local openers=$(grep -c "<<.*'EOF'" "$script_file" || echo 0)
  local closers=$(grep -c "^EOF$" "$script_file" || echo 0)

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
