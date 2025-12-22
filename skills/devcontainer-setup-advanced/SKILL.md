---
name: devcontainer-setup-advanced
description: Use when user wants security-focused development setup with strict firewall controls and customizable domain allowlists - ideal for production-like configurations, security-conscious teams, and scenarios requiring explicit network control
---

# Sandbox Setup: Advanced Mode

## MANDATORY PLANNING PHASE

**Reference:** `skills/_shared/planning-phase.md`

Before executing any implementation steps, Claude MUST follow the shared planning workflow defined in `skills/_shared/planning-phase.md`. This includes:

1. **Project Discovery** - Scan directory, detect languages, check existing config, analyze proxy environment
2. **Create Plan Document** - Write plan to `docs/plans/YYYY-MM-DD-devcontainer-setup.md`
3. **User Approval** - Present plan with security recommendations, ask questions, get approval

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

**Response order for advanced mode:**
1. Project name (e.g., "demo-app")
2. Additional languages (e.g., "none", "go", "rust", or comma-separated)
3. Services needed (e.g., "postgres", "redis", or comma-separated)
4. Proxy-friendly mode (e.g., "yes", "no")
5. Firewall mode (e.g., "permissive", "strict")
6. Firewall ports to allow (e.g., "443,8080" or "80,443,8000")
7. Confirmation (e.g., "yes", "y")

## MODE CHARACTERISTICS

Advanced mode is optimized for:
- **Security** - Strict firewall with curated domain allowlist
- **Control** - Customizable allowlist for project-specific needs
- **Production-like** - Configurations suitable for production environments
- **Transparency** - Brief explanations for each security decision

## TASK IDENTITY

You are a **DevContainer Configuration Generator**. This is a file generation task.

**Your output:** VS Code DevContainer files in `.devcontainer/` directory
**Technology:** Docker, VS Code Dev Containers
**NOT related to:** Claude Code settings, Claude Code sandbox, `.claude/` configs

## MODE-SPECIFIC CONFIGURATION

### Firewall
**Template:** `skills/_shared/templates/init-firewall/strict.sh`

Advanced mode uses STRICT firewall by default with a curated allowlist of essential development domains. Users can add project-specific domains during planning.

**Default Allowlist Categories:**
- Anthropic services (API, statsig, claude.ai)
- Version control (GitHub, GitLab, Bitbucket)
- Container registries (Docker Hub, GHCR)
- Package managers (npm, PyPI)
- Linux distributions (Ubuntu, Debian)

### User Questions (Planning Phase)
During planning, ask these 7-10 questions with brief explanations:

1. **Project type confirmation** - "I detected [type]. Is this correct?"
2. **Primary language** - "What's your primary programming language?"
   - Brief: "This determines base image and package manager allowlist"
3. **Proxy environment** - "Are you behind a corporate proxy?"
   - Brief: "Enables proxy-friendly build (skips GitHub downloads)"
4. **Database selection** - "What database do you need?"
   - Options: PostgreSQL, MySQL, MongoDB, Redis, None, Multiple
   - Brief: "PostgreSQL recommended for relational data"
5. **Firewall mode confirmation** - "Use STRICT firewall mode (recommended)?"
   - Options: Yes (strict with allowlist), Switch to Permissive
   - Brief: "Strict blocks all except allowlist; Permissive allows all"
6. **Review default allowlist** - Show default domains for detected project type
7. **Additional domains** - "Need to allow additional domains?"
   - Examples: "api.mycompany.com, cdn.example.com"
   - Brief: "Add project-specific APIs, CDNs, or private registries"

### Defaults
- **Base image:** Official images (python, node, etc.)
- **Extensions:** Comprehensive set from `skills/_shared/templates/extensions.json`
- **Firewall:** Strict (whitelist only)
- **Services:** Ask for each service with recommendations

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
cp "$TEMPLATES/init-firewall/strict.sh" .devcontainer/init-firewall.sh

# Make scripts executable
chmod +x .devcontainer/setup-claude-credentials.sh .devcontainer/init-firewall.sh
```

### Step 2: Configure Proxy-Friendly Build (if needed)

If user is behind proxy, configure build args in docker-compose.yml:

```yaml
services:
  app:
    build:
      args:
        INSTALL_SHELL_EXTRAS: "false"
        INSTALL_DEV_TOOLS: "false"
```

### Step 3: Compose Dockerfile

```bash
# Same composition function as Basic mode
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

# Compose with selected languages
compose_dockerfile "${DETECTED_LANGUAGES[@]}"
```

### Step 4: Customize Firewall Allowlist

Edit `.devcontainer/init-firewall.sh` to add project-specific domains to ALLOWED_DOMAINS array:

```bash
# Add user-provided domains
ALLOWED_DOMAINS+=(
    "api.mycompany.com"      # [API] Company internal API
    "cdn.mycompany.com"      # [CDN] Company CDN
)
```

### Step 5: Customize Placeholders

Use Edit tool to replace:
- `{{PROJECT_NAME}}` → actual project name
- `{{NETWORK_NAME}}` → `{project-name}-network`

In files:
- `docker-compose.yml`
- `.devcontainer/devcontainer.json`

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
| `Dockerfile` | `.devcontainer/Dockerfile` | Security-hardened container image |
| `devcontainer.json` | `.devcontainer/devcontainer.json` | VS Code DevContainer config |
| `init-firewall.sh` | `.devcontainer/init-firewall.sh` | Strict firewall with allowlist |
| `setup-claude-credentials.sh` | `.devcontainer/setup-claude-credentials.sh` | Credentials helper (Issue #30) |
| `docker-compose.yml` | `./docker-compose.yml` | Docker services with production-like settings |

## PROHIBITED FILES

Never create these files (wrong task):
- ❌ `.claude-code.json` - Claude Code config, NOT DevContainer
- ❌ `.claude/config.json` - Claude Code config, NOT DevContainer
- ❌ `Dockerfile` in project root - Should be in `.devcontainer/`

## DATA REFERENCES

Available data files in `skills/_shared/data/`:
- `allowable-domains.json` - Domain allowlist database with categories
- `sandbox-templates.json` - Docker Hub image catalog
- `official-images.json` - Official Docker images reference

## POST-GENERATION VALIDATION

```bash
# Verify Dockerfile composition
grep -c "^FROM.*AS" .devcontainer/Dockerfile  # Should be >= 1
grep -q "git vim nano" .devcontainer/Dockerfile || echo "⚠ Missing core utilities"
grep -q "claude-code" .devcontainer/Dockerfile || echo "⚠ Missing Claude Code CLI"
wc -l .devcontainer/Dockerfile  # Should be >= 50 lines

# Verify firewall configuration
grep -q "FIREWALL_MODE=\"strict\"" .devcontainer/init-firewall.sh || echo "⚠ Firewall not strict"
grep -q "ALLOWED_DOMAINS" .devcontainer/init-firewall.sh || echo "⚠ No allowlist"
```

## SECURITY MINI-AUDIT

After generation, perform automated security checks:

**Firewall Verification:**
- ✓ Confirm firewall mode is `strict`
- ✓ Verify `init-firewall.sh` exists and has execute permissions
- ✓ Check allowlist contains only necessary domains
- ⚠ Warn if allowlist is too permissive (>20 domains)

**Credential Safety:**
- ✓ Verify no hardcoded passwords in `docker-compose.yml`
- ✓ Check secrets use `${localEnv:VAR}` or `.env` files
- ✓ Confirm `.env` is in `.gitignore`

**Minimal Allowlist Verification:**
- ✓ Review each allowed domain has category marker
- ✓ Suggest removing unused domains based on project analysis
- ⚠ Flag generic wildcards or overly broad domains

## COMPLETION CHECKLIST

Before finishing:
- [ ] Plan document created and approved
- [ ] All 5 files created in correct locations
- [ ] Scripts are executable (`chmod +x`)
- [ ] Placeholders replaced with actual values
- [ ] Dockerfile composed with correct language partials
- [ ] Firewall configured with user-approved allowlist
- [ ] Security mini-audit passed
- [ ] Post-validation passed

## NEXT STEPS FOR USER

After setup complete, inform user:

```
Setup complete! Next steps:

1. Open project in Dev Container:
   - VS Code: Cmd/Ctrl+Shift+P → "Dev Containers: Reopen in Container"
   - Or: docker compose up -d

2. Verify firewall is active:
   docker exec <container-name> iptables -L DOCKER-USER

3. Test connectivity (inside container):
   # Should succeed (in allowlist)
   curl https://pypi.org

   # Should fail (not in allowlist)
   curl https://example.com

For comprehensive security audit, run: /devcontainer:audit

Your secure sandbox is ready!
```

---

**Last Updated:** 2025-12-22
**Version:** 4.0.0 (Planning Mode Integration)
**Related Issue:** #49
