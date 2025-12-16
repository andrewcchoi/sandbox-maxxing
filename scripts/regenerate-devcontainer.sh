#!/bin/bash
# Regenerate devcontainer using the latest plugin version
# This script uses the plugin to regenerate the .devcontainer/ configuration
# ensuring it stays in sync with plugin template changes.

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT"

echo "🔄 Regenerating devcontainer using windows-sandbox plugin..."
echo ""

# Check if .devcontainer exists
if [ ! -d ".devcontainer" ]; then
    echo "❌ Error: .devcontainer directory not found"
    echo "   Run this script from the repository root"
    exit 1
fi

# Create backup
BACKUP_DIR=".devcontainer.backup.$(date +%Y%m%d-%H%M%S)"
echo "📦 Creating backup: $BACKUP_DIR"
cp -r .devcontainer "$BACKUP_DIR"

# Remove current devcontainer
echo "🗑️  Removing current .devcontainer/"
rm -rf .devcontainer

# Note: The actual regeneration would happen via Claude Code CLI
# For now, we provide instructions
echo ""
echo "📝 Next steps:"
echo ""
echo "1. Start Claude Code:"
echo "   claude"
echo ""
echo "2. Run the setup command:"
echo "   /windows-sandbox:setup --basic"
echo ""
echo "3. After generation, review changes:"
echo "   diff -r $BACKUP_DIR .devcontainer"
echo ""
echo "4. If satisfied, remove backup:"
echo "   rm -rf $BACKUP_DIR"
echo ""
echo "5. If not satisfied, restore:"
echo "   rm -rf .devcontainer && mv $BACKUP_DIR .devcontainer"
echo ""
echo "6. Commit changes:"
echo "   git add .devcontainer"
echo "   git commit -m 'chore: regenerate devcontainer with latest plugin'"
echo ""
echo "⚠️  Manual intervention required - follow steps above"
echo "   Backup created at: $BACKUP_DIR"
