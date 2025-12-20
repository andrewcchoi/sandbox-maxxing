#!/bin/bash
# Manual test with sample questions to verify pattern matching

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/response-feeder.sh"

CONFIG="/workspace/examples/demo-app-sandbox-basic/test-config.yml"

echo "=========================================="
echo "Testing Pattern Matching with Sample Questions"
echo "=========================================="
echo ""

if [ ! -f "$CONFIG" ]; then
    echo "ERROR: Config file not found: $CONFIG"
    exit 1
fi

echo "Using config: $CONFIG"
echo ""

# List configured patterns
list_configured_patterns "$CONFIG"
echo ""

# Test various question variations
echo "Testing question variations:"
echo ""

questions=(
    "What is your project name?"
    "Enter project name:"
    "What do you want to call your project?"
    "Which language would you like to use?"
    "Select programming language:"
    "Choose your stack: python, node, go"
    "Do you need any additional services?"
    "Configure database (postgres, mysql, none):"
    "Would you like to proceed with these settings?"
    "Confirm to continue:"
)

for i in "${!questions[@]}"; do
    question="${questions[$i]}"
    echo "Q[$i]: $question"
    response=$(match_pattern_get_response "$question" $i "$CONFIG" 2>/dev/null)
    echo "A[$i]: $response"
    echo ""
done

echo "=========================================="
echo "Test completed successfully"
echo "=========================================="
