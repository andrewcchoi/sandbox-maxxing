# Data Files

This directory contains reference data used by the Claude Code Sandbox Plugin skills to generate consistent, up-to-date configurations.

## Files

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
Reference: `skills/_shared/data/official-images.json`
```

**Update procedure:**
1. Check https://hub.docker.com for latest official image tags
2. Update recommended_tags with current versions
3. Update default_tag if recommendations change
4. Update `metadata.last_updated` date
5. Test pull commands are valid

### `azure-regions.json`
Azure regions catalog for cloud deployment location selection.

**Structure:**
- `metadata`: Last updated date, usage notes, documentation URL
- `regions`:
  - `recommended`: Array of 6 primary regions with code, name, description
  - `all`: Complete list of 40+ Azure regions worldwide

**Usage in skills:**
```markdown
Reference: `skills/_shared/data/azure-regions.json`

# Get recommended regions
Use `regions.recommended` array for common deployments
```

**Update procedure:**
1. Check Azure documentation for new regions
2. Add new regions to `all` array
3. Update `recommended` if primary regions change
4. Update `metadata.last_updated` date

### `ollama-models.json`
Ollama local LLM models catalog for sandbox AI integration.

**Structure:**
- `models`: Array of model configurations with:
  - Model name and size (GB)
  - Specialty and use case
  - Download count (popularity)
- `max_size_gb`: Maximum model size limit
- `default_limit`: Default number of models to suggest

**Usage in skills:**
```markdown
Reference: `skills/_shared/data/ollama-models.json`

# Get popular models under size limit
Filter models by `size_gb <= max_size_gb`
```

**Update procedure:**
1. Check Ollama library for new popular models
2. Update model list with current sizes
3. Verify specialty descriptions are accurate
4. Update download counts quarterly

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
Reference: `skills/_shared/data/allowable-domains.json`

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
Reference: `skills/_shared/data/mcp-servers.json`

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

| Mode             | Server Strategy    | Servers Included                                  |
| ---------------- | ------------------ | ------------------------------------------------- |
| **Basic**        | Essential only     | filesystem, memory                                |
| **Advanced**     | Comprehensive      | All Advanced + postgres, docker, brave-search |
| **YOLO**         | All available      | All servers                                       |

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
Reference: `skills/_shared/data/vscode-extensions.json`

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

| Mode             | Domain Strategy                                | Reference                           |
| ---------------- | ---------------------------------------------- | ----------------------------------- |
| **Basic**        | No firewall - relies on sandbox isolation      | N/A                                 |
| **Advanced**     | Strict allowlist from `mode_defaults.advanced` | `allowable-domains.json`            |
| **YOLO**         | User-configurable                              | `allowable-domains.json` (optional) |

## File Format

All data files use JSON format with JSON Schema metadata for validation.

**Common metadata fields:**
- `last_updated`: ISO date (YYYY-MM-DD) of last update
- `description`: Purpose of the data file
- `$schema`: JSON Schema version

## Skills Integration

Skills reference these files using relative paths from the plugin root directory.

**Example skill reference:**
```markdown
## Available Base Images

Reference: `skills/_shared/data/sandbox-templates.json`

**Sandbox Templates** (recommended for minimal configuration):
- `docker/sandbox-templates:latest` - Default choice
- `docker/sandbox-templates:claude-code` - Optimized for Claude Code
```

## Maintenance

When updating these files:

1. Ensure JSON schema validation passes
2. Update version numbers in file metadata
3. Test with both `/sandboxxer:quickstart` and `/sandboxxer:yolo-vibe-maxxing  commands
4. Update INVENTORY.json if files are added/removed

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
- Mode guide: `../docs/SETUP-OPTIONS.md`

---

**Last Updated:** 2026-01-01
**Version:** 4.6.0
