# MCP (Model Context Protocol) Configuration Guide

MCP enables AI assistants to interact with external services through a standardized protocol.

## Quick Reference

| Mode | MCP Servers | Use Case |
|------|-------------|----------|
| Basic | filesystem, memory | Simple file access |
| Intermediate | + sqlite, fetch, github | Standard development |
| Advanced | + postgres, docker, brave-search | Full-stack projects |
| YOLO | + puppeteer, slack, google-drive | Maximum capabilities |

## Configuration

MCP servers are configured in `.devcontainer/mcp.json`:

```json
{
  "servers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/workspace"]
    }
  }
}
```

## Available Servers

### Core (Basic+)
- **filesystem** - Local file access
- **memory** - Conversation memory

### Development (Intermediate+)
- **sqlite** - SQLite database access
- **fetch** - Web content fetching
- **github** - GitHub API integration (requires token)
- **docker** - Docker Hub search and management

### Advanced (Advanced+)
- **postgres** - PostgreSQL queries (requires connection string)
- **brave-search** - Web search (requires API key)
- **puppeteer** - Browser automation

### Extended (YOLO)
- **slack** - Slack workspace integration
- **google-drive** - Google Drive access

## Credentials

Sensitive credentials use VS Code input variables:

```json
{
  "inputs": {
    "githubToken": {
      "type": "promptString",
      "description": "GitHub personal access token",
      "password": true
    }
  }
}
```

## References

- [Docker Hub MCP](https://docs.docker.com/ai/mcp-catalog-and-toolkit/hub-mcp/)
- [VS Code MCP Servers](https://code.visualstudio.com/docs/copilot/customization/mcp-servers)
