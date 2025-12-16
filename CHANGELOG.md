# Changelog

All notable changes to this project will be documented in this file.

## [2.1.0] - 2025-12-16

### Changed
- Simplified command names: `/sandbox:basic` (was `/sandbox:setup-basic`)
- Updated repo devcontainer to Intermediate tier with PostgreSQL, Redis, RabbitMQ
- Fixed all "Pro" → "YOLO" terminology (~50 occurrences)
- Fixed all "windows-sandbox" → "sandbox" naming (~35 occurrences)
- Removed temporary files from root directory
- Plugin version updated to 2.1.0

### Fixed
- Consistent four-tier terminology throughout documentation
- Skill cross-reference corrections (sandbox-setup-troubleshoot → sandbox-troubleshoot)
- Command reference standardization
- Archived completed plan documents

## [2.0.0] - 2025-12-16

### Changed
- **Breaking**: Four-tier system replaces three-tier: Basic, Intermediate, Advanced, YOLO (was Basic/Advanced/Pro)
- **Breaking**: Renamed skills from `windows-sandbox-*` to `sandbox-*`
- **Breaking**: Command structure updated to tier-specific commands
- Data-driven configuration with JSON files (sandbox-templates, official-images, allowable-domains)
- Modular template system with section markers for composability
- Master templates with tier-specific stripped versions
- Auto-pull Docker images with user confirmation
- Plugin version updated to 2.0.0

### Added
- `data/` directory with JSON reference files
- `templates/master/` with comprehensive kitchen-sink templates
- `templates/compose/` with tier-specific docker-compose templates
- `templates/firewall/` with tier-specific firewall scripts
- `templates/dockerfiles/` with 11 platform-specific Dockerfiles
- `docs/TIERS.md` - 26 KB tier comparison guide
- New skills: sandbox-setup-basic, sandbox-setup-intermediate, sandbox-setup-yolo
- Four examples covering all tiers

### Removed
- Old three-tier mode references
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
