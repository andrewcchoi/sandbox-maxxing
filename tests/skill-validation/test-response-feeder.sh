#!/bin/bash
# Unit tests for response-feeder.sh pattern matching

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the response feeder
source "$SCRIPT_DIR/lib/response-feeder.sh"

# Test result counters
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
assert_equal() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"

    if [ "$expected" = "$actual" ]; then
        echo "  PASS: $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        echo "  FAIL: $test_name"
        echo "    Expected: '$expected'"
        echo "    Got: '$actual'"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_not_empty() {
    local actual="$1"
    local test_name="$2"

    if [ -n "$actual" ]; then
        echo "  PASS: $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        echo "  FAIL: $test_name (result was empty)"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Test 1: Parse YAML responses
test_yaml_parsing() {
    echo "Test 1: YAML Parsing"

    local config="/tmp/test-config-parse.yml"

    cat > "$config" << 'EOF'
metadata:
  mode: test
  description: "Test config"

responses:
  - prompt_pattern: "project.*name"
    response: "test-app"
  - prompt_pattern: "language|stack"
    response: "python"
  - prompt_pattern: "confirm"
    response: "yes"
EOF

    local result=$(parse_yaml_responses "$config")
    local line_count=$(echo "$result" | wc -l)

    assert_equal "3" "$line_count" "Should parse 3 response entries"

    # Check first entry
    local first_line=$(echo "$result" | head -n 1)
    assert_equal "project.*name|||test-app" "$first_line" "First entry should match"

    # Check second entry
    local second_line=$(echo "$result" | sed -n '2p')
    assert_equal "language|stack|||python" "$second_line" "Second entry should match"

    # Check third entry
    local third_line=$(echo "$result" | tail -n 1)
    assert_equal "confirm|||yes" "$third_line" "Third entry should match"

    rm -f "$config"
    echo ""
}

# Test 2: Pattern matching - exact match
test_pattern_matching_exact() {
    echo "Test 2: Pattern Matching - Exact Match"

    local config="/tmp/test-config-exact.yml"

    cat > "$config" << 'EOF'
responses:
  - prompt_pattern: "project.*name"
    response: "test-app"
  - prompt_pattern: "language|stack"
    response: "python"
EOF

    # Test matching first pattern
    local response=$(match_pattern_get_response "What is your project name?" 0 "$config" 2>/dev/null)
    assert_equal "test-app" "$response" "Should match 'project.*name' pattern"

    # Test matching second pattern
    local response=$(match_pattern_get_response "Choose a language: python, node, go" 1 "$config" 2>/dev/null)
    assert_equal "python" "$response" "Should match 'language|stack' pattern"

    rm -f "$config"
    echo ""
}

# Test 3: Case-insensitive matching
test_pattern_matching_case_insensitive() {
    echo "Test 3: Pattern Matching - Case Insensitive"

    local config="/tmp/test-config-case.yml"

    cat > "$config" << 'EOF'
responses:
  - prompt_pattern: "project.*name"
    response: "test-app"
EOF

    # Test uppercase
    local response=$(match_pattern_get_response "WHAT IS YOUR PROJECT NAME?" 0 "$config" 2>/dev/null)
    assert_equal "test-app" "$response" "Should match uppercase question"

    # Test mixed case
    local response=$(match_pattern_get_response "Project Name Required" 0 "$config" 2>/dev/null)
    assert_equal "test-app" "$response" "Should match mixed case question"

    rm -f "$config"
    echo ""
}

# Test 4: Out-of-order matching (resilience)
test_pattern_matching_out_of_order() {
    echo "Test 4: Pattern Matching - Out of Order"

    local config="/tmp/test-config-order.yml"

    cat > "$config" << 'EOF'
responses:
  - prompt_pattern: "project.*name"
    response: "test-app"
  - prompt_pattern: "language|stack"
    response: "python"
  - prompt_pattern: "database"
    response: "postgres"
EOF

    # Ask for database question (index 2) but pass index 0
    # Should still match because we fall back to any-pattern matching
    local response=$(match_pattern_get_response "Which database do you need?" 0 "$config" 2>/dev/null)
    assert_equal "postgres" "$response" "Should match out-of-order pattern"

    rm -f "$config"
    echo ""
}

# Test 5: No match - safe defaults
test_pattern_matching_no_match() {
    echo "Test 5: Pattern Matching - No Match (Safe Defaults)"

    local config="/tmp/test-config-nomatch.yml"

    cat > "$config" << 'EOF'
responses:
  - prompt_pattern: "project.*name"
    response: "test-app"
EOF

    # Test confirmation question without pattern
    local response=$(match_pattern_get_response "Do you want to proceed?" 0 "$config" 2>/dev/null)
    assert_equal "yes" "$response" "Should default to 'yes' for confirmation questions"

    # Test none/skip question
    local response=$(match_pattern_get_response "Do you want to skip this?" 0 "$config" 2>/dev/null)
    assert_equal "none" "$response" "Should default to 'none' for skip questions"

    # Test generic question
    local response=$(match_pattern_get_response "Something completely different?" 0 "$config" 2>/dev/null)
    assert_equal "" "$response" "Should default to empty for generic questions"

    rm -f "$config"
    echo ""
}

# Test 6: Regex patterns
test_pattern_matching_regex() {
    echo "Test 6: Pattern Matching - Regex Patterns"

    local config="/tmp/test-config-regex.yml"

    cat > "$config" << 'EOF'
responses:
  - prompt_pattern: "project.*(name|title)"
    response: "test-app"
  - prompt_pattern: "language|stack|programming"
    response: "python"
EOF

    # Test first pattern variation
    local response=$(match_pattern_get_response "What is your project title?" 0 "$config" 2>/dev/null)
    assert_equal "test-app" "$response" "Should match 'project.*title' variation"

    # Test second pattern with 'programming'
    local response=$(match_pattern_get_response "Select programming language" 1 "$config" 2>/dev/null)
    assert_equal "python" "$response" "Should match 'programming' alternative"

    rm -f "$config"
    echo ""
}

# Test 7: List configured patterns
test_list_configured_patterns() {
    echo "Test 7: List Configured Patterns"

    local config="/tmp/test-config-list.yml"

    cat > "$config" << 'EOF'
responses:
  - prompt_pattern: "project.*name"
    response: "test-app"
  - prompt_pattern: "language"
    response: "python"
EOF

    local output=$(list_configured_patterns "$config" 2>&1)

    # Check that output contains both patterns
    if [[ "$output" =~ "project.*name" ]] && [[ "$output" =~ "language" ]]; then
        echo "  PASS: Should list all configured patterns"
        ((TESTS_PASSED++))
    else
        echo "  FAIL: Should list all configured patterns"
        echo "    Output: $output"
        ((TESTS_FAILED++))
    fi

    rm -f "$config"
    echo ""
}

# Test 8: Empty config file
test_empty_config() {
    echo "Test 8: Empty Config File"

    local config="/tmp/test-config-empty.yml"

    cat > "$config" << 'EOF'
metadata:
  mode: test
EOF

    local result=$(parse_yaml_responses "$config")

    if [ -z "$result" ]; then
        echo "  PASS: Should handle empty responses section"
        ((TESTS_PASSED++))
    else
        echo "  FAIL: Should handle empty responses section"
        echo "    Got: $result"
        ((TESTS_FAILED++))
    fi

    rm -f "$config"
    echo ""
}

# Test 9: Special characters in responses
test_special_characters() {
    echo "Test 9: Special Characters in Responses"

    local config="/tmp/test-config-special.yml"

    cat > "$config" << 'EOF'
responses:
  - prompt_pattern: "ports"
    response: "443,8080"
  - prompt_pattern: "path"
    response: "/usr/local/bin"
EOF

    # Test comma in response
    local response=$(match_pattern_get_response "Which ports do you need?" 0 "$config" 2>/dev/null)
    assert_equal "443,8080" "$response" "Should handle comma in response"

    # Test slash in response
    local response=$(match_pattern_get_response "Enter the path" 1 "$config" 2>/dev/null)
    assert_equal "/usr/local/bin" "$response" "Should handle slash in response"

    rm -f "$config"
    echo ""
}

# Test 10: Real-world test config from examples
test_real_world_config() {
    echo "Test 10: Real-World Config (from examples)"

    local config="/workspace/examples/demo-app-sandbox-basic/test-config.yml"

    if [ ! -f "$config" ]; then
        echo "  SKIP: Config file not found at $config"
        echo ""
        return
    fi

    # Test parsing
    local result=$(parse_yaml_responses "$config")
    assert_not_empty "$result" "Should parse real config file"

    # Test matching various questions
    local response=$(match_pattern_get_response "What is your project name?" 0 "$config" 2>/dev/null)
    assert_equal "demo-app" "$response" "Should match project name question"

    local response=$(match_pattern_get_response "Choose language: python, node, go" 1 "$config" 2>/dev/null)
    assert_equal "python" "$response" "Should match language question"

    echo ""
}

# Run all tests
main() {
    echo "=========================================="
    echo "Response Feeder Pattern Matching Tests"
    echo "=========================================="
    echo ""

    test_yaml_parsing
    test_pattern_matching_exact
    test_pattern_matching_case_insensitive
    test_pattern_matching_out_of_order
    test_pattern_matching_no_match
    test_pattern_matching_regex
    test_list_configured_patterns
    test_empty_config
    test_special_characters
    test_real_world_config

    echo "=========================================="
    echo "Test Results"
    echo "=========================================="
    echo "Passed: $TESTS_PASSED"
    echo "Failed: $TESTS_FAILED"
    echo ""

    if [ $TESTS_FAILED -eq 0 ]; then
        echo "All tests passed!"
        return 0
    else
        echo "Some tests failed!"
        return 1
    fi
}

# Run tests if executed directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main
    exit $?
fi
