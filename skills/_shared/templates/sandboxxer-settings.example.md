---
# Sandbox-maxxing Plugin Settings
# Copy this file to .claude/sandboxxer.local.md in your project
# All settings are optional - defaults are used when not specified

# Stack Profile Selection
# Options: minimal, backend, fullstack, custom
# minimal   = Python 3.12 + Node 20 only
# backend   = + Go, PostgreSQL
# fullstack = + Go, Rust, PostgreSQL
# custom    = use default_tools list below
default_profile: minimal

# Custom Tools (used when default_profile: custom)
# Comma-separated list of: go, rust, ruby, php, cpp-clang, cpp-gcc, postgres
default_tools:

# Firewall Settings
# enabled: true/false
# preset: essentials, cloud, all, custom
# custom_domains: comma-separated list (used when preset: custom)
default_firewall: disabled
firewall_preset: essentials
custom_domains:

# Workspace Mode
# bind   = Real-time file sync (recommended for Linux)
# volume = Docker volume (better I/O for Windows/macOS)
# auto   = Detect platform and choose
default_workspace_mode: auto

# Pre-built Image
# true  = Pull from GHCR (faster, requires authentication)
# false = Build from scratch (works offline)
use_prebuilt_image: false

# Question Behavior
# When true, skips all questions and uses settings above
skip_all_questions: false

# Validation
# When true, skips Docker/port pre-flight checks
skip_validation: false

# Port Configuration
# Customize default ports if needed
default_ports:
  app: 8000
  frontend: 3000
  postgres: 5432
  redis: 6379
---

# Sandboxxer Settings

This file configures default behavior for `/sandboxxer:quickstart`.

## Usage

1. Copy this file to `.claude/sandboxxer.local.md` in your project root
2. Edit the YAML frontmatter above to set your defaults
3. Run `/sandboxxer:quickstart` - your settings will be used as defaults

## Quick Setup Examples

### Zero-Question Setup (Power Users)
```yaml
default_profile: backend
default_firewall: disabled
default_workspace_mode: bind
skip_all_questions: true
```

### Secure Corporate Environment
```yaml
default_profile: minimal
default_firewall: enabled
firewall_preset: essentials
custom_domains: internal.company.com,api.company.com
default_workspace_mode: volume
```

### Full Stack Development
```yaml
default_profile: fullstack
default_firewall: disabled
default_workspace_mode: bind
```
