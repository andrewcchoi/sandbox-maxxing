#!/bin/bash
# Test script for comparison engine
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load Python fallbacks for jq and bc if not available
if ! command -v jq >/dev/null 2>&1 || ! command -v bc >/dev/null 2>&1; then
    source "$SCRIPT_DIR/lib/python-fallbacks.sh"
fi

source "$SCRIPT_DIR/lib/diff-analyzer.sh"
source "$SCRIPT_DIR/lib/section-parser.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test assertion helper
assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"

    ((TESTS_RUN++))

    if [ "$expected" = "$actual" ]; then
        echo -e "${GREEN}✓ PASS${NC}: $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}: $test_name"
        echo "  Expected: $expected"
        echo "  Actual: $actual"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Test validate_syntax function
test_validate_syntax() {
    echo "Testing validate_syntax()..."

    # Valid JSON
    if validate_syntax "$SCRIPT_DIR/fixtures/test-files/valid.json"; then
        assert_equals "0" "0" "Valid JSON should pass validation"
    else
        assert_equals "0" "1" "Valid JSON should pass validation"
    fi

    # Invalid JSON
    if validate_syntax "$SCRIPT_DIR/fixtures/test-files/invalid.json"; then
        assert_equals "1" "0" "Invalid JSON should fail validation"
    else
        assert_equals "1" "1" "Invalid JSON should fail validation"
    fi

    # Valid YAML
    if validate_syntax "$SCRIPT_DIR/fixtures/test-files/valid.yml"; then
        assert_equals "0" "0" "Valid YAML should pass validation"
    else
        assert_equals "0" "1" "Valid YAML should pass validation"
    fi

    # Valid Dockerfile
    if validate_syntax "$SCRIPT_DIR/fixtures/test-files/Dockerfile.valid"; then
        assert_equals "0" "0" "Valid Dockerfile should pass validation"
    else
        assert_equals "0" "1" "Valid Dockerfile should pass validation"
    fi
}

# Test calculate_structure_similarity function
test_calculate_structure_similarity() {
    echo ""
    echo "Testing calculate_structure_similarity()..."

    # Same structure should be 100%
    local score
    score=$(calculate_structure_similarity "$SCRIPT_DIR/fixtures/test-files/valid.json" "$SCRIPT_DIR/fixtures/test-files/valid.json")

    # Check if score is 100 or very close
    if [ "$(echo "$score >= 99" | bc)" -eq 1 ]; then
        assert_equals "100" "100" "Identical files should have ~100% similarity"
    else
        assert_equals "100" "$score" "Identical files should have ~100% similarity"
    fi

    # Similar structure should be high percentage
    score=$(calculate_structure_similarity "$SCRIPT_DIR/fixtures/test-files/valid.json" "$SCRIPT_DIR/fixtures/test-files/similar.json")

    if [ "$(echo "$score >= 80" | bc)" -eq 1 ]; then
        assert_equals "high" "high" "Similar files should have >80% similarity"
    else
        assert_equals "high" "$score" "Similar files should have >80% similarity"
    fi

    # Different structure should be low percentage
    score=$(calculate_structure_similarity "$SCRIPT_DIR/fixtures/test-files/valid.json" "$SCRIPT_DIR/fixtures/test-files/different.json")

    if [ "$(echo "$score < 50" | bc)" -eq 1 ]; then
        assert_equals "low" "low" "Different files should have <50% similarity"
    else
        assert_equals "low" "$score" "Different files should have <50% similarity"
    fi
}

# Test section parser functions
test_section_parser() {
    echo ""
    echo "Testing section parser functions..."

    # Create test file with sections
    local test_file="$SCRIPT_DIR/fixtures/test-files/test-sections.txt"
    cat > "$test_file" <<'EOF'
# Test file with sections
===SECTION_START:header===
This is the header section
===SECTION_END:header===

===SECTION_START:body===
This is the body section
===SECTION_END:body===

===SECTION_START:footer===
This is the footer section
===SECTION_END:footer===
EOF

    # Test extract_sections
    local sections
    sections=$(extract_sections "$test_file")
    local section_count=$(echo "$sections" | wc -l)

    assert_equals "3" "$section_count" "Should extract 3 sections"

    # Test section_exists
    if section_exists "$test_file" "header"; then
        assert_equals "found" "found" "Should find existing section"
    else
        assert_equals "found" "not-found" "Should find existing section"
    fi

    if section_exists "$test_file" "nonexistent"; then
        assert_equals "not-found" "found" "Should not find non-existent section"
    else
        assert_equals "not-found" "not-found" "Should not find non-existent section"
    fi

    # Test get_section_content
    local content
    content=$(get_section_content "$test_file" "header")

    if echo "$content" | grep -q "header section"; then
        assert_equals "contains" "contains" "Should extract section content"
    else
        assert_equals "contains" "missing" "Should extract section content"
    fi

    # Cleanup
    rm -f "$test_file"
}

# Test compare_dockerfile function
test_compare_dockerfile() {
    echo ""
    echo "Testing compare_dockerfile()..."

    # Source the comparison script
    source "$SCRIPT_DIR/compare-containers.sh"

    # Test basic mode with 2-stage Dockerfile
    local score
    score=$(compare_dockerfile "$SCRIPT_DIR/fixtures/test-files/Dockerfile.valid" "" "basic")

    # Should return 90 for 2 stages
    assert_equals "90" "$score" "Basic mode with 2 stages should score 90"

    # Test intermediate mode with 2-stage Dockerfile
    score=$(compare_dockerfile "$SCRIPT_DIR/fixtures/test-files/Dockerfile.valid" "" "intermediate")

    # Should return 95 for 2 stages
    assert_equals "95" "$score" "Intermediate mode with 2 stages should score 95"
}

# Test error handling
test_error_handling() {
    echo ""
    echo "Testing error handling..."

    # Non-existent file
    local score
    score=$(calculate_structure_similarity "/nonexistent/file.json" "$SCRIPT_DIR/fixtures/test-files/valid.json" 2>/dev/null || echo "0")

    assert_equals "0" "$score" "Non-existent file should return 0"

    # Invalid syntax should fail validation
    if validate_syntax "$SCRIPT_DIR/fixtures/test-files/invalid.json" 2>/dev/null; then
        assert_equals "fail" "pass" "Invalid syntax should fail validation"
    else
        assert_equals "fail" "fail" "Invalid syntax should fail validation"
    fi
}

# Main test runner
main() {
    echo "========================================="
    echo "Running Comparison Engine Tests"
    echo "========================================="
    echo ""

    # Check dependencies
    echo "Checking dependencies..."
    command -v jq >/dev/null || { echo "ERROR: jq not found"; exit 1; }
    command -v python3 >/dev/null || { echo "ERROR: python3 not found"; exit 1; }
    command -v bc >/dev/null || { echo "ERROR: bc not found"; exit 1; }
    echo "✓ All dependencies found"
    echo ""

    # Run tests
    test_validate_syntax
    test_calculate_structure_similarity
    test_section_parser
    test_compare_dockerfile
    test_error_handling

    # Summary
    echo ""
    echo "========================================="
    echo "Test Summary"
    echo "========================================="
    echo "Tests run: $TESTS_RUN"
    echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"

    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed${NC}"
        exit 1
    fi
}

main "$@"
