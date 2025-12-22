---
description: Set up a new VS Code DevContainer environment - routes to mode-specific setup
---

# DevContainer Setup Router

This command helps you choose the right setup mode for your needs.

## Quick Selection

Use flags to skip mode selection:
- `--basic` → Fastest setup, no firewall (recommended for beginners)
- `--advanced` → Security-focused, strict firewall with allowlist
- `--yolo` → Full control, no restrictions (expert users)

## If No Flag Provided

Ask the user:

"Which setup mode do you prefer?

**Basic** - Fastest setup (recommended for most users)
- Uses official Docker images
- No firewall (relies on container isolation)
- Minimal questions (1-3)
- Planning mode: auto-detects configuration

**Advanced** - Secure setup (recommended for teams)
- Security-hardened official images
- Strict firewall with configurable allowlist
- Security guidance (7-10 questions)
- Planning mode: presents security recommendations

**YOLO** - Full control (expert users only)
- Any images (unofficial allowed)
- Optional firewall (disabled/permissive/strict)
- All options available (15-20+ questions)
- Planning mode: presents ALL configuration options"

**Note:** All modes now include a planning phase (v4.0.0) where Claude:
1. Scans your project and detects configuration
2. Creates a plan document for your approval
3. Implements after you approve

## Route to Mode Skill

Based on selection, invoke the appropriate skill using the Skill tool:
- Basic → Use devcontainer-setup-basic skill
- Advanced → Use devcontainer-setup-advanced skill
- YOLO → Use devcontainer-setup-yolo skill

---

**Last Updated:** 2025-12-22
**Version:** 4.0.0 (Planning Mode Integration, Intermediate Mode Deprecated)
