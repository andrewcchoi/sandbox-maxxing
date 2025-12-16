# Data Files

This directory contains reference data used by the Docker Sandbox Plugin skills to generate consistent, up-to-date configurations.

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
- Plugin documentation: `/workspace/docs/ARCHITECTURE.md`
- Mode guide: `/workspace/docs/MODES.md`
