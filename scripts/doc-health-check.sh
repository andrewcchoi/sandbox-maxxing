#!/usr/bin/env bash
# doc-health-check.sh - Master documentation validation orchestrator
# Part of documentation health check automation
#
# Runs all documentation validation scripts and provides a comprehensive health report

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PLUGIN_ROOT"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║         Sandboxxer Plugin Documentation Health Check         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

ERRORS=0
WARNINGS=0
CHECKS_PASSED=0
CHECKS_FAILED=0

# Helper function to run a check
run_check() {
  local check_name="$1"
  local script_path="$2"

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "CHECK: $check_name"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  if [[ ! -f "$script_path" ]]; then
    echo "❌ ERROR: Check script not found: $script_path"
    ((ERRORS++))
    ((CHECKS_FAILED++))
    echo ""
    return 1
  fi

  if bash "$script_path"; then
    ((CHECKS_PASSED++))
    echo ""
    return 0
  else
    local exit_code=$?
    ((CHECKS_FAILED++))
    if [[ $exit_code -eq 1 ]]; then
      ((ERRORS++))
    else
      ((WARNINGS++))
    fi
    echo ""
    return $exit_code
  fi
}

# Run all checks
run_check "Version Consistency" "$SCRIPT_DIR/version-checker.sh" || true
run_check "Diagram Inventory" "$SCRIPT_DIR/diagram-inventory.sh" || true
# Note: bidirectional-validation.sh disabled due to sandbox restrictions on find commands
# Run manually in non-sandboxed environments: bash scripts/bidirectional-validation.sh
# run_check "Bidirectional Validation" "$SCRIPT_DIR/bidirectional-validation.sh" || true

# Check line endings for polyglot hook wrapper
echo "CHECK: Polyglot Hook Line Endings"
if file hooks/run-hook.cmd | grep -q "CRLF"; then
    echo "ERROR: hooks/run-hook.cmd has CRLF line endings"
    echo "   Polyglot heredoc requires LF for bash to parse correctly"
    echo "   CRLF causes 'unexpected end of file' errors on Linux/WSL"
    echo "   To fix: sed -i 's/\\r$//' hooks/run-hook.cmd"
    ((ERRORS++)) || true
else
    echo "hooks/run-hook.cmd has correct LF line endings"
    ((CHECKS_PASSED++)) || true
fi

# Note: Additional validation scripts available for manual runs
echo "ℹ️  Note: Additional validation available:"
echo "   • Link checking: bash scripts/link-checker.sh"
echo "   • Bidirectional validation: bash scripts/bidirectional-validation.sh (requires non-sandboxed environment)"
echo ""

# Summary
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                      HEALTH CHECK SUMMARY                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Checks Passed:  $CHECKS_PASSED ✅"
echo "Checks Failed:  $CHECKS_FAILED ❌"
echo "Errors:         $ERRORS"
echo "Warnings:       $WARNINGS"
echo ""

if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
  echo "🎉 EXCELLENT: All documentation health checks passed!"
  echo ""
  echo "Your documentation is in excellent condition:"
  echo "  ✅ Version numbers are consistent"
  echo "  ✅ All diagrams have source files"
  echo "  ✅ No critical issues detected"
  exit 0
elif [[ $ERRORS -eq 0 ]]; then
  echo "⚠️  GOOD: Core checks passed with minor warnings"
  echo ""
  echo "No critical issues, but review warnings above."
  exit 0
else
  echo "❌ FAILED: Critical documentation issues detected"
  echo ""
  echo "Fix the errors reported above before committing."
  echo ""
  echo "Common fixes:"
  echo "  - Version mismatch: Update all version references to match plugin.json"
  echo "  - Missing diagrams: Regenerate SVGs from .mmd files using mermaid-cli"
  echo "  - Broken links: Update or remove invalid documentation references"
  exit 1
fi
