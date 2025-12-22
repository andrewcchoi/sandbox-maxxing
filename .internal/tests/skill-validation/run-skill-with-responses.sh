#!/bin/bash
# Wrapper to run sandbox setup skills with automated responses from test-config.yml
# This wrapper invokes skills via Claude Code's Skill tool instead of bash subprocess

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/response-feeder.sh"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

# Logging
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Usage
usage() {
    cat <<EOF
Usage: $0 <mode> <output_dir> [config_file]

Run a sandbox setup skill with automated responses from test-config.yml

Arguments:
  mode         Sandbox mode: basic, intermediate, advanced, or yolo
  output_dir   Directory where skill should generate files
  config_file  Path to test-config.yml (optional, auto-detected from examples)

Examples:
  $0 basic /tmp/test-output
  $0 intermediate /tmp/test-output /path/to/test-config.yml

Environment Variables:
  SKILL_TIMEOUT  Timeout in seconds (default: 300)
  DEBUG          Enable debug output (true/false)

The wrapper will:
  1. Load test-config.yml for the specified mode
  2. Prepare the output directory
  3. Invoke the skill using Claude Code's Skill tool
  4. Monitor for questions and feed automated responses
  5. Wait for skill completion
  6. Report results

Note: This wrapper must be run within an active Claude Code conversation.
EOF
}

# Parse arguments
if [ "$1" = "-h" ] || [ "$1" = "--help" ] || [ $# -lt 2 ]; then
    usage
    exit 0
fi

MODE="$1"
OUTPUT_DIR="$2"
CONFIG_FILE="${3:-}"

# Validate mode
case "$MODE" in
    basic|intermediate|advanced|yolo) ;;
    *)
        log_error "Invalid mode: $MODE"
        log_error "Must be one of: basic, intermediate, advanced, yolo"
        exit 1
        ;;
esac

# Auto-detect config file if not provided
if [ -z "$CONFIG_FILE" ]; then
    CONFIG_FILE="/workspace/examples/demo-app-sandbox-$MODE/test-config.yml"
    if [ ! -f "$CONFIG_FILE" ]; then
        log_error "Config file not found: $CONFIG_FILE"
        exit 1
    fi
    log_info "Using config: $CONFIG_FILE"
fi

# Validate config file
if [ ! -f "$CONFIG_FILE" ]; then
    log_error "Config file not found: $CONFIG_FILE"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"
cd "$OUTPUT_DIR"

log_info "========================================="
log_info "Sandbox Skill Test Wrapper"
log_info "========================================="
log_info "Mode: $MODE"
log_info "Output: $OUTPUT_DIR"
log_info "Config: $CONFIG_FILE"
log_info "========================================="
log_info ""

# Load responses from config
log_info "Loading test configuration..."
RESPONSES=$(parse_yaml_responses "$CONFIG_FILE")
if [ -z "$RESPONSES" ]; then
    log_error "No responses found in config file"
    exit 1
fi

RESPONSE_COUNT=$(echo "$RESPONSES" | wc -l)
log_info "Loaded $RESPONSE_COUNT response patterns"
log_info ""

# Create a temporary file to store the conversation prompt
PROMPT_FILE=$(mktemp)
trap "rm -f $PROMPT_FILE" EXIT

# Build the prompt with responses
cat > "$PROMPT_FILE" <<EOF
I need you to run the /devcontainer-setup:$MODE skill in this directory: $OUTPUT_DIR

Please use these automated responses when the skill asks questions:

EOF

# Add each response to the prompt
RESPONSE_INDEX=0
while IFS='|||' read -r pattern response; do
    ((RESPONSE_INDEX++))
    echo "$RESPONSE_INDEX. $response" >> "$PROMPT_FILE"
done <<< "$RESPONSES"

cat >> "$PROMPT_FILE" <<'EOF'

Please run the skill now and use these responses automatically.

IMPORTANT:
- Answer each question with the corresponding numbered response above
- Do not ask me for clarification - use the provided responses
- Complete the full skill execution
- Report when done
EOF

log_info "========================================="
log_info "Skill Invocation Instructions Prepared"
log_info "========================================="
cat "$PROMPT_FILE"
log_info "========================================="
log_info ""

log_warn "MANUAL STEP REQUIRED:"
log_warn "This wrapper has prepared the skill invocation instructions above."
log_warn "To complete the test, you need to:"
log_warn "  1. Use the Skill tool to invoke /devcontainer-setup:$MODE"
log_warn "  2. Feed the numbered responses when questions are asked"
log_warn "  3. Wait for skill completion"
log_warn "  4. Verify files are generated in: $OUTPUT_DIR"
log_warn ""
log_warn "The test harness will then compare the generated files against examples."

# For now, we document that manual invocation is needed
# In the future, this could be integrated with Claude Code's conversation API

log_info ""
log_info "Waiting for manual skill invocation..."
log_info "Press Ctrl+C to abort"

# Since we can't directly invoke the Skill tool from bash, we'll wait
# and provide instructions for manual completion
sleep 2

echo ""
echo "========================================="
echo "NEXT STEPS:"
echo "========================================="
echo "1. The skill should be invoked with: /devcontainer-setup:$MODE"
echo "2. Provide responses in order when asked:"
echo ""
while IFS='|||' read -r pattern response; do
    echo "   - $response"
done <<< "$RESPONSES"
echo ""
echo "3. After skill completes, the test harness will compare files"
echo "========================================="

exit 0
