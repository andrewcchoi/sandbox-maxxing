# Contributing to Claude Code Sandbox Plugin

Thank you for your interest in contributing! This guide will help you set up your development environment and understand our contribution workflow.

## Development Setup

### Option 1: Using the DevContainer (Recommended)

This plugin uses itself for development (dogfooding approach), which ensures the devcontainer works correctly and provides a consistent development environment.

1. **Prerequisites**:
   - Docker Desktop (Windows/Mac) or Docker Engine (Linux)
   - Visual Studio Code with Dev Containers extension
   - Git

2. **Clone and open**:
   ```bash
   git clone https://github.com/andrewcchoi/sandbox-maxxing
   cd sandbox-maxxing
   code .
   ```

3. **Open in container**:
   - Press `F1` in VS Code
   - Select "Dev Containers: Reopen in Container"
   - Wait for container to build (3-5 minutes first time)

4. **Verify setup**:
   ```bash
   # Test basic example
   cd examples/streamlit-sandbox-basic
   uv pip install -r requirements.txt
   streamlit run app.py
   ```
   Click the test buttons to verify PostgreSQL and Redis connectivity.

5. **Install plugin locally**:
   ```bash
   # From inside the devcontainer
   claude plugins add .
   ```

See [DEVELOPMENT.md](DEVELOPMENT.md) for comprehensive development guide.

### Option 2: Local Setup (Without DevContainer)

1. Clone the repository
2. Install Claude Code CLI
3. Link plugin locally: `claude plugins add .`

Note: Without the devcontainer, you won't be able to fully test the example applications or service integrations.

## Development Workflow

### Working on Skills

Skills are located in the `skills/` directory:
- `sandbox-setup-basic/SKILL.md` - Basic mode setup
- `sandbox-setup-intermediate/SKILL.md` - Intermediate mode setup
- `sandbox-setup-advanced/SKILL.md` - Advanced mode setup
- `sandbox-setup-yolo/SKILL.md` - YOLO mode setup
- `sandbox-troubleshoot/SKILL.md` - Troubleshooting assistant
- `sandbox-security/SKILL.md` - Security auditor

See [skills/README.md](skills/README.md) for detailed skill documentation.

When modifying skills:
1. Make changes to the skill markdown file
2. Test using: `claude-code` then invoke the skill
3. Verify all branches and edge cases work
4. Update skill documentation if needed

### Working on Templates

Templates are in the `templates/` directory:
- `master/` - Master templates with all features
- `dockerfiles/` - Language-specific Dockerfiles (Python, Node.js, Go, Rust, etc.)
- `compose/` - Mode-specific docker-compose templates
- `firewall/` - Mode-specific firewall scripts
- `legacy/` - Deprecated monolithic templates (python/, nodejs/, fullstack/)

Template placeholders:
- `{{PROJECT_NAME}}` - Project name
- `{{NETWORK_NAME}}` - Docker network name
- `{{DATABASE_USER}}` - Database username
- `{{DATABASE_NAME}}` - Database name
- `{{FIREWALL_MODE}}` - Firewall mode (strict/permissive)

After modifying templates:
1. Test generation with the skill
2. Verify the generated files work correctly
3. Test in all modes (Basic/Advanced/YOLO)

### Working on Example Applications

The `examples/` directory contains working applications that validate the plugin:

#### Streamlit Examples
- **Shared**: `examples/streamlit-shared/` - Quick validation app for testing service connectivity
- **Basic Mode**: `examples/streamlit-sandbox-basic/` - Self-contained DevContainer

#### Demo Blog Application
- **Shared**: `examples/demo-app-shared/` - Full-stack application code
- **Basic Mode**: `examples/demo-app-sandbox-basic/` - Minimal DevContainer configuration
- **Intermediate Mode**: `examples/demo-app-sandbox-intermediate/` - Standard DevContainer with permissive firewall
- **Advanced Mode**: `examples/demo-app-sandbox-advanced/` - Balanced DevContainer with customization
- **YOLO Mode**: `examples/demo-app-sandbox-yolo/` - Full-control DevContainer with comprehensive tooling

When modifying examples:
1. Make your changes
2. Run tests: `./run-tests.sh` (or `.\run-tests.ps1` on Windows)
3. Verify all tests pass with coverage
4. Test manually in the devcontainer

### Regenerating the DevContainer

If you modify the templates and want to regenerate this repository's devcontainer:

**⚠️ IMPORTANT**: Regenerating will overwrite existing devcontainer files. Commit your changes first!

1. **Backup current configuration**:
   ```bash
   git stash push -m "backup devcontainer" .devcontainer/ docker-compose.yml
   ```

2. **Regenerate using the plugin**:
   ```bash
   claude-code
   ```
   Then ask Claude:
   ```
   Please regenerate the devcontainer configuration for this plugin using the sandbox-setup skill in basic mode
   ```

3. **Review changes**:
   ```bash
   git diff .devcontainer/
   git diff docker-compose.yml
   ```

4. **Test the new configuration**:
   ```bash
   # Rebuild container
   # Press F1 → Dev Containers: Rebuild Container

   # Verify services
   cd examples/streamlit-sandbox-basic
   streamlit run app.py
   ```

5. **If successful, commit**:
   ```bash
   git add .devcontainer/ docker-compose.yml
   git commit -m "Regenerate devcontainer configuration"
   ```

6. **If issues, restore backup**:
   ```bash
   git stash pop
   ```

### Dogfooding Philosophy

This plugin follows a "dogfooding" approach - we use it to develop itself. This ensures:
- Templates work in real-world scenarios
- Security settings are practical
- Documentation is accurate
- The devcontainer provides a good developer experience

When making changes, always test them using the plugin's own devcontainer to ensure quality.

## Testing

See `tests/README.md` for manual test procedures.

Run all tests before submitting:
- Basic mode test
- Advanced mode test
- YOLO mode test
- Troubleshooting test
- Security audit test

## Submitting Changes

1. Create a feature branch
2. Make your changes
3. Test thoroughly
4. Update CHANGELOG.md
5. Submit pull request

## Code Style

- Use clear, descriptive variable names
- Comment complex logic
- Follow existing patterns
- Keep skills focused and modular

## Repository Organization

Before submitting changes, please review the [`docs/repo-keeper/ORGANIZATION_CHECKLIST.md`](docs/repo-keeper/ORGANIZATION_CHECKLIST.md) to ensure your contribution maintains repository consistency.

**Key guidelines:**

1. **Version Footers**: Add version footers to all new .md files
   ```markdown
   ---

   **Last Updated:** YYYY-MM-DD
   **Version:** X.Y.Z
   ```

2. **Inventory**: Update [`docs/repo-keeper/INVENTORY.json`](docs/repo-keeper/INVENTORY.json) when adding/removing files

3. **Cross-References**: Use relative paths for internal links (not absolute `/workspace/` paths)

4. **Naming Conventions**:
   - Commands: `/sandbox:{action}`
   - Skills: `sandbox-{action}[-mode]/SKILL.md`
   - Templates: `{component}.{mode}.{ext}`

5. **Validation**: Run these scripts before committing:
   ```powershell
   # Check version consistency
   .\docs\repo-keeper\scripts\check-version-sync.ps1

   # Check for broken links
   .\docs\repo-keeper\scripts\check-links.ps1

   # Validate inventory
   .\docs\repo-keeper\scripts\validate-inventory.ps1
   ```

See the full [Organization Checklist](docs/repo-keeper/ORGANIZATION_CHECKLIST.md) for complete guidelines.

---

**Last Updated:** 2025-12-16
**Version:** 2.2.1
