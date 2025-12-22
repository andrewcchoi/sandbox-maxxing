# Plan: Repo-Keeper as a Reusable Plugin

**Status:** Reference Plan (for future implementation)
**Date:** 2025-12-18
**Scope:** Design document for making repo-keeper a universal repository validation tool

---

## Executive Summary

Transform repo-keeper from a sandbox-maxxing-specific validation system into a **universal repository health validator** distributed as:
- **NPM CLI tool** (`npm install -g repo-keeper`)
- **Homebrew package** (`brew install repo-keeper`)
- **Claude Code plugin** (AI-assisted validation)

**Key features:**
- Zero-config via auto-detection
- Presets for common project types
- Extensible validator system
- Tiered validation (quick/standard/full)

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    REPO-KEEPER                          │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐  │
│  │ Claude Code │  │   CLI Tool  │  │  GitHub Action  │  │
│  │   Plugin    │  │ (npm/brew)  │  │   (optional)    │  │
│  └──────┬──────┘  └──────┬──────┘  └────────┬────────┘  │
│         └────────────────┼──────────────────┘           │
│                          ▼                              │
│              ┌───────────────────────┐                  │
│              │      Core Engine      │                  │
│              │  (TypeScript/Node.js) │                  │
│              └───────────┬───────────┘                  │
│                          ▼                              │
│    ┌──────────┐  ┌──────────────┐  ┌──────────────┐    │
│    │  Presets │  │ Auto-Detect  │  │  Validators  │    │
│    │ Library  │  │    Engine    │  │   (Plugins)  │    │
│    └──────────┘  └──────────────┘  └──────────────┘    │
└─────────────────────────────────────────────────────────┘
```

---

## Auto-Detection Engine

Scans repo for markers to identify project type(s):

### Detection Rules

```typescript
const detectors = [
  {
    type: 'claude-plugin',
    primary: ['.claude-plugin/plugin.json'],
    secondary: ['skills/', 'commands/']
  },
  {
    type: 'npm-package',
    primary: ['package.json'],
    secondary: ['package-lock.json', 'node_modules/', 'tsconfig.json']
  },
  {
    type: 'python-package',
    primary: ['pyproject.toml', 'setup.py', 'setup.cfg'],
    secondary: ['uv.lock', 'ruff.toml', 'requirements.txt', 'Pipfile']
  },
  {
    type: 'docs-site',
    primary: ['mkdocs.yml', 'docusaurus.config.js'],
    secondary: ['docs/']
  },
  {
    type: 'monorepo',
    primary: ['pnpm-workspace.yaml', 'lerna.json'],
    secondary: ['packages/', 'apps/']
  },
  {
    type: 'generic',
    primary: ['README.md'],  // fallback
    secondary: []
  }
];
```

### Detection Logic

1. **Match primary markers** → Apply preset
2. **Check secondary markers** → Enable additional validators or sub-presets
3. **Multiple matches allowed** → Combine presets (e.g., npm-package + docs-site)

---

## Presets Library

Each preset defines which validators run and their configuration:

| Preset | Validators Enabled |
|--------|-------------------|
| `claude-plugin` | version-sync, links, inventory, relationships, schemas, completeness, content |
| `npm-package` | version-sync, links, package-json, dependencies, changelog, license |
| `python-package` | version-sync, links, pyproject, dependencies, changelog, license |
| `docs-site` | links, content-sections, spelling, broken-images |
| `monorepo` | version-sync (per-package), cross-package-deps, workspace-consistency |
| `generic` | links, readme-sections, license |

### Config Override (`.repo-keeper.json`)

```json
{
  "extends": "claude-plugin",
  "validators": {
    "links": { "checkExternal": true },
    "version-sync": { "exclude": ["CHANGELOG.md"] }
  },
  "custom": ["./my-validator.js"]
}
```

---

## Validator System

### Interface

```typescript
interface Validator {
  name: string;
  description: string;
  tier: 1 | 2 | 3;  // quick, standard, full

  // Check if this validator applies to the repo
  applies(context: RepoContext): boolean;

  // Run validation, return findings
  validate(context: RepoContext, options: ValidatorOptions): Finding[];
}

interface Finding {
  severity: 'error' | 'warning' | 'info';
  file?: string;
  line?: number;
  message: string;
  fix?: string;        // suggested fix description
  autofix?: () => void; // optional auto-fix function
}

interface RepoContext {
  root: string;
  detectedTypes: string[];
  config: RepoKeeperConfig;
  hasType(type: string): boolean;
  readFile(path: string): string;
  glob(pattern: string): string[];
}
```

### Built-in Validators

| Validator | Tier | What it checks |
|-----------|------|----------------|
| `version-sync` | 1 | Version consistency across files |
| `links` | 1 | Internal markdown link integrity |
| `inventory` | 1 | Inventory paths exist on filesystem |
| `relationships` | 1 | Cross-references between components |
| `schemas` | 1 | JSON schema compliance |
| `completeness` | 2 | Required files/sections present |
| `content` | 3 | Document quality, required sections |
| `external-links` | 3 | External URL reachability |
| `package-json` | 1 | package.json required fields |
| `dependencies` | 2 | Dependency freshness, vulnerabilities |
| `changelog` | 2 | CHANGELOG.md format and entries |
| `license` | 1 | License file exists |

### Custom Validators

Users create `repo-keeper/validators/my-check.js`:

```javascript
export default {
  name: 'no-console-logs',
  description: 'Ensure no console.log statements in production code',
  tier: 1,
  applies: (ctx) => ctx.hasType('npm-package'),
  validate: (ctx) => {
    const findings = [];
    for (const file of ctx.glob('src/**/*.ts')) {
      const content = ctx.readFile(file);
      const matches = content.matchAll(/console\.log\(/g);
      for (const match of matches) {
        findings.push({
          severity: 'warning',
          file,
          message: 'console.log found in production code',
          fix: 'Remove or replace with proper logging'
        });
      }
    }
    return findings;
  }
};
```

---

## CLI Interface

### Commands

```bash
# Basic usage - auto-detect and validate
repo-keeper

# Specify tier
repo-keeper --quick      # Tier 1 only (~10 sec)
repo-keeper --full       # All tiers (~2-5 min)

# Target specific validators
repo-keeper --only links,version-sync
repo-keeper --skip external-links

# Initialize config
repo-keeper init         # Interactive setup
repo-keeper init --preset claude-plugin

# Other commands
repo-keeper list         # Show detected type & active validators
repo-keeper fix          # Auto-fix what's possible
repo-keeper watch        # Re-run on file changes
```

### Output Formats

```bash
repo-keeper --format pretty   # Default, colored terminal output
repo-keeper --format json     # Machine-readable for CI
repo-keeper --format markdown # For PR comments
```

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All checks passed |
| 1 | Errors found |
| 2 | Warnings only |
| 3 | Configuration error |

---

## Claude Code Plugin

### Commands

```
/repo-keeper              # Run validation
/repo-keeper fix          # AI helps fix findings
/repo-keeper explain      # AI explains what each check does
/repo-keeper add-check    # AI helps create custom validator
```

### AI Value-Add

- **Explain findings** in context of the specific codebase
- **Suggest fixes** with actual code examples
- **Write custom validators** based on user requirements
- **Integrate with conversation** - remember previous findings

### Plugin Structure

```
plugins/repo-keeper/
├── plugin.json
├── commands/
│   └── repo-keeper.md     # Main slash command
├── skills/
│   ├── repo-validation/   # AI-assisted validation skill
│   └── fix-findings/      # AI-assisted fix skill
└── hooks/
    └── pre-commit.md      # Optional pre-commit integration
```

---

## Distribution

### NPM (Primary)

```bash
npm install -g repo-keeper
# or
npx repo-keeper
```

**Package structure:**
```
repo-keeper/
├── bin/repo-keeper.js     # CLI entry point
├── src/
│   ├── core/              # Detection, validation engine
│   │   ├── detector.ts
│   │   ├── runner.ts
│   │   └── reporter.ts
│   ├── validators/        # Built-in validators
│   │   ├── version-sync.ts
│   │   ├── links.ts
│   │   └── ...
│   └── presets/           # Preset definitions
│       ├── claude-plugin.ts
│       ├── npm-package.ts
│       └── ...
├── schemas/               # JSON schemas for validation
├── package.json
└── README.md
```

### Homebrew

```bash
brew tap sandbox-maxxing/repo-keeper
brew install repo-keeper
```

### Claude Code Plugin

```bash
claude plugins add repo-keeper
# Plugin auto-installs npm package if not present
```

---

## Migration Path

### Phase 1: Foundation (Current repo only)

**Goal:** Port existing bash scripts to TypeScript core

| Task | Current | Becomes |
|------|---------|---------|
| Port validators | `scripts/*.sh` | `src/validators/*.ts` |
| Create preset | `INVENTORY.json` structure | `presets/claude-plugin.ts` |
| Preserve schemas | `schemas/*.json` | `src/schemas/*.json` |
| Build runner | `run-all-checks.sh` | `src/core/runner.ts` |

**Deliverable:** CLI that works on sandbox-maxxing with same checks as current bash scripts

### Phase 2: Generalization

**Goal:** Make it work on any repo

- Add auto-detection engine
- Create additional presets (npm-package, python-package, docs-site)
- Add `.repo-keeper.json` config support
- Implement custom validator loading

**Deliverable:** CLI that auto-detects and validates common project types

### Phase 3: Distribution

**Goal:** Make it easy to install and use

- Publish to npm registry
- Create Homebrew tap
- Build Claude Code plugin wrapper
- Add `repo-keeper init` interactive setup
- Write documentation

**Deliverable:** Publicly available tool with multiple install methods

### Phase 4: Enhancement

**Goal:** Advanced features

- Auto-fix capabilities for common issues
- Watch mode for development
- GitHub Action template
- More presets (monorepo, rust, go, etc.)
- Web dashboard (optional)

**Deliverable:** Feature-complete repository health tool

---

## Current Gaps to Address

These gaps in the current bash implementation should be fixed during migration:

| Gap | Priority | Phase |
|-----|----------|-------|
| Orphan file detection (missing in Bash) | High | 1 |
| jq dependency issues | High | 1 |
| Hardcoded paths in PowerShell | Medium | 1 |
| External link checking (optional only) | Medium | 2 |
| No pre-commit hooks | Medium | 3 |
| No auto-fix capabilities | Low | 4 |
| No dependency vulnerability scanning | Low | 4 |

---

## Files to Create (Phase 1)

```
repo-keeper/
├── package.json
├── tsconfig.json
├── bin/
│   └── repo-keeper.ts
├── src/
│   ├── index.ts
│   ├── core/
│   │   ├── detector.ts      # Auto-detection engine
│   │   ├── runner.ts        # Validation orchestrator
│   │   ├── reporter.ts      # Output formatting
│   │   └── config.ts        # Config loading
│   ├── validators/
│   │   ├── index.ts
│   │   ├── version-sync.ts
│   │   ├── links.ts
│   │   ├── inventory.ts
│   │   ├── relationships.ts
│   │   ├── schemas.ts
│   │   ├── completeness.ts
│   │   └── content.ts
│   ├── presets/
│   │   ├── index.ts
│   │   └── claude-plugin.ts
│   └── types/
│       └── index.ts
├── schemas/
│   ├── inventory.schema.json
│   └── data-file.schema.json
└── README.md
```

---

## Success Criteria

### Phase 1 Complete When:
- [ ] `npx repo-keeper` runs on sandbox-maxxing
- [ ] Same findings as current bash scripts
- [ ] All 7 validators ported to TypeScript
- [ ] Tiered execution (--quick, default, --full) works

### Phase 2 Complete When:
- [ ] Auto-detects npm-package, python-package, docs-site
- [ ] Applies correct preset automatically
- [ ] Custom validators load from config
- [ ] `.repo-keeper.json` config works

### Phase 3 Complete When:
- [ ] Published to npm registry
- [ ] Homebrew tap available
- [ ] Claude Code plugin installable
- [ ] Documentation complete

### Phase 4 Complete When:
- [ ] Auto-fix works for common issues
- [ ] Watch mode functional
- [ ] GitHub Action template available
- [ ] 5+ presets available

---

## Notes

- **This is a reference plan** - implementation deferred until ready
- **Core engine in TypeScript** - for npm distribution and type safety
- **Bash scripts preserved** - as reference during migration
- **Backwards compatible** - current validation still works during development
