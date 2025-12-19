# Data Files

This directory contains reference data used by the Claude Code Sandbox Plugin skills to generate consistent, up-to-date configurations.

## Files

### `sandbox-templates.json`
Docker sandbox-templates image registry with available tags, architectures, and recommended modes.

**Structure:**
- `metadata`: Registry information and update date
- `tags`: Array of available sandbox template tags with:
  - Image details (OS, architectures, sizes)
  - Descriptions
  - Recommended modes
  - Pull commands

**Usage in skills:**
```markdown
Reference: `${CLAUDE_PLUGIN_ROOT}/data/sandbox-templates.json`
```

**Update procedure:**
1. Visit https://hub.docker.com/r/docker/sandbox-templates/tags
2. Update tag list with new/changed tags
3. Update `metadata.last_updated` date
4. Verify pull commands are correct

### `official-images.json`
Official Docker images registry for common languages, databases, and tools.

**Structure:**
- `metadata`: Hub search URL and update date
- `images`: Object with image details:
  - Repository information
  - Recommended tags
  - Default tag selection
  - Pull commands
  - Usage notes

**Usage in skills:**
```markdown
Reference: `${CLAUDE_PLUGIN_ROOT}/data/official-images.json`
```

**Update procedure:**
1. Check https://hub.docker.com for latest official image tags
2. Update recommended_tags with current versions
3. Update default_tag if recommendations change
4. Update `metadata.last_updated` date
5. Test pull commands are valid

### `allowable-domains.json`
Firewall domain allowlist organized by category for different mode defaults.

**Structure:**
- `metadata`: Usage information and update date
- `categories`: Domain categories with:
  - Description
  - Minimum mode requirement
  - Domain lists
  - Wildcard patterns (where applicable)
  - Sub-categories for complex categories
- `mode_defaults`: Which categories are included per mode

**Usage in skills:**
```markdown
Reference: `${CLAUDE_PLUGIN_ROOT}/data/allowable-domains.json`

# Extract domains for specific mode
Use `mode_defaults.<mode_name>` to get included categories
```

**Update procedure:**
1. Review domain lists for additions/removals
2. Test domain accessibility from sandbox
3. Update category lists as needed
4. Update `metadata.last_updated` date
5. Document any new categories in mode_defaults

### `mcp-servers.json`
MCP (Model Context Protocol) servers catalog for configuring Claude Code integrations in DevContainers.

**Structure:**
- `metadata`: Documentation references and update date
- `servers`: Object with MCP server configurations:
  - Server details (command, args, env)
  - Mode minimum requirement
  - Category (core, database, web, etc.)
  - Optional inputs for secrets/configuration
- `mode_defaults`: Which servers are included per mode

**Usage in skills:**
```markdown
Reference: `${CLAUDE_PLUGIN_ROOT}/data/mcp-servers.json`

# Get default servers for a mode
Use `mode_defaults.<mode_name>.servers` array
```

**Update procedure:**
1. Check MCP documentation for new/updated servers
2. Add new server entries with appropriate mode_minimum
3. Update mode_defaults if server should be included by default
4. Test server configurations in DevContainer
5. Update `metadata.last_updated` date

**Mode-Specific Server Usage:**

| Mode | Server Strategy | Servers Included |
|------|----------------|------------------|
| **Basic** | Essential only | filesystem, memory |
| **Intermediate** | Common development | filesystem, memory, sqlite, fetch, github |
| **Advanced** | Comprehensive | All Intermediate + postgres, docker, brave-search |
| **YOLO** | All available | All servers |

### `secrets.json`
Secret handling patterns catalog for DevContainer configurations.

**Structure:**
- `metadata`: Version and description
- `categories`: Secret types organized by use case:
  - git_auth (SSH keys, tokens)
  - database_creds (connection strings, passwords)
  - api_keys (third-party service keys)
  - certificates (SSL/TLS certs)
  - cloud_provider (AWS, Azure, GCP credentials)
- Each secret includes:
  - Description and mount type
  - Mode minimum requirement
  - Security level (critical/high/medium)
  - VS Code input configuration
  - Example usage patterns

**Usage in skills:**
```markdown
Reference: `${CLAUDE_PLUGIN_ROOT}/data/secrets.json`

# Get secret handling pattern
Use categories.<category>.secrets.<secret_name>
```

**Update procedure:**
1. Add new secret patterns as needed
2. Ensure VS Code input examples are correct
3. Document security level appropriately
4. Update version number
5. Test configurations in DevContainer

**Important:** This file contains _patterns_ for handling secrets, not actual secret values.

### `variables.json`
Configuration variables catalog for DevContainer setup (non-sensitive).

**Structure:**
- `metadata`: Version and description
- `categories`: Variable types:
  - build (Dockerfile ARG for image construction)
  - runtime (ENV for container runtime)
  - development (dev tools configuration)
  - language_specific (Python, Node, Go, etc.)
- Each variable includes:
  - Description and type (ARG/ENV)
  - Default value
  - Mode minimum requirement
  - Security level
  - Example values

**Usage in skills:**
```markdown
Reference: `${CLAUDE_PLUGIN_ROOT}/data/variables.json`

# Get variable configuration
Use categories.<category>.variables.<var_name>
```

**Update procedure:**
1. Add new variable patterns for new tools/languages
2. Update default values when recommendations change
3. Document security level (public for variables, never sensitive)
4. Update version number
5. For sensitive data, use secrets.json instead

### `vscode-extensions.json`
VS Code extensions catalog organized by language and category.

**Structure:**
- `metadata`: Update date and usage notes
- `categories`: Extension groups:
  - essential (core extensions for all modes)
  - git (version control)
  - javascript, python, go, rust, etc. (language-specific)
  - database (database tools)
  - containers (Docker/Kubernetes)
  - productivity (general dev tools)
- Each extension includes:
  - Extension ID and name
  - Mode minimum requirement (optional)
  - Platform applicability (optional)
  - Required flag (for essential extensions)

**Usage in skills:**
```markdown
Reference: `${CLAUDE_PLUGIN_ROOT}/data/vscode-extensions.json`

# Get extensions for language
Use categories.<language>.extensions array
```

**Update procedure:**
1. Check for new popular extensions quarterly
2. Update extension IDs if publishers change
3. Add language-specific extensions as needed
4. Update mode_minimum based on complexity
5. Test extensions in DevContainer
6. Update metadata.last_updated date

## Mode-Specific Domain Usage

| Mode | Domain Strategy | Reference |
|------|----------------|-----------|
| **Basic** | No firewall - relies on sandbox isolation | N/A |
| **Intermediate** | Permissive - all traffic allowed | N/A |
| **Advanced** | Strict allowlist from `mode_defaults.advanced` | `allowable-domains.json` |
| **YOLO** | User-configurable | `allowable-domains.json` (optional) |

## File Format

All data files use JSON format with JSON Schema metadata for validation.

**Common metadata fields:**
- `last_updated`: ISO date (YYYY-MM-DD) of last update
- `description`: Purpose of the data file
- `$schema`: JSON Schema version

## Skills Integration

Skills reference these files using the `${CLAUDE_PLUGIN_ROOT}` variable which resolves to the plugin's root directory.

**Example skill reference:**
```markdown
## Available Base Images

Reference: `${CLAUDE_PLUGIN_ROOT}/data/sandbox-templates.json`

**Sandbox Templates** (recommended for Basic mode):
- `docker/sandbox-templates:latest` - Default choice
- `docker/sandbox-templates:claude-code` - Optimized for Claude Code
```

## Maintenance Schedule

- **Monthly**: Review and update all image tags
- **Quarterly**: Review domain lists for new services
- **As needed**: Add new categories or images based on user requests

## Version Control

These data files are tracked in git. When updating:
1. Update the file(s)
2. Update the `last_updated` date
3. Commit with descriptive message: `data: update <file> - <reason>`
4. Test affected skills to ensure compatibility

## Questions?

For questions about data file structure or usage, see:
- Plugin documentation: `../docs/ARCHITECTURE.md`
- Mode guide: `../docs/MODES.md`

---

**Last Updated:** 2025-12-16
**Version:** 3.0.0
