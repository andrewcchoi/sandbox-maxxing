# VS Code Extensions Reference

Curated extensions for DevContainer development, organized by mode and category.

## Quick Reference

| Mode | Essential | Language | Themes | Productivity | Fun | Total |
|------|-----------|----------|--------|--------------|-----|-------|
| Basic | 3 | 2+ | 1 | 0 | 1 | 6-8 |
| Intermediate | 5 | 4+ | 3 | 2 | 3 | 15-20 |
| Advanced | 7 | 4+ | 5 | 4 | 4 | 22-28 |
| YOLO | 7 | 6+ | 9 | 4 | 7 | 35+ |

## Categories

### Essential (All Modes)
- `anthropic.claude-code` - Claude Code AI assistant
- `ms-azuretools.vscode-docker` - Docker support
- `redhat.vscode-yaml` - YAML language support

### Git & Version Control
- `eamodio.gitlens` - Git supercharged (Basic+)
- `mhutchie.git-graph` - Git graph visualization (Intermediate+)

### Themes (All Modes)
| Extension | Name | Mode |
|-----------|------|------|
| `PKief.material-icon-theme` | Material Icon Theme | Basic+ |
| `GitHub.github-vscode-theme` | GitHub Theme | Intermediate+ |
| `dracula-theme.theme-dracula` | Dracula | Intermediate+ |
| `EliverLara.andromeda` | Andromeda | Intermediate+ |
| `zhuangtongfa.material-theme` | One Dark Pro | Advanced+ |
| `sdras.night-owl` | Night Owl | Advanced+ |
| `arcticicestudio.nord-visual-studio-code` | Nord | YOLO |
| `akamud.vscode-theme-onedark` | Atom One Dark | YOLO |
| `monokai.theme-monokai-pro-vscode` | Monokai Pro | YOLO |

### Fun Extensions (All Modes)
| Extension | Name | Mode |
|-----------|------|------|
| `johnpapa.vscode-peacock` | Peacock (workspace colors) | Basic+ |
| `hoovercj.vscode-power-mode` | Power Mode | Intermediate+ |
| `tonybaloney.vscode-pets` | VS Code Pets | Intermediate+ |
| `wayou.vscode-todo-highlight` | TODO Highlight | Advanced+ |
| `icrawl.discord-vscode` | Discord Presence | YOLO |
| `s-nlf-fh.glassit` | GlassIt (transparency) | YOLO |
| `be5invis.vscode-custom-css` | Custom CSS/JS | YOLO |

### Language-Specific

#### Python
- `ms-python.python` - Python language support (Basic+)
- `ms-python.vscode-pylance` - Type checking (Basic+)
- `ms-python.black-formatter` - Code formatting (Intermediate+)
- `charliermarsh.ruff` - Fast linter (Advanced+)

#### JavaScript/TypeScript
- `dbaeumer.vscode-eslint` - ESLint (Basic+)
- `esbenp.prettier-vscode` - Prettier (Basic+)
- `bradlc.vscode-tailwindcss` - Tailwind CSS (Intermediate+)
- `christian-kohler.npm-intellisense` - npm support (Intermediate+)

#### Go
- `golang.go` - Go language support (Basic+)

#### Rust
- `rust-lang.rust-analyzer` - Rust analyzer (Basic+)

#### Java
- `redhat.java` - Java language support (Basic+)
- `vscjava.vscode-maven` - Maven support (Intermediate+)
- `vscjava.vscode-java-pack` - Java Extension Pack (Advanced+)

### Database
- `mtxr.sqltools` - SQL tools (Intermediate+)
- `mongodb.mongodb-vscode` - MongoDB (Advanced+)
- `cweijan.vscode-database-client2` - Database client (Advanced+)

### Productivity
- `streetsidesoftware.code-spell-checker` - Spell checker (Intermediate+)
- `usernamehw.errorlens` - Inline errors (Advanced+)
- `christian-kohler.path-intellisense` - Path completion (Advanced+)
- `formulahendry.auto-rename-tag` - Auto rename tags (Advanced+)

## Usage

Extensions are configured in `.devcontainer/devcontainer.json`:

```json
{
  "customizations": {
    "vscode": {
      "extensions": [
        "anthropic.claude-code",
        "eamodio.gitlens"
      ]
    }
  }
}
```
