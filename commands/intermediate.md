---
description: [DEPRECATED] Intermediate mode has been removed in v4.0.0 - use Basic or Advanced instead
---

# ⚠️ Intermediate Mode Deprecated

**Intermediate mode has been deprecated in v4.0.0** and is no longer available.

## Why Was It Deprecated?

The intermediate mode sat between Basic and Advanced, but analysis showed:
- **90% of users** preferred either Basic (simple) or Advanced (security-focused)
- **Maintenance burden** - duplicated templates and workflows
- **Unclear positioning** - "standard" vs "basic" was confusing

## Migration Guide

Choose the mode that best fits your needs:

### Use Basic Mode Instead If:
- You want fast setup with minimal questions
- You're working on trusted code
- You don't need strict firewall controls
- Container isolation is sufficient for your security needs

```bash
/setup --basic
```

### Use Advanced Mode Instead If:
- You need security-focused configuration
- You want strict firewall with domain allowlist
- You're working in a team environment
- You need production-like security controls

```bash
/setup --advanced
```

## What's New in v4.0.0

All modes now include **planning mode**:
1. Claude scans your project and detects configuration
2. Creates a plan document for your approval
3. Implements only after you approve

This gives you the control that intermediate mode provided, but with clearer security posture.

---

**Last Updated:** 2025-12-22
**Version:** 4.0.0 (Deprecated)
