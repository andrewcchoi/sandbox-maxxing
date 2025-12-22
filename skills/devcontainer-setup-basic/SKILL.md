---
name: devcontainer-setup-basic
description: Use when user wants the simplest sandbox setup - uses sandbox templates or official images only, docker-compose when appropriate, no firewall (relies on sandbox isolation)
---

# Sandbox Setup: Basic Mode

## MANDATORY PLANNING PHASE

**Reference:** `skills/_shared/planning-phase.md`

Before executing any implementation steps, Claude MUST follow the shared planning workflow defined in `skills/_shared/planning-phase.md`. This includes:

1. **Project Discovery** - Scan directory, detect languages, check existing config
2. **Create Plan Document** - Write plan to `docs/plans/YYYY-MM-DD-devcontainer-setup.md`
3. **User Approval** - Present plan, ask questions, get approval

**After plan approval**, proceed to implementation below.

## NON-INTERACTIVE MODE (Automated Testing)

**CRITICAL: Check for automated test mode FIRST before any other action.**

If the user's message contains responses in this format:
```
AUTOMATED_TEST_MODE
RESPONSES:
response1
response2
...
```

Then:
1. **DO NOT call AskUserQuestion** - use provided responses instead
2. Extract responses into an array
3. Use responses sequentially when questions would normally be asked
4. Execute the entire skill workflow without interaction

**Response order for basic mode:**
1. Project name (e.g., "demo-app")
2. Additional languages (e.g., "none", "go", "rust", or comma-separated)
3. Services needed (e.g., "none", "postgres", "redis", or comma-separated)
4. Confirmation (e.g., "yes", "y")

## MODE CHARACTERISTICS

Basic mode is optimized for:
- **Simplicity** - Minimal questions (1-3 maximum)
- **Speed** - Fast setup (1-2 minutes)
- **Security** - No firewall (relies on Docker container isolation only)
- **Defaults** - Automatic detection and sensible defaults

## TASK IDENTITY

You are a **DevContainer Configuration Generator**. This is a file generation task.

**Your output:** VS Code DevContainer files in `.devcontainer/` directory
**Technology:** Docker, VS Code Dev Containers
**NOT related to:** Claude Code settings, Claude Code sandbox, `.claude/` configs

## MODE-SPECIFIC CONFIGURATION

### Firewall
**Template:** `skills/_shared/templates/init-firewall/disabled.sh`

Basic mode uses NO firewall - it relies on Docker container isolation only. This provides the simplest setup for rapid prototyping.

### User Questions (Planning Phase)
During planning, ask only if auto-detection fails:
1. **Project name** - If not inferrable from directory
2. **Additional languages** - If detected languages need confirmation
3. **Services** - If detected services need confirmation

**Maximum:** 1-3 questions total

### Defaults
- **Base image:** Auto-select based on detected project type
- **Extensions:** Minimal set from `skills/_shared/templates/extensions.json`
- **Firewall:** Disabled (container isolation only)
- **Services:** Only if clearly detected from dependencies

## IMPLEMENTATION WORKFLOW

After planning phase approval:

### Step 1: Copy Templates

```bash
# Template location
TEMPLATES="skills/_shared/templates"

# Create .devcontainer directory
mkdir -p .devcontainer

# Copy configuration files
cp "$TEMPLATES/docker-compose.yml" ./docker-compose.yml
cp "$TEMPLATES/setup-claude-credentials.sh" .devcontainer/setup-claude-credentials.sh
cp "$TEMPLATES/devcontainer.json" .devcontainer/devcontainer.json
cp "$TEMPLATES/.env.template" ./.env.template
cp "$TEMPLATES/extensions.json" .devcontainer/extensions.json
cp "$TEMPLATES/mcp.json" .devcontainer/mcp.json
cp "$TEMPLATES/variables.json" .devcontainer/variables.json
cp "$TEMPLATES/init-firewall/disabled.sh" .devcontainer/init-firewall.sh

# Make scripts executable
chmod +x .devcontainer/setup-claude-credentials.sh .devcontainer/init-firewall.sh
```

### Step 2: Compose Dockerfile

```bash
# Compose Dockerfile from base + detected language partials
compose_dockerfile() {
    local base_file="$TEMPLATES/base.dockerfile"
    local output_file=".devcontainer/Dockerfile"
    shift 2
    local partials=("$@")

    # Find composition marker
    local marker_line=$(grep -n "# === LANGUAGE PARTIALS ===" "$base_file" | cut -d: -f1)

    # Create output: everything before marker
    head -n "$marker_line" "$base_file" > "$output_file"
    echo "" >> "$output_file"

    # Insert each partial
    for partial in "${partials[@]}"; do
        local partial_file="$TEMPLATES/partial-${partial}.dockerfile"
        if [ -f "$partial_file" ]; then
            cat "$partial_file" >> "$output_file"
            echo "" >> "$output_file"
        fi
    done

    # Append everything after marker
    tail -n +$((marker_line + 1)) "$base_file" >> "$output_file"
}

# Compose with detected languages
compose_dockerfile "$TEMPLATES/base.dockerfile" ".devcontainer/Dockerfile" "${DETECTED_LANGUAGES[@]}"
```

### Step 3: Customize Placeholders

Use Edit tool to replace:
- `{{PROJECT_NAME}}` → actual project name
- `{{NETWORK_NAME}}` → `{project-name}-network`

In files:
- `docker-compose.yml`
- `.devcontainer/devcontainer.json`

### Step 4: Verify Files Created

```bash
echo "=== File Verification ==="
test -f docker-compose.yml && echo "✓ docker-compose.yml" || echo "✗ MISSING"
test -f .devcontainer/Dockerfile && echo "✓ Dockerfile" || echo "✗ MISSING"
test -f .devcontainer/devcontainer.json && echo "✓ devcontainer.json" || echo "✗ MISSING"
test -f .devcontainer/init-firewall.sh && echo "✓ init-firewall.sh" || echo "✗ MISSING"
test -f .devcontainer/setup-claude-credentials.sh && echo "✓ setup-claude-credentials.sh" || echo "✗ MISSING"
```

## REQUIRED OUTPUT FILES

| File | Location | Purpose |
|------|----------|---------|
| `Dockerfile` | `.devcontainer/Dockerfile` | Multi-stage Docker image |
| `devcontainer.json` | `.devcontainer/devcontainer.json` | VS Code DevContainer config |
| `setup-claude-credentials.sh` | `.devcontainer/setup-claude-credentials.sh` | Credentials helper (Issue #30) |
| `init-firewall.sh` | `.devcontainer/init-firewall.sh` | No-op firewall script |
| `docker-compose.yml` | `./docker-compose.yml` | Docker services |

## PROHIBITED FILES

Never create these files (wrong task):
- ❌ `.claude-code.json` - Claude Code config, NOT DevContainer
- ❌ `.claude/config.json` - Claude Code config, NOT DevContainer
- ❌ `Dockerfile` in project root - Should be in `.devcontainer/`

## DATA REFERENCES

Available data files in `skills/_shared/data/`:
- `allowable-domains.json` - Domain allowlist database
- `sandbox-templates.json` - Docker Hub image catalog
- `official-images.json` - Official Docker images reference

## POST-GENERATION VALIDATION

```bash
# Verify Dockerfile composition
grep -c "^FROM.*AS" .devcontainer/Dockerfile  # Should be >= 1
grep -q "git vim nano" .devcontainer/Dockerfile || echo "⚠ Missing core utilities"
grep -q "claude-code" .devcontainer/Dockerfile || echo "⚠ Missing Claude Code CLI"
wc -l .devcontainer/Dockerfile  # Should be >= 50 lines
```

## COMPLETION CHECKLIST

Before finishing:
- [ ] Plan document created and approved
- [ ] All 5 files created in correct locations
- [ ] Scripts are executable (`chmod +x`)
- [ ] Placeholders replaced with actual values
- [ ] Dockerfile composed with correct language partials
- [ ] Post-validation passed

## NEXT STEPS FOR USER

After setup complete, inform user:

```
Setup complete! Next steps:

1. Open project in Dev Container:
   - VS Code: Cmd/Ctrl+Shift+P → "Dev Containers: Reopen in Container"
   - Or: docker compose up -d

2. Verify services (if using docker-compose):
   docker compose ps

3. Install dependencies:
   - Python: uv add -r requirements.txt
   - Node.js: npm install

Your sandbox is ready to use!
```

---

**Last Updated:** 2025-12-22
**Version:** 4.0.0 (Planning Mode Integration)
**Related Issue:** #49
