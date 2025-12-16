# Demo Blog Application - Intermediate Mode Sandbox

This is a **self-contained** example demonstrating the Claude Code Sandbox DevContainer setup in **Intermediate mode**. It includes a full-stack blog application with Python FastAPI backend, React frontend, and RabbitMQ message queue.

## What is Intermediate Mode?

Intermediate mode is designed for developers who want:
- **Platform-specific configuration** using templates (Python, Node.js, etc.)
- **Permissive firewall** for flexibility with audit logging
- **Build arguments** for version customization
- **Additional services** like message queues
- **More VS Code extensions** for enhanced productivity (5 essential extensions)

This example shows what the `windows-sandbox` plugin generates when run in Intermediate mode on a full-stack application.

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

### DevContainer Features (Intermediate Mode)
- **Configurable stack**: Python 3.12 + Node.js 20 (customizable via build args)
- **Database services**: PostgreSQL 15 + Redis 7
- **Message queue**: RabbitMQ 3 with management UI
- **Network security**: Permissive firewall (no restrictions, audit logging)
- **VS Code extensions**: 15-20 total including Python, Pylance, ESLint, Prettier, GitLens, Git Graph, Code Spell Checker, SQLTools, Material Icons, GitHub Theme, Andromeda, Peacock, Power Mode, and VS Code Pets
- **MCP servers**: 5 servers (filesystem, memory, sqlite, fetch, github) for enhanced AI integration
- **Port forwarding**: Backend (8000), Frontend (5173), PostgreSQL (5432), Redis (6379), RabbitMQ (5672), RabbitMQ Management (15672)

## Quick Start

### Prerequisites
- Docker Desktop
- Visual Studio Code with Dev Containers extension

### Steps

1. **Open in VS Code**:
   ```bash
   code examples/demo-app-sandbox-intermediate
   ```

2. **Reopen in Container**:
   - Press \`F1\` or \`Ctrl+Shift+P\`
   - Select: \`Dev Containers: Reopen in Container\`
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
   - RabbitMQ Management: http://localhost:15672 (guest/guest)

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

## DevContainer Configuration (Intermediate Mode)

### What the Plugin Generated

**devcontainer.json**:
- Platform-specific configuration
- 5 curated VS Code extensions (Python, Pylance, ESLint, Prettier, Docker)
- Firewall initialization on container start
- Dependency installation commands
- Port forwarding including RabbitMQ

**Dockerfile**:
- Build arguments for Python and Node.js versions
- Platform template: \`python:3.12-slim-bookworm\`
- Node.js installation from official repository
- Firewall tools (iptables, ipset) for permissive mode
- Non-root user (\`node\`) with sudo access for firewall

**docker-compose.yml**:
- Build args for version customization (PYTHON_VERSION, NODE_VERSION)
- App container with NET_ADMIN/NET_RAW capabilities for firewall
- PostgreSQL 15 with health checks
- Redis 7 with health checks
- RabbitMQ 3 with management plugin
- Isolated network for services
- Persistent volumes for data

**init-firewall.sh**:
- Permissive mode (no network restrictions)
- Clears any existing firewall rules
- Sets all policies to ACCEPT
- Provides informational messages about security model
- Container isolation is primary protection

## Customization

### Change Python or Node.js Version

Edit \`docker-compose.yml\`:
\`\`\`yaml
services:
  app:
    build:
      args:
        PYTHON_VERSION: "3.11"  # Change Python version
        NODE_VERSION: "18"      # Change Node.js version
\`\`\`

Then rebuild: \`Dev Containers: Rebuild Container\`

### Upgrade to Stricter Security

If you need network-level restrictions:

**Advanced Mode**: Add strict firewall with customizable allowlist
- Copy configuration from \`demo-app-sandbox-advanced/\`
- Provides whitelist-based network access control

**YOLO Mode**: Full customization with optional firewall
- Copy configuration from \`demo-app-sandbox-yolo/\`
- Maximum flexibility with all available options

### Add More VS Code Extensions

Edit \`.devcontainer/devcontainer.json\`:
\`\`\`json
{
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python",
        "ms-python.vscode-pylance",
        "dbaeumer.vscode-eslint",
        "esbenp.pretmode-vscode",
        "ms-azuretools.vscode-docker",
        "eamodio.gitlens"  // Add more here
      ]
    }
  }
}
\`\`\`

## Troubleshooting

### Database Connection Issues
If you see database connection errors:
\`\`\`bash
# Wait for PostgreSQL to be ready
docker-compose logs postgres

# Check health status
docker-compose ps
\`\`\`

### RabbitMQ Connection Issues
\`\`\`bash
# Check RabbitMQ logs
docker-compose logs rabbitmq

# Verify RabbitMQ is healthy
docker-compose exec rabbitmq rabbitmq-diagnostics ping
\`\`\`

### Firewall Issues
Intermediate mode uses permissive mode (no restrictions), but if you experience issues:
\`\`\`bash
# Check firewall status
sudo iptables -L -v

# Verify permissive mode
echo $FIREWALL_MODE  # Should output: permissive
\`\`\`

### Port Already in Use
\`\`\`bash
# Stop conflicting services
docker-compose down

# Or change ports in devcontainer.json
"forwardPorts": [8001, 5174, 5433, 6380, 5673, 15673]
\`\`\`

## Comparing to Other Modes

| Feature | Basic | Intermediate | Advanced | YOLO |
|---------|-------|--------------|----------|------|
| Questions asked | 1-2 | 3-5 | 5-7 | 10-15+ |
| Configuration style | Auto-detected | Platform-specific | Customizable | Fully explicit |
| Dockerfile | Sandbox template/official image | Platform template | Configurable | Technology-optimized |
| VS Code extensions | Essential (2) | Basic (5) | Curated (10+) | Comprehensive (20+) |
| Firewall | None | Permissive | Strict | Configurable |
| Services | Essential only | + Message queue | + Resource limits | All available |
| Build args | None | Python/Node versions | More options | All dependencies |
| Best for | Quick start | Learning | Production dev | Full control |

## Related Examples

- \`examples/demo-app-shared/\` - Uses shared Docker Compose services
- \`examples/demo-app-sandbox-basic/\` - Basic mode (no firewall, minimal config)
- \`examples/demo-app-sandbox-advanced/\` - Advanced mode with strict firewall
- \`examples/demo-app-sandbox-yolo/\` - YOLO mode with full customization
- \`examples/streamlit-sandbox-basic/\` - Simpler Python-only app

## Learn More

- [Claude Code Sandbox Documentation](../../docs/)
- [Security Model](../../docs/security-model.md)
- [Development Guide](../../DEVELOPMENT.md)
- [Contributing](../../CONTRIBUTING.md)

## License

MIT
