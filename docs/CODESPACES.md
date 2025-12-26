# GitHub Codespaces Guide

This guide explains how to use the DevContainer configuration with GitHub Codespaces.

## Quick Start

1. **Open in Codespaces**:
   - Go to your repository on GitHub
   - Click the green "Code" button
   - Select "Codespaces" tab
   - Click "Create codespace on main"

2. **Configure Secrets** (before creating codespace):
   - Go to repository Settings > Secrets and variables > Codespaces
   - Add your API keys:
     - `ANTHROPIC_API_KEY` - Required for Claude Code
     - `OPENAI_API_KEY` - Optional
     - `GITHUB_TOKEN` - For private repo access

## Machine Types

The devcontainer.json specifies minimum requirements:

```json
"hostRequirements": {
  "cpus": 4,
  "memory": "8gb",
  "storage": "32gb"
}
```

**Recommended machine types**:
| Type | CPUs | RAM | Best For |
|------|------|-----|----------|
| 4-core | 4 | 16GB | General development |
| 8-core | 8 | 32GB | Large projects, ML |
| 16-core | 16 | 64GB | Heavy compilation |

## Port Forwarding

The following ports are automatically forwarded:

| Port | Service | Visibility |
|------|---------|------------|
| 8000 | App | Notify on forward |
| 3000 | Frontend | Notify on forward |
| 5432 | PostgreSQL | Silent |
| 6379 | Redis | Silent |

### Making Ports Public

By default, forwarded ports are private. To make public:

1. Click the "Ports" tab in VS Code
2. Right-click the port
3. Select "Port Visibility" > "Public"

Or add to devcontainer.json:
```json
"portsAttributes": {
  "8000": { "visibility": "public" }
}
```

## Secrets Management

### Repository Secrets (Recommended)

1. Go to repository Settings > Secrets and variables > Codespaces
2. Click "New repository secret"
3. Add name (e.g., `ANTHROPIC_API_KEY`) and value
4. Secrets are automatically available as environment variables

### User Secrets

For personal secrets across all codespaces:

1. Go to github.com/settings/codespaces
2. Click "New secret"
3. Select repositories that can access the secret

## Prebuilds

To speed up codespace creation, enable prebuilds:

1. Go to repository Settings > Codespaces
2. Click "Set up prebuild"
3. Configure:
   - Branch: `main`
   - Trigger: Push to branch
   - Region: Select closest to your users

Prebuilds create container images in advance, reducing startup time from minutes to seconds.

### Prebuild Configuration

Add to `.devcontainer/devcontainer.json`:

```json
"codespaces": {
  "prebuildEvents": {
    "onPush": true,
    "onPullRequest": false
  }
}
```

## Customization

### dotfiles Repository

Personalize your codespace with your dotfiles:

1. Go to github.com/settings/codespaces
2. Under "Dotfiles", select your dotfiles repository
3. New codespaces will run your dotfiles install script

### Default Editor Settings

Sync your VS Code settings:

1. Enable Settings Sync in VS Code
2. Your settings will apply to all codespaces

## Troubleshooting

### Slow Startup

- Enable prebuilds (see above)
- Use a larger machine type
- Check for heavy postCreateCommand scripts

### Out of Storage

```bash
# Check disk usage
df -h

# Clear Docker cache
docker system prune -af

# Remove unused images
docker image prune -af
```

### Container Fails to Start

1. Check the "Creation Log" in the Codespaces page
2. Look for errors in `.devcontainer/Dockerfile`
3. Try rebuilding: Command Palette > "Codespaces: Rebuild Container"

### Secrets Not Available

- Verify secret is added to repository or user settings
- Check secret name matches environment variable reference
- Restart the codespace after adding new secrets

## Cost Optimization

- Stop codespaces when not in use (they auto-stop after 30min idle)
- Delete unused codespaces
- Use prebuilds to reduce compute time
- Choose appropriate machine type for your workload

## VS Code vs Browser

You can use Codespaces in:

- **Browser**: Click "Open in Browser" (default)
- **VS Code Desktop**: Click "Open in VS Code Desktop"
- **JetBrains**: Install JetBrains Gateway

For the best experience with Claude Code, VS Code Desktop is recommended.

## Resources

- [GitHub Codespaces Documentation](https://docs.github.com/en/codespaces)
- [Managing Codespaces Secrets](https://docs.github.com/en/codespaces/managing-your-codespaces/managing-encrypted-secrets-for-your-codespaces)
- [Prebuilds](https://docs.github.com/en/codespaces/prebuilding-your-codespaces)
- [Machine Types](https://docs.github.com/en/codespaces/customizing-your-codespace/changing-the-machine-type-for-your-codespace)

---

**Last Updated:** 2025-12-25
**Version:** 4.6.0
