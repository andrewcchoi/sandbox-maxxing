# Sandboxxer Plugin - Claude Code Context

## Quick Reference

```bash
# Testing
npm run test           # Unit tests only
npm run test:all       # All tests (unit + integration)
npm run test:hooks     # Hook tests only

# Documentation health
./scripts/doc-health-check.sh   # Run all doc validation
./scripts/version-checker.sh    # Check version consistency
./scripts/diagram-inventory.sh  # Validate diagram files
```

## Architecture

### Commands (User-Facing)
| Command | Purpose |
|---------|---------|
| `/sandboxxer:quickstart` | Interactive setup with project type + firewall selection |
| `/sandboxxer:yolo-docker-maxxing` | Instant no-questions setup (Python+Node, no firewall) |
| `/sandboxxer:yolo-linux-maxxing` | Native Linux/WSL2 setup with Bubblewrap |
| `/sandboxxer:health` | Diagnostic health checks |
| `/sandboxxer:troubleshoot` | Docker sandbox issue diagnosis |
| `/sandboxxer:linux-troubleshoot` | Linux/WSL2 issue diagnosis |
| `/sandboxxer:audit` | Security audit |
| `/sandboxxer:deploy-to-azure` | Azure Container Apps deployment |

### Internal Components
- `agents/` - Internal subagents (devcontainer-generator, validator, troubleshooter)
- `skills/` - Workflow guidance for troubleshooting/audit
- `hooks/` - SessionStart/End, PreToolUse hooks (*.sh)
- `skills/_shared/templates/` - DevContainer templates with `{{PLACEHOLDERS}}`

### Template System
Templates are **copied directly** via `cp`, then placeholders replaced via `sed`:
- Placeholders: `{{PROJECT_NAME}}`, `{{APP_PORT}}`, `{{FRONTEND_PORT}}`, etc.
- Language partials: `partials/*.dockerfile` concatenated to base
- Data files (`data/*.json`): Reference catalogs for selection, NOT copied to user projects

**Note:** Labels like "basic/advanced/yolo" in data files are tier markers for organizing
which items to include during interactive selection, not plugin modes.

**Template execution order** (in `postCreateCommand`):
1. `fix-worktree-paths.sh` - Windows path translation (must run first)
2. `setup-claude-credentials.sh` - Environment setup (14 steps)
3. `setup-frontend.sh` - Frontend tooling

## Testing

**Framework:** BATS (Bash Automated Testing System)
- Tests in `tests/unit/` and `tests/integration/`
- Helpers in `tests/helpers/` (source these in test files)
- Fixtures in `tests/fixtures/`

**Critical:** BATS must be installed system-wide. npm sandbox restrictions prevent bundled execution.

### Regression Testing (MANDATORY)

**After EVERY implementation change**, run the full test suite:

```bash
npm run test:all      # Unit + Integration tests
./scripts/doc-health-check.sh  # Documentation validation
```

**This is not optional.** Regression testing catches:
- Broken functionality from seemingly unrelated changes
- Template/placeholder mismatches
- Line ending issues introduced by edits
- Documentation drift from code changes

### Test Suite Evolution

**When a bug or failure occurs:**
1. **Fix the immediate issue**
2. **Ask: "Should this be a test?"** - If the failure could recur or affect others, YES
3. **Add a test** that would have caught it:
   - Unit test for isolated logic (`tests/unit/`)
   - Integration test for cross-component behavior (`tests/integration/`)
4. **Verify the new test fails** on the broken code, passes on the fix

**Test coverage grows from real failures** - not theoretical edge cases. Every bug
that escapes to production is a missing test.

### Test Categories

| Command | Scope | When to Run |
|---------|-------|-------------|
| `npm run test` | Unit tests only | Quick validation during development |
| `npm run test:all` | All tests | **Before every commit** |
| `npm run test:hooks` | Hook tests | After modifying hooks/ |
| `npm run test:integration` | Integration | After template/script changes |

## Code Style

- Shell scripts: `#!/usr/bin/env bash`, `set -euo pipefail`
- Line endings: LF only (enforced by `.gitattributes`)
- Templates use `{{PLACEHOLDER}}` syntax (double braces)

## Design Decisions

### Multi-Stage Docker Builds (Proxy-Friendly)

**Problem solved:** Corporate proxies with SSL interception break curl-based installers
(NodeSource, rustup, etc.) with certificate errors (#29).

**Solution:** Copy binaries from official Docker Hub images instead of downloading:

| Tool | Traditional (broken behind proxy) | Multi-Stage (proxy-friendly) |
|------|-----------------------------------|------------------------------|
| Node.js | `curl deb.nodesource.com/setup_20.x` | `COPY --from=node:20-bookworm-slim` |
| Python | Download from python.org | `COPY --from=python:3.12-slim-bookworm` |
| Go | Download from golang.org | `COPY --from=golang:1.22-bookworm` |
| Rust | `curl rustup.sh` | `COPY --from=rust:bookworm` |

**Why it works:**
- Docker Hub registry uses different SSL paths (often whitelisted)
- No runtime HTTPS downloads during build
- Same versions, same functionality
- Faster, more reliable builds

**Corporate CA support:** Set `INSTALL_CA_CERT=true` and place `corporate-ca.crt`
in `.devcontainer/` for SSL inspection environments.

**Minimal build mode:** Set `INSTALL_SHELL_EXTRAS=false` and `INSTALL_DEV_TOOLS=false`
to skip GitHub-hosted extras that may be blocked.

### No Sudo in Container (Intentional)

**Design choice:** The container user (`vscode`) has no sudo access by default.

**Why this is beneficial:**
- **Forces Dockerfile updates** - Need `htop`? Add it to Dockerfile, rebuild. This ensures
  the container definition stays current with actual requirements.
- **Reproducible environments** - Every team member gets identical setup. No "works on my
  container" because someone manually installed a dependency.
- **Security posture** - Reduced attack surface. No accidental `sudo rm -rf` disasters.
- **GitOps-friendly** - All container changes are tracked in version control via Dockerfile.

**When you need a new package:**
1. Edit `.devcontainer/Dockerfile` - add to `apt-get install` list
2. Rebuild container: `Ctrl+Shift+P` → "Dev Containers: Rebuild Container"
3. Commit the Dockerfile change

**The "inconvenience" is the feature** - it prevents configuration drift where the running
container diverges from its definition. Six months later, you can rebuild the exact same
environment from the Dockerfile.

**Exception:** Some operations (like firewall init) run via `sudo` in lifecycle scripts
because they require root. These are pre-configured in the container image.

## Gotchas

1. **Version consistency** - Update ALL of these together:
   - `.claude-plugin/plugin.json`
   - `package.json`
   - `README.md` badge
   - `CHANGELOG.md`

2. **Diagram sources** - Never delete `.mmd` files in `docs/diagrams/mermaid/`. SVGs are generated from these.

3. **Template placeholders** - `{{PROJECT_NAME}}`, `{{PYTHON_VERSION}}`, etc. are replaced at runtime by setup scripts.

4. **Hook scripts** - Must be executable and have LF line endings. Windows CRLF will cause failures.

5. **Setup script step counters** - `setup-claude-credentials.sh` uses `[N/M]` pattern. Adding/removing steps requires updating ALL `echo "[X/M]"` lines.

6. **Git workaround** - If files named `HEAD`, `config`, `objects`, `refs` exist in working directory, use `git diff -- <files>` to separate paths from revisions.

## Common Errors (from GitHub Issues)

### Permission Errors
- **UID mismatch (#306):** Add `user: "1000:1000"` to docker-compose.yml
- **uv .venv permissions (#108):** Anonymous volume `- /app/.venv` + chown before USER

### Platform Errors
- **WSL2 hooks fail (#294):** `chmod +x ~/.claude/plugins/.../hooks/*.sh`
- **Paths with spaces (#202):** Quote: `"${CLAUDE_PLUGIN_ROOT}/hooks/..."`
- **df -BG not portable (#264):** Use `df -k` + awk instead

### Docker/Volume Errors
- **Named volume empty (#91):** Use bind mounts or add copy step from temp mount
- **Volume doesn't exist (#90):** `initializeCommand: "docker volume create X || true"`
- **Stale .venv (#101):** `rm -rf /workspace/.venv` in onCreateCommand

### Network Errors
- **EHOSTUNREACH (#109):** Three fixes: sudoers SETENV + env var passing + IFS fix
- **Duplicate IPs (#7):** Use `ipset add -exist` flag

### Line Ending Errors
- **CRLF breaks scripts (#24):** `.gitattributes` with `*.sh text eol=lf`
- **run-hook.cmd must be LF:** Bash heredoc in polyglot script fails with CRLF

### SSL Errors
- **Corporate proxy (#29):** Use multi-stage Docker build, not curl scripts
- **uv installer fails (#24):** Install `ca-certificates` package first

### Other Errors
- **Missing libpython (#241):** Copy `libpython3.12.so*` + run `ldconfig`
- **sudo -v hangs (#247):** Add timeout for non-interactive contexts
- **fzf integration missing (#110):** Download from GitHub, not Debian package

## PR Workflow

1. Run `./scripts/doc-health-check.sh` before committing
2. Ensure `npm run test:all` passes
3. Update CHANGELOG.md for user-facing changes
