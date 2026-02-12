# Plugin Settings

Sandbox-maxxing supports user-customizable settings via a local configuration file. Settings are stored in `.claude/sandboxxer.local.md` in your project directory.

## Quick Start

Create `.claude/sandboxxer.local.md` in your project:

```markdown
---
# Sandbox-maxxing User Preferences
# These settings customize the default behavior of sandbox commands

# Default firewall mode for new sandboxes
# Options: "enabled", "disabled"
default_firewall: disabled

# Preferred language stack (added to base Python+Node)
# Options: "go", "rust", "ruby", "php", "cpp-clang", "cpp-gcc", "postgres", "none"
default_language: none

# Default workspace mode
# Options: "bind", "volume"
default_workspace_mode: bind

# Skip pre-flight validation by default
# Options: true, false
skip_validation: false

# Default port assignments (0 = auto-assign)
default_ports:
  app: 8000
  frontend: 3000
  postgres: 5432
  redis: 6379
---

# Project-Specific Notes

Add any project-specific sandbox configuration notes here.

## Custom Domains

If using firewall mode, these domains should be added to the allowlist:
- api.example.com
- cdn.example.com

## Environment Variables

Required API keys for this project:
- ANTHROPIC_API_KEY
- OPENAI_API_KEY
```

## Quickstart v2 Settings (Issue #271)

The refactored `/sandboxxer:quickstart` command supports additional settings for zero-question setup:

### Profile Settings

| Setting | Values | Default | Description |
|---------|--------|---------|-------------|
| `default_profile` | `minimal`, `backend`, `fullstack`, `custom` | (none) | Pre-select stack profile |
| `default_tools` | comma-separated list | (none) | Tools for custom profile (e.g., `go,rust,postgres`) |

**Profile Tool Mappings:**
- `minimal` → Python 3.12 + Node 20 only
- `backend` → + Go 1.22, PostgreSQL tools
- `fullstack` → + Go 1.22, Rust, PostgreSQL tools
- `custom` → Uses `default_tools` list

### Question Control

| Setting | Values | Default | Description |
|---------|--------|---------|-------------|
| `skip_all_questions` | `true`, `false` | `false` | Skip all questions, use settings |

When `skip_all_questions: true`, quickstart runs non-interactively using all settings. Same as `--yes` flag.

### Firewall Presets

| Setting | Values | Default | Description |
|---------|--------|---------|-------------|
| `firewall_preset` | `essentials`, `cloud`, `all`, `custom` | `essentials` | Domain category preset |
| `custom_domains` | comma-separated list | (none) | Custom domains for firewall |

**Preset Mappings:**
- `essentials` → npm, PyPI, GitHub, GitLab, Docker Hub
- `cloud` → Essentials + AWS, GCP, Azure
- `all` → All categories including analytics
- `custom` → Uses `custom_domains` list

### Example: Zero-Question Backend Setup

```yaml
---
default_profile: backend
default_firewall: disabled
default_workspace_mode: bind
skip_all_questions: true
---
```

Run `/sandboxxer:quickstart` and it generates configuration instantly with no prompts.

### Example: Secure Corporate Environment

```yaml
---
default_profile: minimal
default_firewall: enabled
firewall_preset: essentials
custom_domains: api.company.com,registry.internal.corp
default_workspace_mode: volume
---
```

### CLI Flag Overrides

CLI flags override settings file values:

| Flag | Overrides Setting |
|------|------------------|
| `--yes` | `skip_all_questions` |
| `--profile=NAME` | `default_profile` |
| `--tools=LIST` | `default_tools` |
| `--firewall` | `default_firewall=enabled` |
| `--no-firewall` | `default_firewall=disabled` |
| `--volume` | `default_workspace_mode=volume` |

---

## Settings Reference

### Firewall Settings

| Setting | Values | Default | Description |
|---------|--------|---------|-------------|
| `default_firewall` | `enabled`, `disabled` | `disabled` | Whether to enable network firewall by default |

### Language Settings

| Setting | Values | Default | Description |
|---------|--------|---------|-------------|
| `default_language` | `go`, `rust`, `ruby`, `php`, `cpp-clang`, `cpp-gcc`, `postgres`, `none` | `none` | Additional language toolchain to include |

### Workspace Settings

| Setting | Values | Default | Description |
|---------|--------|---------|-------------|
| `default_workspace_mode` | `bind`, `volume` | `bind` | File mounting strategy |
| `skip_validation` | `true`, `false` | `false` | Skip pre-flight checks |

### Port Settings

| Setting | Values | Default | Description |
|---------|--------|---------|-------------|
| `default_ports.app` | `1024-65535`, `0` | `8000` | App service port (0 = auto) |
| `default_ports.frontend` | `1024-65535`, `0` | `3000` | Frontend port (0 = auto) |
| `default_ports.postgres` | `1024-65535`, `0` | `5432` | PostgreSQL port (0 = auto) |
| `default_ports.redis` | `1024-65535`, `0` | `6379` | Redis port (0 = auto) |

## How Settings Are Used

### In Commands

Commands like `/sandboxxer:quickstart` and `/sandboxxer:yolo-docker-maxxing` check for settings:

```bash
# Read settings from .claude/sandboxxer.local.md
SETTINGS_FILE=".claude/sandboxxer.local.md"

if [ -f "$SETTINGS_FILE" ]; then
  # Extract YAML frontmatter and parse settings
  DEFAULT_FIREWALL=$(sed -n '/^---$/,/^---$/p' "$SETTINGS_FILE" | grep "^default_firewall:" | cut -d: -f2 | tr -d ' ')

  if [ "$DEFAULT_FIREWALL" = "enabled" ]; then
    NEEDS_FIREWALL="Yes"
  fi
fi
```

### Precedence

Settings are applied in this order (later overrides earlier):

1. **Built-in defaults** - Hardcoded in commands
2. **Settings file** - `.claude/sandboxxer.local.md`
3. **Command arguments** - Explicit flags override everything

Example:
```bash
# Uses settings file default
/sandboxxer:quickstart

# Overrides settings file with explicit flag
/sandboxxer:quickstart --skip-validation
```

## File Location

Settings file must be at: `.claude/sandboxxer.local.md`

This location:
- Is project-specific (each project can have different settings)
- Is ignored by git (add `.claude/*.local.md` to `.gitignore`)
- Follows Claude Code plugin conventions

## Creating Settings

### Option 1: Manual Creation

Create the file manually:

```bash
mkdir -p .claude
cat > .claude/sandboxxer.local.md << 'EOF'
---
default_firewall: disabled
default_language: none
default_workspace_mode: bind
---

# My Sandbox Settings
EOF
```

### Option 2: Copy Template

Copy the template from the plugin:

```bash
mkdir -p .claude
cp "${CLAUDE_PLUGIN_ROOT}/docs/features/SETTINGS.md" .claude/sandboxxer.local.md
# Then edit to customize
```

## Git Ignore

Add to your `.gitignore`:

```gitignore
# Claude Code local settings (may contain sensitive preferences)
.claude/*.local.md
```

## Validation

Settings are validated when read. Invalid values are ignored with a warning:

```
⚠️ Invalid setting: default_firewall=maybe (expected: enabled, disabled)
   Using default: disabled
```

## Troubleshooting

### Settings Not Being Applied

1. **Check file location**: Must be `.claude/sandboxxer.local.md` (not `.claude-plugin/`)
2. **Check YAML syntax**: Frontmatter must be valid YAML between `---` markers
3. **Check setting names**: Use exact names from reference table
4. **Check values**: Use exact values (case-sensitive)

### Viewing Current Settings

Run the health check with verbose output:

```bash
/sandboxxer:health --verbose
```

This shows which settings are active and where they came from.

## Template File

See [sandboxxer-settings.example.md](../../skills/_shared/templates/sandboxxer-settings.example.md) for a complete template with all available settings.

## See Also

- [CUSTOMIZATION.md](CUSTOMIZATION.md) - Other customization options
- [SETUP-OPTIONS.md](SETUP-OPTIONS.md) - Available setup modes
