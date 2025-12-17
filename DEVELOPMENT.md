# Development Guide

This guide explains how to develop the Sandbox Plugin using the minimal devcontainer setup.

## Overview

This plugin uses itself for development (dogfooding approach). The devcontainer provides a lightweight environment for editing plugin files - **no services included**. Example applications have a separate docker-compose file for optional testing.

## Prerequisites

- **Docker Desktop** (Windows/Mac) or **Docker Engine** (Linux)
- **Visual Studio Code** with the **Dev Containers** extension
- **Claude Code CLI** (optional, for testing the plugin)

## Quick Start

### Option 1: VS Code DevContainer (Recommended)

1. Clone the repository:
   ```bash
   git clone https://github.com/andrewcchoi/sandbox-maxxing
   cd sandbox-maxxing
   ```

2. Open in VS Code:
   ```bash
   code .
   ```

3. Reopen in container:
   - Press `F1`
   - Select **Dev Containers: Reopen in Container**
   - Wait ~2 minutes for first-time build
   - Ready to edit plugin files!

### Option 2: Direct Docker Development

```bash
# Clone repository
git clone https://github.com/andrewcchoi/sandbox-maxxing
cd sandbox-maxxing

# Build and run container
docker build -f .devcontainer/Dockerfile -t sandbox-dev .
docker run -it -v $(pwd):/workspace sandbox-dev bash

# Now you can edit files with your favorite editor
```

## What's Included in the Devcontainer

The devcontainer is **intentionally minimal** for plugin development:

### ✅ Included
- **Python 3.12** with `uv` package manager
- **Node.js 20** with `npm`
- **Git** and essential development tools
- **VS Code extensions** for Python, JavaScript, and Markdown
- **Claude Code CLI** for testing the plugin

### ❌ NOT Included (By Design)
- No PostgreSQL (plugin doesn't use a database)
- No Redis (plugin doesn't use caching)
- No docker-compose services (kept separate)

**Why minimal?** The plugin generates configurations for OTHER projects, but doesn't need those services itself. This keeps the development environment fast and lightweight.

## Project Structure

```
sandbox/
├── .devcontainer/              # Generated using plugin Basic mode
│   ├── devcontainer.json       # VS Code configuration
│   ├── Dockerfile              # Python + Node.js only
│   └── init-firewall.sh        # Disabled (not needed)
│
├── skills/                     # Plugin skills (main work here)
│   ├── sandbox-setup-advanced/
│   ├── sandbox-troubleshoot/
│   └── sandbox-security/
│
├── commands/                   # Slash commands
│   ├── setup.md
│   ├── troubleshoot.md
│   └── audit.md
│
├── templates/                  # Configuration templates
│   ├── python/
│   ├── node/
│   └── fullstack/
│
├── examples/                   # Demo applications
│   ├── docker-compose.yml      # Services for examples ONLY
│   ├── streamlit-shared/       # Quick validation (shared services)
│   ├── streamlit-sandbox-basic/ # Self-contained Streamlit
│   ├── demo-app-shared/        # Full-stack demo (shared services)
│   ├── demo-app-sandbox-basic/  # Full-stack demo (Basic mode)
│   ├── demo-app-sandbox-advanced/ # Full-stack demo (Advanced mode)
│   └── demo-app-sandbox-yolo/   # Full-stack demo (YOLO mode)
│
└── docs/                       # Documentation
```

## Development Workflow

### 1. Plugin Development (No Services Needed)

Most development work doesn't require services:

```bash
# Edit plugin skills
code skills/sandbox-setup-advanced/SKILL.md

# Edit templates
code templates/python/devcontainer.json

# Edit documentation
code README.md
code DEVELOPMENT.md
```

### 2. Testing the Plugin Locally

Install and test the plugin with Claude Code:

```bash
# Install plugin locally
claude plugins add .

# Verify installation
claude plugins list

# Test slash commands
claude
> /sandbox:setup --basic
> /sandbox:troubleshoot
> /sandbox:audit
```

### 3. Running Example Applications (Optional)

Only if you want to test the example apps, start services separately:

```bash
# Start PostgreSQL + Redis
cd examples
docker compose up -d

# Verify services are running
docker compose ps

# Test basic example
cd streamlit-sandbox-basic
uv pip install -r requirements.txt
streamlit run app.py
# Open browser to http://localhost:8501

# Test full demo app (shared services)
cd ../demo-app-shared/backend
uv pip install -r requirements.txt
alembic upgrade head
uvicorn app.main:app --reload
# API available at http://localhost:8000/docs

# Stop services when done
cd ../../
docker compose down
```

## Testing

### Manual Testing

Test the plugin by using it to generate configurations:

```bash
# Create a test directory
mkdir /tmp/test-project
cd /tmp/test-project

# Use the plugin to generate configs
claude
> /sandbox:setup --basic

# Verify generated files
ls -la .devcontainer/
cat docker-compose.yml
```

### Example Application Tests

The example applications include test suites:

```bash
# Start services first
cd examples
docker compose up -d

# Run backend tests
cd demo-app/backend
pytest
pytest --cov=app --cov-report=html

# Run frontend tests
cd ../frontend
npm install
npm test
npm test -- --coverage

# Stop services
cd ../../
docker compose down
```

## Dogfooding: How the Devcontainer Was Generated

The `.devcontainer/` in this repository was created using the plugin itself:

```bash
# What was run (hypothetically, during setup)
/sandbox:basic

# Plugin detection output:
# ✓ Scanning repository...
# ✓ Found: 24 .md files (primary content)
# ✓ Found: 9 .py files (in examples/)
# ✓ Found: 4 .js files (in examples/)
# ✓ No database imports in root code
#
# Assessment: Documentation/Template repository
# Recommendation: Lightweight devcontainer with language runtimes
#
# Generating:
# ✓ .devcontainer/devcontainer.json (Python + Node.js)
# ✓ .devcontainer/Dockerfile (minimal tools)
# ✓ .devcontainer/init-firewall.sh (disabled)
# ✓ No docker-compose.yml (not needed for plugin development)
```

This demonstrates the plugin's smart detection - it generates configurations appropriate to the project, not generic templates.

## Updating the Devcontainer

When plugin templates change, regenerate the devcontainer to stay current:

```bash
# Use the regeneration script
./scripts/regenerate-devcontainer.sh

# Or manually:
# 1. Backup current config
mv .devcontainer .devcontainer.backup

# 2. Regenerate using latest plugin
/sandbox:basic

# 3. Review changes
diff -r .devcontainer.backup .devcontainer

# 4. Keep or restore
# If good: rm -rf .devcontainer.backup
# If bad: rm -rf .devcontainer && mv .devcontainer.backup .devcontainer

# 5. Commit
git add .devcontainer
git commit -m "chore: regenerate devcontainer with latest plugin version"
```

## Troubleshooting

### Devcontainer Won't Build

```bash
# Rebuild without cache
docker build --no-cache -f .devcontainer/Dockerfile -t sandbox-dev .

# Or in VS Code
# F1 → Dev Containers: Rebuild Container Without Cache
```

### Examples Can't Connect to Services

```bash
# Verify services are running
cd examples
docker compose ps

# Check logs
docker compose logs postgres
docker compose logs redis

# Restart services
docker compose restart

# Or full rebuild
docker compose down
docker compose up -d --build
```

### Port Conflicts

If PostgreSQL or Redis ports are already in use:

```bash
# Check what's using the ports
# Windows
netstat -ano | findstr :5432
netstat -ano | findstr :6379

# Linux/Mac
lsof -i :5432
lsof -i :6379

# Option 1: Stop conflicting service
# Option 2: Change port in examples/docker-compose.yml
```

### Claude Code Plugin Not Loading

```bash
# Reinstall plugin
claude plugins remove sandbox-maxxing
claude plugins add .

# Verify installation
claude plugins list

# Check plugin.json is valid
cat .claude-plugin/plugin.json | jq .
```

## Environment Variables

The devcontainer sets minimal environment variables:

| Variable              | Value                           | Purpose                        |
| --------------------- | ------------------------------- | ------------------------------ |
| `NPM_CONFIG_PREFIX`   | `/usr/local/share/npm-global`   | Global npm packages location   |
| `UV_COMPILE_BYTECODE` | `1`                             | Speed up Python imports        |
| `UV_LINK_MODE`        | `copy`                          | Ensure dependencies are copied |
| `PATH`                | Includes npm global and uv bins | Tool availability              |

**No database variables** - these are only needed when running examples, set in `examples/docker-compose.yml`.

## Best Practices

1. **Keep the devcontainer minimal** - Don't add services unless the plugin itself needs them
2. **Use examples/docker-compose.yml** - Keep example services separate
3. **Test with the plugin** - Use `/sandbox:basic` to validate changes
4. **Document changes** - Update this file when modifying the development workflow
5. **Regenerate periodically** - Keep the devcontainer in sync with plugin templates

## Next Steps

1. Read [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines
2. Explore [examples/README.md](examples/README.md) for example applications
3. Check [skills/README.md](skills/README.md) for skill documentation
4. Review [ARCHITECTURE.md](docs/ARCHITECTURE.md) for plugin design

## Getting Help

- **Issues**: https://github.com/andrewcchoi/sandbox-maxxing/issues
- **Documentation**: See `skills/*/references/` directories
- **Claude Code**: https://claude.ai/code
- **Plugin Development**: Use `/sandbox:troubleshoot` for debugging

---

**Last Updated:** 2025-12-16
**Version:** 2.2.1
