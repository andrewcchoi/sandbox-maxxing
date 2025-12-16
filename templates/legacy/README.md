# Legacy Templates (Deprecated)

This directory contains deprecated monolithic templates from version 1.x of the plugin.

## What's Here

These templates were used in the original three-tier system (Basic/Advanced/Pro):

- **base/** - Flexible templates for Basic/Advanced modes
- **python/** - Python-optimized templates with FastAPI + PostgreSQL + Redis
- **node/** - Node.js-optimized templates with Express + MongoDB + Redis
- **fullstack/** - Full-stack templates with React + FastAPI + PostgreSQL

## Why Deprecated?

Version 2.0 introduced a modular, data-driven template system:

1. **Master Templates**: All configurations in `templates/master/` with section markers
2. **Modular Sections**: Service-specific configs in `templates/compose/`, `templates/dockerfiles/`, `templates/firewall/`
3. **Data-Driven**: Image and domain registries in `data/` directory
4. **Four Tiers**: Basic, Intermediate, Advanced, YOLO (replacing Basic/Advanced/Pro)

The new system generates templates dynamically by:
- Reading JSON data files for available options
- Extracting sections from master templates
- Combining sections based on user choices
- Customizing per tier requirements

## Migration

If you have custom modifications to these legacy templates:

1. Identify the customizations you made
2. Check if they're available in the new system via:
   - `data/official-images.json` - for image/version choices
   - `data/allowable-domains.json` - for firewall domains
   - `templates/master/` - for template structure
3. If not available, file an issue or:
   - Use YOLO tier for full customization
   - Manually modify generated configs after setup

## Should I Delete These?

**No, not yet.** Keep them for:
- Reference during migration
- Fallback if new system has issues
- Understanding what changed between versions

They may be removed in a future major version (3.0+).

## Version History

- **v1.0** (2025-01): Original monolithic templates
- **v2.0** (2025-12): Moved to legacy/, replaced with modular system
- **v3.0** (future): May be removed entirely

## Questions?

See:
- [ARCHITECTURE.md](/workspace/docs/ARCHITECTURE.md) - New template system
- [TIERS.md](/workspace/docs/TIERS.md) - Four-tier comparison
- [CHANGELOG.md](/workspace/CHANGELOG.md) - Version history
