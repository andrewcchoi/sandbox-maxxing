# Examples

Example applications demonstrating the Claude Code Sandbox plugin's capabilities across four experience tiers: **Basic**, **Intermediate**, **Advanced**, and **YOLO** tiers.

## Overview

This directory contains:
- **Shared application code** - Reusable backend and frontend implementations
- **Sandbox examples** - Self-contained DevContainer configurations demonstrating each tier
- **Two application stacks** - Full-stack demo app (Python + Node.js) and Streamlit (Python-only)

## Quick Start Guide

### For First-Time Users

1. **Start with Streamlit Basic** - Fastest way to validate your setup (< 1 minute)
2. **Try Demo App Basic** - Full-stack application with minimal configuration
3. **Explore Intermediate** - Add message queue and permissive firewall
4. **Try Advanced/YOLO** - More features and production-ready patterns

### For Production Projects

1. **Demo App Intermediate** - Learning and experimentation with additional services
2. **Demo App Advanced** - Balanced configuration with strict security for team development
3. **Demo App YOLO** - Comprehensive setup with all tooling and maximum customization

## Examples Structure

```
examples/
├── README.md                        # This file
├── docker-compose.yml               # Shared PostgreSQL + Redis services
│
├── streamlit-shared/                # Shared Streamlit application code
├── streamlit-sandbox-basic/         # Streamlit with Basic tier DevContainer
│
├── demo-app-shared/                 # Shared full-stack application code
├── demo-app-sandbox-basic/          # Demo app with Basic tier DevContainer
├── demo-app-sandbox-intermediate/   # Demo app with Intermediate tier DevContainer
├── demo-app-sandbox-advanced/       # Demo app with Advanced tier DevContainer
└── demo-app-sandbox-yolo/           # Demo app with YOLO tier DevContainer
```

## Application Examples

### 1. Streamlit App (Python-only)

**Shared Code**: `streamlit-shared/`
- Simple Streamlit dashboard
- PostgreSQL and Redis connection testing
- ~50 lines of code
- Perfect for quick validation

**Sandbox Examples**:
- `streamlit-sandbox-basic/` - Basic tier configuration

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
- `demo-app-sandbox-basic/` - Basic tier (quick start, no firewall)
- `demo-app-sandbox-intermediate/` - Intermediate tier (permissive firewall, message queue)
- `demo-app-sandbox-advanced/` - Advanced tier (strict firewall, balanced)
- `demo-app-sandbox-yolo/` - YOLO tier (full customization)

## DevContainer Tiers Explained

### Basic Tier - Quick Start

**Best for**: Prototypes, first-time users, solo developers

**Characteristics**:
- 1-2 configuration questions
- Auto-detected stack and dependencies
- Sensible defaults applied automatically
- No firewall (relies on Windows Sandbox hypervisor isolation)
- Essential VS Code extensions (2)
- Sandbox template or official Docker image
- Minimal configuration files

**Setup time**: < 1 minute
**Build time**: 2-3 minutes

**Examples**: `streamlit-sandbox-basic/`, `demo-app-sandbox-basic/`

### Intermediate Tier - Learning & Experimentation

**Best for**: Learning, experimentation, small projects

**Characteristics**:
- 3-5 configuration questions
- Platform-specific templates (Python, Node.js, etc.)
- Permissive firewall (no restrictions, audit logging)
- Additional services (message queues like RabbitMQ)
- More VS Code extensions (5)
- Build arguments for version customization
- Enhanced configuration options

**Setup time**: 2 minutes
**Build time**: 2-3 minutes

**Example**: `demo-app-sandbox-intermediate/`

### Advanced Tier - Production Development

**Best for**: Small teams, active development, production-ready projects

**Characteristics**:
- 5-7 configuration questions
- Strict firewall with customizable allowlist
- Curated VS Code extensions (10+)
- Configurable Dockerfile with build args
- Resource limits for containers
- Environment variable overrides
- Enhanced developer experience

**Setup time**: 3-4 minutes
**Build time**: 3-4 minutes

**Example**: `demo-app-sandbox-advanced/`

### YOLO Tier - Maximum Customization

**Best for**: Large teams, production projects, comprehensive tooling, full control

**Characteristics**:
- 10-15+ configuration questions
- Fully explicit configuration (no hidden defaults)
- Optional firewall (configurable: strict, permissive, or disabled)
- Comprehensive VS Code extensions (20+)
- Multi-stage optimized Dockerfile
- All available services and tools
- Production-ready patterns and best practices
- Complete observability and debugging tools
- Resource limits and security hardening
- Full documentation

**Setup time**: 5-10 minutes
**Build time**: 5-7 minutes (with BuildKit)

**Example**: `demo-app-sandbox-yolo/`

## Comparison Matrix

| Feature | Basic | Intermediate | Advanced | YOLO |
|---------|-------|--------------|----------|------|
| **Setup** |
| Questions | 1-2 | 3-5 | 5-7 | 10-15+ |
| Config files | 4 | 4 | 4 | 7 |
| Setup time | <1 min | 2 min | 3-4 min | 5-10 min |
| **Dockerfile** |
| Build stages | 1 | 1 | 1 | 7 (multi-stage) |
| Build args | 0 | 2 | 2 | 5+ |
| Dev tools | Minimal | Basic | Moderate | Comprehensive |
| **VS Code** |
| Extensions | 2 | 5 | 10+ | 20+ |
| Pre-config | Minimal | Basic | Curated | Complete |
| Format on save | No | No | Yes | Yes + linting |
| **Development** |
| Firewall | None | Permissive | Strict | Configurable |
| Dev dependencies | No | No | Some | Complete |
| Debugging tools | No | No | Some | Full suite |
| Testing tools | pytest, jest | pytest, jest | + coverage | + profiling |
| **Services** |
| Essential | PostgreSQL, Redis | PostgreSQL, Redis | PostgreSQL, Redis | PostgreSQL, Redis |
| Additional | None | RabbitMQ | None | All (optional) |
| **Production** |
| Resource limits | No | No | Yes | Yes (configurable) |
| Health checks | Basic | Standard | Standard | Comprehensive |
| Security hardening | Minimal | Partial | Good | Full |
| Monitoring hooks | No | No | No | Yes |
| **Best For** |
| Use case | Prototypes | Learning | Production dev | Full control |
| Team size | Solo | Solo/Small | Small | Large |
| Project phase | Early | Learning | Active dev | Production |

## Getting Started

### Prerequisites

- **Docker Desktop** (with BuildKit enabled for Pro mode)
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

### Basic Tier
- Add VS Code extensions
- Change ports in `devcontainer.json`
- Upgrade to higher tier for more features

### Intermediate Tier
- Set Python/Node.js versions via build args
- Add more services to `docker-compose.yml`
- Customize VS Code extensions
- Firewall is permissive by default (no restrictions)

### Advanced Tier
- Set Python/Node.js versions via build args
- Configure resource limits
- Customize strict firewall allowlist
- Customize VS Code settings and extensions
- Override environment variables

### YOLO Tier
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
# Enable BuildKit (Pro mode)
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
2. Review `docs/TROUBLESHOOTING.md` in the repository root
3. Open an issue on GitHub (for bugs only)

## Directory Details

### Shared Examples (No DevContainer)

**streamlit-shared/**: Minimal Streamlit app for connection testing
- Run directly on host: `pip install -r requirements.txt && streamlit run app.py`
- Or use with shared services: `docker compose up -d`

**demo-app-shared/**: Full-stack blog application
- Backend: FastAPI + PostgreSQL + Redis
- Frontend: React + Vite
- Run with shared services: `docker compose up -d`

### Sandbox Examples (With DevContainer)

**streamlit-sandbox-basic/**: Self-contained Streamlit with Basic tier
- Python-only stack
- Embedded PostgreSQL and Redis
- Quickest way to validate sandbox setup

**demo-app-sandbox-basic/**: Full-stack with Basic tier
- Auto-detected Python + Node.js
- Minimal configuration
- No firewall (hypervisor isolation)
- Perfect for quick start

**demo-app-sandbox-intermediate/**: Full-stack with Intermediate tier
- Platform-specific templates
- Permissive firewall
- Message queue (RabbitMQ)
- Learning and experimentation

**demo-app-sandbox-advanced/**: Full-stack with Advanced tier
- Customizable versions and settings
- Strict firewall with allowlist
- Resource limits
- Balanced for team development

**demo-app-sandbox-yolo/**: Full-stack with YOLO tier
- Multi-stage optimized build
- Optional firewall (configurable)
- Comprehensive tooling (20+ extensions)
- Production-ready patterns
- Complete observability

## Next Steps

- ✅ Try Basic tier for quick start
- ✅ Explore Intermediate tier for learning with additional services
- ✅ Use Advanced tier for production development with strict security
- ✅ Try YOLO tier for maximum customization
- 📖 Read tier-specific READMEs for detailed guides
- 🔒 Review `docs/SECURITY.md` for security best practices
- 🚀 Customize examples for your project needs

## About

**Note**: I am not actively accepting pull requests or feature requests for this project. However, you are more than welcome to fork this repository and make your own improvements!

This project was created with [Claude](https://claude.ai) using the [Superpowers](https://github.com/obra/superpowers) plugin.
