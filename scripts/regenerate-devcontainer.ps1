# Regenerate devcontainer using the latest plugin version
# This script uses the plugin to regenerate the .devcontainer/ configuration
# ensuring it stays in sync with plugin template changes.

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir

Set-Location $RepoRoot

Write-Host "🔄 Regenerating devcontainer using windows-sandbox plugin..." -ForegroundColor Cyan
Write-Host ""

# Check if .devcontainer exists
if (-not (Test-Path ".devcontainer")) {
    Write-Host "❌ Error: .devcontainer directory not found" -ForegroundColor Red
    Write-Host "   Run this script from the repository root" -ForegroundColor Red
    exit 1
}

# Create backup
$BackupDir = ".devcontainer.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Write-Host "📦 Creating backup: $BackupDir" -ForegroundColor Green
Copy-Item -Recurse .devcontainer $BackupDir

# Remove current devcontainer
Write-Host "🗑️  Removing current .devcontainer/" -ForegroundColor Yellow
Remove-Item -Recurse -Force .devcontainer

# Note: The actual regeneration would happen via Claude Code CLI
# For now, we provide instructions
Write-Host ""
Write-Host "📝 Next steps:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Start Claude Code:"
Write-Host "   claude"
Write-Host ""
Write-Host "2. Run the setup command:"
Write-Host "   /sandbox:basic"
Write-Host ""
Write-Host "3. After generation, review changes:"
Write-Host "   # Compare directories manually or use a diff tool"
Write-Host ""
Write-Host "4. If satisfied, remove backup:"
Write-Host "   Remove-Item -Recurse $BackupDir"
Write-Host ""
Write-Host "5. If not satisfied, restore:"
Write-Host "   Remove-Item -Recurse .devcontainer"
Write-Host "   Rename-Item $BackupDir .devcontainer"
Write-Host ""
Write-Host "6. Commit changes:"
Write-Host "   git add .devcontainer"
Write-Host "   git commit -m 'chore: regenerate devcontainer with latest plugin'"
Write-Host ""
Write-Host "⚠️  Manual intervention required - follow steps above" -ForegroundColor Yellow
Write-Host "   Backup created at: $BackupDir" -ForegroundColor Green
