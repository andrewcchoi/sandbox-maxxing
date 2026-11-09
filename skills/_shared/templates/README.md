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
- `.gitattributes` → Copied to project root (ensures LF line endings for Docker/shell files)
- `.dockerignore` → Copied to project root (optimizes Docker build context)
- `.gitignore` → Copied to project root (protects secrets and build artifacts)
- `.editorconfig` → Copied to project root (ensures consistent editor settings)
- `extensions.json` → Simple list of VS Code extensions (copied to devcontainer)
- `variables.json` → Simple environment variable templates
- `mcp.json` → MCP server configuration template

**Note on File Formats:**
- `devcontainer.json` uses **JSONC** (JSON with Comments) format, which allows:
  - Comments using `//` and `/* */` syntax
  - Trailing commas in arrays and objects
  - This is a VS Code standard for configuration files

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
- **NOT copied to user's `.devcontainer/` directory** - these are reference catalogs only

## Language Partials

**Location:** `skills/_shared/templates/partials/`

Language-specific dockerfiles that are **appended** to `base.dockerfile` when user selects a project type:

- `go.dockerfile` - Go 1.22 toolchain
- `ruby.dockerfile` - Ruby 3.3 and bundler
- `rust.dockerfile` - Rust toolchain and Cargo
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

## Firewall Script

**Location:** `skills/_shared/templates/init-firewall.sh`

The firewall script can be configured for different modes:

- **Permissive mode** (default) - Allows all traffic while providing extensibility points
- **Strict mode** - Can be customized for allowlist-based firewall with domain restrictions

## Git Worktrees (Windows)

**Location:** `skills/_shared/templates/fix-worktree-paths.sh`

Sandboxxer automatically supports git worktrees on Windows hosts. Git worktrees have a `.git` file (not directory) containing an absolute Windows path that is invalid inside Linux containers.

### How It Works

When you open a git worktree from Windows in a DevContainer:

1. **Detection:** The `fix-worktree-paths.sh` script detects Windows paths in `.git` file (e.g., `C:/Users/...`)
2. **Translation:** Extracts main repo name and worktree name from the path
3. **Verification:** Confirms main repo is accessible as sibling (via parent directory mount)
4. **Rewriting:** Updates `.git` to relative Unix path: `gitdir: ../<main-repo>/.git/worktrees/<worktree-name>`

### Requirements

**Standard Layout:** Worktrees must be siblings of the main repo (standard git worktree behavior):

```
repos/
├── my-project/           ← main repo
└── my-project-feature/   ← worktree (opened in VS Code)
```

The DevContainer template mounts the parent directory (`..:/workspace:cached`), so both the main repo and worktree are accessible.

### Troubleshooting

If git commands fail in the container:

1. Check `.git` file contents:
   ```bash
   cat /workspace/.git
   ```

2. Should show relative Unix path:
   ```
   gitdir: ../<main-repo>/.git/worktrees/<worktree-name>
   ```

3. If Windows path still present:
   - Verify worktrees are siblings of main repo
   - Check container logs during `postCreateCommand`
   - Manually run: `bash .devcontainer/fix-worktree-paths.sh`

### Implementation

The fix runs automatically at two points:

1. **Early in `postCreateCommand`** (devcontainer.json:71) - Runs before other git operations
2. **Section 0 of `setup-claude-credentials.sh`** - Double-checks before git configuration

This ensures git commands work throughout the container setup process.

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
| **Copied to user's devcontainer** | **NOT copied - reference only** |
| Ready for immediate use | Source of truth for all options |
| Read by skills for interactive prompts | Provides metadata for user selection |

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

