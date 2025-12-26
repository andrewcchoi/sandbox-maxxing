# VS Code Extensions Reference

Curated extensions for DevContainer development, organized by mode and category.

## Quick Reference

| Configuration | Essential | Language | Themes | Productivity | Fun | Total |
|---------------|-----------|----------|--------|--------------|-----|-------|
| Minimal | 3 | 2+ | 1 | 0 | 1 | 6-8 |
| Domain Allowlist | 7 | 4+ | 5 | 4 | 4 | 22-28 |
| Custom | 7 | 6+ | 9 | 4 | 7 | 35+ |

## Categories

### Essential (All Configurations)
- `anthropic.claude-code` - Claude Code AI assistant
- `ms-azuretools.vscode-docker` - Docker support
- `redhat.vscode-yaml` - YAML language support

### Git & Version Control
- `eamodio.gitlens` - Git supercharged (All configurations)
- `mhutchie.git-graph` - Git graph visualization (Domain Allowlist, Custom)

### Themes (All Configurations)
| Extension | Name | Configuration |
|-----------|------|------|
| `PKief.material-icon-theme` | Material Icon Theme | All |
| `GitHub.github-vscode-theme` | GitHub Theme | Domain Allowlist, Custom |
| `dracula-theme.theme-dracula` | Dracula | Domain Allowlist, Custom |
| `EliverLara.andromeda` | Andromeda | Domain Allowlist, Custom |
| `zhuangtongfa.material-theme` | One Dark Pro | Domain Allowlist, Custom |
| `sdras.night-owl` | Night Owl | Domain Allowlist, Custom |
| `arcticicestudio.nord-visual-studio-code` | Nord | Custom only |
| `akamud.vscode-theme-onedark` | Atom One Dark | Custom only |
| `monokai.theme-monokai-pro-vscode` | Monokai Pro | Custom only |

### Fun Extensions (All Configurations)
| Extension | Name | Configuration |
|-----------|------|------|
| `johnpapa.vscode-peacock` | Peacock (workspace colors) | All |
| `hoovercj.vscode-power-mode` | Power Mode | Domain Allowlist, Custom |
| `tonybaloney.vscode-pets` | VS Code Pets | Domain Allowlist, Custom |
| `wayou.vscode-todo-highlight` | TODO Highlight | Domain Allowlist, Custom |
| `icrawl.discord-vscode` | Discord Presence | Custom only |
| `s-nlf-fh.glassit` | GlassIt (transparency) | Custom only |
| `be5invis.vscode-custom-css` | Custom CSS/JS | Custom only |

### Language-Specific

#### Python
- `ms-python.python` - Python language support (All configurations)
- `ms-python.vscode-pylance` - Type checking (All configurations)
- `ms-python.black-formatter` - Code formatting (Domain Allowlist, Custom)
- `charliermarsh.ruff` - Fast linter (Domain Allowlist, Custom)

#### JavaScript/TypeScript
- `dbaeumer.vscode-eslint` - ESLint (All configurations)
- `esbenp.prettier-vscode` - Prettier (All configurations)
- `bradlc.vscode-tailwindcss` - Tailwind CSS (Domain Allowlist, Custom)
- `christian-kohler.npm-intellisense` - npm support (Domain Allowlist, Custom)

#### Go
- `golang.go` - Go language support (All configurations)

#### Rust
- `rust-lang.rust-analyzer` - Rust analyzer (All configurations)

#### Java
- `redhat.java` - Java language support (All configurations)
- `vscjava.vscode-maven` - Maven support (Domain Allowlist, Custom)
- `vscjava.vscode-java-pack` - Java Extension Pack (Domain Allowlist, Custom)

### Database
- `mtxr.sqltools` - SQL tools (Domain Allowlist, Custom)
- `mongodb.mongodb-vscode` - MongoDB (Domain Allowlist, Custom)
- `cweijan.vscode-database-client2` - Database client (Domain Allowlist, Custom)

### Productivity
- `streetsidesoftware.code-spell-checker` - Spell checker (Domain Allowlist, Custom)
- `usernamehw.errorlens` - Inline errors (Domain Allowlist, Custom)
- `christian-kohler.path-intellisense` - Path completion (Domain Allowlist, Custom)
- `formulahendry.auto-rename-tag` - Auto rename tags (Domain Allowlist, Custom)

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

---

**Last Updated:** 2025-12-25
**Version:** 4.6.0
