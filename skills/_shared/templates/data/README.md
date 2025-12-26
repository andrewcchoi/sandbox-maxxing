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
Reference: `skills/_shared/data/sandbox-templates.json`
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
Reference: `skills/_shared/data/official-images.json`
```

**Update procedure:**
1. Check https://hub.docker.com for latest official image tags
2. Update recommended_tags with current versions
3. Update default_tag if recommendations change
4. Update `metadata.last_updated` date
5. Test pull commands are valid

### `uv-images.json`
Astral UV Docker images registry - Python package manager with fast dependency resolution.

**Structure:**
- `metadata`: Registry information, API endpoint, and update date
- `categories`: Image categories (alpine, debian-slim, bookworm, trixie) with:
  - Description
  - Recommended modes
- `tags`: Array of filtered image tags with:
  - Tag name, category, Python version
  - Base image type
  - Size (MB) per architecture
  - Last updated timestamp
  - Digest and architectures
  - Recommended tier
  - Pull command
- `mode_defaults`: Which tags are included per mode

**Usage in skills:**
```markdown
Reference: `skills/_shared/data/uv-images.json`

# Get recommended tags for a mode
Use `mode_defaults.<mode_name>` array
```

**Update procedure:**
1. Run `.internal/scripts/update-uv-images.sh` (Python script)
2. Script automatically:
   - Fetches all tags from Docker Hub API
   - Filters to floating tags (excludes version-pinned like 0.9.18-)
   - Deduplicates by Python version + base image
   - Updates `metadata.last_updated` date
3. Verify JSON output is valid
4. Commit changes

**Mode-Specific Tag Selection:**

| Mode             | Tag Strategy                    | Tags Included                                        |
| ---------------- | ------------------------------- | ---------------------------------------------------- |
| **Basic**        | Alpine only, Python 3.12+       | python3.12-alpine, python3.13-alpine                 |
| **Advanced**     | All stable Python versions      | Python 3.10-3.13 across all base images              |
| **YOLO**         | All tags including experimental | All filtered tags including Python 3.8, 3.14, trixie |

**About UV:**
- Fast Python package manager written in Rust
- Drop-in replacement for pip with 10-100x faster dependency resolution
- Images include uv pre-installed with various Python versions
- Alpine variants are smallest (~40MB), Debian variants offer better compatibility

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
Reference: `skills/_shared/data/secrets.json`

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
Reference: `skills/_shared/data/variables.json`

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

**Last Updated:** 2025-12-24
**Version:** 4.6.0
