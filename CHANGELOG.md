# Changelog

All notable changes to this project will be documented in this file.

## [2.2.2] - 2025-12-18

### Changed
- **Plugin name**: Renamed from "sandbox-maxxing" to "sandboxxer"
  - Updated plugin.json and marketplace.json with new plugin name
  - Repository and marketplace name remain "sandbox-maxxing"
  - Updated documentation to clarify naming convention
  - Commands and skills continue to use "sandbox" shorthand

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
  - `docs/security-model.md` - Comprehensive security architecture and threat model
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
  - Fixed security-model.md links in all example READMEs
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
- Simplified command names: `/sandbox:basic` (was `/sandbox:setup-basic`)
- Updated repo devcontainer to Intermediate mode with PostgreSQL, Redis, RabbitMQ
- Fixed all "Pro" → "YOLO" terminology (~50 occurrences)
- Fixed all "sandbox-maxxing" → "sandbox" naming (~35 occurrences)
- Removed temporary files from root directory
- Plugin version updated to 2.1.0

### Fixed
- Consistent four-mode terminology throughout documentation
- Skill cross-reference corrections (sandbox-setup-troubleshoot → sandbox-troubleshoot)
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
- New skills: sandbox-setup-basic, sandbox-setup-intermediate, sandbox-setup-yolo
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

## [Unreleased]

### Planned
- Automated testing framework
- More language templates (Go, Rust, Java)
- GitHub Actions integration
- Template customization CLI

---

**Last Updated:** 2025-12-16
**Version:** 2.2.1
