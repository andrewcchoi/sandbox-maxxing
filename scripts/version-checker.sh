#!/usr/bin/env bash
# version-checker.sh - Validates version consistency across plugin files
# Part of documentation health check automation

set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PLUGIN_ROOT"

echo "=== Version Consistency Check ==="
echo ""

# Extract versions from different sources
PLUGIN_VERSION=$(jq -r '.version' .claude-plugin/plugin.json 2>/dev/null || echo "ERROR")
MARKET_VERSION=$(jq -r '.version' .claude-plugin/marketplace.json 2>/dev/null || echo "ERROR")
README_VERSION=$(grep -oP 'version-\K[0-9]+\.[0-9]+\.[0-9]+' README.md 2>/dev/null | head -1 || echo "ERROR")
CHANGELOG_VERSION=$(grep -oP '^\## \[\K[0-9]+\.[0-9]+\.[0-9]+' CHANGELOG.md 2>/dev/null | head -1 || echo "ERROR")
PKG_VERSION=$(jq -r '.version' package.json 2>/dev/null || echo "N/A")

# Display versions
echo "plugin.json:       $PLUGIN_VERSION"
echo "marketplace.json:  $MARKET_VERSION"
echo "README.md badge:   $README_VERSION"
echo "CHANGELOG.md:      $CHANGELOG_VERSION"
echo "package.json:      $PKG_VERSION"
echo ""

# Check for inconsistencies
ERRORS=0

if [[ "$PLUGIN_VERSION" != "$MARKET_VERSION" ]]; then
  echo "❌ ERROR: plugin.json ($PLUGIN_VERSION) != marketplace.json ($MARKET_VERSION)"
  ((ERRORS++))
fi

if [[ "$PLUGIN_VERSION" != "$README_VERSION" ]]; then
  echo "❌ ERROR: plugin.json ($PLUGIN_VERSION) != README.md badge ($README_VERSION)"
  ((ERRORS++))
fi

if [[ "$PLUGIN_VERSION" != "$CHANGELOG_VERSION" ]]; then
  echo "⚠️  WARNING: plugin.json ($PLUGIN_VERSION) != CHANGELOG.md ($CHANGELOG_VERSION)"
  echo "   (This may be expected if CHANGELOG has unreleased version)"
fi

# Check package.json
if [[ "$PKG_VERSION" != "N/A" && "$PLUGIN_VERSION" != "$PKG_VERSION" ]]; then
  echo "❌ ERROR: plugin.json ($PLUGIN_VERSION) != package.json ($PKG_VERSION)"
  ((ERRORS++))
fi

if [[ $ERRORS -eq 0 ]]; then
  echo "✅ All critical version references are consistent"
  exit 0
else
  echo ""
  echo "Fix version inconsistencies before committing."
  echo "Run: scripts/set-version.sh <version> (if that script exists)"
  exit 1
fi
