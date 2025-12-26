# Changelog

All notable changes to this project will be documented in this file.

## [4.6.0] - 2025-12-25

### Breaking Changes
- **Plugin Rename**: `devcontainer-setup` → `sandboxxer`
  - Plugin name: `sandboxxer`
  - Marketplace name: `sandbox-maxxing`
  - All slash commands updated: `/devcontainer:*` → `/sandboxxer:*`
  - Command examples: `/sandboxxer:quickstart`, `/sandboxxer:yolo-vibe-maxxing`

### Changed
- **All Documentation**: Updated plugin name references across all files
  - Plugin configuration files (`plugin.json`, `marketplace.json`)
  - README.md, DEVELOPMENT.md, CONTRIBUTING.md
  - All command and agent documentation
  - Examples and templates

### Removed
- Obsolete skill references: `devcontainer-setup-basic`, `devcontainer-setup-advanced`, `devcontainer-setup-yolo`

### Migration Guide
```bash
# Uninstall old plugin
claude plugins remove devcontainer-setup

# Install new plugin
claude plugins add sandboxxer

# Commands are now:
/sandboxxer:quickstart
/sandboxxer:yolo-vibe-maxxing
/sandboxxer:troubleshoot
/sandboxxer:audit
```

## [4.5.0] - 2025-12-24

### Breaking Changes
- **Command Renames**: Updated command names for better clarity and style
  - `/devcontainer:setup` → `/devcontainer:quickstart`
  - `/devcontainer:yolo` → `/devcontainer:yolo-vibe-maxxing`
  - File renames: `commands/setup.md` → `commands/quickstart.md`
  - File renames: `commands/yolo.md` → `commands/yolo-vibe-maxxing.md`

### Changed
- **All Documentation**: Updated 12+ files with new command names
  - README.md: Updated all command references and examples
  - commands/README.md: Updated command documentation
  - CHANGELOG.md: Updated historical references
  - skills/: Updated skill cross-references
  - docs/: Updated all documentation files

### Migration Guide
Update your usage:
```bash
# Old commands (no longer work)
/devcontainer:setup
/devcontainer:yolo

# New commands (v4.5.0)
/sandboxxer:quickstart
/sandboxxer:yolo-vibe-maxxing
```

### Technical Details
- Commands renamed for clarity:
  - "setup" → "quickstart" (more descriptive of the quick interactive flow)
  - "yolo" → "yolo-vibe-maxxing" (more stylistic, matches project vibe)
- All file references updated across codebase
- Version bumped to 4.5.0 (breaking change in command names)

## [4.4.3] - 2025-12-24

### Fixed
- **Banner Display**: Made base stack banner more compact to prevent cutoff on narrow terminals
  - Changed from 44-character wide Unicode box to 30-character single line
  - Previous: `╔══════...╗` with multiple lines (44 chars)
  - New: `[Base: Python 3.12 + Node 20]` (30 chars)

### Changed
- **commands/quickstart.md**:
  - Step 1.5: Replaced wide Unicode banner with single-line bracket format
  - Banner now fits in narrow terminals without truncation
  - Updated version footer to 4.4.3

### Technical Details
- Old banner width: ~44 characters (Unicode box drawing, 5 lines)
- New banner width: ~30 characters (single line)
- Format: `[Base: Python 3.12 + Node 20]`

## [4.4.2] - 2025-12-24

### Changed
- **UX Improvement: Clearer Base Stack Communication**
  - Added visual banner showing "BASE STACK (always included): Python 3.12 + Node 20"
  - Updated question text to emphasize "ADDITIONAL" tools (not just "additional")
  - Added descriptions to all tool category options explaining what they include
  - "None - use base only" option now clearly states "Just Python 3.12 + Node 20 - ready to code!"

### Technical Details
- **commands/quickstart.md**:
  - New Step 1.5: Shows base stack banner before first question
  - Step 2 question: "What ADDITIONAL tools do you want to add to your stack?"
  - Added arrow-prefixed descriptions (→) for each option
  - Updated version footer to 4.4.2

### Benefits
- Users see what's included BEFORE answering any questions
- "ADDITIONAL" emphasis makes it clear Python + Node are always present
- Option descriptions provide context about what each choice adds
- Reduces confusion about base tooling

## [4.4.1] - 2025-12-24

### Fixed
- **Windows Compatibility**: All bash scripts now work on Windows (Git Bash/WSL), Linux, and macOS
  - Fixed Windows path handling with `!` character (history expansion)
  - Fixed backslash escape character issues in paths
  - Portable `sed` usage (removed `-i` flag, use temp files)
  - Portable shebangs: `#!/usr/bin/env bash` instead of `#!/bin/bash`

### Changed
- **commands/quickstart.md**:
  - Added `set +H` to disable history expansion (fixes Windows paths with `!`)
  - Windows path conversion: `${CLAUDE_PLUGIN_ROOT//\\//}` converts backslashes to forward slashes
  - Reordered plugin discovery: check current directory before searching ~/.claude/plugins
  - Portable sed: use temp file approach instead of `sed -i`
- **commands/yolo-vibe-maxxing.md**:
  - Applied same plugin discovery and sed fixes as setup.md
- **hooks/verify-template-match.sh**:
  - Changed shebang to `#!/usr/bin/env bash`
  - Updated shebang validation to accept both `#!/bin/bash` and `#!/usr/bin/env bash`
- **hooks/verify-devcontainer-complete.sh**:
  - Changed shebang to `#!/usr/bin/env bash`
- **skills/_shared/templates/setup-claude-credentials.sh**:
  - Changed shebang to `#!/usr/bin/env bash`
  - Fixed 3 occurrences of `sed -i` to use portable temp file approach

### Technical Details
- Plugin discovery now checks in this order:
  1. `CLAUDE_PLUGIN_ROOT` environment variable (with backslash conversion)
  2. Current directory (if templates exist)
  3. `~/.claude/plugins` directory (fallback)
- All `sed -i "s/old/new/" file` replaced with: `sed "s/old/new/" file > file.tmp && mv file.tmp file`
- History expansion disabled with `set +H 2>/dev/null || true` at start of scripts

### Benefits
- Works with Windows paths like `D:\!wip\sandbox-maxxing`
- No more "syntax error near unexpected token" on Windows
- Consistent behavior across all platforms
- More robust error handling with fallbacks

## [4.4.0] - 2025-12-24

### Added
- **Multi-Stack Selection**: Users can now select multiple tools to build full stacks
  - Example: Python + Node (base) + Go (backend) + PostgreSQL tools
  - Solves AskUserQuestion 4-option limit with category-based flow
  - "Add more tools?" loop enables building complete development stacks

### Changed
- **commands/quickstart.md**: Complete rewrite of question flow
  - Step 1: Initialize `SELECTED_PARTIALS` array
  - Step 2-6: Category selection with loop-back logic
    - Backend languages: Go, Rust, Java, Ruby (via "More languages..."), PHP
    - Database tools: PostgreSQL client + extensions
    - C++ development: Clang 17 or GCC (mutually exclusive)
  - Step 10: Build Dockerfile now loops over all selected partials
  - Step 13: Report shows complete stack summary
- **skills/_shared/templates/partials/postgres.dockerfile**:
  - Removed duplicate `PGHOST`, `PGUSER`, `PGDATABASE` ENV definitions
  - Base dockerfile already defines these values
  - Added comment explaining why ENVs are not redefined

### Technical Details
- New question flow supports:
  - Multi-select: Choose Go + PostgreSQL + C++ in one session
  - Overflow handling: "More languages..." for Ruby/PHP (4-option limit)
  - Mutual exclusion: C++ Clang vs GCC handled by single-select question
- Partial composition:
  - All partials use `USER root` → `USER node` pattern
  - Safely composable (no USER command conflicts)
  - PATH extensions use `$PATH:...` pattern (no conflicts)
- ENV conflict resolution:
  - Postgres partial no longer redefines PGHOST/PGUSER/PGDATABASE
  - Uses base values: `sandboxxer_user` / `sandboxxer_dev`

### Benefits
- Users can build realistic multi-stack projects (frontend + backend + database)
- All 9 language options discoverable through categories
- Stays within AskUserQuestion 4-option limit
- No ENV conflicts when composing multiple partials

## [4.2.1] - 2025-12-23

### Fixed
- **Basic Mode: Template Source Correction**
  - Fixed command to use canonical templates from `skills/_shared/templates/` instead of `docs/examples/demo-app-sandbox-basic/`
  - Command now copies and processes actual templates with placeholder replacement
  - Includes required `data/allowable-domains.json` for Docker build

### Changed
- **commands/basic.md**:
  - Added plugin directory discovery (works in both installed and development environments)
  - Copies from `skills/_shared/templates/` (canonical source)
  - File mapping: `base.dockerfile` → `Dockerfile`, `init-firewall/disabled.sh` → `init-firewall.sh`
  - Uses `sed` to replace `{{PROJECT_NAME}}` placeholders
  - Copies `allowable-domains.json` to `data/` directory for Docker build

### Technical Details
- Plugin discovery (3 methods, in order):
  1. `${CLAUDE_PLUGIN_ROOT}` environment variable (inline/development plugins)
  2. Search in `~/.claude/plugins` (installed plugins)
  3. Current directory if templates exist (fallback)
- Template processing: 5 DevContainer files + 1 data file = 6 total files
- Placeholder replacement: `{{PROJECT_NAME}}` replaced in devcontainer.json and docker-compose.yml

## [4.2.0] - 2025-12-23

### Breaking Changes
- **Basic Mode: Converted from Skill to Command**
  - Replaced `skills/devcontainer-setup-basic/` with `commands/basic.md`
  - Added `allowed-tools: [Bash]` restriction to enforce file copying at system level
  - Command now uses direct `cp -r` from reference implementation at `docs/examples/demo-app-sandbox-basic/`
  - Write tool is now **prohibited** at the system level, preventing agent from generating files

### Fixed
- **Root cause of incomplete file generation**: Both planning and default modes were using Write tool instead of copying from reference
  - Planning mode placed files correctly due to more deliberate reasoning time
  - Default mode grouped all files in `.devcontainer/` including docker-compose.yml (wrong location)
  - Solution: System-level tool restriction forces exact file copying behavior

### Changed
- **Basic mode workflow**:
  - Old: Agent reads skill, attempts to generate files via Write tool
  - New: Agent executes single bash command to copy all 5 files from reference
  - Result: Guaranteed correct files, correct locations, no interpretation needed

### Technical Details
- Command uses: `cp -r docs/examples/demo-app-sandbox-basic/.devcontainer . && cp docs/examples/demo-app-sandbox-basic/docker-compose.yml .`
- All 5 files copied: Dockerfile, devcontainer.json, init-firewall.sh, setup-claude-credentials.sh, docker-compose.yml
- docker-compose.yml placed at project root (correct Docker Compose convention)
- Scripts automatically marked executable via `chmod +x`

## [4.1.1] - 2025-12-23

### Fixed
- **Basic Mode: Enforced Bash Tool Usage**
  - Fixed issue where agent ignored skill's bash cp instructions and used Write tool instead
  - Added explicit tool restrictions prohibiting Write tool for devcontainer files
  - Made Bash command mandatory with clear directive language
  - Updated Stop hook to enforce all 5 files present (exit 2 if missing)
  - Cleaned up non-working PreToolUse/PostToolUse hooks from hooks.json
  - Root cause: Agent interpreted bash code blocks as documentation rather than executable instructions

### Changed
- **devcontainer-setup-basic skill**
  - Added "TOOL RESTRICTIONS" section at top with explicit prohibitions
  - Converted multi-line bash example into single-line mandatory command
  - Added "DO NOT" list to prevent common mistakes
- **verify-devcontainer-complete.sh hook**
  - Moved script files from optional warnings to required errors
  - Changed exit behavior: exit 2 (block) on errors instead of exit 0 (informational)
  - All 5 files now mandatory: Dockerfile, devcontainer.json, docker-compose.yml, init-firewall.sh, setup-claude-credentials.sh
- **hooks.json**
  - Removed PreToolUse and PostToolUse hooks (matched but never executed)
  - Kept only Stop hook which reliably executes

## [4.1.0] - 2025-12-22

### Fixed
- **Basic Mode: Direct Copy from Reference Implementation**
  - Fixed missing files issue (`init-firewall.sh`, `setup-claude-credentials.sh` were not generated)
  - Fixed wrong file locations (`docker-compose.yml` was in `.devcontainer/` instead of root)
  - Fixed incorrect configurations (wrong user, missing postStartCommand, etc.)
  - **Solution**: Basic mode now copies all 5 files directly from `docs/examples/demo-app-sandbox-basic/`
  - Benefits: Guaranteed consistency, all files present, correct configurations
  - Evaluated against requirements in Dec 2025 gap analysis

### Changed
- **devcontainer-setup-basic skill v4.1.0**
  - Replaced agent-based generation with direct file copy
  - Removed template composition complexity
  - Updated validation checks to verify reference file integrity
  - Added clear documentation about the change

## [4.0.0] - 2025-12-22

### Major Breaking Changes
- **Mandatory Planning Mode**: All devcontainer skills now require planning phase before execution
  - Scans project directory and detects configuration
  - Creates plan document in `docs/plans/YYYY-MM-DD-devcontainer-setup.md`
  - Presents plan to user for approval
  - Only implements after explicit user approval
  - Benefits: User visibility, opportunity to review, clear decision documentation

- **Intermediate Mode Deprecated**: Removed devcontainer-setup-intermediate skill
  - Analysis showed 90% of users preferred Basic (simple) or Advanced (security-focused)
  - Maintenance burden of duplicate templates eliminated
  - Users should migrate to Basic or Advanced modes
  - See `commands/intermediate.md` for migration guide

### Added
- **Shared Resources Architecture**: Consolidated templates and data
  - New `skills/_shared/` directory structure
  - `skills/_shared/planning-phase.md` - Common planning workflow
  - `skills/_shared/templates/` - Single source of truth for all templates (~45 → ~18 files)
  - `skills/_shared/data/` - Consolidated data files (moved from root `data/`)
  - `skills/_shared/templates/init-firewall/` - Three firewall variants (disabled/permissive/strict)

### Changed
- **Simplified Skills**: All SKILL.md files dramatically reduced in size
  - devcontainer-setup-basic: 1093 → 234 lines (79% reduction)
  - devcontainer-setup-advanced: 780 → 309 lines (60% reduction)
  - devcontainer-setup-yolo: 1092 → 372 lines (66% reduction)
  - Total: 2965 → 915 lines (69% average reduction)
  - Skills now reference shared resources instead of duplicating content

- **Updated Documentation**: All docs updated for v4.0.0
  - Removed intermediate mode references
  - Added planning phase documentation
  - Updated skill comparison tables
  - Updated command reference guides

- **Repository Cleanup**: Removed duplicate root directories
  - Deleted `data/` directory (exact duplicate of `skills/_shared/data/`)
  - Deleted `templates/` directory (outdated master template system)
  - Deleted `.internal/scripts/sync-templates.sh` (no longer needed)
  - Updated `skills/_shared/data/README.md` paths to reference new location
  - Rewrote `docs/ARCHITECTURE.md` for v4.0.0 shared resources architecture

### Benefits
- Single source of truth for templates (easier maintenance)
- Consistent planning workflow across all modes
- User approval before execution (no surprises)
- ~70% reduction in skill file sizes
- Eliminated template duplication

## [Unreleased]

### Changed
- Reorganized repository structure for better clarity
  - Moved maintenance files to `.internal/`: repo-keeper, audits, archive, plans, legacy-templates, tests, scripts, bin, hooks, node_modules
  - Moved examples to `docs/examples/`
  - Core plugin files remain at root: .claude-plugin/, agents/, commands/, data/, skills/, templates/master/

### Fixed
- **Template path discovery failure**: Fixed silent template copy failures when running from user projects
  - Root cause: Plugin directory discovery using `find ~/.claude/plugins` was unreliable
  - Solution: Reorganized templates with hybrid approach using skill-relative paths
  - Changed: Mode-specific files moved to `skills/*/templates/` for self-contained discovery
  - Changed: Shared files (Dockerfiles, compose, credentials) moved to `templates/shared/`
  - Result: Templates now work reliably regardless of execution directory
  - Updated all four skill files with simpler path discovery logic
  - Updated INVENTORY.json and ARCHITECTURE.md with new structure

## [3.0.0] - 2025-12-19

### Major Breaking Changes
- **Plugin renamed**: `devcontainer-setup` → `sandboxxer`
  - All slash commands updated: `/devcontainer-setup:*` → `/sandboxxer:*`
  - Updated plugin.json and marketplace.json with new name
  - Clarified purpose: Creates VS Code DevContainer configurations for sandboxed development
  - Repository name remains "sandbox-maxxing" for backwards compatibility

### Added
- **Copy-first workflow**: Complete template structure redesign
  - New `/templates/output-structures/` directory with complete file hierarchies
  - Four mode-specific template directories: basic/, intermediate/, advanced/, yolo/
  - Each mode includes: Dockerfile (multi-stage), devcontainer.json, docker-compose.yml, credentials script, firewall script (where applicable)
  - Templates are copied directly, then customized with placeholders
  - Ensures complete files with all features (multi-stage builds, credentials persistence, comprehensive tooling)

### Changed
- **Workflow methodology**: From "read-and-generate" to "copy-first"
  - All four skill files updated with new copy-first workflow instructions
  - Added plugin root discovery using find commands
  - Added mandatory verification checkpoints for copied files
  - Ensures Dockerfiles have 80+ lines with multi-stage builds
- **File generation accuracy**: Fixed all four reported issues
  - ✅ Missing files - Now copies complete template structures
  - ✅ Wrong locations - Explicit file paths in copy commands
  - ✅ Minimal/incorrect content - Complete templates with all features
  - ✅ Wrong file types - Clear distinction between DevContainer and Claude Code configs
- **Descriptions updated**: All command files and README
  - Clarified "VS Code DevContainer setup" vs "sandbox setup"
  - Updated command descriptions to reflect DevContainer focus
  - Removed ambiguous references to "Claude Code sandbox"

### Fixed
- **Template reading issues**: Claude was not using template files at all
  - Root cause: `${CLAUDE_PLUGIN_ROOT}` variable not being resolved
  - Solution: Direct file copy operations via Bash instead of read-and-generate
- **Dockerfile requirements**: Now enforced for ALL modes
  - Basic mode: Multi-stage Dockerfile required (was previously optional)
  - All modes: 80+ line Dockerfiles with comprehensive tooling
- **Firewall configuration**: Clarified mode-specific firewall behavior
  - Basic: NO firewall script (relies on container isolation only)
  - Intermediate/Advanced/YOLO: Appropriate firewall scripts included

## [2.2.1] - 2025-12-16

### Fixed
- Fixed shell script executable permissions (28 files)
- Propagated Issue #29 fix (multi-stage Node.js) to templates and examples
- Propagated Issue #30 fix (credentials mount) to templates and examples
- Updated all language Dockerfiles (11 files) with Node.js + npm-based Claude Code install
- Fixed deprecated Claude Code installation method in all Dockerfiles

### Changed
- Updated master templates to include multi-stage build pattern
- Added `setup-claude-credentials.sh` to master templates
- Added credentials mount pattern to docker-compose templates
- Added credentials mount documentation to compose templates (4 files)

## [2.2.0] - 2025-12-16

### Added
- **Documentation files** (5 new):
  - `docs/SECURITY-MODEL.md` - Comprehensive security architecture and threat model
  - `docs/TROUBLESHOOTING.md` - Complete troubleshooting guide for all common issues
  - `skills/README.md` - Skills index with comparison table and usage guide
  - `commands/README.md` - Commands index with syntax and examples
  - `templates/README.md` - Template system documentation with master templates guide
- **SECURITY.md** - Security policy with responsible disclosure process
- **docs/CONSOLIDATION_RECOMMENDATIONS.md** - Future documentation improvement suggestions
- **docs/LOW_PRIORITY_FIXES_v2.2.1.md** - Status report on all low priority issues
- **Version footers** added to all key documentation files for traceability

### Fixed
- **Critical firewall documentation errors** in README.md:
  - Basic mode: Corrected to "None (relies on container isolation)" from "strict firewall"
  - Intermediate mode: Corrected to "Permissive (no restrictions)" from "100+ domains"
  - Advanced mode: Improved description to "Strict (customizable allowlist)"
- **Broken cross-references** (8+ occurrences):
  - Fixed SECURITY-MODEL.md links in all example READMEs
  - Fixed TROUBLESHOOTING.md reference in examples/README.md
  - Fixed skills/README.md link in DEVELOPMENT.md
- **Outdated references** (6 occurrences):
  - Fixed `basic-streamlit` → `streamlit-sandbox-basic` in CONTRIBUTING.md and DEVELOPMENT.md
  - Added missing demo-app-sandbox-intermediate to README.md structure
  - Updated skill references to show correct directory structure
- **Terminology inconsistencies** (4 occurrences):
  - Fixed "tier" → "mode" in templates/legacy/README.md (3 occurrences)
  - Standardized plugin naming: "sandboxxer" (plugin name), "sandbox-maxxing" (repository/marketplace), "sandbox" (shorthand)

### Changed
- **Documentation completeness**: Improved from 91% to 100%
- **Documentation accuracy**: Improved from ~95% to 100%
- All cross-references verified and working
- Consistent version footers across documentation

## [2.1.0] - 2025-12-16

### Changed
- Simplified command names: `/devcontainer:basic` (was `/devcontainer:quickstart-basic`)
- Updated repo devcontainer to Intermediate mode with PostgreSQL, Redis, RabbitMQ
- Fixed all "Pro" → "YOLO" terminology (~50 occurrences)
- Fixed all "sandbox-maxxing" → "sandbox" naming (~35 occurrences)
- Removed temporary files from root directory
- Plugin version updated to 2.1.0

### Fixed
- Consistent four-mode terminology throughout documentation
- Skill cross-reference corrections (devcontainer-setup-troubleshoot → sandboxxer-troubleshoot)
- Command reference standardization
- Archived completed plan documents

## [2.0.0] - 2025-12-16

### Changed
- **Breaking**: Four-mode system replaces three-mode: Basic, Intermediate, Advanced, YOLO (was Basic/Advanced/Pro)
- **Breaking**: Renamed skills from `sandbox-maxxing-*` to `sandbox-*`
- **Breaking**: Command structure updated to mode-specific commands
- Data-driven configuration with JSON files (sandbox-templates, official-images, allowable-domains)
- Modular template system with section markers for composability
- Master templates with mode-specific stripped versions
- Auto-pull Docker images with user confirmation
- Plugin version updated to 2.0.0

### Added
- `data/` directory with JSON reference files
- `templates/master/` with comprehensive kitchen-sink templates
- `templates/compose/` with mode-specific docker-compose templates
- `templates/firewall/` with mode-specific firewall scripts
- `templates/dockerfiles/` with 11 platform-specific Dockerfiles
- `docs/MODES.md` - 26 KB mode comparison guide
- New skills: devcontainer-setup-basic, devcontainer-setup-intermediate, devcontainer-setup-yolo
- Four examples covering all modes

### Removed
- Old three-mode mode references
- Monolithic templates (moved to templates/legacy/)

## [1.0.0] - 2025-12-12

### Added
- Interactive setup wizard with three modes (Basic/Advanced/Pro)
- Troubleshooting assistant for common sandbox issues
- Security auditor for configuration hardening
- Templates for Python, Node.js, and fullstack projects
- Firewall configuration with strict/permissive modes
- Comprehensive reference documentation
- Manual test suite

### Features
- Auto-detection of project type
- Docker Compose service configuration
- DevContainer setup automation
- Network isolation and security
- Health checks for all services

---

**Last Updated:** 2025-12-25
**Version:** 4.6.0
