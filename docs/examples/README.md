# Examples

Example applications demonstrating the Claude Code Sandbox plugin's capabilities with different configuration approaches: **Minimal Configuration**, **Domain Allowlist Configuration**, and **Custom Configuration**.

## Overview

This directory contains:
- **Shared application code** - Reusable backend and frontend implementations
- **Sandbox examples** - Self-contained DevContainer configurations demonstrating different setups
- **Two application stacks** - Full-stack demo app (Python + Node.js) and Streamlit (Python-only)

## Quick Start Guide

### For First-Time Users

1. **Start with Streamlit Minimal** - Fastest way to validate your setup (< 1 minute)
2. **Try Demo App Minimal** - Full-stack application with minimal configuration
3. **Try Domain Allowlist/Custom** - More features and production-ready patterns

### For Production Projects

1. **Demo App Domain Allowlist** - Production-ready configuration with domain allowlist security
2. **Demo App Custom** - Comprehensive setup with all tooling and maximum customization

## Examples Structure

```
examples/
├── README.md                        # This file
├── docker-compose.yml               # Shared PostgreSQL + Redis services
│
├── streamlit-shared/                # Shared Streamlit application code
├── streamlit-sandbox-basic/         # Streamlit with minimal configuration
│
├── demo-app-shared/                 # Shared full-stack application code
├── demo-app-sandbox-basic/          # Demo app with minimal configuration
├── demo-app-sandbox-advanced/       # Demo app with domain allowlist configuration
└── demo-app-sandbox-yolo/           # Demo app with custom configuration
```

## Application Examples

### 1. Streamlit App (Python-only)

**Shared Code**: `streamlit-shared/`
- Simple Streamlit dashboard
- PostgreSQL and Redis connection testing
- ~50 lines of code
- Perfect for quick validation

**Sandbox Examples**:
- `streamlit-sandbox-basic/` - Minimal configuration (container isolation only)

### 2. Demo Blog App (Full-stack Python + Node.js)

**Shared Code**: `demo-app-shared/`

**Backend (FastAPI)**:
- RESTful API with CRUD operations
- PostgreSQL persistence with SQLAlchemy
- Redis caching for posts and view counts
- Comprehensive pytest test suite

**Frontend (React + Vite)**:
- Modern React SPA
- Create, read, update, delete blog posts
- Real-time view counter
- Component tests with React Testing Library

**Sandbox Examples**:
- `demo-app-sandbox-basic/` - Minimal configuration (quick start, container isolation only)
- `demo-app-sandbox-advanced/` - Domain allowlist configuration (strict firewall, production-ready)
- `demo-app-sandbox-yolo/` - Custom configuration (full customization and control)

## DevContainer Configurations Explained

### Minimal Configuration - Quick Start

**Best for**: Prototypes, first-time users, solo developers, trusted code

**Characteristics**:
- Container isolation only (no network firewall)
- Sensible defaults applied automatically
- Essential VS Code extensions (2)
- Base Python 3.12 + Node 20 image
- Minimal configuration files
- Fast setup and build

**Setup time**: < 1 minute
**Build time**: 2-3 minutes

**Security**: Container isolation provides basic protection. Suitable for trusted code and development-only scenarios.

**Examples**: `streamlit-sandbox-basic/`, `demo-app-sandbox-basic/`

### Domain Allowlist Configuration - Production Development

**Best for**: Small teams, active development, production-ready projects, security-conscious workflows

**Characteristics**:
- Strict firewall with domain allowlist
- Curated VS Code extensions (10+)
- Configurable Dockerfile with build args
- Resource limits for containers
- Environment variable overrides
- Enhanced developer experience
- Network-level security

**Setup time**: 2-3 minutes (via interactive quickstart)
**Build time**: 3-4 minutes

**Security**: Strict whitelist-based firewall allows only specified domains. Suitable for production-like development and team environments.

**Example**: `demo-app-sandbox-advanced/`

### Custom Configuration - Maximum Customization

**Best for**: Large teams, production projects, comprehensive tooling, full control

**Characteristics**:
- Fully explicit configuration (no hidden defaults)
- Optional firewall (configurable: strict, permissive, or disabled)
- Comprehensive VS Code extensions (20+)
- Multi-stage optimized Dockerfile
- All available services and tools
- Production-ready patterns and best practices
- Complete observability and debugging tools
- Resource limits and security hardening
- Full documentation

**Setup time**: < 1 minute (via non-interactive YOLO vibe maxxing)
**Build time**: 5-7 minutes (with BuildKit)

**Security**: Fully customizable security model. User has complete control and responsibility.

**Example**: `demo-app-sandbox-yolo/`

## Comparison Matrix

| Feature            | Minimal           | Domain Allowlist  | Custom             |
| ----------------- | ----------------- | ----------------- | ------------------ |
| **Setup**          |
| Questions          | 0 (non-interactive) | 2-3 (interactive) | 0 (non-interactive) |
| Config files       | 4                 | 4                 | 7                  |
| Setup time         | <1 min            | 2-3 min           | <1 min             |
| **Dockerfile**     |
| Build stages       | 1                 | 1                 | 7 (multi-stage)    |
| Build args         | 0                 | 2                 | 5+                 |
| Dev tools          | Minimal           | Moderate          | Comprehensive      |
| **VS Code**        |
| Extensions         | 2                 | 10+               | 20+                |
| Pre-config         | Minimal           | Curated           | Complete           |
| Format on save     | No                | Yes               | Yes + linting      |
| **Development**    |
| Firewall           | None (container isolation) | Strict (domain allowlist) | Configurable |
| Dev dependencies   | No                | Some              | Complete           |
| Debugging tools    | No                | Some              | Full suite         |
| Testing tools      | pytest, jest      | + coverage        | + profiling        |
| **Services**       |
| Essential          | PostgreSQL, Redis | PostgreSQL, Redis | PostgreSQL, Redis  |
| Additional         | None              | None              | All (optional)     |
| **Production**     |
| Resource limits    | No                | Yes               | Yes (configurable) |
| Health checks      | Minimal             | Standard          | Comprehensive      |
| Security hardening | Minimal           | Good              | Full               |
| Monitoring hooks   | No                | No                | Yes                |
| **Best For**       |
| Use case           | Prototypes        | Production dev    | Full control       |
| Team size          | Solo              | Small             | Large              |
| Project phase      | Early             | Active dev        | Production         |

## Getting Started

### Prerequisites

- **Docker Desktop** (with BuildKit enabled for custom configuration)
- **Visual Studio Code** with Dev Containers extension
- **Git** (for version control)

### Option 1: Shared Services (Recommended for Learning)

Use shared PostgreSQL and Redis services for multiple examples:

```bash
# Start shared services
cd examples
docker compose up -d

# Verify services are running
docker compose ps

# Use any example without embedded services
cd streamlit-shared
# or demo-app-shared
```

**Service URLs**:
- PostgreSQL: `postgresql://sandbox_user:devpassword@localhost:5432/sandbox_dev`
- Redis: `redis://localhost:6379`

**Stop services**:
```bash
docker compose down
```

### Option 2: Self-Contained DevContainers

Each sandbox example includes embedded services:

```bash
# Open in VS Code
code examples/demo-app-sandbox-basic

# Reopen in Container (F1 → "Dev Containers: Reopen in Container")
# All services start automatically
```

## Learning Path

### Path 1: Quick Validation (5 minutes)

1. Start shared services: `cd examples && docker compose up -d`
2. Open `streamlit-sandbox-basic/` in VS Code
3. Reopen in Container
4. Run: `streamlit run app.py`
5. Verify PostgreSQL and Redis connections work

### Path 2: Full-Stack Development (15 minutes)

1. Open `demo-app-sandbox-basic/` in VS Code
2. Reopen in Container (wait 2-3 minutes for build)
3. Start backend: `cd backend && uvicorn app.api:app --reload`
4. Start frontend: `cd frontend && npm run dev`
5. Create and manage blog posts at http://localhost:5173

### Path 3: Production Patterns (30 minutes)

1. Open `demo-app-sandbox-advanced/` or `demo-app-sandbox-yolo/`
2. Reopen in Container
3. Explore comprehensive tooling and configurations
4. Run tests: `./run-tests.sh`
5. Review production-ready patterns in README

## Testing Examples

All examples include test suites:

```bash
# Run all tests (backend + frontend)
./run-tests.sh

# Backend tests only
cd backend
pytest

# Frontend tests only
cd frontend
npm test

# With coverage
./run-tests.sh --coverage
```

## Customization

### Minimal Configuration
- Add VS Code extensions
- Change ports in `devcontainer.json`
- Upgrade to domain allowlist for network security

### Domain Allowlist Configuration
- Set Python/Node.js versions via build args
- Configure resource limits
- Customize strict firewall allowlist
- Customize VS Code settings and extensions
- Override environment variables

### Custom Configuration
- Full environment variable configuration via `.env`
- Optional firewall (strict/permissive/disabled)
- Resource limits and reservations
- Security hardening options
- Optional admin tools (pgAdmin, Redis Commander)
- Database initialization scripts
- Shell customization

See individual example READMEs for detailed customization guides.

## Troubleshooting

### Common Issues

**Port already in use**:
```bash
# Stop conflicting services
docker compose down
# Or change ports in devcontainer.json
```

**Database connection failed**:
```bash
# Check service health
docker compose ps
docker compose logs postgres
```

**Build failures**:
```bash
# Enable BuildKit (custom configuration)
export DOCKER_BUILDKIT=1
# Rebuild without cache
docker-compose build --no-cache
```

**Firewall blocking**:
```bash
# Temporarily disable
export FIREWALL_MODE=permissive
sudo /usr/local/bin/init-firewall.sh
```

### Getting Help

1. Check the example's README for specific guidance
2. Review [TROUBLESHOOTING.md](../features/TROUBLESHOOTING.md) in the repository root
3. Open an issue on GitHub (for bugs only)

## Directory Details

### Shared Examples (No DevContainer)

**streamlit-shared/**: Minimal Streamlit app for connection testing
- Run directly on host: `uv add -r requirements.txt && streamlit run app.py`
- Or use with shared services: `docker compose up -d`

**demo-app-shared/**: Full-stack blog application
- Backend: FastAPI + PostgreSQL + Redis
- Frontend: React + Vite
- Run with shared services: `docker compose up -d`

### Sandbox Examples (With DevContainer)

**streamlit-sandbox-basic/**: Self-contained Streamlit with minimal configuration
- Python-only stack
- Embedded PostgreSQL and Redis
- Quickest way to validate sandbox setup

**demo-app-sandbox-basic/**: Full-stack with minimal configuration
- Auto-detected Python + Node.js
- Minimal configuration
- Container isolation only (no firewall)
- Perfect for quick start

- Platform-specific templates
- Container isolation
- Message queue (RabbitMQ)
- Learning and experimentation

**demo-app-sandbox-advanced/**: Full-stack with domain allowlist configuration
- Customizable versions and settings
- Strict firewall with domain allowlist
- Resource limits
- Balanced for team development

**demo-app-sandbox-yolo/**: Full-stack with custom configuration
- Multi-stage optimized build
- Optional firewall (configurable)
- Comprehensive tooling (20+ extensions)
- Production-ready patterns
- Complete observability

## Next Steps

- ✅ Try minimal configuration for quick start
- ✅ Use domain allowlist configuration for production development with strict security
- ✅ Try custom configuration for maximum customization
- 📖 Read configuration-specific READMEs for detailed guides
- 🔒 Review [SECURITY-MODEL.md](../features/SECURITY-MODEL.md) for security best practices
- 🚀 Customize examples for your project needs

## About

**Note**: I am not actively accepting pull requests or feature requests for this project. However, you are more than welcome to fork this repository and make your own improvements!

This project was created with [Claude](https://claude.ai) using the [Superpowers](https://github.com/obra/superpowers) plugin.

---

**Last Updated:** 2025-12-25
**Version:** 4.6.0
