# Templates Directory

This directory contains **template files** that are copied directly into user DevContainer configurations.

## Template vs Data Files Pattern

The plugin uses two types of files:

### 1. Template Files (This Directory)

**Purpose:** Copied as-is to user's `.devcontainer/` directory

**Location:** `skills/_shared/templates/`

**Examples:**
- `base.dockerfile` → Copied to `.devcontainer/Dockerfile`
- `devcontainer.json` → Copied to `.devcontainer/devcontainer.json`
- `docker-compose.yml` → Copied to project root
- `extensions.json` → Simple list of VS Code extensions (copied to devcontainer)
- `variables.json` → Simple environment variable templates
- `mcp.json` → MCP server configuration template

**Characteristics:**
- Small, focused files
- Ready for direct use by user
- Minimal processing (only `{{PROJECT_NAME}}` placeholders replaced)

### 2. Data Files (Reference Catalogs)

**Purpose:** Reference data read by skills for interactive selection

**Location:** `skills/_shared/templates/data/`

**Examples:**
- `vscode-extensions.json` → Comprehensive catalog with categories and metadata
- `variables.json` → Catalog of all possible variables with descriptions
- `allowable-domains.json` → Domain categories for firewall configuration
- `official-images.json` → Docker image registry with tags and recommendations

**Characteristics:**
- Large, comprehensive catalogs
- Include metadata, descriptions, and categorizations
- Used by skills to present options to users

## Language Partials

**Location:** `skills/_shared/templates/partials/`

Language-specific dockerfiles that are **appended** to `base.dockerfile` when user selects a project type:

- `go.dockerfile` - Go 1.22 toolchain
- `ruby.dockerfile` - Ruby 3.3 and bundler
- `rust.dockerfile` - Rust toolchain and Cargo
- `java.dockerfile` - OpenJDK 21, Maven, Gradle
- `cpp-clang.dockerfile` - Clang 17, CMake, vcpkg
- `cpp-gcc.dockerfile` - GCC, CMake, vcpkg
- `php.dockerfile` - PHP 8.3 and Composer
- `postgres.dockerfile` - PostgreSQL client and dev tools

**Build Process:**
```bash
# Always copy base first
cp base.dockerfile .devcontainer/Dockerfile

# Append language partial if selected
cat partials/go.dockerfile >> .devcontainer/Dockerfile
```

## Firewall Scripts

**Location:** `skills/_shared/templates/init-firewall/`

Three firewall options available:

- `disabled.sh` - No firewall (container isolation only)
- `permissive.sh` - Allow all traffic (alternative to disabled)
- `strict.sh` - Strict allowlist-based firewall (domain allowlist)

## Template Placeholders

Templates use placeholders that are replaced during setup:

| Placeholder | Used In | Replaced With |
|-------------|---------|---------------|
| `{{PROJECT_NAME}}` | devcontainer.json, docker-compose.yml | Current directory name |

### Placeholder Replacement

Commands use portable sed to replace placeholders:

```bash
PROJECT_NAME="$(basename $(pwd))"
for f in .devcontainer/devcontainer.json docker-compose.yml; do
  sed "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$f" > "$f.tmp" && mv "$f.tmp" "$f"
done
```

### Where Placeholders Appear

**devcontainer.json:**
- `"name": "{{PROJECT_NAME}}"` - Display name in VS Code

**docker-compose.yml:**
- `container_name: {{PROJECT_NAME}}-postgres` - Container naming
- `container_name: {{PROJECT_NAME}}-redis` - Container naming
- `name: {{PROJECT_NAME}}-network` - Network naming

### Why This Matters
- Helps users understand what gets customized
- Enables manual customization if needed
- Documents the build process for contributors

## Why Duplicate-Looking Files?

You may notice:
- `templates/extensions.json` vs `templates/data/vscode-extensions.json`
- `templates/variables.json` vs `templates/data/variables.json`

These serve **different purposes**:

| Template File | Data File |
|---------------|-----------|
| Simple array/object | Comprehensive catalog |
| Copied to user's devcontainer | Read by skills for interactive prompts |
| Ready for immediate use | Source of truth for all options |

**Example:**
- `extensions.json` has 6 essential extension IDs → copied to `.devcontainer/devcontainer.json`
- `vscode-extensions.json` has 50+ extensions with categories → used by `/sandboxxer:quickstart` to let users choose

## File Discovery

Commands use `CLAUDE_PLUGIN_ROOT` environment variable to locate templates:

```bash
TEMPLATES="$CLAUDE_PLUGIN_ROOT/skills/_shared/templates"
PARTIALS="$TEMPLATES/partials"
DATA="$TEMPLATES/data"
```

## See Also

- [Data Directory README](data/README.md) - Detailed documentation of reference catalogs
- [SETUP-OPTIONS.md](../../../docs/features/SETUP-OPTIONS.md) - Command comparison and setup workflows

---

**Last Updated:** 2025-12-25
**Version:** 4.6.0
