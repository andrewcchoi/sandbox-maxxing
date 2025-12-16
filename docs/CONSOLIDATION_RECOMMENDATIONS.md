# Documentation Consolidation Recommendations

This document outlines opportunities for future documentation consolidation to reduce duplication and improve maintainability. These are recommendations for future work, not immediate action items.

**Status:** Recommendations for v2.3.0 or later
**Priority:** Low (documentation is functional as-is)
**Last Updated:** 2025-12-16

## Overview

Following the v2.2.0 documentation cleanup, several consolidation opportunities have been identified. While the current documentation is complete and functional, reducing duplication would improve long-term maintainability.

## Recommendation 1: README.md Consolidation

### Current State

**README.md** (688 lines) contains detailed mode descriptions that duplicate content from:
- `docs/MODES.md` (915 lines) - Comprehensive mode comparison
- `examples/README.md` (411 lines) - Example-focused mode usage

### Duplication Analysis

| Section | README.md | MODES.md | Duplication Level |
|---------|-----------|----------|-------------------|
| Mode philosophy | Lines 52-158 | Lines 84-450 | High (80%+) |
| Key features | Lines 56-140 | Lines 10-80 | High (90%+) |
| Example dialogues | Lines 64-158 | Lines 96-450 | Medium (60%) |
| Quick reference | Lines 162-170 | Lines 6-22 | High (100%) |

### Recommendation

**Keep in README.md:**
- Brief 2-3 sentence summary per mode (< 10 lines each)
- Quick reference table (current lines 162-170)
- Links to detailed documentation

**Move to MODES.md:**
- Detailed philosophy and use cases
- Extended example dialogues
- Feature comparisons

**Example Consolidated README.md Section:**
```markdown
## Four-Mode System

Choose your development experience:

- **Basic** - Zero configuration, auto-detection, 1-2 minutes
- **Intermediate** - Balanced control and convenience, 3-5 minutes
- **Advanced** - Security-first with strict firewall, 8-12 minutes
- **YOLO** - Complete customization and control, 15-30 minutes

See [MODES.md](docs/MODES.md) for detailed comparison and selection guide.

### Quick Commands

| Command | Mode | Setup Time |
|---------|------|------------|
| `/sandbox:basic` | Basic | 1-2 min |
| `/sandbox:intermediate` | Intermediate | 3-5 min |
| `/sandbox:advanced` | Advanced | 8-12 min |
| `/sandbox:yolo` | YOLO | 15-30 min |

See [Commands Guide](commands/README.md) for full command documentation.
```

**Benefits:**
- README.md becomes scannable (reduce from 688 to ~400 lines)
- Single source of truth for mode details (MODES.md)
- Easier to maintain consistency

**Risks:**
- Users may prefer having details in README without clicking links
- GitHub README is the "front door" - may want more detail there

**Recommendation:** Implement in v2.3.0 with community feedback

---

## Recommendation 2: VARIABLES.md and SECRETS.md Delineation

### Current State

**VARIABLES.md** (500+ lines) and **SECRETS.md** (600+ lines) have overlapping content about credentials, passwords, and API keys.

### Overlap Analysis

| Topic | VARIABLES.md | SECRETS.md | Overlap |
|-------|--------------|------------|---------|
| Build ARGs | Detailed | Warning only | Low |
| Runtime ENV | Detailed | Basic | Medium |
| Passwords | "Don't use ENV" | How to handle | High |
| API Keys | "Don't use ENV" | How to handle | High |
| Docker secrets | Brief mention | Detailed | Low |
| VS Code inputs | Examples | Detailed | High |

### Recommendation

**VARIABLES.md Focus:** Non-sensitive configuration
- What variables are and how they work
- Build ARGs vs Runtime ENV
- Mode-specific variable configs
- **Warning box:** "For sensitive data, see [SECRETS.md](SECRETS.md)"
- Remove detailed password/API key examples (keep brief warnings)

**SECRETS.md Focus:** Sensitive credentials only
- Why secrets management matters
- Secret types and methods
- VS Code inputs for development credentials
- Docker secrets for production
- Build secrets for private registries
- **Reference:** "For non-sensitive config, see [VARIABLES.md](VARIABLES.md)"

**Example VARIABLES.md Header:**
```markdown
# Variables Guide

This guide covers **non-sensitive** configuration using environment variables and build arguments.

> **⚠️ For sensitive data (passwords, API keys, certificates):** See [Secrets Management Guide](SECRETS.md)

## Table of Contents
1. [Build Arguments (ARG)](#build-arguments-arg)
2. [Runtime Environment Variables (ENV)](#runtime-environment-variables-env)
3. [Container Environment (containerEnv)](#container-environment-containerenv)
...
```

**Benefits:**
- Clear separation of concerns
- Easier to find relevant information
- Reduced duplication (remove ~100 lines combined)

**Risks:**
- Users may need to check both files
- Some context useful in both places

**Recommendation:** Implement in v2.3.0

---

## Recommendation 3: Mode Comparison Tables

### Current State

Mode comparison tables appear in multiple locations:
1. `docs/MODES.md` - Lines 6-22, comprehensive tables
2. `examples/demo-app-sandbox-basic/README.md` - Lines 230-240
3. `examples/demo-app-sandbox-intermediate/README.md` - Lines 224-234
4. `examples/demo-app-sandbox-advanced/README.md` - Lines 430-440
5. `examples/demo-app-sandbox-yolo/README.md` - Lines 715-725

### Duplication Analysis

All example READMEs duplicate the same comparison table with minor variations:

| Feature | Basic | Intermediate | Advanced | YOLO |
|---------|-------|--------------|----------|------|
| Questions | 2-3 | 5-8 | 10-15 | 15-20+ |
| Setup time | 1-2 min | 3-5 min | 8-12 min | 15-30 min |
| ... | ... | ... | ... | ... |

### Recommendation

**Option A: Accept Duplication**
- Keep tables in each README for standalone readability
- Users can read example READMEs independently
- **Benefit:** No cross-file dependencies
- **Cost:** Maintenance burden (5 places to update)

**Option B: Shared Reference**
- Keep full table only in `docs/MODES.md`
- Example READMEs show 2-3 row summary with link
- **Benefit:** Single source of truth
- **Cost:** Users must follow link for full comparison

**Option C: Include File (Advanced)**
- Create `docs/_includes/mode-comparison-table.md`
- Use markdown include syntax (if supported by renderer)
- **Benefit:** DRY principle, easy updates
- **Cost:** May not work on all markdown renderers

### Recommendation

**Current Decision:** Accept duplication (Option A)
- Standalone documentation is valuable
- Tables are relatively stable
- Only ~15 lines per example README

**Future Decision:** If tables grow significantly or update frequency increases, reconsider Option B in v3.0

---

## Implementation Priority

| Recommendation | Priority | Effort | Impact | Suggested Version |
|----------------|----------|--------|--------|-------------------|
| README.md Consolidation | Medium | Medium | Medium | v2.3.0 |
| VARIABLES.md & SECRETS.md | Medium | Low | High | v2.3.0 |
| Mode Comparison Tables | Low | N/A | Low | Accept as-is |

## Implementation Approach

### Phase 1: Community Feedback (v2.2.0 - v2.3.0)
1. Share this document in GitHub Discussions
2. Gather feedback from users and contributors
3. Identify any additional consolidation opportunities
4. Refine recommendations based on feedback

### Phase 2: Implementation (v2.3.0)
1. Implement approved consolidations
2. Update cross-references
3. Verify all links work
4. Test documentation with new users

### Phase 3: Monitoring (v2.3.0+)
1. Monitor user feedback on consolidated docs
2. Adjust based on confusion or questions
3. Document lessons learned

## Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2025-12-16 | Defer to v2.3.0 | v2.2.0 focused on completeness and correctness |
| 2025-12-16 | Keep mode tables duplicated | Standalone readability valued over DRY |

## Questions for Community

1. **README.md Length**: Do you prefer detailed mode descriptions in README or brief summaries with links?
2. **VARIABLES vs SECRETS**: Is the overlap confusing? Would clearer separation help?
3. **Navigation**: Do you typically read docs top-to-bottom or jump to specific sections?
4. **Missing Topics**: Are there other documentation consolidation opportunities we missed?

## Alternatives Considered

### Alternative 1: Aggressive Consolidation
- Single `SETUP_GUIDE.md` with all mode, variable, and secret information
- **Rejected:** Too large, hard to navigate

### Alternative 2: No Consolidation
- Keep all duplication as-is
- **Rejected:** Maintenance burden over time

### Alternative 3: Wiki-Style Documentation
- Move to GitHub Wiki with better cross-linking
- **Rejected:** Markdown in repo is more maintainable

## References

- [Documentation Cleanup Plan](plans/2025-12-16-documentation-cleanup.md)
- [MODES.md](MODES.md) - Current mode comparison guide
- [VARIABLES.md](VARIABLES.md) - Current variables guide
- [SECRETS.md](SECRETS.md) - Current secrets guide

---

**Maintainer Notes:**
- Review this document before starting v2.3.0 planning
- Update decision log when implementing changes
- Archive when all recommendations implemented or rejected
