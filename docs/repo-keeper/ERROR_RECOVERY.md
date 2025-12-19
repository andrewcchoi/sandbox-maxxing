# Error Recovery Guide

**Last Updated:** 2025-12-18
**Version:** 3.0.0

This guide explains how to handle validation failures and recover from common errors detected by repo-keeper scripts.

## Quick Recovery Steps

1. **Identify the failing check** - Review script output for specific errors
2. **Locate the problem** - Check file paths and line numbers in error messages
3. **Apply the fix** - Follow the specific recovery steps below
4. **Re-run validation** - Confirm the issue is resolved
5. **Commit the fix** - Document what was fixed in commit message

## Common Error Scenarios

### 1. Version Mismatch Errors

**Detected by:** `check-version-sync.sh`

**Error Example:**
```
[ERROR] data/secrets.json: 2.1.0 (expected: 2.2.1)
[ERROR] data/variables.json: 2.1.0 (expected: 2.2.1)
```

**Recovery Steps:**

1. Get the correct version from plugin.json:
   ```bash
   grep '"version"' .claude-plugin/plugin.json
   ```

2. Update each file with version mismatch:
   ```bash
   # Edit the file
   vim data/secrets.json

   # Change:
   "version": "2.1.0"

   # To:
   "version": "2.2.1"
   ```

3. Re-run validation:
   ```bash
   ./docs/repo-keeper/scripts/check-version-sync.sh
   ```

4. Commit the fix:
   ```bash
   git add data/secrets.json data/variables.json
   git commit -m "fix: sync data file versions to 2.2.1"
   ```

**Prevention:** Update versions in one commit using search-replace across all files

---

### 2. Broken Internal Links

**Detected by:** `check-links.sh`

**Error Example:**
```
[BROKEN] docs/GUIDE.md:45
  Text: Installation Guide
  URL: ../guides/install.md
  Resolved to: docs/guides/install.md (NOT FOUND)
```

**Recovery Steps:**

1. Locate the correct file:
   ```bash
   find . -name "install.md" -o -name "*install*.md"
   ```

2. Update the link in the source file:
   ```bash
   # If file moved to docs/setup/install.md:
   vim docs/GUIDE.md

   # Change line 45:
   [Installation Guide]\(../guides/install.md)

   # To:
   [Installation Guide]\(setup/install.md)
   ```

3. Re-run validation:
   ```bash
   ./docs/repo-keeper/scripts/check-links.sh
   ```

**Alternative:** If file was deleted intentionally, remove the broken link or update to point to new location

**Prevention:**
- Use grep before renaming/moving files: `grep -r "old-filename.md" .`
- Run link check before committing file moves

---

### 3. Missing Inventory Entries

**Detected by:** `validate-inventory.sh`

**Error Example:**
```
[MISSING] skills/new-skill/SKILL.md
[MISSING] commands/new-command.md
```

**Recovery Steps:**

1. Check if files exist:
   ```bash
   ls -la skills/new-skill/SKILL.md
   ls -la commands/new-command.md
   ```

2. If files exist, add to INVENTORY.json:
   ```bash
   vim docs/repo-keeper/INVENTORY.json
   ```

3. Add entries in appropriate sections:
   ```json
   "skills": [
     {
       "name": "new-skill",
       "path": "skills/new-skill/SKILL.md",
       "description": "Description here",
       "mode": "intermediate"
     }
   ],
   "commands": [
     {
       "name": "new-command",
       "path": "commands/new-command.md"
     }
   ]
   ```

4. Re-run validation:
   ```bash
   ./docs/repo-keeper/scripts/validate-inventory.sh
   ```

**Alternative:** If files don't exist, remove from inventory or create the missing files

**Prevention:** Update inventory immediately when adding/removing files

---

### 4. Schema Validation Failures

**Detected by:** `validate-schemas.sh`

**Error Example:**
```
[ERROR] data/secrets.json - Schema validation failed
  data/categories should be object
```

**Recovery Steps:**

1. Check the schema definition:
   ```bash
   cat docs/repo-keeper/schemas/secrets.schema.json
   ```

2. Validate JSON syntax first:
   ```bash
   node -e "JSON.parse(require('fs').readFileSync('data/secrets.json'))"
   ```

3. Fix structure to match schema:
   ```bash
   vim data/secrets.json

   # Ensure structure matches:
   {
     "version": "2.2.1",
     "description": "...",
     "categories": {
       "git_auth": { ... }
     }
   }
   ```

4. Re-run validation:
   ```bash
   ./docs/repo-keeper/scripts/validate-schemas.sh
   ```

**Common Schema Issues:**
- Missing required fields (version, description)
- Wrong data types (string vs object)
- Extra/unknown properties
- Invalid enum values

**Prevention:** Use schema-aware editors (VSCode with JSON schema extension)

---

### 5. Missing Documentation

**Detected by:** `validate-completeness.sh`

**Error Example:**
```
[ERROR] Skill 'sandbox-security' missing documentation
[ERROR] Mode 'yolo' missing in skill 'sandbox-setup'
```

**Recovery Steps:**

1. **Missing skill documentation:**
   ```bash
   # Create the documentation file
   vim docs/skills/sandbox-security.md

   # Add content:
   # # Sandbox Security Skill
   # ## Overview
   # ...
   ```

2. **Missing mode in skill:**
   ```bash
   # Add mode-specific content
   vim skills/sandbox-setup/SKILL.md

   # Add yolo mode section
   ```

3. Re-run validation:
   ```bash
   ./docs/repo-keeper/scripts/validate-completeness.sh
   ```

**Prevention:** Use template when creating new features to ensure all required content exists

---

### 6. Content Validation Errors

**Detected by:** `validate-content.sh`

**Error Example:**
```
[ERROR] sandbox-security missing: Usage Examples
```

**Recovery Steps:**

1. Check what sections exist:
   ```bash
   grep -i "^#" skills/sandbox-security/SKILL.md
   ```

2. Add missing section:
   ```bash
   vim skills/sandbox-security/SKILL.md

   # Add at appropriate location:
   ## Usage
   ...

   ## Examples
   ...
   ```

3. Re-run validation:
   ```bash
   ./docs/repo-keeper/scripts/validate-content.sh
   ```

**Required Sections for SKILL.md:**
- Overview
- Usage
- Examples
- Footer (with version)

**Prevention:** Follow SKILL.md template when creating new skills

---

### 7. Invalid Template Variables

**Detected by:** `validate-templates.sh`

**Error Example:**
```
[WARNING] templates/env/.env.advanced - Bare $ variable (should use ${VAR})
[WARNING] templates/variables/variables.yolo.json - References undefined variable: DATABASE_HOST
```

**Recovery Steps:**

1. **Fix bare variables:**
   ```bash
   vim templates/env/.env.advanced

   # Change:
   $DATABASE_URL

   # To:
   ${DATABASE_URL}
   ```

2. **Fix undefined variable references:**
   ```bash
   vim templates/variables/variables.yolo.json

   # Either define the variable:
   "DATABASE_HOST": "localhost"

   # Or remove the reference in derived_vars:
   "DATABASE_URL": "postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}"
   ```

3. Re-run validation:
   ```bash
   ./docs/repo-keeper/scripts/validate-templates.sh
   ```

**Prevention:** Use template variable checklist when creating new variables files

---

### 8. Dockerfile Errors

**Detected by:** `validate-dockerfiles.sh`

**Error Example:**
```
[ERROR] templates/dockerfiles/Dockerfile.test - Must start with FROM or ARG
[WARNING] Dockerfile.node - MAINTAINER is deprecated, use LABEL instead
```

**Recovery Steps:**

1. **Fix missing FROM:**
   ```bash
   vim templates/dockerfiles/Dockerfile.test

   # Add at the top:
   FROM ubuntu:22.04
   ```

2. **Replace MAINTAINER:**
   ```bash
   vim templates/dockerfiles/Dockerfile.node

   # Change:
   MAINTAINER Your Name <your.email@example.com>

   # To:
   LABEL maintainer="Your Name <your.email@example.com>"
   ```

3. Re-run validation:
   ```bash
   ./docs/repo-keeper/scripts/validate-dockerfiles.sh
   ```

**Prevention:** Use Dockerfile linter (hadolint) during development

---

### 9. Docker Compose Errors

**Detected by:** `validate-compose.sh`

**Error Example:**
```
[ERROR] docker-compose.yml - Missing 'services:' key
[WARNING] docker-compose.advanced.yml - Service 'web' missing 'image' or 'build'
```

**Recovery Steps:**

1. **Fix missing services key:**
   ```bash
   vim docker-compose.yml

   # Add:
   services:
     app:
       image: node:20
   ```

2. **Add missing image/build:**
   ```bash
   vim docker-compose.advanced.yml

   # Add either:
   services:
     web:
       image: nginx:latest

   # Or:
   services:
     web:
       build: ./web
   ```

3. Re-run validation:
   ```bash
   ./docs/repo-keeper/scripts/validate-compose.sh
   ```

**Prevention:** Use docker-compose config to validate before committing

---

## Batch Error Recovery

When multiple validation scripts fail:

### 1. Prioritize Fixes

**Tier 1 (Critical):**
1. Version sync errors
2. Schema validation failures
3. Broken links
4. Missing inventory entries

**Tier 2 (Important):**
5. Missing documentation
6. Content validation errors

**Tier 3 (Nice to have):**
7. Template/Dockerfile/Compose warnings

### 2. Fix in Order

```bash
# 1. Fix version sync
./docs/repo-keeper/scripts/check-version-sync.sh
# Fix issues, commit

# 2. Fix schemas
./docs/repo-keeper/scripts/validate-schemas.sh
# Fix issues, commit

# 3. Fix links
./docs/repo-keeper/scripts/check-links.sh
# Fix issues, commit

# 4. Run all checks
./docs/repo-keeper/scripts/run-all-checks.sh
```

### 3. Bulk Operations

**Update multiple file versions:**
```bash
# Find all files with old version
grep -r "2.1.0" --include="*.json" --include="*.md"

# Replace with new version
find . -type f \( -name "*.json" -o -name "*.md" \) -exec sed -i 's/2\.1\.0/2.2.1/g' {} +

# Verify changes
git diff
```

**Fix multiple broken links:**
```bash
# Get list of broken links
./docs/repo-keeper/scripts/check-links.sh | grep BROKEN > broken-links.txt

# Fix each one systematically
vim broken-links.txt  # Review
# Fix each file
```

---

## Prevention Strategies

### Pre-Commit Checks

Add to `.git/hooks/pre-commit`:
```bash
#!/bin/bash
echo "Running pre-commit validation..."
./docs/repo-keeper/scripts/run-all-checks.sh --quick
if [ $? -ne 0 ]; then
    echo "Validation failed. Fix issues before committing."
    exit 1
fi
```

### PR Template Checklist

- [ ] Ran `run-all-checks.sh --quick` successfully
- [ ] Updated version if needed
- [ ] Added new files to INVENTORY.json
- [ ] Verified no broken links
- [ ] Updated documentation for changes

### IDE Integration

**VSCode tasks.json:**
```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Validate Repository",
      "type": "shell",
      "command": "./docs/repo-keeper/scripts/run-all-checks.sh --quick",
      "problemMatcher": []
    }
  ]
}
```

---

## Getting Help

If you're stuck:

1. **Check script output** - Error messages are descriptive
2. **Review documentation** - [README.md](./README.md), [EXIT_CODES.md](./EXIT_CODES.md)
3. **Check examples** - Look at similar files that pass validation
4. **Ask for help** - Create GitHub issue with:
   - Script that failed
   - Full error output
   - Steps you tried
   - File content (if relevant)

---

**Related Documentation:**
- [EXIT_CODES.md](./EXIT_CODES.md) - Understanding exit codes
- [README.md](./README.md) - Main documentation
- [ORGANIZATION_CHECKLIST.md](./ORGANIZATION_CHECKLIST.md) - Maintenance checklist
- [schemas/README.md](./schemas/README.md) - Schema documentation
