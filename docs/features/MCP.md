# MCP (Model Context Protocol) Configuration Guide

MCP enables AI assistants to interact with external services through a standardized protocol.

## Quick Reference

| Mode | MCP Servers | Use Case |
|------|-------------|----------|
| Minimal | filesystem, memory | Simple file access |
| Domain Allowlist | + postgres, docker, brave-search | Full-stack projects |
| Custom | + puppeteer, slack, google-drive | Maximum capabilities |

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

### Core (All Configurations)
- **filesystem** - Local file access
- **memory** - Conversation memory

### Development (Domain Allowlist, Custom)
- **sqlite** - SQLite database access
- **fetch** - Web content fetching
- **github** - GitHub API integration (requires token)
- **docker** - Docker Hub search and management

### Advanced (Domain Allowlist, Custom)
- **postgres** - PostgreSQL queries (requires connection string)
- **brave-search** - Web search (requires API key)
- **puppeteer** - Browser automation

### Extended (Custom Only)
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

## Practical Examples

### Example 1: Adding GitHub MCP Server

Add GitHub integration for repository access:

**1. Update `.devcontainer/mcp.json`:**
```json
{
  "servers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/workspace"]
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "${localEnv:GITHUB_TOKEN}"
      }
    }
  }
}
```

**2. Add token to `.env`:**
```bash
GITHUB_TOKEN=ghp_your_personal_access_token_here
```

**3. Restart DevContainer to apply changes**

### Example 2: PostgreSQL MCP Server

Enable database queries through Claude:

**1. Update `.devcontainer/mcp.json`:**
```json
{
  "servers": {
    "postgres": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres"],
      "env": {
        "POSTGRES_CONNECTION_STRING": "postgresql://user:password@postgres:5432/dbname"
      }
    }
  }
}
```

**2. For sensitive credentials, use VS Code inputs in `devcontainer.json`:**
```json
{
  "inputs": {
    "postgresPassword": {
      "type": "promptString",
      "description": "PostgreSQL password",
      "password": true
    }
  },
  "remoteEnv": {
    "POSTGRES_CONNECTION_STRING": "postgresql://user:${input:postgresPassword}@postgres:5432/dbname"
  }
}
```

### Example 3: Multiple MCP Servers for Full-Stack Project

Complete configuration for a full-stack app:

```json
{
  "servers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/workspace"]
    },
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"]
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "${localEnv:GITHUB_TOKEN}"
      }
    },
    "postgres": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres"],
      "env": {
        "POSTGRES_CONNECTION_STRING": "postgresql://user:password@postgres:5432/dbname"
      }
    },
    "docker": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-docker"]
    }
  }
}
```

### Example 4: Custom MCP Server

Create your own MCP server for specialized functionality:

**1. Create `custom-mcp-server.js`:**
```javascript
#!/usr/bin/env node
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';

const server = new Server({
  name: 'custom-api-server',
  version: '1.0.0',
}, {
  capabilities: {
    tools: {}
  }
});

server.setRequestHandler('tools/list', async () => ({
  tools: [{
    name: 'fetch_data',
    description: 'Fetch data from custom API',
    inputSchema: {
      type: 'object',
      properties: {
        endpoint: { type: 'string' }
      }
    }
  }]
}));

const transport = new StdioServerTransport();
await server.connect(transport);
```

**2. Add to `.devcontainer/mcp.json`:**
```json
{
  "servers": {
    "custom-api": {
      "command": "node",
      "args": ["/workspace/.devcontainer/custom-mcp-server.js"]
    }
  }
}
```

## Troubleshooting

### MCP Server Not Loading

**Symptoms:** Claude doesn't recognize MCP tools

**Solutions:**
1. Check `mcp.json` syntax with `jq . .devcontainer/mcp.json`
2. Verify firewall allows npm package downloads
3. Restart VS Code DevContainer
4. Check VS Code output panel for MCP errors

### Authentication Failures

**Symptoms:** "Authentication failed" or "Invalid token" errors

**Solutions:**
1. Verify token format (GitHub: `ghp_`, not `ghs_`)
2. Check token permissions (repo, read:org for GitHub)
3. Use `${localEnv:VAR}` for .env variables
4. Use `${input:var}` for VS Code prompt inputs

### Performance Issues

**Symptoms:** Slow responses when using MCP tools

**Solutions:**
1. Limit concurrent MCP servers (use only what you need)
2. Use caching for frequently accessed data
3. Consider connection pooling for database servers

## References

- [Docker Hub MCP](https://docs.docker.com/ai/mcp-catalog-and-toolkit/hub-mcp/)
- [VS Code MCP Servers](https://code.visualstudio.com/docs/copilot/customization/mcp-servers)
- [MCP SDK Documentation](https://github.com/modelcontextprotocol/sdk)
- [Available MCP Servers](https://github.com/modelcontextprotocol/servers)

