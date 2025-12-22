---
name: devcontainer-setup-yolo
description: Use when user wants full customization with no restrictions - unofficial images allowed, optional firewall, complete control over all settings
---

# Sandbox Setup: YOLO Mode

## WARNING - READ THIS FIRST

```
╔═══════════════════════════════════════════════════════════════╗
║                    YOLO MODE ACTIVATED                        ║
║                                                               ║
║  You are in full control. This mode:                         ║
║  • Allows unofficial Docker images (security risk)           ║
║  • Does not enforce firewall restrictions                    ║
║  • Provides no security guardrails                           ║
║  • Permits experimental and untested configurations          ║
║                                                               ║
║  Ensure you understand the security implications.            ║
╔═══════════════════════════════════════════════════════════════╗
```

**DISPLAY THIS WARNING** prominently at the start of every YOLO mode session.

## MANDATORY PLANNING PHASE

**Reference:** `skills/_shared/planning-phase.md`

Before executing any implementation steps, Claude MUST follow the shared planning workflow defined in `skills/_shared/planning-phase.md`. This includes:

1. **Project Discovery** - Scan directory, detect languages, check existing config
2. **Create Plan Document** - Write plan to `docs/plans/YYYY-MM-DD-devcontainer-setup.md`
3. **User Approval** - Present plan with ALL options and security warnings, get approval

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

**Response order for yolo mode:**
1. Project name (e.g., "demo-app")
2. Additional languages (e.g., "none", "go,rust", or comma-separated)
3. Firewall mode (e.g., "disabled", "permissive", "strict")
4. Confirmation (e.g., "yes", "y")

## MODE CHARACTERISTICS

YOLO mode provides:
- **Complete Control** - ALL options available, no restrictions
- **Unofficial Images** - Any Docker image from any registry
- **Optional Firewall** - Disabled, permissive, or strict (user choice)
- **Expert Level** - Assumes deep Docker and security knowledge
- **Maximum Flexibility** - Support any valid Docker configuration

## TASK IDENTITY

You are a **DevContainer Configuration Generator**. This is a file generation task.

**Your output:** VS Code DevContainer files in `.devcontainer/` directory
**Technology:** Docker, VS Code Dev Containers
**NOT related to:** Claude Code settings, Claude Code sandbox, `.claude/` configs

## MODE-SPECIFIC CONFIGURATION

### Firewall
**Templates Available:**
- `skills/_shared/templates/init-firewall/disabled.sh` - No firewall (container isolation only)
- `skills/_shared/templates/init-firewall/permissive.sh` - Allow all outbound traffic
- `skills/_shared/templates/init-firewall/strict.sh` - Whitelist only (customizable)

YOLO mode allows user to choose ANY firewall configuration, including:
- **Disabled** - No restrictions (fastest)
- **Permissive** - Allow all (maximum compatibility)
- **Strict** - Custom allowlist (maximum security)
- **Custom** - User provides own script

### User Questions (Planning Phase)
During planning, present ALL configuration options (15-20+ questions):

**Phase 1: Image Selection**
1. **Base image choice** - Official, sandbox template, or unofficial
   - If unofficial: warn about security risks, confirm explicitly

**Phase 2: Full Configuration**
2. **Project name** - Default from directory or specify
3. **Languages** - All detected languages + user additions
4. **Services** - Present ALL service options with descriptions
5. **Firewall mode** - Disabled/Permissive/Strict/Custom
6. **Proxy environment** - Corporate proxy detection
7. **Build args** - ALL available build args exposed
8. **VS Code extensions** - Present all available extensions
9. **Environment variables** - Custom env vars
10. **Port forwarding** - All ports to expose
11. **Dev container features** - Docker-in-Docker, etc.
12. **Lifecycle scripts** - postCreateCommand, postStartCommand
13. **MCP servers** - All available MCP servers
14. **Resource limits** - Memory/CPU constraints
15. **Custom domains** - If strict firewall, ask for full allowlist

**Phase 3: Security Warnings**
For risky choices, display warnings:
- Unofficial images
- Disabled firewall
- Permissive firewall with sensitive data
- Excessive permissions

### Defaults
NO defaults - user makes ALL choices. Ask about everything.

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

# Copy selected firewall template
case "$FIREWALL_MODE" in
    disabled)
        cp "$TEMPLATES/init-firewall/disabled.sh" .devcontainer/init-firewall.sh
        ;;
    permissive)
        cp "$TEMPLATES/init-firewall/permissive.sh" .devcontainer/init-firewall.sh
        ;;
    strict)
        cp "$TEMPLATES/init-firewall/strict.sh" .devcontainer/init-firewall.sh
        ;;
    custom)
        # User provides custom script
        ;;
esac

# Make scripts executable
chmod +x .devcontainer/setup-claude-credentials.sh .devcontainer/init-firewall.sh
```

### Step 2: Configure Build Args

If user selected custom build args, configure in docker-compose.yml:

```yaml
services:
  app:
    build:
      args:
        INSTALL_SHELL_EXTRAS: "${INSTALL_SHELL_EXTRAS:-true}"
        INSTALL_DEV_TOOLS: "${INSTALL_DEV_TOOLS:-true}"
        INSTALL_GO_TOOLS: "${INSTALL_GO_TOOLS:-true}"
        INSTALL_RUST_TOOLS: "${INSTALL_RUST_TOOLS:-true}"
        # ... user-specified args
```

### Step 3: Compose Dockerfile

```bash
# Same composition function as other modes
compose_dockerfile() {
    local base_file="$TEMPLATES/base.dockerfile"
    local output_file=".devcontainer/Dockerfile"
    local partials=("$@")

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

# Compose with ALL selected languages
compose_dockerfile "${ALL_LANGUAGES[@]}"
```

### Step 4: Customize Firewall (if strict mode)

If strict firewall selected, edit `.devcontainer/init-firewall.sh` with user-provided allowlist:

```bash
# Add ALL user-provided domains
ALLOWED_DOMAINS+=(
    # User-specified domains with categories
    "custom.domain.com"      # [CUSTOM] User description
)
```

### Step 5: Customize ALL Placeholders

Use Edit tool to replace:
- `{{PROJECT_NAME}}` → actual project name
- `{{NETWORK_NAME}}` → custom network name
- `{{BASE_IMAGE}}` → user-selected base image
- ALL user-specified custom values

In files:
- `docker-compose.yml`
- `.devcontainer/devcontainer.json`
- `.devcontainer/Dockerfile` (if using unofficial image)

### Step 6: Verify Files Created

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
| `Dockerfile` | `.devcontainer/Dockerfile` | Custom container image (ANY image allowed) |
| `devcontainer.json` | `.devcontainer/devcontainer.json` | VS Code DevContainer config |
| `init-firewall.sh` | `.devcontainer/init-firewall.sh` | Firewall script (user-selected mode) |
| `setup-claude-credentials.sh` | `.devcontainer/setup-claude-credentials.sh` | Credentials helper (Issue #30) |
| `docker-compose.yml` | `./docker-compose.yml` | Docker services |

## PROHIBITED FILES

Never create these files (wrong task):
- ❌ `.claude-code.json` - Claude Code config, NOT DevContainer
- ❌ `.claude/config.json` - Claude Code config, NOT DevContainer
- ❌ `Dockerfile` in project root - Should be in `.devcontainer/`

## DATA REFERENCES

Available data files in `skills/_shared/data/`:
- `allowable-domains.json` - Domain allowlist database with ALL categories
- `sandbox-templates.json` - Docker Hub image catalog
- `official-images.json` - Official Docker images reference
- `mcp-servers.json` - All available MCP servers
- `vscode-extensions.json` - All available VS Code extensions

## POST-GENERATION VALIDATION

```bash
# Verify Dockerfile composition
grep -c "^FROM.*AS" .devcontainer/Dockerfile  # Should be >= 1
grep -q "git vim nano" .devcontainer/Dockerfile || echo "⚠ Missing core utilities"
grep -q "claude-code" .devcontainer/Dockerfile || echo "⚠ Missing Claude Code CLI"
wc -l .devcontainer/Dockerfile  # Should be >= 100 lines (YOLO = most comprehensive)
```

## SECURITY AUDIT (INFORMATIONAL)

After generation, perform security audit but DO NOT block:

**Findings:**
- ⚠️ Unofficial image detected: `<image>` (if applicable)
- ⚠️ Firewall disabled or permissive (if applicable)
- ⚠️ Default passwords in configuration (warn to use env vars)
- ⚠️ Unnecessary ports exposed to host
- ⚠️ Running as root user (if detected)

List all findings with severity (high/medium/low) but proceed anyway - user has full control.

## COMPLETION CHECKLIST

Before finishing:
- [ ] YOLO warning displayed
- [ ] Plan document created and approved
- [ ] ALL user choices documented in plan
- [ ] All 5 files created in correct locations
- [ ] Scripts are executable (`chmod +x`)
- [ ] Placeholders replaced with ALL custom values
- [ ] Dockerfile composed with ALL selected language partials
- [ ] Firewall configured per user choice
- [ ] Security audit performed (findings logged, not blocking)
- [ ] Post-validation passed

## NEXT STEPS FOR USER

After setup complete, inform user with ALL details:

```
Setup complete! Configuration summary:

Mode: YOLO
Base Image: <image> (official/unofficial)
Firewall: <mode>
Languages: <all languages>
Services: <all services>
Custom Build Args: <count>

⚠️ Security Warnings (if any):
<list all warnings>

Next steps:

1. Review configuration:
   cat .devcontainer/devcontainer.json
   cat .devcontainer/Dockerfile
   cat docker-compose.yml

2. Start services:
   docker compose up -d

3. Verify services:
   docker compose ps
   docker compose logs

4. Open in DevContainer:
   code .
   # Ctrl+Shift+P → "Dev Containers: Reopen in Container"

5. Test inside container:
   # Database connection
   psql postgresql://user:pass@postgres:5432/db
   # Cache connection
   redis-cli -h redis ping
   # Network test
   curl -I https://github.com

6. Monitor resources:
   docker stats

For security audit: /devcontainer:audit

Your YOLO sandbox is ready!
```

---

**Last Updated:** 2025-12-22
**Version:** 4.0.0 (Planning Mode Integration)
**Related Issue:** #49
