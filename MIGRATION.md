# Migration Guide

This document covers breaking changes and migration steps for major sandboxxer plugin updates.

## Version Compatibility Matrix

| From Version | To Version | Breaking Changes | Migration Difficulty |
|-------------|------------|------------------|---------------------|
| 4.10.x | 4.11.x | Command rename | Easy (find/replace) |
| 4.5.x | 4.6.x | Plugin rename | Medium (reinstall) |
| 4.4.x | 4.5.x | Command rename | Easy (find/replace) |
| 3.x.x | 4.0.x | Architecture change | Complex |

---

## v4.11.0 - Command Rename: yolo-vibe-maxxing → yolo-docker-maxxing

**Release Date:** 2026-02-04

### What Changed

The `/sandboxxer:yolo-vibe-maxxing` command was renamed to `/sandboxxer:yolo-docker-maxxing` to create clearer distinction with the new native Linux command:

| Old Command | New Command | Purpose |
|-------------|-------------|---------|
| `/sandboxxer:yolo-vibe-maxxing` | `/sandboxxer:yolo-docker-maxxing` | Docker container isolation |
| (new) | `/sandboxxer:yolo-linux-maxxing` | Native Linux bubblewrap |

### Why This Changed

With the addition of `/sandboxxer:yolo-linux-maxxing` (bubblewrap for native Linux), a tool-based naming convention (`docker` vs `linux`) is more intuitive than experience-based naming (`vibe` vs `linux`).

### Migration Steps

```bash
# Old command (no longer works in v4.11.0+)
/sandboxxer:yolo-vibe-maxxing

# New command
/sandboxxer:yolo-docker-maxxing
```

**Search and Replace:**
```bash
# In your scripts/documentation
sed -i 's/yolo-vibe-maxxing/yolo-docker-maxxing/g' your-file.md
```

### Affected Files

If you have custom scripts or documentation referencing the old command:
- CI/CD workflows
- README files
- Automation scripts
- Bookmarks/aliases

---

## v4.6.0 - Plugin Rename: devcontainer-setup → sandboxxer

**Release Date:** 2025-12-25

### What Changed

The entire plugin was renamed from `devcontainer-setup` to `sandboxxer`:

| Component | Old Name | New Name |
|-----------|----------|----------|
| Plugin name | devcontainer-setup | sandboxxer |
| Marketplace name | devcontainer-setup | sandbox-maxxing |
| Commands prefix | `/devcontainer:*` | `/sandboxxer:*` |
| Skills prefix | `devcontainer-setup-*` | `sandboxxer-*` |

### Why This Changed

The new name better reflects the plugin's purpose: creating sandboxed development environments with security features beyond just DevContainer configuration.

### Migration Steps

**1. Uninstall Old Plugin**
```bash
claude plugins remove devcontainer-setup
```

**2. Install New Plugin**
```bash
claude plugins add https://github.com/andrewcchoi/sandbox-maxxing
# or
claude plugins add sandboxxer
```

**3. Update Command References**
```bash
# Old commands (no longer work)
/devcontainer:setup
/devcontainer:yolo
/devcontainer:troubleshoot
/devcontainer:audit

# New commands
/sandboxxer:quickstart
/sandboxxer:yolo-docker-maxxing
/sandboxxer:troubleshoot
/sandboxxer:audit
```

### Command Mapping

| Old Command | New Command |
|-------------|-------------|
| `/devcontainer:setup` | `/sandboxxer:quickstart` |
| `/devcontainer:yolo` | `/sandboxxer:yolo-docker-maxxing` |
| `/devcontainer:troubleshoot` | `/sandboxxer:troubleshoot` |
| `/devcontainer:audit` | `/sandboxxer:audit` |
| `/devcontainer:basic` | (removed - use quickstart) |
| `/devcontainer:intermediate` | (removed - use quickstart) |
| `/devcontainer:advanced` | (removed - use quickstart) |

---

## v4.5.0 - Command Rename: setup → quickstart, yolo → yolo-docker-maxxing

**Release Date:** 2025-12-24

### What Changed

Commands were renamed for better clarity:

| Old Command | New Command | Reason |
|-------------|-------------|--------|
| `/devcontainer:setup` | `/devcontainer:quickstart` | More descriptive of the quick interactive flow |
| `/devcontainer:yolo` | `/devcontainer:yolo-docker-maxxing` | More stylistic, matches project vibe |

### Migration Steps

```bash
# Old (v4.4.x and earlier)
/devcontainer:setup
/devcontainer:yolo

# New (v4.5.0+)
/devcontainer:quickstart
/devcontainer:yolo-docker-maxxing
```

> **Note:** This was immediately followed by v4.6.0 which renamed the entire plugin. If migrating from v4.4.x or earlier, go directly to the v4.6.0 migration.

---

## v4.0.0 - Architecture: Shared Resources & Mandatory Planning

**Release Date:** 2025-12-22

### What Changed

Major architectural changes:

1. **Mandatory Planning Mode** - All skills require a planning phase before execution
2. **Intermediate Mode Deprecated** - Removed `devcontainer-setup-intermediate` skill
3. **Shared Resources** - Consolidated templates under `skills/_shared/`

### Why This Changed

- **Planning mode** gives users visibility and approval before changes
- **Intermediate mode** was rarely used (90% preferred Basic or Advanced)
- **Shared resources** reduce duplication by 60%

### Migration Steps

**1. Intermediate Mode Users**

If you used intermediate mode, migrate to either:

```bash
# Option A: Basic mode (simpler, container isolation)
/sandboxxer:quickstart
# Select: Python/Node → No firewall

# Option B: Advanced mode (more control, domain allowlist)
/sandboxxer:quickstart
# Select: Your language → Yes firewall → Configure domains
```

**2. Plan Files**

v4.0.0+ creates plan files before execution:
- Location: `docs/plans/YYYY-MM-DD-devcontainer-setup.md`
- You must approve the plan before implementation proceeds

**3. Template Locations**

Templates moved from multiple locations to:
```
skills/_shared/templates/
├── base.dockerfile
├── devcontainer.json
├── docker-compose.yml
├── init-firewall.sh
├── setup-claude-credentials.sh
├── partials/          # Language-specific sections
└── data/              # JSON configuration files
```

---

## v3.0.0 - Plugin Rename (Legacy)

**Release Date:** 2025-12-19

First rename from early development naming. If upgrading from v2.x or earlier, follow the v4.6.0 migration (most comprehensive).

---

## Troubleshooting Migration Issues

### "Command not found"

```bash
# Verify plugin is installed
claude plugins list | grep sandboxxer

# If not listed, install it
claude plugins add https://github.com/andrewcchoi/sandbox-maxxing
```

### "Old command still works"

You may have both old and new plugins installed:

```bash
# Remove old plugin
claude plugins remove devcontainer-setup

# Verify only sandboxxer remains
claude plugins list
```

### Configuration Files Incompatible

If you have existing `.devcontainer/` files from an older version:

1. **Backup existing files:**
   ```bash
   mv .devcontainer .devcontainer.backup
   mv docker-compose.yml docker-compose.yml.backup
   ```

2. **Regenerate with new plugin:**
   ```bash
   /sandboxxer:yolo-docker-maxxing
   # or
   /sandboxxer:quickstart
   ```

3. **Compare and merge customizations:**
   ```bash
   diff .devcontainer.backup/Dockerfile .devcontainer/Dockerfile
   ```

---

## Getting Help

- **Issues:** https://github.com/andrewcchoi/sandbox-maxxing/issues
- **Troubleshooting:** Run `/sandboxxer:troubleshoot`
- **Full Documentation:** See [README.md](README.md)

---

*Last updated: v4.13.3 (2026-02-10)*
