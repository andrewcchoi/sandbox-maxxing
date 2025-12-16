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
   git clone https://github.com/andrewcchoi/windows-sandbox
   cd windows-sandbox
   code .
   ```

3. **Open in container**:
   - Press `F1` in VS Code
   - Select "Dev Containers: Reopen in Container"
   - Wait for container to build (3-5 minutes first time)

4. **Verify setup**:
   ```bash
   # Test basic example
   cd examples/basic-streamlit
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
- `sandbox-setup.md` - Interactive setup wizard
- `sandbox-troubleshoot.md` - Troubleshooting assistant (TODO)
- `sandbox-security.md` - Security auditor (TODO)

When modifying skills:
1. Make changes to the skill markdown file
2. Test using: `claude-code` then invoke the skill
3. Verify all branches and edge cases work
4. Update skill documentation if needed

### Working on Templates

Templates are in the `templates/` directory:
- `python/` - Python + PostgreSQL + Redis
- `nodejs/` - Node.js + MongoDB + Redis
- `fullstack/` - React + FastAPI + PostgreSQL

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
   cd examples/basic-streamlit
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
