# Automated Skill Testing Design

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Automated regression testing for sandbox setup skills using recorded conversations and example-based validation.

**Architecture:** Response feeder system that monitors skill output in real-time, feeds canned responses from test configs, and compares generated files against working examples.

**Tech Stack:** Bash, named pipes (mkfifo), YAML configs, existing comparison engine

---

## Problem Statement

The continuous skill testing framework revealed that sandbox setup skills cannot run in headless mode - they ask clarifying questions and wait for interactive responses. This makes automated regression testing impossible with simple input piping.

**Requirements:**
- Automated testing after skill changes (no manual intervention)
- Compare against known-good configurations (examples directory)
- Handle skill variations in questions/flow
- Clear failure reporting when skills break

---

## Architecture Overview

**Three-Layer System:**

1. **Test Configs** - YAML files co-located with examples, define canned responses
2. **Response Feeder** - Monitors skill output, feeds responses via named pipes
3. **Example Comparison** - Validates generated files against example configs

**Flow:**
```
test-harness.sh
  ↓
feed_responses_interactive() → skill via named pipes
  ↓                              ↓
monitors questions ←──────────── skill output
  ↓
feeds responses → skill input
  ↓
compare_with_examples() → score
  ↓
report
```

**Fallback Strategy:**
- Primary: Interactive monitoring with test-config.yml
- Fallback: Pre-piped default responses when no config exists
- Both methods are fully automated

---

## Test Config Format

**Location:** Co-located with examples
```
/workspace/examples/demo-app-sandbox-basic/
  ├── .devcontainer/...
  ├── docker-compose.yml
  └── test-config.yml  ← New
```

**Format:**
```yaml
metadata:
  mode: basic
  description: "Basic mode with Python backend, minimal setup"
  expected_files:
    - .devcontainer/devcontainer.json
    - .devcontainer/Dockerfile
    - docker-compose.yml
    - .devcontainer/init-firewall.sh
    - .devcontainer/setup-claude-credentials.sh

responses:
  - prompt_pattern: "project.*name|what.*call"
    response: "demo-app"

  - prompt_pattern: "language|stack"
    response: "python"

  - prompt_pattern: "services|database"
    response: "none"

  - prompt_pattern: "confirm|proceed"
    response: "yes"
```

**Design Principles:**
- Uses regex patterns for resilience to question variations
- Ordered responses matching typical skill flow
- Metadata documents what this config represents
- Expected files list used for validation

---

## Response Feeder Component

**File:** `lib/response-feeder.sh`

### Interactive Monitoring (Primary)

```bash
feed_responses_interactive() {
  local mode="$1"
  local config_file="$2"
  local response_index=0

  # Create named pipes for bidirectional communication
  mkfifo skill_output skill_input

  # Launch skill in background with pipes
  claude skill devcontainer-setup-$mode < skill_input > skill_output 2>&1 &
  local skill_pid=$!

  # Set 1-minute timeout
  local start_time=$(date +%s)
  local timeout=60

  # Monitor loop
  while IFS= read -r line; do
    echo "$line" >> "$LOG_FILE"  # Log everything

    # Check timeout
    local current_time=$(date +%s)
    if [ $((current_time - start_time)) -gt $timeout ]; then
      log_error "Skill timeout after 1 minute"
      kill $skill_pid 2>/dev/null
      break
    fi

    # Check if line contains a question
    if [[ "$line" =~ \?$ ]] || is_prompt_line "$line"; then

      # Find matching response from config
      local response=$(match_pattern_get_response "$line" "$response_index")

      if [ -n "$response" ]; then
        echo "$response" > skill_input
        ((response_index++))
      else
        log_error "No response configured for: $line"
        break
      fi
    fi

    # Check if skill completed
    if skill_completed "$mode"; then
      break
    fi
  done < skill_output

  # Cleanup
  kill $skill_pid 2>/dev/null
  rm skill_output skill_input
}
```

**Key Features:**
- Named pipes for real-time bidirectional communication
- Pattern matching against config for each question
- 1-minute timeout to prevent hung tests
- Complete conversation logged for debugging

### Pre-Pipe Fallback

```bash
feed_responses_prepipe() {
    local mode="$1"

    # Fallback: Default response sequences
    case "$mode" in
        basic)
            echo -e "demo-app\npython\nyes\n" | claude skill devcontainer-setup-basic
            ;;
        intermediate)
            echo -e "demo-app\npython\npostgres\nyes\n" | claude skill devcontainer-setup-intermediate
            ;;
        advanced)
            echo -e "demo-app\npython\npostgres\n443,8080\nyes\n" | claude skill devcontainer-setup-advanced
            ;;
        yolo)
            echo -e "demo-app\npython\nyes\n" | claude skill devcontainer-setup-yolo
            ;;
    esac
}
```

**Key Features:**
- Simple concatenated responses
- Ensures tests can always run
- Used when no test-config.yml exists

---

## Integration with Test Harness

**Modified:** `test-harness.sh` - `generate_skill_output()` function

```bash
generate_skill_output() {
    local mode="$1"
    local test_project="$TEST_DIR/test-project"
    local output_dir="$GENERATED_DIR/$mode"
    local example_dir="/workspace/examples/demo-app-sandbox-$mode"
    local config_file="$example_dir/test-config.yml"

    log_info "Generating output for $mode mode..."

    # Create fresh test directory
    rm -rf "$output_dir"
    cp -r "$test_project" "$output_dir"
    cd "$output_dir"

    # Load response feeder
    source "$TEST_DIR/lib/response-feeder.sh"

    # Try interactive monitoring first
    if [ -f "$config_file" ]; then
        log_info "Using test config with interactive monitoring: $config_file"
        feed_responses_interactive "$mode" "$config_file"
    else
        # Fallback: Pre-pipe default responses
        log_warn "No test config found, using pre-piped defaults"
        feed_responses_prepipe "$mode"
    fi

    # Validate generated files exist
    validate_generated_files "$mode"

    # Return to test directory
    cd "$TEST_DIR"
}
```

**Two-Tier Approach:**
1. Try interactive monitoring with test config (preferred)
2. Fall back to pre-pipe if no config (ensures always works)
3. Both methods fully automated

---

## Comparison Strategy

**Modified:** `compare-containers.sh` - New `compare_with_examples()` function

```bash
compare_with_examples() {
    local mode="$1"
    local generated_dir="$GENERATED_DIR/$mode"
    local example_dir="/workspace/examples/demo-app-sandbox-$mode"

    log_info "Comparing generated files against examples for $mode..."

    # Check if example exists
    if [ ! -d "$example_dir" ]; then
        log_warn "No example for $mode, falling back to template comparison"
        compare_with_templates "$mode"
        return $?
    fi

    local total_score=0
    local file_count=0

    # Compare devcontainer.json
    if [ -f "$example_dir/.devcontainer/devcontainer.json" ]; then
        local score=$(compare_json_files \
            "$generated_dir/.devcontainer/devcontainer.json" \
            "$example_dir/.devcontainer/devcontainer.json")
        total_score=$((total_score + score))
        ((file_count++))
        log_info "devcontainer.json similarity: $score%"
    fi

    # Compare docker-compose.yml
    if [ -f "$example_dir/docker-compose.yml" ]; then
        local score=$(compare_yaml_files \
            "$generated_dir/docker-compose.yml" \
            "$example_dir/docker-compose.yml")
        total_score=$((total_score + score))
        ((file_count++))
        log_info "docker-compose.yml similarity: $score%"
    fi

    # Compare Dockerfile
    if [ -f "$example_dir/.devcontainer/Dockerfile" ]; then
        local score=$(compare_dockerfiles \
            "$generated_dir/.devcontainer/Dockerfile" \
            "$example_dir/.devcontainer/Dockerfile")
        total_score=$((total_score + score))
        ((file_count++))
        log_info "Dockerfile similarity: $score%"
    fi

    # Compare shell scripts
    for script in init-firewall.sh setup-claude-credentials.sh; do
        if [ -f "$example_dir/.devcontainer/$script" ]; then
            local score=$(compare_shell_scripts \
                "$generated_dir/.devcontainer/$script" \
                "$example_dir/.devcontainer/$script")
            total_score=$((total_score + score))
            ((file_count++))
            log_info "$script similarity: $score%"
        fi
    done

    # Calculate average
    if [ $file_count -eq 0 ]; then
        echo "0"
        return 1
    fi

    local avg_score=$((total_score / file_count))
    log_info "Average similarity for $mode: $avg_score%"
    echo "$avg_score"
}
```

**Key Changes:**
- Compares against example files instead of templates
- Uses existing structural comparison logic
- Falls back to template comparison if no example
- Reports per-file and average similarity scores

---

## Error Handling and Edge Cases

### Unexpected Questions

```bash
match_pattern_get_response() {
  local question="$1"
  local response_index="$2"

  # Try to match configured patterns
  local response=$(grep_yaml_responses | match_by_index "$response_index")

  if [ -z "$response" ]; then
    # No match at expected index - try matching any pattern
    response=$(match_any_pattern "$question")

    if [ -z "$response" ]; then
      log_error "Unexpected question: $question"
      log_error "No response configured. Available patterns:"
      list_configured_patterns

      # Feed safe default: "yes" for confirmation, empty for open-ended
      if [[ "$question" =~ (confirm|proceed|continue|ok) ]]; then
        echo "yes"
      else
        echo ""  # Let skill use defaults
      fi

      return 1  # Signal mismatch for reporting
    fi
  fi

  echo "$response"
}
```

### Timeout Handling

- **Timeout:** 1 minute per skill run
- **Action:** Kill skill process, log failure, preserve output for debugging
- **Reporting:** Include timeout in failure report
- **Tuning:** Start conservative, increase if timeouts are frequent

### Skill Errors During Generation

- **Capture:** stderr to separate error.log
- **Detection:** Non-zero exit code from skill
- **Reporting:** "Generation failed" with error log excerpt
- **Behavior:** Skip comparison if generation failed

### Cleanup on Failure

```bash
cleanup() {
  # Always clean up named pipes
  rm -f skill_output skill_input 2>/dev/null

  # Kill background skill if still running
  if [ -n "$skill_pid" ]; then
    kill $skill_pid 2>/dev/null
  fi

  # Preserve failed output for debugging
  if [ "$FAILED" = "true" ]; then
    cp -r "$output_dir" "$REPORT_DIR/failed-$mode-$timestamp"
  fi

  # Log complete conversation
  cp "$LOG_FILE" "$REPORT_DIR/$mode-conversation.log"
}

trap cleanup EXIT
```

### Pattern Mismatch Reporting

- **Track:** Which questions had no configured response
- **Include:** In test report under "Configuration Issues"
- **Purpose:** Identify when skills change their questions
- **Action:** Suggests updating test-config.yml

---

## Testing the Test System

### Unit Tests for Pattern Matching

```bash
# test-response-feeder.sh
test_pattern_matching() {
  local config="/tmp/test-config.yml"

  # Create test config
  cat > "$config" << 'EOF'
responses:
  - prompt_pattern: "project.*name"
    response: "test-app"
  - prompt_pattern: "language|stack"
    response: "python"
EOF

  # Test exact matches
  assert_match "What is your project name?" "test-app"
  assert_match "Choose a language: python, node, go" "python"

  # Test no match
  assert_no_match "Unexpected question?" ""

  echo "Pattern matching tests: PASSED"
}
```

### Dry-Run Mode

```bash
# Add to test-harness.sh
if [ "$DRY_RUN" = "true" ]; then
  # Show what would happen without running skill
  echo "Would test: $mode"
  echo "Config: $config_file"
  echo "Responses:"
  cat "$config_file" | yq '.responses[].response'
  exit 0
fi
```

### Validation Checks

**Pre-flight checks before running:**
- Verify example directory exists for each mode
- Validate test-config.yml syntax (valid YAML)
- Check response count is reasonable (2-10 responses typical)
- Warn if no responses configured

### Smoke Test

**Manual validation before automation:**
1. Run basic mode test once manually
2. Verify it generates files without errors
3. Verify comparison produces reasonable score (>70%)
4. Check conversation log shows correct Q&A flow

---

## Implementation Phases

### Phase 1: Response Feeder Foundation

**Goal:** Get basic pre-pipe fallback working

**Tasks:**
- Create `lib/response-feeder.sh` with basic structure
- Implement `feed_responses_prepipe()` with hardcoded defaults
- Test with one mode (basic) to verify skill runs
- Verify files are generated

**Deliverable:** Basic mode generates files via pre-pipe fallback

---

### Phase 2: Test Config and Pattern Matching

**Goal:** Build pattern matching system in isolation

**Tasks:**
- Define test-config.yml schema
- Create config for basic mode example
- Implement `match_pattern_get_response()` function
- Write unit tests for pattern matching
- Test against sample questions

**Deliverable:** Pattern matcher works in isolation

---

### Phase 3: Interactive Monitoring

**Goal:** Get named pipes working with real skill

**Tasks:**
- Implement `feed_responses_interactive()` with named pipes
- Add timeout handling (1 minute)
- Add question detection logic
- Test with basic mode using real test-config.yml
- Debug pipe communication issues

**Deliverable:** Basic mode runs via interactive monitoring

---

### Phase 4: Integration and Comparison

**Goal:** Full end-to-end flow for one mode

**Tasks:**
- Modify `generate_skill_output()` to use response feeder
- Implement `compare_with_examples()` function
- Update `compare-containers.sh` to prefer examples
- Test full flow: generate → compare → report
- Verify similarity score is reasonable (>70%)

**Deliverable:** One mode tested end-to-end

---

### Phase 5: Complete Coverage

**Goal:** All modes working with automated tests

**Tasks:**
- Create test configs for intermediate, advanced, yolo modes
- Test each mode individually
- Run continuous test across all modes
- Analyze results, tune timeout/patterns as needed
- Fix any failing modes

**Deliverable:** All modes passing automated tests

---

### Phase 6: Robustness

**Goal:** Production-ready test harness

**Tasks:**
- Add error handling from Section 7
- Implement dry-run mode and validation checks
- Add cleanup on failure
- Document test config format
- Create README for test system

**Deliverable:** Production-ready test harness

---

## Success Criteria

**Test system is successful when:**
1. All 4 modes generate files without manual intervention
2. Comparison scores are >70% similarity to examples
3. Tests complete in <5 minutes for all modes
4. Clear failure reports identify what broke
5. Pattern mismatches suggest config updates

**Regression detection works when:**
1. Skill change breaks generation → test catches it
2. Skill changes questions → pattern mismatch reported
3. Generated files differ from examples → low score flags it
4. Can run tests after every skill edit confidently

---

## Files to Create

1. `lib/response-feeder.sh` - Interactive monitoring and pre-pipe fallback
2. `examples/demo-app-sandbox-basic/test-config.yml` - Basic mode responses
3. `examples/demo-app-sandbox-intermediate/test-config.yml` - Intermediate mode responses
4. `examples/demo-app-sandbox-advanced/test-config.yml` - Advanced mode responses
5. `examples/demo-app-sandbox-yolo/test-config.yml` - YOLO mode responses
6. `test-response-feeder.sh` - Unit tests for pattern matching
7. `docs/TEST_SYSTEM.md` - Documentation for test system

## Files to Modify

1. `test-harness.sh` - Update `generate_skill_output()` to use response feeder
2. `compare-containers.sh` - Add `compare_with_examples()` function
3. `run-continuous.sh` - Update to use new comparison strategy

---

## Next Steps

After implementation:
1. Run full continuous test suite
2. Analyze results and tune thresholds
3. Document any patterns discovered
4. Add to CI/CD if applicable
5. Use for regression testing during skill development

---

**Version:** 3.0.0
**Date:** 2025-12-20
**Status:** Design Complete, Ready for Implementation
