# Demo Blog Application - Basic Mode Sandbox

This is a **self-contained** example demonstrating the Claude Code Sandbox DevContainer setup in **Basic mode**. It includes a full-stack blog application with Python FastAPI backend and React frontend.

## What is Basic Mode?

Basic mode is designed for developers who want:
- **Quick setup** with minimal configuration (using sandbox templates or official images)
- **No firewall** - relies on hypervisor-level Windows Sandbox isolation
- **Sensible defaults** automatically applied
- **Auto-detection** of project type and dependencies
- **Minimal configuration files** for fastest setup

This example shows what the `windows-sandbox` plugin generates when run in Basic mode on a full-stack application.

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

### DevContainer Features (Basic Mode)
- **Auto-detected stack**: Python 3.12 + Node.js 20
- **Database services**: PostgreSQL 15 + Redis 7
- **Network security**: No firewall (relies on Windows Sandbox hypervisor isolation)
- **VS Code extensions**: Python and ESLint (minimal set)
- **Port forwarding**: Backend (8000), Frontend (5173), PostgreSQL (5432), Redis (6379)

## Quick Start

### Prerequisites
- Docker Desktop
- Visual Studio Code with Dev Containers extension

### Steps

1. **Open in VS Code**:
   ```bash
   code examples/demo-app-sandbox-basic
   ```

2. **Reopen in Container**:
   - Press `F1` or `Ctrl+Shift+P`
   - Select: `Dev Containers: Reopen in Container`
   - Wait for container to build and start (first time takes 2-3 minutes)

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
   - Frontend: http://localhost:5173
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

## DevContainer Configuration (Basic Mode)

### What the Plugin Generated

**devcontainer.json**:
- Minimal configuration with sensible defaults
- Auto-detected Python + Node.js stack
- Essential VS Code extensions (Python, ESLint)
- Simple post-create command for dependency installation
- No firewall initialization (Basic mode relies on sandbox isolation)

**Dockerfile**:
- Flexible base image: `python:3.12-slim-bookworm`
- Node.js 20 installation
- Minimal system dependencies
- Non-root user (`node`) for security
- No firewall tools (keeping it simple)

**docker-compose.yml**:
- App container with minimal configuration
- PostgreSQL 15 with health checks
- Redis 7 with health checks
- Isolated network for services
- Persistent volumes for data
- No NET_ADMIN/NET_RAW capabilities (not needed without firewall)

**init-firewall.sh**:
- No firewall configured (Basic mode)
- Outputs informational message about security model
- Relies on Windows Sandbox hypervisor-level isolation
- Ephemeral environment provides security

## Customization

### Upgrade to Higher Mode

If you need network-level security controls:

**Intermediate Mode**: Add permissive firewall (no restrictions, but audit logging)
- Copy configuration from `demo-app-sandbox-intermediate/`

**Advanced Mode**: Add strict firewall with customizable allowlist
- Copy configuration from `demo-app-sandbox-advanced/`

**YOLO Mode**: Full customization with optional firewall
- Copy configuration from `demo-app-sandbox-yolo/`

### Add VS Code Extensions

Edit `.devcontainer/devcontainer.json`:
```json
{
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python",
        "dbaeumer.vscode-eslint",
        "ms-python.vscode-pylance"  // Add more here
      ]
    }
  }
}
```

## Troubleshooting

### Database Connection Issues
If you see database connection errors:
```bash
# Wait for PostgreSQL to be ready
docker-compose logs postgres
```

### Network Access Issues
Basic mode has no firewall restrictions. If you experience network issues:
```bash
# Check DNS resolution
nslookup example.com

# Check network connectivity
ping 8.8.8.8

# View network configuration
ip addr show
```

### Port Already in Use
```bash
# Stop conflicting services
docker-compose down

# Or change ports in devcontainer.json
"forwardPorts": [8001, 5174, 5433, 6380]
```

## Comparing to Other Modes

| Feature | Basic | Intermediate | Advanced | YOLO |
|---------|-------|--------------|----------|------|
| Questions asked | 1-2 | 3-5 | 5-7 | 10-15+ |
| Configuration style | Auto-detected | Platform-specific | Customizable | Fully explicit |
| Dockerfile | Sandbox template/official image | Platform template | Configurable | Technology-optimized |
| VS Code extensions | Essential (2) | Basic (5) | Curated (10+) | Comprehensive (20+) |
| Firewall | None | Permissive | Strict | Configurable |
| Services | Essential only | + Message queue | + Resource limits | All available |
| Best for | Quick start | Learning | Production dev | Full control |

## Related Examples

- `examples/demo-app-shared/` - Uses shared Docker Compose services
- `examples/demo-app-sandbox-intermediate/` - Intermediate mode with permissive firewall
- `examples/demo-app-sandbox-advanced/` - Advanced mode with strict firewall
- `examples/demo-app-sandbox-yolo/` - YOLO mode with full customization
- `examples/streamlit-sandbox-basic/` - Simpler Python-only app

## Learn More

- [Claude Code Sandbox Documentation](../../docs/)
- [Security Model](../../docs/security-model.md)
- [Development Guide](../../DEVELOPMENT.md)
- [Contributing](../../CONTRIBUTING.md)

## License

MIT
