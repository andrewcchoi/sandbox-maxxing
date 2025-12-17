---
description: Set up a new Claude Code Docker sandbox environment - routes to mode-specific setup
---

# Sandbox Setup Router

This command helps you choose the right setup mode for your needs.

## Quick Selection

Use flags to skip mode selection:
- `--basic` → Fastest setup, sandbox templates, no firewall
- `--intermediate` → Standard Dockerfile, permissive firewall
- `--advanced` → Customizable, strict firewall with allowlist
- `--yolo` → Full control, no restrictions

## If No Flag Provided

Ask the user:

"Which setup mode do you prefer?

**Basic** - Fastest setup
- Uses sandbox templates or official images
- No firewall (relies on sandbox isolation)
- Minimal questions (1-2)

**Intermediate** - Standard setup
- Standard Dockerfile
- Permissive firewall (no restrictions)
- Common service options (4-6 questions)

**Advanced** - Secure setup (recommended for teams)
- Customizable templates
- Strict firewall with configurable allowlist
- Security guidance (7-10 questions)

**YOLO** - Full control
- Any images (unofficial allowed)
- Optional firewall
- All options available (extensive questions)"

## Route to Mode Skill

Based on selection, invoke the appropriate skill using the Skill tool:
- Basic → Use sandbox-setup-basic skill
- Intermediate → Use sandbox-setup-intermediate skill
- Advanced → Use sandbox-setup-advanced skill
- YOLO → Use sandbox-setup-yolo skill

---

**Last Updated:** 2025-12-16
**Version:** 2.2.1
