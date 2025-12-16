# Demo Blog Application - Advanced Mode Sandbox

This is a **self-contained** example demonstrating the Claude Code Sandbox DevContainer setup in **Advanced mode**. It includes a full-stack blog application with Python FastAPI backend and React frontend, configured with enhanced customization options.

## What is Advanced Tier?

Advanced tier is designed for developers who want:
- **Balanced configuration** with 5-7 interactive prompts
- **Strict firewall** with customizable allowlist (whitelist-based network access)
- **Curated VS Code extensions** for productivity (10+ extensions)
- **Configurable Dockerfile** with build arguments
- **Resource limits** for containers
- **Enhanced developer experience** with additional tools

This example shows what the `windows-sandbox` plugin generates when run in Advanced tier on a full-stack application.

## Features

### Application Features
- **Backend (Python FastAPI)**:
  - RESTful API for blog posts (CRUD operations)
  - PostgreSQL database for persistent storage
  - Redis caching for view counts and post content
  - Comprehensive test suite with pytest

- **Frontend (React + Vite)**:
  - Single-page application for blog management
  - Create, read, update, and delete posts
  - View counter with Redis caching
  - Component tests with React Testing Library

### DevContainer Features (Advanced Tier)
- **Configurable stack**: Python 3.12 + Node.js 20 (customizable via build args)
- **Database services**: PostgreSQL 15 + Redis 7 with persistence
- **Network security**: Strict firewall with customizable allowlist (whitelist-based)
- **Curated extensions**: Python, Pylance, Black, ESLint, Prettier, SQLTools, GitLens, Docker (10+ extensions)
- **Resource limits**: CPU and memory limits configured for containers
- **Port forwarding**: Backend (8000), Frontend (5173), PostgreSQL (5432), Redis (6379) with labels
- **Development tools**: Black, Pylint, pytest, IPython, build-essential
- **Shell enhancements**: Zsh with Oh My Zsh (optional feature)

## Quick Start

### Prerequisites
- Docker Desktop
- Visual Studio Code with Dev Containers extension

### Steps

1. **Open in VS Code**:
   ```bash
   code examples/demo-app-sandbox-advanced
   ```

2. **Reopen in Container**:
   - Press `F1` or `Ctrl+Shift+P`
   - Select: `Dev Containers: Reopen in Container`
   - Wait for container to build and start (first time takes 3-4 minutes)

3. **Start the Application**:

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
   - Frontend: http://localhost:5173 (auto-opens in browser)
   - Backend API: http://localhost:8000/docs
   - Create posts, view them, edit, and delete!

## Running Tests

**Run all tests** (backend + frontend):
```bash
./run-tests.sh
```

**Run backend tests only**:
```bash
cd backend
pytest
```

**Run frontend tests only**:
```bash
cd frontend
npm test
```

**With coverage**:
```bash
./run-tests.sh --coverage
```

## Architecture

### Backend Structure
```
backend/
├── app/
│   ├── __init__.py
│   ├── api.py          # FastAPI routes
│   ├── models.py       # SQLAlchemy models
│   ├── database.py     # Database connection
│   └── cache.py        # Redis caching utilities
├── tests/
│   ├── test_api.py     # API endpoint tests
│   └── test_cache.py   # Cache functionality tests
├── requirements.txt
└── pytest.ini
```

### Frontend Structure
```
frontend/
├── src/
│   ├── components/
│   │   ├── PostList.jsx      # List all posts
│   │   ├── PostDetail.jsx    # View single post
│   │   ├── PostForm.jsx      # Create/edit form
│   │   └── __tests__/        # Component tests
│   ├── api/
│   │   └── posts.js          # API client
│   ├── App.jsx               # Main app component
│   └── main.jsx              # Entry point
├── package.json
└── vite.config.js
```

## DevContainer Configuration (Advanced Tier)

### What the Plugin Generated

**devcontainer.json** (Advanced Tier):
- Curated VS Code extensions for full-stack development
- Code formatting on save (Black for Python, Prettier for JS)
- Port attributes with labels and auto-forward behaviors
- SQLTools for database management
- GitLens for enhanced Git integration
- Docker extension for container management
- Optional Dev Container features (Zsh/Oh My Zsh)

**Dockerfile** (Advanced Tier):
- Configurable Python and Node.js versions via build args
- Additional development tools (build-essential, vim, nano, less)
- Pre-installed Python tools (black, pylint, pytest, ipython)
- Enhanced shell prompt
- Environment variables for development

**docker-compose.yml** (Advanced Tier):
- Build args for version customization
- Environment variables with defaults (FIREWALL_MODE=strict, DATABASE_URL)
- Resource limits (CPU and memory) for containers
- Configurable database credentials via environment
- Persistent volumes for PostgreSQL and Redis
- Optional port exposure for external tools
- Custom network with subnet configuration
- Restart policies for development

**init-firewall.sh**:
- Strict mode by default (whitelist-only)
- Customizable allowlist with category markers
- Pre-configured allowed domains (GitHub, npm, PyPI, AI providers, VS Code)
- Easy to add project-specific domains
- Domain verification on startup

## Customization Options

### 1. Change Python or Node.js Version

Edit `docker-compose.yml`:
```yaml
services:
  app:
    build:
      args:
        PYTHON_VERSION: "3.11"  # Change Python version
        NODE_VERSION: "18"      # Change Node.js version
```

Then rebuild: `Dev Containers: Rebuild Container`

### 2. Configure Firewall Mode

**Option A - Environment Variable** (create `.env` file):
```env
FIREWALL_MODE=permissive
```

**Option B - docker-compose.yml**:
```yaml
environment:
  - FIREWALL_MODE=permissive  # or "strict" or "disabled"
```

**Option C - devcontainer.json**:
```json
{
  "containerEnv": {
    "FIREWALL_MODE": "permissive"
  }
}
```

### 3. Add Custom Allowed Domains

Edit `.devcontainer/init-firewall.sh`:
```bash
ALLOWED_DOMAINS=(
  # ... existing domains ...
  "api.yourproject.com"
  "cdn.example.com"
  "custom-registry.io"
)
```

### 4. Customize Database Credentials

Create `.env` file:
```env
POSTGRES_USER=myuser
POSTGRES_PASSWORD=mypassword
POSTGRES_DB=mydb
```

Update backend connection in `docker-compose.yml` if needed.

### 5. Add More VS Code Extensions

Edit `.devcontainer/devcontainer.json`:
```json
{
  "customizations": {
    "vscode": {
      "extensions": [
        // ... existing extensions ...
        "redhat.vscode-yaml",
        "ms-vscode.makefile-tools"
      ]
    }
  }
}
```

### 6. Expose Database Ports for External Tools

Edit `docker-compose.yml`:
```yaml
postgres:
  ports:
    - "5432:5432"  # Uncomment to expose

redis:
  ports:
    - "6379:6379"  # Uncomment to expose
```

### 7. Configure Editor Settings

Edit `.devcontainer/devcontainer.json`:
```json
{
  "customizations": {
    "vscode": {
      "settings": {
        "editor.tabSize": 4,
        "python.linting.pylintEnabled": true,
        // ... add more settings ...
      }
    }
  }
}
```

## What Makes This "Advanced Tier"

According to the plan, Advanced tier is characterized by:

1. **More Interactive Setup (5-7 questions)**
   - Firewall mode selection
   - Python/Node.js version preferences
   - VS Code extension choices
   - Development tool selection

2. **Customizable Configuration**
   - Build args for version control
   - Environment variable overrides
   - Configurable credentials
   - Optional features

3. **Configurable Dockerfile**
   - Build arguments for versions
   - Additional dev tools included
   - Enhanced shell configuration
   - Pre-installed development utilities

4. **Curated VS Code Extensions**
   - Language servers (Pylance)
   - Formatters (Black, Prettier)
   - Database tools (SQLTools)
   - Git enhancement (GitLens)
   - Docker management

5. **Strict Firewall with Customizable Allowlist**
   - Whitelist-based network access control
   - Category-based domain organization
   - Easy to add project-specific domains
   - Domain verification on startup

6. **Balanced Approach**
   - More than Basic (flexible)
   - Less than Pro (not overwhelming)
   - Production-ready patterns
   - Development-friendly defaults

## Comparing Tiers

| Feature | Basic | Intermediate | Advanced | YOLO |
|---------|-------|--------------|----------|------|
| Questions asked | 1-2 | 3-5 | 5-7 | 10-15+ |
| Configuration style | Auto-detected | Platform-specific | Customizable | Fully explicit |
| Dockerfile | Sandbox template/official image | Platform template | Configurable | Technology-optimized |
| VS Code extensions | Essential (2) | Basic (5) | Curated (10+) | Comprehensive (20+) |
| Firewall | None | Permissive | Strict | Configurable |
| Services | Essential only | + Message queue | + Resource limits | All available |
| Build args | None | Python/Node versions | More options | All dependencies |
| Resource limits | None | None | Yes | Yes (configurable) |
| Best for | Quick start | Learning | Production dev | Full control |

## Troubleshooting

### Database Connection Issues
If you see database connection errors:
```bash
# Wait for PostgreSQL to be ready
docker-compose logs postgres

# Check health status
docker-compose ps
```

### Firewall Blocking Needed Sites
```bash
# Check current mode
echo $FIREWALL_MODE

# Switch to permissive mode
export FIREWALL_MODE=permissive
sudo /usr/local/bin/init-firewall.sh

# View firewall rules
sudo iptables -L -v
```

### Container Build Failures
```bash
# Rebuild with different Python version
# Edit docker-compose.yml, change PYTHON_VERSION
# Then: Dev Containers: Rebuild Container

# Or rebuild without cache
docker-compose build --no-cache
```

### Extension Not Loading
```bash
# Check VS Code extension logs
# Command Palette -> "Developer: Show Logs"

# Manually install extension
# Extensions view -> Search -> Install
```

### Port Already in Use
```bash
# Stop conflicting services
docker-compose down

# Or change ports in devcontainer.json
"forwardPorts": [8001, 5174, 5433, 6380]
```

## Advanced Usage

### Using SQLTools with PostgreSQL

1. The SQLTools extension is pre-installed
2. Click the database icon in VS Code sidebar
3. Connection is pre-configured:
   - Host: `postgres`
   - Port: `5432`
   - Database: `sandbox_dev`
   - User: `sandbox_user`
   - Password: `devpassword`

### Interactive Python with IPython

```bash
cd backend
ipython
>>> from app.models import Post
>>> from app.database import engine
>>> # Interactive Python development
```

### Code Formatting

Files are automatically formatted on save:
- Python: Black
- JavaScript/JSX: Prettier

Manual formatting:
```bash
# Backend
cd backend
black app/ tests/

# Frontend
cd frontend
npm run format  # if configured in package.json
```

### Database Migrations (Advanced)

For production projects, consider adding Alembic:
```bash
pip install alembic
alembic init migrations
# Configure and create migrations
```

## Related Examples

- `examples/demo-app-shared/` - Uses shared Docker Compose services
- `examples/demo-app-sandbox-basic/` - Basic tier (no firewall, minimal config)
- `examples/demo-app-sandbox-intermediate/` - Intermediate tier (permissive firewall, message queue)
- `examples/demo-app-sandbox-yolo/` - YOLO tier (full customization)
- `examples/streamlit-sandbox-basic/` - Simpler Python-only app

## Learn More

- [Claude Code Sandbox Documentation](../../docs/)
- [Security Model](../../docs/security-model.md)
- [Development Guide](../../DEVELOPMENT.md)
- [Contributing](../../CONTRIBUTING.md)

## License

MIT
