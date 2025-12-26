# Sandboxxer Plugin Diagrams

This directory contains Mermaid diagrams visualizing the sandboxxer plugin architecture, workflows, and data flows.

## Available Diagrams

### 1. Plugin Architecture

**File:** [`plugin-architecture.mmd`](plugin-architecture.mmd) | **SVG:** [`svg/plugin-architecture.svg`](svg/plugin-architecture.svg)

**Purpose:** Shows the component hierarchy of the sandboxxer plugin.

**Components visualized:**
- **Commands (5)**: `/quickstart`, `/yolo-vibe-maxxing`, `/troubleshoot`, `/audit`, `/deploy-to-azure`
- **Skills (2)**: `sandboxxer-troubleshoot`, `sandboxxer-security`
- **Agents (2)**: `devcontainer-generator`, `devcontainer-validator`
- **Hooks (1)**: PreToolUse for Docker safety
- **Shared Resources**: Templates, data catalogs, language partials

**Used in:** README.md, docs/ARCHITECTURE.md

![Plugin Architecture](svg/plugin-architecture.svg)

---

### 2. Quickstart Setup Flow

**File:** [`quickstart-flow.mmd`](quickstart-flow.mmd) | **SVG:** [`svg/quickstart-flow.svg`](svg/quickstart-flow.svg)

**Purpose:** Interactive setup workflow showing the `/quickstart` command process.

**Workflow:**
1. User runs `/quickstart`
2. Project type selection (9 language options)
3. Network restrictions decision
4. Optional firewall configuration with domain categories
5. DevContainer file generation

**Used in:** README.md, docs/features/SETUP-OPTIONS.md

![Quickstart Setup Flow](svg/quickstart-flow.svg)

---

### 3. File Generation Process

**File:** [`file-generation.mmd`](file-generation.mmd) | **SVG:** [`svg/file-generation.svg`](svg/file-generation.svg)

**Purpose:** Shows how templates are processed to generate DevContainer files.

**Flow:**
- **Input:** Templates, data catalogs, language partials
- **Processing:** Copy templates, append partials, replace placeholders, configure firewall
- **Output:** .devcontainer/ directory with Dockerfile, devcontainer.json, docker-compose.yml, init-firewall.sh

**Used in:** docs/ARCHITECTURE.md

![File Generation Process](svg/file-generation.svg)

---

### 4. Mode Selection

**File:** [`mode-selection.mmd`](mode-selection.mmd) | **SVG:** [`svg/mode-selection.svg`](svg/mode-selection.svg)

**Purpose:** Decision tree for selecting the appropriate Docker Compose mode.

**Modes:**
- **Standard Bind Mount** (`docker-compose.yml`) - Linux default, direct file editing
- **Volume Mode** (`docker-compose.volume.yml`) - Windows/macOS, fast I/O with volume
- **Prebuilt Mode** (`docker-compose.prebuilt.yml`) - CI/CD with pre-built images
- **Profiles Mode** (`docker-compose-profiles.yml`) - Backend/frontend service isolation

**Used in:** docs/features/SETUP-OPTIONS.md

![Mode Selection](svg/mode-selection.svg)

---

## Editing Diagrams

### Using Mermaid Live Editor (Recommended)

1. Open https://mermaid.live
2. Copy content from any `.mmd` file
3. Edit the diagram interactively
4. Download as SVG and save to `svg/` directory
5. Commit both `.mmd` source and `.svg` output

### Using Mermaid CLI

Requires Node.js and works in environments with browser support:

```bash
# Generate single diagram
npx -y @mermaid-js/mermaid-cli -i plugin-architecture.mmd -o svg/plugin-architecture.svg -b transparent

# Generate all diagrams
for file in *.mmd; do
    npx -y @mermaid-js/mermaid-cli -i "$file" -o "svg/${file%.mmd}.svg" -b transparent
done
```

**Note:** In Docker containers, you may need a puppeteer config to disable sandbox:

```json
{
  "args": ["--no-sandbox", "--disable-setuid-sandbox"]
}
```

Then use: `npx @mermaid-js/mermaid-cli -i <input> -o <output> -p puppeteer-config.json`

### Mermaid Syntax Reference

- **Flowchart:** `flowchart TD` (top-down) or `flowchart LR` (left-right)
- **Nodes:** `A[Rectangle]`, `B{Diamond}`, `C([Rounded])`
- **Edges:** `A --> B` (arrow), `A -.-> B` (dotted), `A -->|Label| B` (labeled)
- **Styling:** `style A fill:#90EE90,stroke:#333,stroke-width:2px`
- **Subgraphs:** `subgraph Title ... end`

Full reference: https://mermaid.js.org/intro/

---

## Color Coding

All diagrams follow this color scheme:

| Component Type | Color | Hex Code | Usage |
|----------------|-------|----------|-------|
| Commands | Light Green | `#90EE90` | Slash commands |
| Skills | Sky Blue | `#87CEEB` | Workflow skills |
| Agents | Orange | `#FFB366` | Subagents |
| Hooks | Red | `#FF6B6B` | Event hooks |
| Shared Resources | Purple | `#DDA0DD` | Templates/data |
| Decision Points | Peach | `#FFE4B5` | User choices |
| Processing | Light Gray | `#f0f0f0` | Internal processing |

---

## Embedding in Documentation

To embed diagrams in markdown files, use:

```markdown
![Diagram Title](diagrams/svg/diagram-name.svg)
```

Or for relative paths from different locations:

```markdown
<!-- From README.md -->
![Plugin Architecture](docs/diagrams/svg/plugin-architecture.svg)

<!-- From docs/ARCHITECTURE.md -->
![Plugin Architecture](diagrams/svg/plugin-architecture.svg)
```

---

## File Structure

```
docs/diagrams/
├── README.md                   # This file
├── puppeteer-config.json       # Config for Mermaid CLI in Docker
├── plugin-architecture.mmd     # Mermaid source files
├── quickstart-flow.mmd
├── file-generation.mmd
├── mode-selection.mmd
└── svg/                        # Generated SVG files
    ├── plugin-architecture.svg
    ├── quickstart-flow.svg
    ├── file-generation.svg
    └── mode-selection.svg
```

---

## Related Documentation

- [Plugin Architecture](../ARCHITECTURE.md) - Technical architecture overview
- [Setup Options](../features/SETUP-OPTIONS.md) - Command comparison and mode selection
- [Skills README](../../skills/README.md) - Skill documentation
- [Commands README](../../commands/README.md) - Command reference

---

**Last Updated:** 2025-12-25
**Version:** 4.6.0
