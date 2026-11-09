---
description: YOLO docker-maxxing - instant DevContainer with Python, Node, Go, AWS/Azure CLI, Terraform, Tailscale, PDF tools - 99% proxy-friendly
argument-hint: "[project-name] [--portless]"
allowed-tools: [Bash]
---

# YOLO Docker-Maxxing DevContainer Setup

**Quick setup with zero questions.** Creates a fully-loaded DevContainer with:

**Languages & Runtimes:**
- Python 3.12 + Node.js 20 + Go 1.22 (multi-stage Docker builds)

**Cloud & Infrastructure:**
- AWS CLI v2 + Azure CLI (az) + Azure Developer CLI (azd)
- Terraform (infrastructure as code)

**PDF & OCR Tools:**
- poppler-utils, ghostscript, qpdf, tesseract, ocrmypdf, pdftk

**Developer Tools:**
- Tailscale (secure remote access)
- bat (syntax-highlighted cat/git diffs)
- Zsh with Powerlevel10k + fzf

**Security:**
- No firewall (Docker container isolation only)
- 99% proxy-friendly via multi-stage Docker builds (no curl installers)

**New to sandboxing?** See the [Docker sandbox visual guide](../docs/diagrams/svg/sandbox-explained.svg) to understand what Docker sandboxes protect.

**Portless mode:** Add `--portless` flag to create containers without host port mappings for running multiple devcontainers in parallel.

**Need customization?** Use `/sandboxxer:quickstart` for interactive mode with project type selection and firewall options.

## Execution Instructions

**IMPORTANT:** Execute the script immediately without asking questions. This is a YOLO command - zero user interaction required.

- Do NOT ask if the user wants to run the setup
- Do NOT present options or choices
- Execute the script in the current directory
- Only ask questions if the script fails or returns errors

## Execute This Command

Run the standalone script with any user-provided arguments:

```
bash "${CLAUDE_PLUGIN_ROOT}/scripts/yolo-docker-maxxing.sh" [ARGS]
```

Where `[ARGS]` are the arguments passed by the user:
- `--portless` - Creates container without host port mappings
- `project-name` - Custom project name (defaults to current directory name)

**Examples:**
- No arguments: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/yolo-docker-maxxing.sh"`
- With project name: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/yolo-docker-maxxing.sh" my-project`
- Portless mode: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/yolo-docker-maxxing.sh" --portless`
- Both: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/yolo-docker-maxxing.sh" --portless my-project`

---

## Related Commands

- **`/sandboxxer:quickstart`** - Interactive setup with customization options
- **`/sandboxxer:health`** - Verify environment after setup
- **`/sandboxxer:troubleshoot`** - Fix issues if setup fails

## Related Documentation

- [Setup Options](../docs/features/SETUP-OPTIONS.md) - Available configuration options
- [Quickstart Flow](../docs/diagrams/svg/quickstart-flow.svg) - Setup workflow diagram
