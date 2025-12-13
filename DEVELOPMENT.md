# Development Guide

This guide explains how to develop and test the Claude Code Sandbox Plugin using its own devcontainer configuration.

## Overview

This plugin uses itself for development (dogfooding approach). The devcontainer provides a complete isolated environment with all necessary services and tools.

## Prerequisites

- **Docker Desktop** (Windows/Mac) or **Docker Engine** (Linux)
- **Visual Studio Code** with the **Dev Containers** extension
- **Claude Code CLI** installed and configured

## Quick Start

### Option 1: Using Claude Code (Recommended)

1. Open this repository in your terminal
2. Start Claude Code:
   ```bash
   claude-code
   ```
3. Ask Claude to set up the development environment:
   ```
   Please set up the devcontainer for development
   ```
4. Claude will generate and start the devcontainer using the plugin's templates

### Option 2: Manual Setup

1. Open this repository in VS Code
2. Press `F1` and select **Dev Containers: Reopen in Container**
3. Wait for the container to build and start (first time takes 3-5 minutes)
4. Once ready, you'll have a complete development environment

## What's Included

The devcontainer provides:

### Services
- **PostgreSQL 15**: Database for testing backend applications
  - Host: `postgres`
  - Port: `5432` (exposed to host)
  - Database: `sandbox_dev`
  - User: `sandbox_user`
  - Password: `devpassword`

- **Redis 7**: Cache and session store for testing
  - Host: `redis`
  - Port: `6379` (exposed to host)

### Development Tools
- **Python 3.12** with `uv` package manager
- **Node.js 20** with `npm`
- **Git** with bash history persistence
- **PostgreSQL client tools** (`psql`)
- **Redis client tools** (`redis-cli`)

### VS Code Extensions
- Python (ms-python.python)
- Pylance (ms-python.vscode-pylance)
- Python Debugger (ms-python.debugpy)
- Jest (orta.vscode-jest)
- ESLint (dbaeumer.vscode-eslint)

## Project Structure

```
windows-sandbox-plugin/
├── .devcontainer/           # DevContainer configuration
│   ├── Dockerfile           # Container image definition
│   ├── devcontainer.json    # VS Code container settings
│   └── init-firewall.sh     # Firewall initialization script
├── docker-compose.yml       # Service orchestration
├── examples/                # Example applications
│   ├── basic-streamlit/     # Quick validation example
│   │   ├── app.py          # Streamlit app with DB/Redis tests
│   │   ├── requirements.txt
│   │   └── README.md
│   └── demo-app/           # Full-stack demo application
│       ├── backend/        # FastAPI + SQLAlchemy + Redis
│       │   ├── app/        # Application code
│       │   └── tests/      # Pytest test suite
│       ├── frontend/       # React + Vite
│       │   └── src/        # Components and tests
│       ├── run-tests.sh    # Test runner (bash)
│       └── run-tests.ps1   # Test runner (PowerShell)
├── templates/              # Devcontainer templates
│   ├── python/            # Python project template
│   ├── nodejs/            # Node.js project template
│   └── fullstack/         # Full-stack template
└── skills/                # Claude Code skills
    ├── sandbox-setup.md
    ├── sandbox-troubleshoot.md
    └── sandbox-security.md
```

## Development Workflow

### 1. Quick Validation

Test that services are running using the basic Streamlit example:

```bash
cd examples/basic-streamlit
uv pip install -r requirements.txt
streamlit run app.py
```

Open the displayed URL and click the test buttons to verify PostgreSQL and Redis connectivity.

### 2. Working with the Demo Application

The demo app is a full-stack blogging platform showcasing real-world patterns.

#### Backend Development

```bash
cd examples/demo-app/backend

# Install dependencies
uv pip install -r requirements.txt

# Run database migrations
alembic upgrade head

# Start the API server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

The API will be available at http://localhost:8000
- API docs: http://localhost:8000/docs
- Alternative docs: http://localhost:8000/redoc

#### Frontend Development

```bash
cd examples/demo-app/frontend

# Install dependencies
npm install

# Start the dev server
npm run dev
```

The frontend will be available at http://localhost:5173

### 3. Running Tests

#### All Tests (Recommended)

From the `examples/demo-app` directory:

**On Linux/Mac:**
```bash
./run-tests.sh
```

**On Windows:**
```powershell
.\run-tests.ps1
```

**With Coverage:**
```bash
./run-tests.sh --coverage
# or
.\run-tests.ps1 -Coverage
```

#### Backend Tests Only

```bash
cd examples/demo-app/backend
pytest
# or with coverage
pytest --cov=app --cov-report=term-missing --cov-report=html
```

Coverage report: `backend/htmlcov/index.html`

#### Frontend Tests Only

```bash
cd examples/demo-app/frontend
npm test
# or with coverage
npm test -- --coverage
```

Coverage report: `frontend/coverage/index.html`

### 4. Database Management

#### Using psql

```bash
# Connect to the database
psql -h postgres -U sandbox_user -d sandbox_dev

# List tables
\dt

# View table structure
\d posts

# Run queries
SELECT * FROM posts;

# Exit
\q
```

#### Using Alembic (Migrations)

```bash
cd examples/demo-app/backend

# Create a new migration
alembic revision --autogenerate -m "Description of changes"

# Apply migrations
alembic upgrade head

# Rollback one version
alembic downgrade -1

# View migration history
alembic history
```

### 5. Cache Management

#### Using redis-cli

```bash
# Connect to Redis
redis-cli -h redis

# View all keys
KEYS *

# Get a value
GET post:1:content

# View view count
GET post:1:views

# Clear all data
FLUSHALL

# Exit
exit
```

## Testing the Plugin

### Manual Testing

1. **Template Generation**: Use the plugin skills to generate configurations for different project types
2. **Service Verification**: Ensure PostgreSQL and Redis are accessible
3. **Network Security**: Test firewall rules in different modes
4. **Port Exposure**: Verify services are accessible from the host

### Automated Testing

The example applications include comprehensive test suites:

- **Backend**: 8 tests covering API endpoints and caching logic
- **Frontend**: 20+ tests covering component rendering, user interactions, and API calls

Run all tests to validate the entire environment:
```bash
cd examples/demo-app
./run-tests.sh --coverage
```

## Troubleshooting

### Services Not Starting

If PostgreSQL or Redis fail to start:

1. Check Docker is running:
   ```bash
   docker ps
   ```

2. View service logs:
   ```bash
   docker-compose logs postgres
   docker-compose logs redis
   ```

3. Restart services:
   ```bash
   docker-compose down
   docker-compose up -d
   ```

### Database Connection Issues

If you can't connect to PostgreSQL:

1. Verify the service is healthy:
   ```bash
   docker-compose ps
   ```

2. Test connection manually:
   ```bash
   psql -h postgres -U sandbox_user -d sandbox_dev
   ```

3. Check environment variables:
   ```bash
   echo $DATABASE_URL
   ```

### Port Conflicts

If you see "port already in use" errors:

1. Check what's using the port:
   ```bash
   # Linux/Mac
   lsof -i :5432

   # Windows
   netstat -ano | findstr :5432
   ```

2. Either stop the conflicting service or change the port in `docker-compose.yml`

### Container Build Failures

If the container fails to build:

1. Rebuild without cache:
   ```bash
   docker-compose build --no-cache
   ```

2. Check Docker Desktop has sufficient resources (4GB+ RAM recommended)

3. Clear Docker cache:
   ```bash
   docker system prune -a
   ```

### Test Failures

If tests fail:

1. Ensure all services are running:
   ```bash
   docker-compose ps
   ```

2. Check test output for specific errors

3. For frontend tests, ensure dependencies are installed:
   ```bash
   cd examples/demo-app/frontend
   npm install
   ```

## Environment Variables

The devcontainer sets these environment variables:

| Variable | Value | Purpose |
|----------|-------|---------|
| `DATABASE_URL` | `postgresql://sandbox_user:devpassword@postgres:5432/sandbox_dev` | PostgreSQL connection string |
| `REDIS_URL` | `redis://redis:6379` | Redis connection string |
| `FIREWALL_MODE` | `permissive` | Sandbox firewall mode |
| `DEVELOPMENT_MODE` | `true` | Enable development features |
| `HISTFILE` | `/home/node/.bash_history_dir/.bash_history` | Persistent bash history |

## Advanced Topics

### Customizing the Devcontainer

To modify the devcontainer configuration:

1. Edit `.devcontainer/devcontainer.json` for VS Code settings
2. Edit `.devcontainer/Dockerfile` to add system packages
3. Edit `docker-compose.yml` to add or modify services
4. Rebuild the container:
   ```
   F1 → Dev Containers: Rebuild Container
   ```

### Adding New Services

To add a service (e.g., MongoDB):

1. Add to `docker-compose.yml`:
   ```yaml
   mongo:
     image: mongo:latest
     ports:
       - "27017:27017"
     networks:
       - windows-sandbox-network
   ```

2. Update environment variables in `.devcontainer/devcontainer.json`

3. Rebuild and restart the container

### Testing Different Firewall Modes

Change the `FIREWALL_MODE` environment variable:

- `permissive`: All outbound traffic allowed (development)
- `basic`: Restricted to common services (testing)
- `advanced`: Strict allowlist (staging)
- `pro`: Maximum restrictions (production)

## Best Practices

1. **Always run tests** before committing changes
2. **Use the test runner scripts** for consistent results
3. **Check coverage reports** to ensure adequate test coverage
4. **Commit database migrations** with related code changes
5. **Document new features** in the relevant README files
6. **Test in different firewall modes** to ensure compatibility

## Getting Help

- Check the [main README](README.md) for plugin overview
- Review [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines
- Use Claude Code's troubleshooting skill:
  ```
  /sandbox-troubleshoot
  ```
- Open an issue on GitHub for bugs or feature requests

## Next Steps

1. Explore the example applications to understand the plugin's capabilities
2. Try generating devcontainer configurations for your own projects
3. Experiment with different firewall modes
4. Contribute improvements back to the plugin
