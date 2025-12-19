# Example: Python Project with PostgreSQL and Redis

Complete configuration for a Python web application using FastAPI, PostgreSQL, and Redis.

## Project Structure

```
my-python-project/
├── .devcontainer/
│   ├── devcontainer.json
│   ├── Dockerfile
│   └── init-firewall.sh
├── docker-compose.yml
├── requirements.txt
├── pyproject.toml
├── src/
│   ├── __init__.py
│   ├── main.py
│   └── db.py
└── tests/
    └── test_main.py
```

## Configuration Files

### .devcontainer/devcontainer.json

```json
{
  "name": "My Python App Sandbox",
  "build": {
    "dockerfile": "Dockerfile",
    "context": "..",
    "args": {
      "TZ": "${localEnv:TZ:America/Los_Angeles}",
      "CLAUDE_CODE_VERSION": "latest",
      "GIT_DELTA_VERSION": "0.18.2",
      "ZSH_IN_DOCKER_VERSION": "1.2.0"
    }
  },
  "runArgs": [
    "--cap-add=NET_ADMIN",
    "--cap-add=NET_RAW",
    "--network=python-app-network"
  ],
  "containerUser": "node",
  "remoteUser": "node",
  "mounts": [
    {
      "source": "claude-code-bashhistory-${devcontainerId}",
      "target": "/home/node/.bash_history_dir",
      "type": "volume"
    },
    {
      "source": "claude-code-config-${devcontainerId}",
      "target": "/home/node/.claude",
      "type": "volume"
    }
  ],
  "workspaceMount": "source=${localWorkspaceFolder},target=/workspace,type=bind,consistency=delegated",
  "workspaceFolder": "/workspace",
  "postStartCommand": "/usr/local/bin/init-firewall.sh",
  "customizations": {
    "vscode": {
      "extensions": [
        "anthropic.claude-code",
        "ms-python.python",
        "ms-python.vscode-pylance",
        "ms-python.black-formatter",
        "charliermarsh.ruff",
        "dbaeumer.vscode-eslint",
        "esbenp.prettier-vscode",
        "eamodio.gitlens"
      ],
      "settings": {
        "terminal.integrated.defaultProfile.linux": "zsh",
        "python.defaultInterpreterPath": "/workspace/.venv/bin/python",
        "python.formatting.provider": "black",
        "python.linting.enabled": true,
        "python.linting.ruffEnabled": true,
        "editor.formatOnSave": true,
        "editor.tabSize": 4
      }
    }
  },
  "containerEnv": {
    "HISTFILE": "/home/node/.bash_history_dir/.bash_history",
    "FIREWALL_MODE": "strict",
    "PYTHONPATH": "/workspace/src",
    "DATABASE_URL": "postgresql+asyncpg://myapp:devpass@postgres:5432/myapp_db",
    "REDIS_URL": "redis://redis:6379/0",
    "ENVIRONMENT": "development"
  }
}
```

### .devcontainer/Dockerfile

```dockerfile
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim

ARG TZ=America/Los_Angeles
ARG CLAUDE_CODE_VERSION=latest
ARG GIT_DELTA_VERSION=0.18.2
ARG ZSH_IN_DOCKER_VERSION=1.2.0

ENV TZ="$TZ"

# Install system packages
RUN apt-get update && apt-get install -y --no-install-recommends \
  git vim nano less procps sudo unzip wget curl ca-certificates gnupg gnupg2 \
  jq man-db zsh fzf gh \
  iptables ipset iproute2 dnsutils \
  python3-venv python3-pip \
  build-essential libpq-dev \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Node.js (for Claude Code CLI)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
  apt-get install -y nodejs && \
  apt-get clean && rm -rf /var/lib/apt/lists/*

# Create node user
RUN groupadd --gid 1000 node && \
  useradd --uid 1000 --gid node --shell /bin/bash --create-home node

RUN mkdir -p /usr/local/share/npm-global && \
  chown -R node:node /usr/local/share

# Persistent bash history
RUN mkdir /commandhistory && \
  touch /commandhistory/.bash_history && \
  chown -R node /commandhistory

ENV DEVCONTAINER=true

# Create workspace and config directories
RUN mkdir -p /workspace /home/node/.claude && \
  chown -R node:node /workspace /home/node/.claude

WORKDIR /workspace

# Pre-install Python dependencies
COPY requirements.txt /tmp/
RUN pip install --no-cache-dir -r /tmp/requirements.txt && \
  rm /tmp/requirements.txt

# Install git-delta
RUN ARCH=$(dpkg --print-architecture) && \
  wget "https://github.com/dandavison/delta/releases/download/${GIT_DELTA_VERSION}/git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
  dpkg -i "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
  rm "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb"

USER node

# Global npm configuration
ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$PATH:/usr/local/share/npm-global/bin

# ZSH with Powerlevel10k
ENV SHELL=/bin/zsh

RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v${ZSH_IN_DOCKER_VERSION}/zsh-in-docker.sh)" -- \
  -p git -p fzf \
  -a "source /usr/share/doc/fzf/examples/key-bindings.zsh" \
  -a "source /usr/share/doc/fzf/examples/completion.zsh" \
  -a "export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
  -x

ENV EDITOR=nano
ENV VISUAL=nano

# Install Claude Code
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}

# Set up firewall script
COPY .devcontainer/init-firewall.sh /usr/local/bin/
USER root
RUN chmod +x /usr/local/bin/init-firewall.sh && \
  echo "node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/node-firewall && \
  chmod 0440 /etc/sudoers.d/node-firewall
USER node
```

### docker-compose.yml

```yaml
services:
  # PostgreSQL Database
  postgres:
    image: postgres:15
    container_name: python-app-postgres
    environment:
      POSTGRES_DB: myapp_db
      POSTGRES_USER: myapp
      POSTGRES_PASSWORD: devpass
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U myapp -d myapp_db"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Redis Cache
  redis:
    image: redis:7-alpine
    container_name: python-app-redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Adminer (Database UI - Optional)
  adminer:
    image: adminer:latest
    container_name: python-app-adminer
    ports:
      - "8080:8080"
    environment:
      ADMINER_DEFAULT_SERVER: postgres

volumes:
  postgres_data:
  redis_data:

networks:
  default:
    name: python-app-network
```

### requirements.txt

```txt
# Web Framework
fastapi==0.109.0
uvicorn[standard]==0.27.0

# Database
sqlalchemy==2.0.25
asyncpg==0.29.0
alembic==1.13.1

# Redis
redis==5.0.1
aioredis==2.0.1

# Utilities
pydantic==2.5.3
pydantic-settings==2.1.0
python-dotenv==1.0.0

# Development
pytest==7.4.4
pytest-asyncio==0.23.3
httpx==0.26.0
black==24.1.1
ruff==0.1.14
```

### .devcontainer/init-firewall.sh

Copy the template firewall script and customize the allowed domains:

```bash
ALLOWED_DOMAINS=(
  # Version control
  "github.com"

  # Package registries
  "pypi.org"
  "files.pythonhosted.org"

  # AI providers
  "api.anthropic.com"

  # Analytics
  "sentry.io"

  # VS Code
  "marketplace.visualstudio.com"
  "vscode.blob.core.windows.net"
  "update.code.visualstudio.com"
)
```

## Application Code Examples

### src/main.py

```python
from fastapi import FastAPI, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from redis import Redis
import os

app = FastAPI(title="My Python App")

@app.get("/")
async def root():
    return {"message": "Hello from Claude Code sandbox!"}

@app.get("/health")
async def health():
    return {
        "status": "healthy",
        "database": os.getenv("DATABASE_URL", "").split("@")[1] if "@" in os.getenv("DATABASE_URL", "") else "not configured",
        "redis": os.getenv("REDIS_URL", "not configured")
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

### src/db.py

```python
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import declarative_base
import os

# NOTE: For passwords with special characters (@, :, /, etc.), use urllib.parse.quote()
# from urllib.parse import quote
# DATABASE_URL = f"postgresql+asyncpg://{quote(user, safe='')}:{quote(password, safe='')}@host:port/db"
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql+asyncpg://myapp:devpass@postgres:5432/myapp_db")

engine = create_async_engine(DATABASE_URL, echo=True)
async_session_maker = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
Base = declarative_base()

async def get_db():
    async with async_session_maker() as session:
        yield session
```

## Setup Instructions

### 1. Copy Template Files

```bash
cd my-python-project
cp -r /path/to/template/.devcontainer .
cp /path/to/template/docker-compose.base.yml docker-compose.yml
```

### 2. Create Python Files

```bash
mkdir -p src tests
touch src/__init__.py src/main.py src/db.py
touch tests/test_main.py
touch requirements.txt
```

### 3. Start Services

```bash
docker compose up -d
```

### 4. Open in DevContainer

```bash
code .
# Ctrl+Shift+P → "Dev Containers: Reopen in Container"
```

### 5. Set Up Python Environment

Inside the DevContainer:

```bash
# Create virtual environment
python -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run application
python src/main.py
```

### 6. Test Database Connection

```bash
# PostgreSQL
psql postgresql://myapp:devpass@postgres:5432/myapp_db

# Redis
redis-cli -h redis ping
```

## Development Workflow

### Running the Application

```bash
# Activate venv
source .venv/bin/activate

# Run with hot reload
uvicorn src.main:app --reload --host 0.0.0.0 --port 8000
```

Access at: http://localhost:8000

### Running Tests

```bash
pytest tests/
```

### Database Migrations with Alembic

```bash
# Initialize Alembic
alembic init alembic

# Create migration
alembic revision --autogenerate -m "Initial migration"

# Apply migration
alembic upgrade head
```

### Using Claude Code

```bash
# Start Claude Code session
claude

# Ask Claude to help with your code
# Claude has access to your entire workspace
```

## Firewall Configuration

This setup uses **strict mode** by default. The firewall allows:

- `pypi.org` and `files.pythonhosted.org` for pip
- `api.anthropic.com` for Claude Code
- `github.com` for git operations

To add more domains, edit `.devcontainer/init-firewall.sh`:

```bash
ALLOWED_DOMAINS=(
  "pypi.org"
  "files.pythonhosted.org"
  "your-api.com"  # Add your domains here
)
```

Then restart the firewall:

```bash
sudo /usr/local/bin/init-firewall.sh
```

## Common Tasks

### Install New Package

```bash
pip install package-name
pip freeze > requirements.txt
```

Then rebuild the container to bake it into the image.

### Access Database UI

Adminer is available at: http://localhost:8080

- System: PostgreSQL
- Server: postgres
- Username: myapp
- Password: devpass
- Database: myapp_db

### View Logs

```bash
# Application logs
# (Your application output)

# Service logs
docker compose logs -f postgres
docker compose logs -f redis
```

## Troubleshooting

### Can't connect to database

```bash
# Check if postgres is healthy
docker compose ps

# Test connection
psql postgresql://myapp:devpass@postgres:5432/myapp_db -c "SELECT 1"
```

### Package installation fails

```bash
# Switch to permissive firewall temporarily
export FIREWALL_MODE=permissive
sudo /usr/local/bin/init-firewall.sh

# Install packages
pip install -r requirements.txt

# Switch back to strict
export FIREWALL_MODE=strict
sudo /usr/local/bin/init-firewall.sh
```

## Next Steps

- Add more models to `src/models.py`
- Implement authentication with JWT
- Add background tasks with Celery
- Integrate with external APIs
- Deploy to production

## Additional Resources

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [SQLAlchemy 2.0 Documentation](https://docs.sqlalchemy.org/en/20/)
- [Alembic Tutorial](https://alembic.sqlalchemy.org/en/latest/tutorial.html)
- [Redis Python Client](https://redis-py.readthedocs.io/)

---

**Last Updated:** 2025-12-16
**Version:** 2.2.2
