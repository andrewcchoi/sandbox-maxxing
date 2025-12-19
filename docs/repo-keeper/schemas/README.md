# JSON Schema Documentation

**Last Updated:** 2025-12-18
**Version:** 3.0.0

This directory contains JSON Schema definitions for validating repository configuration files.

## Overview

JSON Schemas provide:
- **Structure validation** - Ensure required fields exist
- **Type checking** - Verify data types (string, number, object, array)
- **Format validation** - Check patterns (semver, dates, enums)
- **Documentation** - Self-documenting schema with descriptions
- **IDE support** - Auto-completion and validation in editors

## Available Schemas

| Schema File | Validates | Purpose |
|-------------|-----------|---------|
| `inventory.schema.json` | `INVENTORY.json` | Master inventory of all repository entities |
| `data-file.schema.json` | `data/*.json` | Generic data file structure (fallback) |
| `secrets.schema.json` | `data/secrets.json` | Secret handling patterns catalog |

## Schema Details

### inventory.schema.json

**Validates:** `/docs/repo-keeper/INVENTORY.json`

**Purpose:** Ensures the master inventory file has correct structure for tracking all repository entities.

**Required Fields:**
- `version` (string, semver format)
- `last_updated` (string, YYYY-MM-DD format)
- `skills` (array)
- `commands` (array)
- `templates` (object with categorized arrays)
- `examples` (array)
- `data_files` (array)
- `documentation` (object with categorized arrays)
- `devcontainers` (array)

**Key Validations:**
- Version must be valid semantic version (e.g., "2.2.1")
- Date must be YYYY-MM-DD format
- All file paths must be strings
- Mode values must be: "basic", "intermediate", "advanced", or "yolo"
- Template categories: master, dockerfiles, compose, firewall, extensions, mcp, variables, env

**Example Structure:**
```json
{
  "version": "2.2.1",
  "last_updated": "2025-12-18",
  "skills": [
    {
      "name": "skill-name",
      "path": "skills/skill-name/SKILL.md",
      "description": "Skill description",
      "mode": "intermediate",
      "references": ["docs/guide.md"]
    }
  ],
  "commands": [
    {
      "name": "command-name",
      "path": "commands/command-name.md"
    }
  ]
}
```

**Validation Command:**
```bash
ajv validate -s schemas/inventory.schema.json -d ../../INVENTORY.json --spec=draft7
```

---

### data-file.schema.json

**Validates:** `data/*.json` (generic fallback)

**Purpose:** Provides basic validation for data files that don't have specific schemas.

**Required Fields:**
- `version` (string)
- `description` (string)

**Example Structure:**
```json
{
  "version": "2.2.1",
  "description": "File description",
  "data": {
    // File-specific content
  }
}
```

**Validation Command:**
```bash
ajv validate -s schemas/data-file.schema.json -d ../../data/example.json --spec=draft7
```

---

### secrets.schema.json

**Validates:** `data/secrets.json`

**Purpose:** Validates the master catalog of secret handling patterns for DevContainer setup.

**Required Fields:**
- `version` (string, semver format)
- `description` (string)
- `categories` (object)

**Key Validations:**
- Version must be valid semantic version
- Category keys must be lowercase with underscores (e.g., "git_auth", "api_keys")
- Each category must have a description
- Mode minimum values must be: "basic", "intermediate", "advanced", or "yolo"

**Example Structure:**
```json
{
  "version": "2.2.1",
  "description": "Master catalog of secret handling patterns",
  "categories": {
    "git_auth": {
      "description": "Git authentication secrets",
      "mode_minimum": "intermediate",
      "secrets": {
        "GIT_AUTH_TOKEN": {
          "description": "Personal access token",
          "mount_type": "env",
          "security_level": "critical"
        }
      }
    }
  }
}
```

**Validation Command:**
```bash
ajv validate -s schemas/secrets.schema.json -d ../../data/secrets.json --spec=draft7
```

---

## Schema Usage

### Command Line Validation

**Validate single file:**
```bash
cd docs/repo-keeper
ajv validate -s schemas/inventory.schema.json -d INVENTORY.json --spec=draft7
```

**Validate all data files:**
```bash
for file in data/*.json; do
    echo "Validating $file..."
    ajv validate -s schemas/data-file.schema.json -d "$file" --spec=draft7
done
```

### Automated Validation

**Via validation script:**
```bash
./docs/repo-keeper/scripts/validate-schemas.sh
```

This script:
1. Validates INVENTORY.json against inventory.schema.json
2. Validates each data/*.json file against specific schema (if available)
3. Falls back to data-file.schema.json for files without specific schemas

### IDE Integration

#### VSCode

Add to `.vscode/settings.json`:
```json
{
  "json.schemas": [
    {
      "fileMatch": ["docs/repo-keeper/INVENTORY.json"],
      "url": "./docs/repo-keeper/schemas/inventory.schema.json"
    },
    {
      "fileMatch": ["data/secrets.json"],
      "url": "./docs/repo-keeper/schemas/secrets.schema.json"
    },
    {
      "fileMatch": ["data/*.json"],
      "url": "./docs/repo-keeper/schemas/data-file.schema.json"
    }
  ]
}
```

Benefits:
- Real-time validation while editing
- Auto-completion for properties
- Hover documentation
- Error highlighting

#### Other Editors

Most JSON-aware editors support JSON Schema:
- **IntelliJ/WebStorm** - Built-in schema support
- **Sublime Text** - Via LSP-json plugin
- **Vim/Neovim** - Via coc-json or ALE
- **Atom** - Via linter-jsonlint

---

## Creating New Schemas

### Step 1: Define Schema

Create `schemas/<name>.schema.json`:
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://claude.ai/schemas/<name>.schema.json",
  "title": "Schema Title",
  "description": "Schema description",
  "type": "object",
  "required": ["version", "description"],
  "properties": {
    "version": {
      "type": "string",
      "description": "Semantic version",
      "pattern": "^[0-9]+\\.[0-9]+\\.[0-9]+$"
    },
    "description": {
      "type": "string",
      "description": "Human-readable description"
    }
  }
}
```

### Step 2: Add to Validation Script

Edit `scripts/validate-schemas.sh`:
```bash
# Define specific schemas for data files
declare -A SPECIFIC_SCHEMAS
SPECIFIC_SCHEMAS["secrets.json"]="$REPO_ROOT/docs/repo-keeper/schemas/secrets.schema.json"
SPECIFIC_SCHEMAS["<your-file>.json"]="$REPO_ROOT/docs/repo-keeper/schemas/<name>.schema.json"
```

### Step 3: Test Schema

```bash
# Validate against schema
ajv validate -s schemas/<name>.schema.json -d data/<your-file>.json --spec=draft7

# Run full validation
./scripts/validate-schemas.sh
```

### Step 4: Document Schema

Add section to this README with:
- What it validates
- Required fields
- Key validations
- Example structure
- Validation command

---

## Schema Patterns

### Common Field Types

**Semantic Version:**
```json
{
  "version": {
    "type": "string",
    "pattern": "^[0-9]+\\.[0-9]+\\.[0-9]+$"
  }
}
```

**Date (YYYY-MM-DD):**
```json
{
  "date": {
    "type": "string",
    "pattern": "^[0-9]{4}-[0-9]{2}-[0-9]{2}$"
  }
}
```

**Enum Values:**
```json
{
  "mode": {
    "type": "string",
    "enum": ["basic", "intermediate", "advanced", "yolo"]
  }
}
```

**File Path:**
```json
{
  "path": {
    "type": "string",
    "description": "Relative path from repo root"
  }
}
```

**Dynamic Object Keys:**
```json
{
  "categories": {
    "type": "object",
    "patternProperties": {
      "^[a-z_]+$": {
        "type": "object",
        "properties": {
          "description": { "type": "string" }
        }
      }
    }
  }
}
```

### Conditional Validation

**Require field based on another:**
```json
{
  "if": {
    "properties": {
      "type": { "const": "skill" }
    }
  },
  "then": {
    "required": ["mode"]
  }
}
```

### Array Validation

**Array of objects:**
```json
{
  "items": {
    "type": "array",
    "items": {
      "type": "object",
      "required": ["name", "path"],
      "properties": {
        "name": { "type": "string" },
        "path": { "type": "string" }
      }
    }
  }
}
```

---

## Troubleshooting

### Schema Validation Fails

**Issue:** Schema validation reports errors
**Solution:**
1. Check JSON syntax first: `node -e "JSON.parse(require('fs').readFileSync('file.json'))"`
2. Review specific error message from ajv
3. Compare against example structure in this documentation
4. Verify all required fields exist
5. Check data types match schema (string vs number vs object)

### Missing Schema File

**Issue:** Script reports "Schema not found"
**Solution:**
1. Verify schema file exists: `ls -la schemas/<name>.schema.json`
2. Check file path in validation script
3. Ensure schema is committed to repository

### IDE Not Using Schema

**Issue:** VSCode doesn't validate against schema
**Solution:**
1. Check `.vscode/settings.json` has correct fileMatch pattern
2. Reload VSCode window (Cmd/Ctrl+Shift+P → "Reload Window")
3. Verify schema file path is relative to workspace root

---

## Schema Development Resources

### JSON Schema Documentation
- **Official Spec:** https://json-schema.org/
- **Draft-07 Spec:** https://json-schema.org/draft-07/schema
- **Understanding JSON Schema:** https://json-schema.org/understanding-json-schema/

### Tools
- **ajv-cli:** Command-line JSON Schema validator
- **JSONSchemaLint:** Online validator - https://jsonschemalint.com/
- **Schema Generator:** Generate schema from example - https://jsonschema.net/

### Validators
- **ajv:** Fast JSON Schema validator (Node.js)
- **jsonschema:** Python JSON Schema validator
- **go-jsonschema:** Go JSON Schema validator

---

## Future Schema Additions

Planned schemas for remaining data files:

| Priority | Schema | File | Status |
|----------|--------|------|--------|
| High | `variables.schema.json` | `data/variables.json` | Planned |
| High | `mcp-servers.schema.json` | `data/mcp-servers.json` | Planned |
| Medium | `official-images.schema.json` | `data/official-images.json` | Planned |
| Medium | `sandbox-templates.schema.json` | `data/sandbox-templates.json` | Planned |
| Low | `vscode-extensions.schema.json` | `data/vscode-extensions.json` | Planned |
| Low | `allowable-domains.schema.json` | `data/allowable-domains.json` | Planned |

To contribute a new schema:
1. Create schema file following patterns in this document
2. Add to validation script
3. Test thoroughly
4. Update this README
5. Submit PR with schema + tests

---

**Version History:**

| Version | Date | Changes |
|---------|------|---------|
| 2.2.1 | 2025-12-18 | Added secrets.schema.json, documented schema development |
| 2.1.0 | 2025-12-16 | Initial schemas (inventory, data-file) |

---

**Related Documentation:**
- [EXIT_CODES.md](../EXIT_CODES.md) - Exit codes for validation scripts
- [ERROR_RECOVERY.md](../ERROR_RECOVERY.md) - Handling validation failures
- [README.md](../README.md) - Main documentation
