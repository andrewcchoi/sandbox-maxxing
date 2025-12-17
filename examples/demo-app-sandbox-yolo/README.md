# Demo Blog Application - YOLO Mode Sandbox

This is a **self-contained** example demonstrating the Claude Code Sandbox DevContainer setup in **YOLO mode**. It includes a production-ready full-stack blog application with Python FastAPI backend and React frontend, configured with comprehensive tooling and optimizations.

## What is YOLO Mode?

YOLO mode is designed for teams and production-ready projects that require:
- **Comprehensive setup** with 10-15+ configuration prompts
- **Fully explicit configuration** with no hidden defaults
- **Technology-optimized Dockerfile** with multi-stage builds
- **Comprehensive VS Code extensions** (20+ extensions)
- **Production-ready patterns** and best practices
- **Full observability** with debugging and profiling tools
- **Complete documentation** of all configuration options

This example shows what the `sandbox-maxxing` plugin generates when run in YOLO mode on a full-stack application.

## Features

### Application Features
- **Backend (Python FastAPI)**:
  - RESTful API for blog posts (CRUD operations)
  - PostgreSQL database with UUID support and text search extensions
  - Redis caching with LRU policy and persistence
  - Comprehensive test suite with pytest, async support, and coverage
  - Type hints and runtime type checking

- **Frontend (React + Vite)**:
  - Single-page application for blog management
  - Create, read, update, and delete posts
  - View counter with Redis caching
  - Component tests with React Testing Library
  - Modern build tooling with Vite

### DevContainer Features (YOLO Mode)
- **Multi-stage Dockerfile**: Optimized layers for minimal image size and fast builds
- **VS Code extensions**: 35+ including all language support, themes (Material Icons, GitHub, Dracula, Andromeda, One Dark Pro, Night Owl, Nord, Atom One Dark, Monokai Pro), productivity tools (GitLens, Git Graph, Code Spell Checker, Error Lens, Path Intellisense, Auto Rename Tag), database clients (SQLTools, MongoDB, Database Client), and fun extensions (Peacock, Power Mode, VS Code Pets, TODO Highlight, Discord Presence, GlassIt, Custom CSS/JS)
- **MCP servers**: 11+ servers for maximum AI integration including filesystem, memory, sqlite, fetch, github, postgres, docker, brave-search, puppeteer, slack, and google-drive
- **Comprehensive tooling**:
  - Python: Black, isort, flake8, pylint, ruff, mypy, pytest, ipdb, IPython
  - Node.js: ESLint, Prettier, Jest, nodemon, yarn, pnpm
  - Database: SQLTools, PostgreSQL Client
  - Git: GitLens, Git Graph, Git History
  - Docker: Docker extension, container management
  - Testing: Test Explorer, coverage reporting
- **Production patterns**:
  - Resource limits and reservations
  - Health checks for all services
  - Security hardening (cap_drop, no-new-privileges)
  - Persistent named volumes
  - Custom network configuration
- **Developer experience**:
  - Format on save (Black, Prettier)
  - Auto-import organization
  - Enhanced shell with git branch display
  - Pre-configured database connections
  - Port forwarding with labels

## Quick Start

### Prerequisites
- Docker Desktop (with BuildKit enabled)
- Visual Studio Code with Dev Containers extension
- Git

### Steps

1. **Open in VS Code**:
   ```bash
   code examples/demo-app-sandbox-yolo
   ```

2. **Reopen in Container**:
   - Press `F1` or `Ctrl+Shift+P`
   - Select: `Dev Containers: Reopen in Container`
   - Wait for container to build (first time: 5-7 minutes with BuildKit)

3. **Install Claude Code** (required after each container rebuild):
   ```bash
   curl -fsSL https://claude.ai/install.sh | sh
   ```

   > **Note:** Claude Code must be reinstalled each time the devcontainer is rebuilt. If you're in an offline or air-gapped environment where the installation script cannot be reached, see [TROUBLESHOOTING.md](../../docs/TROUBLESHOOTING.md#claude-code-installation) for alternative installation methods.

4. **Start the Application**:

   **Terminal 1 - Backend**:
   ```bash
   cd backend
   uvicorn app.api:app --host 0.0.0.0 --port 8000 --reload
   ```

   **Terminal 2 - Frontend**:
   ```bash
   cd frontend
   npm run dev
   ```

4. **Access the Application**:
   - Frontend: http://localhost:5173 (opens automatically)
   - Backend API: http://localhost:8000/docs (interactive Swagger UI)
   - Database: Use SQLTools extension in VS Code (pre-configured)

## Architecture

### Directory Structure
```
demo-app-sandbox-yolo/
├── .devcontainer/
│   ├── devcontainer.json      # Comprehensive VS Code configuration
│   ├── Dockerfile             # Multi-stage optimized build
│   ├── init-firewall.sh       # Network security
│   ├── .bashrc                # Enhanced shell configuration
│   └── .editorconfig          # Code style enforcement
│
├── backend/
│   ├── app/
│   │   ├── api.py             # FastAPI routes
│   │   ├── models.py          # SQLAlchemy models
│   │   ├── database.py        # DB connection with pooling
│   │   └── cache.py           # Redis utilities
│   ├── tests/
│   │   ├── test_api.py        # API endpoint tests
│   │   └── test_cache.py      # Cache tests
│   ├── requirements.txt       # Production dependencies
│   ├── requirements-dev.txt   # Development dependencies
│   └── pytest.ini             # Test configuration
│
├── frontend/
│   ├── src/
│   │   ├── components/        # React components
│   │   ├── api/               # API client
│   │   ├── App.jsx
│   │   └── main.jsx
│   ├── package.json
│   └── vite.config.js
│
├── db-init/
│   └── 01-init.sql            # PostgreSQL initialization
│
├── docker-compose.yml         # Production-ready service definitions
├── .env.example               # Environment variables template
└── README.md                  # This file
```

## Running Tests

### All Tests (Backend + Frontend)
```bash
./run-tests.sh
```

### Backend Tests
```bash
cd backend
pytest                    # Run all tests
pytest -v                 # Verbose output
pytest --cov              # With coverage
pytest -k "test_create"   # Run specific tests
pytest --lf               # Run last failed
pytest -n auto            # Parallel execution
```

### Frontend Tests
```bash
cd frontend
npm test                  # Run all tests
npm test -- --watch       # Watch mode
npm test -- --coverage    # With coverage
```

### Code Quality Checks
```bash
# Backend
cd backend
black app/ tests/         # Format code
isort app/ tests/         # Sort imports
flake8 app/ tests/        # Lint code
mypy app/                 # Type checking
pylint app/               # Full lint
bandit -r app/            # Security check

# Frontend
cd frontend
npm run lint              # ESLint
npm run format            # Prettier
```

## DevContainer Configuration (YOLO Mode)

### Multi-Stage Dockerfile

The Dockerfile uses 7 stages for optimal build:

1. **python-base**: Base Python image with system dependencies
2. **nodejs-added**: Add Node.js from official repository
3. **python-tools**: Install comprehensive Python dev tools
4. **nodejs-tools**: Install global npm packages
5. **user-setup**: Create non-root user with security
6. **environment-config**: Configure environment variables
7. **final**: Production-ready development environment

**Benefits**:
- Optimal layer caching
- Minimal image size
- Clear separation of concerns
- Easy to customize individual stages

### Production-Ready docker-compose.yml

**Key features**:
- Build arguments for version control
- Environment variable overrides with defaults
- Resource limits and reservations
- Health checks for all services
- Security hardening (cap_drop, no-new-privileges)
- Named volumes for performance
- Custom network with subnet
- Optional admin tools (pgAdmin, Redis Commander)

### VS Code Extensions (20+)

**Python Development**:
- Python, Pylance (language server)
- Black Formatter, isort
- Flake8, Ruff (linting)

**JavaScript/TypeScript**:
- ESLint, Prettier
- React snippets, Babel syntax

**Database & DevOps**:
- SQLTools with PostgreSQL driver
- Database Client
- Docker extension

**Git & Version Control**:
- GitLens, Git Graph, Git History

**Testing & Quality**:
- Test Explorer, Python Test Adapter, Jest
- SonarLint, IntelliCode

**Productivity**:
- EditorConfig, TODO Tree
- Spell Checker, REST Client

### Claude Credentials

**Automatic Credential Persistence** (Issue #30):

Claude Code credentials are automatically copied from your host machine to the container:

1. **Host Mount** (in `docker-compose.yml`):
```yaml
app:
  volumes:
    - ~/.claude:/tmp/host-claude:ro  # Read-only mount from host
```

2. **Setup Script** (`.devcontainer/setup-claude-credentials.sh`):
- Runs automatically on container creation
- Copies `.credentials.json` and `settings.json` from host
- Preserves authentication across container rebuilds

3. **Result**:
- No need to run `claude login` after rebuilds
- Credentials persist automatically
- Works seamlessly with container recreation

**Manual Override:**

If you need to re-authenticate:
```bash
claude login
```

The new credentials will be saved in the container's `~/.claude` directory.

## Customization Guide

### 1. Environment Variables

Create `.env` file (copy from `.env.example`):
```env
# Database Configuration
POSTGRES_USER=myuser
POSTGRES_PASSWORD=mypassword
POSTGRES_DB=mydb
DATABASE_POOL_SIZE=20

# Redis Configuration
REDIS_MAX_MEMORY=512mb
REDIS_DB=0

# Firewall Configuration
FIREWALL_MODE=strict  # strict, permissive, disabled

# Application Configuration
APP_ENV=development
DEBUG=true
LOG_LEVEL=DEBUG

# Security
SECRET_KEY=your-secret-key-here
ALLOWED_HOSTS=*
CORS_ORIGINS=http://localhost:5173

# Network Configuration
NETWORK_SUBNET=172.29.0.0/16
NETWORK_GATEWAY=172.29.0.1
```

### 2. Change Python/Node.js Versions

Edit `docker-compose.yml`:
```yaml
services:
  app:
    build:
      args:
        NODE_VERSION: "18"  # or "20", "21"
```

Rebuild: `Dev Containers: Rebuild Container`

### 3. Resource Limits

Edit `docker-compose.yml`:
```yaml
services:
  app:
    deploy:
      resources:
        limits:
          cpus: '4.0'        # Maximum CPU cores
          memory: 8G         # Maximum memory
        reservations:
          cpus: '1.0'        # Minimum CPU cores
          memory: 2G         # Minimum memory
```

### 4. Database Initialization

Add SQL scripts to `db-init/`:
```bash
# Files are executed in alphabetical order
db-init/
├── 01-init.sql       # Extensions and schemas
├── 02-functions.sql  # Custom functions
└── 03-seed.sql       # Initial data
```

### 5. Firewall Configuration

**Strict Mode** (Whitelist-only):
```env
FIREWALL_MODE=strict
```

**Permissive Mode** (Audit logging):
```env
FIREWALL_MODE=permissive
```

**Disabled** (No firewall):
```env
FIREWALL_MODE=disabled
```

**Add Custom Domains**:
Edit `.devcontainer/init-firewall.sh`:
```bash
ALLOWED_DOMAINS=(
  # ... existing ...
  "api.myservice.com"
  "cdn.mycdn.com"
)
```

### 6. Enable Optional Services

**pgAdmin** (Database GUI):
```yaml
# Uncomment in docker-compose.yml
pgadmin:
  image: dpage/pgadmin4:latest
  # ... configuration ...
```
Access: http://localhost:5050

**Redis Commander** (Redis GUI):
```yaml
# Uncomment in docker-compose.yml
redis-commander:
  image: rediscommander/redis-commander:latest
  # ... configuration ...
```
Access: http://localhost:8081

### 7. VS Code Settings

Customize `.devcontainer/devcontainer.json`:
```json
{
  "customizations": {
    "vscode": {
      "settings": {
        "python.linting.pylintEnabled": true,
        "editor.rulers": [80, 120],
        "editor.formatOnSave": true,
        // ... add more ...
      },
      "extensions": [
        // Add more extensions
      ]
    }
  }
}
```

### 8. Shell Configuration

Customize `.devcontainer/.bashrc`:
```bash
# Add custom aliases
alias mycommand='...'

# Add custom environment variables
export MY_VAR=value

# Add custom functions
my_function() {
    # ...
}
```

## What Makes This "YOLO Mode"

According to the plan, YOLO mode is characterized by:

### 1. Comprehensive Setup (10-15+ questions)
The plugin would ask about:
- Python version preference
- Node.js version preference
- Database choice and version
- Cache layer preference
- Firewall mode selection
- Extension preferences (minimal, curated, comprehensive)
- Development tool selection
- Testing framework preferences
- Linting and formatting preferences
- Resource limits and optimization goals
- Security hardening level
- Monitoring and observability tools
- Documentation generation
- CI/CD integration

### 2. Fully Explicit Configuration
- All settings visible and documented
- No hidden defaults
- Clear explanation of each option
- Environment variable overrides
- Build arguments for all versions

### 3. Technology-Optimized Dockerfile
- Multi-stage build for efficiency
- Optimal layer caching
- Security hardening
- Health checks
- Resource optimization
- Build metadata

### 4. Comprehensive VS Code Extensions
- 20+ essential extensions
- Language servers and IntelliSense
- Formatters and linters
- Testing and debugging tools
- Git enhancements
- Database management
- Container management
- Documentation tools

### 5. Production-Ready Patterns
- Resource limits and reservations
- Health checks for all services
- Security hardening (capabilities, privileges)
- Persistent volumes with proper drivers
- Custom network configuration
- Database connection pooling
- Cache configuration with LRU
- Restart policies
- Monitoring hooks

### 6. Complete Documentation
- Comprehensive README
- Inline comments in all config files
- Environment variable documentation
- Troubleshooting guides
- Customization examples
- Best practices

## Comparing Modes

| Feature | Basic | Intermediate | Advanced | YOLO |
|---------|-------|--------------|----------|------|
| **Setup** |
| Questions asked | 1-2 | 3-5 | 5-7 | 10-15+ |
| Configuration time | <1 min | 2 min | 2-3 min | 5-10 min |
| **Dockerfile** |
| Build stages | Single | Single | Single | Multi-stage (7) |
| Image optimization | No | No | Partial | Full |
| Build args | No | 2 | 2 | 5+ |
| **VS Code** |
| Extensions | 2 | 5 | 10 | 20+ |
| Pre-configured | Minimal | Basic | Moderate | Comprehensive |
| Settings | Basic | Basic | Curated | Complete |
| **Services** |
| Health checks | Basic | Standard | Standard | Comprehensive |
| Resource limits | No | No | Yes | Yes |
| Security hardening | Partial | Partial | Good | Full |
| Admin tools | No | No | No | Optional |
| **Development** |
| Dev dependencies | No | No | Some | All |
| Code quality tools | No | No | Basic | Comprehensive |
| Debugging tools | No | No | Some | Full suite |
| Profiling | No | No | No | Yes |
| **Production Readiness** |
| Config documentation | Minimal | Basic | Moderate | Complete |
| Environment variables | Few | Some | Some | Comprehensive |
| Customization options | Limited | Moderate | Good | Extensive |
| Best practices | Basic | Basic | Good | Industry-standard |
| **Best For** |
| Use case | Quick start | Learning | Balanced dev | Production teams |
| Team size | Solo | Solo/Small | Small team | Large team |
| Project phase | Prototype | Learning | Development | Production |

## Advanced Usage

### Using SQLTools Extension

1. Open SQLTools (database icon in sidebar)
2. Connection "PostgreSQL (Dev)" is pre-configured
3. Click to connect (no password needed)
4. Run queries directly from VS Code

### Interactive Python Development

```bash
cd backend
ipython

>>> from app.models import Post
>>> from app.database import get_db
>>> # Interactive REPL with all imports
```

### Debugging with ipdb

Add breakpoint in code:
```python
import ipdb; ipdb.set_trace()
```

Run application, execution will pause at breakpoint.

### Performance Profiling

**Memory profiling**:
```bash
python -m memory_profiler app/api.py
```

**Line profiling**:
```python
from line_profiler import LineProfiler
# Profile specific functions
```

### Database Migrations (Alembic)

```bash
cd backend
pip install alembic
alembic init migrations
alembic revision --autogenerate -m "Initial migration"
alembic upgrade head
```

### Running in Production Mode

```bash
# Set production environment
export APP_ENV=production
export DEBUG=false

# Use production WSGI server
cd backend
gunicorn app.api:app --workers 4 --bind 0.0.0.0:8000
```

### Docker BuildKit Optimization

Enable BuildKit for faster builds:
```bash
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1
docker-compose build
```

## Troubleshooting

### Build Failures

**Issue**: Build takes too long
```bash
# Enable BuildKit
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# Use build cache
docker-compose build --pull
```

**Issue**: Out of memory during build
```bash
# Increase Docker memory limit
# Docker Desktop → Settings → Resources → Memory: 8GB+

# Or reduce resource limits in docker-compose.yml
```

### Database Issues

**Issue**: Connection refused
```bash
# Check health status
docker-compose ps

# View PostgreSQL logs
docker-compose logs postgres

# Wait for healthy status
docker-compose up -d postgres
docker-compose logs -f postgres  # Wait for "ready to accept connections"
```

**Issue**: Data persistence
```bash
# Check volumes
docker volume ls

# Backup data
docker-compose exec postgres pg_dump -U sandbox_user sandbox_dev > backup.sql

# Restore data
docker-compose exec -T postgres psql -U sandbox_user sandbox_dev < backup.sql
```

### Firewall Issues

**Issue**: Cannot access needed domains
```bash
# Check current mode
echo $FIREWALL_MODE

# Switch to permissive mode temporarily
export FIREWALL_MODE=permissive
sudo /usr/local/bin/init-firewall.sh

# Add domain permanently to init-firewall.sh
```

**Issue**: Firewall not working
```bash
# Check capabilities
docker-compose exec app sh -c 'cat /proc/self/status | grep Cap'

# Verify NET_ADMIN is present
docker inspect demo-app-yolo | grep -A 10 CapAdd
```

### Performance Issues

**Issue**: Slow container performance
```bash
# Check resource usage
docker stats

# Increase resource limits in docker-compose.yml
# Check host system resources
```

**Issue**: Volume performance on Windows
```bash
# Use named volumes instead of bind mounts for node_modules
# Already configured in docker-compose.yml
```

### Extension Issues

**Issue**: Extension not loading
```bash
# Rebuild container
# Dev Containers: Rebuild Container

# Check extension logs
# Command Palette → Developer: Show Logs → Select extension
```

**Issue**: SQLTools not connecting
```bash
# Verify PostgreSQL is healthy
docker-compose ps postgres

# Test connection manually
docker-compose exec postgres psql -U sandbox_user -d sandbox_dev
```

## Security Best Practices

### 1. Change Default Credentials

Never use default credentials in production:
```env
POSTGRES_PASSWORD=$(openssl rand -base64 32)
SECRET_KEY=$(openssl rand -hex 32)
```

### 2. Enable Firewall in Production

Always use strict mode:
```env
FIREWALL_MODE=strict
```

### 3. Regular Security Audits

```bash
# Python dependencies
safety check

# Code security scan
bandit -r app/

# npm audit
cd frontend && npm audit
```

### 4. Keep Dependencies Updated

```bash
# Python
pip list --outdated
pip install --upgrade -r requirements.txt

# Node.js
npm outdated
npm update
```

## Related Examples

- `examples/demo-app-shared/` - Shared application code
- `examples/demo-app-sandbox-basic/` - Basic mode (quick start)
- `examples/demo-app-sandbox-advanced/` - Advanced mode (balanced)
- `examples/streamlit-sandbox-basic/` - Python-only example

## Learn More

- [Claude Code Sandbox Documentation](../../docs/)
- [Security Model](../../docs/security-model.md)
- [Development Guide](../../DEVELOPMENT.md)
- [Contributing](../../CONTRIBUTING.md)

## License

MIT

---

**YOLO Mode** - Production-ready development environments with comprehensive tooling and best practices.

---

**Last Updated:** 2025-12-16
**Version:** 2.2.1
