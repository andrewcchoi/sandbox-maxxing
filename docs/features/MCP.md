# MCP (Model Context Protocol) Configuration Guide

MCP lets Claude Code call tools from external servers (databases, web search, GitHub, a browser).

Sandboxxer does **not** install any MCP servers. Every server runs code fetched from npm or PyPI
and gets access to your container, so you add only the ones you want.

## Where Claude Code reads MCP config

| Scope | File | Shared with | Inside the container |
|---|---|---|---|
| **Project** (recommended) | `.mcp.json` at the project root | Everyone who clones the repo | Yes, through the workspace bind mount |
| User | `~/.claude.json` (`mcpServers`) | Only you | No. It isn't synced from the host, so add servers again inside the container with `claude mcp add --scope user` |

Claude Code does **not** read `.devcontainer/mcp.json` or `.vscode/mcp.json`. The `.vscode/mcp.json`
file uses a different format (top-level `servers` key) and is only read by VS Code's own MCP
support.

Claude Code asks you to approve project servers from `.mcp.json` the first time it sees them.
Run `/mcp` in a session to see which servers connected.

## Quick start

Either run `claude mcp add` from the project root inside the container:

```bash
claude mcp add --scope project memory -- npx -y @modelcontextprotocol/server-memory
claude mcp add --scope project filesystem -- npx -y @modelcontextprotocol/server-filesystem .
```

Or create `.mcp.json` at the project root yourself. This is the plugin's starter template
(`skills/_shared/templates/mcp.json`):

```json
{
  "mcpServers": {
    "filesystem": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "."]
    },
    "memory": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"]
    }
  }
}
```

Restart Claude Code (not the container) after editing `.mcp.json`.

## Server catalog

`skills/_shared/templates/data/mcp-servers.json` lists servers that are known to be maintained.
Each entry is a ready-to-paste `mcpServers` entry. Drop the catalog-only fields
(`description`, `mode_minimum`, `category`, `requires`) when you copy it.

| Server | Runs | Needs |
|---|---|---|
| `filesystem` | `npx @modelcontextprotocol/server-filesystem .` | Nothing |
| `memory` | `npx @modelcontextprotocol/server-memory` | Nothing |
| `fetch` | `uvx mcp-server-fetch` | Nothing (`uvx` is in the image) |
| `github` | GitHub's hosted server, `https://api.githubcopilot.com/mcp/` | `GITHUB_TOKEN` |
| `brave-search` | `npx @brave/brave-search-mcp-server` | `BRAVE_API_KEY` |
| `playwright` | `npx @playwright/mcp --headless` | A browser in the image (see below) |

The older `@modelcontextprotocol/server-{sqlite,fetch,postgres,github,puppeteer,brave-search,slack,gdrive}`
npm packages were removed from the catalog in v4.13.12 (#386): they are archived, deprecated, or were
never published to npm.

## Credentials

`.mcp.json` is meant to be committed, so never put secrets in it. Reference environment variables
instead. Claude Code expands `${VAR}` and `${VAR:-default}` in `command`, `args`, `env`, `url` and
`headers`:

```json
{
  "mcpServers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/",
      "headers": { "Authorization": "Bearer ${GITHUB_TOKEN}" }
    },
    "brave-search": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@brave/brave-search-mcp-server"],
      "env": { "BRAVE_API_KEY": "${BRAVE_API_KEY}" }
    }
  }
}
```

Forward the variables from the host through `remoteEnv` in `.devcontainer/devcontainer.json`
(the template already forwards `GITHUB_TOKEN`), then rebuild:

```jsonc
"remoteEnv": {
  "GITHUB_TOKEN": "${localEnv:GITHUB_TOKEN}",
  "BRAVE_API_KEY": "${localEnv:BRAVE_API_KEY}"
}
```

`${localEnv:...}` works there because VS Code expands it. VS Code's `${input:...}` and
`${localEnv:...}` syntax does **not** work in `.mcp.json`.

## Practical examples

### Database access

Point a database MCP server at the compose service name (for example `postgres:5432`), with the
connection string in an environment variable:

```json
{
  "mcpServers": {
    "postgres": {
      "type": "stdio",
      "command": "<server command>",
      "args": ["${DATABASE_URL}"]
    }
  }
}
```

Choose a maintained server from the
[MCP server registry](https://github.com/modelcontextprotocol/servers). The reference
`@modelcontextprotocol/server-postgres` package is archived.

### Browser automation

`@playwright/mcp` needs a browser. Add this to `.devcontainer/Dockerfile` (as the container user,
after Node.js is installed) and rebuild:

```dockerfile
RUN npx -y playwright install --with-deps chromium
```

### A custom server

```json
{
  "mcpServers": {
    "custom-api": {
      "type": "stdio",
      "command": "node",
      "args": ["tools/custom-mcp-server.js"]
    }
  }
}
```

See the [MCP TypeScript SDK](https://github.com/modelcontextprotocol/typescript-sdk) for
writing the server.

## Troubleshooting

### Server not loading

1. Check that the file is at the project root and named `.mcp.json`, with a top-level `mcpServers` key:
   `jq '.mcpServers | keys' .mcp.json`
2. Run `/mcp` in Claude Code. A server you declined at the approval prompt stays disabled until
   you reset it with `claude mcp reset-project-choices`.
3. Run the server's command by hand in the container terminal to see its errors.
4. **Strict firewall:** `npx` needs `registry.npmjs.org` and `uvx` needs `pypi.org` and
   `files.pythonhosted.org`. Both are allowlisted by default. Remote servers need their own host
   allowlisted under `project_specific` (for example `api.githubcopilot.com`, `api.search.brave.com`).
5. **Corporate proxy:** `npx` and `uvx` download packages when the server starts. If that fails
   behind a proxy, install the package in the Dockerfile and point `command` at the installed binary.

### Authentication failures

1. Check that the variable is set in the shell that runs Claude Code: `printenv GITHUB_TOKEN`
2. Restart Claude Code after changing environment variables. Values are expanded at startup.

## References

- [Claude Code MCP documentation](https://docs.claude.com/en/docs/claude-code/mcp)
- [MCP servers repository](https://github.com/modelcontextprotocol/servers)
- [GitHub MCP server](https://github.com/github/github-mcp-server)
