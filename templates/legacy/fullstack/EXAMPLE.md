# Example: Full-Stack Project with AI Integration

Complete configuration for a full-stack application with:
- **Backend**: Python FastAPI
- **Frontend**: React + TypeScript + Vite
- **Database**: PostgreSQL
- **Cache**: Redis
- **AI**: Ollama (local LLM with GPU acceleration)

## Project Structure

```
my-fullstack-app/
├── .devcontainer/
│   ├── devcontainer.json
│   ├── Dockerfile
│   └── init-firewall.sh
├── docker-compose.yml
├── backend/
│   ├── requirements.txt
│   ├── main.py
│   ├── models.py
│   └── ai/
│       └── ollama_client.py
└── frontend/
    ├── package.json
    ├── tsconfig.json
    ├── vite.config.ts
    ├── index.html
    └── src/
        ├── main.tsx
        ├── App.tsx
        └── api/
            └── client.ts
```

## Configuration Files

### .devcontainer/devcontainer.json

```json
{
  "name": "Full-Stack AI App Sandbox",
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
    "--network=fullstack-network"
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
  "postCreateCommand": "cd /workspace/frontend && npm install",
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
        "python.defaultInterpreterPath": "/workspace/backend/.venv/bin/python",
        "editor.formatOnSave": true,
        "editor.tabSize": 2,
        "[python]": {
          "editor.tabSize": 4
        }
      }
    }
  },
  "containerEnv": {
    "HISTFILE": "/home/node/.bash_history_dir/.bash_history",
    "FIREWALL_MODE": "strict",
    "PYTHONPATH": "/workspace/backend",
    "DATABASE_URL": "postgresql+asyncpg://fullstack:devpass@postgres:5432/fullstack_db",
    "REDIS_URL": "redis://redis:6379/0",
    "OLLAMA_ENDPOINT": "http://ollama:11434",
    "OLLAMA_MODEL": "qwen2.5:7b",
    "BACKEND_PORT": "8000",
    "FRONTEND_PORT": "5173"
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
  python3-venv python3-pip build-essential libpq-dev \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Node.js 20
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

# Pre-install backend dependencies
COPY backend/requirements.txt /tmp/
RUN pip install --no-cache-dir -r /tmp/requirements.txt && \
  rm /tmp/requirements.txt

# Pre-install frontend dependencies
COPY --chown=node:node frontend/package*.json /workspace/frontend/
RUN cd /workspace/frontend && \
  npm ci && \
  chown -R node:node /workspace/frontend/node_modules

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
    container_name: fullstack-postgres
    environment:
      POSTGRES_DB: fullstack_db
      POSTGRES_USER: fullstack
      POSTGRES_PASSWORD: devpass
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U fullstack -d fullstack_db"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Redis Cache
  redis:
    image: redis:7-alpine
    container_name: fullstack-redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    command: redis-server --appendonly yes
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Ollama AI Service (Requires NVIDIA GPU)
  ollama:
    image: ollama/ollama:latest
    container_name: fullstack-ollama
    ports:
      - "11434:11434"
    volumes:
      - ollama_data:/root/.ollama
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:11434/api/tags || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
    restart: unless-stopped

  # Backend API (Optional - can run directly in DevContainer)
  # backend:
  #   build:
  #     context: ./backend
  #   container_name: fullstack-backend
  #   environment:
  #     DATABASE_URL: postgresql+asyncpg://fullstack:devpass@postgres:5432/fullstack_db
  #     REDIS_URL: redis://redis:6379/0
  #     OLLAMA_ENDPOINT: http://ollama:11434
  #   ports:
  #     - "8000:8000"
  #   depends_on:
  #     postgres:
  #       condition: service_healthy
  #     redis:
  #       condition: service_healthy
  #     ollama:
  #       condition: service_healthy

volumes:
  postgres_data:
  redis_data:
  ollama_data:

networks:
  default:
    name: fullstack-network
```

### .devcontainer/init-firewall.sh

```bash
ALLOWED_DOMAINS=(
  # Version control
  "github.com"

  # Package registries
  "registry.npmjs.org"
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

  # CDNs (for frontend development)
  "cdn.jsdelivr.net"
  "unpkg.com"
)
```

## Backend Code Examples

### backend/requirements.txt

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

# AI Integration
httpx==0.26.0

# Utilities
pydantic==2.5.3
pydantic-settings==2.1.0
python-dotenv==1.0.0

# Development
pytest==7.4.4
pytest-asyncio==0.23.3
black==24.1.1
```

### backend/main.py

```python
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import os
from ai.ollama_client import OllamaClient

app = FastAPI(title="Full-Stack AI App")

# CORS configuration for frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

ollama = OllamaClient(
    endpoint=os.getenv("OLLAMA_ENDPOINT", "http://ollama:11434"),
    model=os.getenv("OLLAMA_MODEL", "qwen2.5:7b")
)

class ChatRequest(BaseModel):
    message: str

class ChatResponse(BaseModel):
    response: str

@app.get("/")
async def root():
    return {"message": "Full-Stack AI App API"}

@app.get("/health")
async def health():
    return {
        "status": "healthy",
        "services": {
            "postgres": os.getenv("DATABASE_URL", "").split("@")[1] if "@" in os.getenv("DATABASE_URL", "") else "not configured",
            "redis": os.getenv("REDIS_URL", "not configured"),
            "ollama": os.getenv("OLLAMA_ENDPOINT", "not configured")
        }
    }

@app.post("/api/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    try:
        response = await ollama.generate(request.message)
        return ChatResponse(response=response)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("BACKEND_PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
```

### backend/ai/ollama_client.py

```python
import httpx
from typing import AsyncGenerator

class OllamaClient:
    def __init__(self, endpoint: str, model: str):
        self.endpoint = endpoint
        self.model = model
        self.client = httpx.AsyncClient(timeout=120.0)

    async def generate(self, prompt: str) -> str:
        """Generate a response from Ollama."""
        url = f"{self.endpoint}/api/generate"
        payload = {
            "model": self.model,
            "prompt": prompt,
            "stream": False
        }

        response = await self.client.post(url, json=payload)
        response.raise_for_status()

        data = response.json()
        return data.get("response", "")

    async def chat(self, messages: list[dict]) -> str:
        """Chat with Ollama using conversation history."""
        url = f"{self.endpoint}/api/chat"
        payload = {
            "model": self.model,
            "messages": messages,
            "stream": False
        }

        response = await self.client.post(url, json=payload)
        response.raise_for_status()

        data = response.json()
        return data.get("message", {}).get("content", "")

    async def close(self):
        await self.client.aclose()
```

## Frontend Code Examples

### frontend/package.json

```json
{
  "name": "fullstack-frontend",
  "private": true,
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "lint": "eslint . --ext ts,tsx --report-unused-disable-directives --max-warnings 0"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0"
  },
  "devDependencies": {
    "@types/react": "^18.2.48",
    "@types/react-dom": "^18.2.18",
    "@typescript-eslint/eslint-plugin": "^6.18.1",
    "@typescript-eslint/parser": "^6.18.1",
    "@vitejs/plugin-react": "^4.2.1",
    "eslint": "^8.56.0",
    "eslint-plugin-react-hooks": "^4.6.0",
    "eslint-plugin-react-refresh": "^0.4.5",
    "typescript": "^5.3.3",
    "vite": "^5.0.11"
  }
}
```

### frontend/vite.config.ts

```typescript
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    host: '0.0.0.0',
    port: 5173,
    proxy: {
      '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true
      }
    }
  }
})
```

### frontend/src/App.tsx

```typescript
import { useState } from 'react'

function App() {
  const [message, setMessage] = useState('')
  const [response, setResponse] = useState('')
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)

    try {
      const res = await fetch('/api/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ message })
      })

      if (!res.ok) throw new Error('Failed to get response')

      const data = await res.json()
      setResponse(data.response)
    } catch (error) {
      console.error('Error:', error)
      setResponse('Error: Failed to get response from AI')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div style={{ maxWidth: '800px', margin: '0 auto', padding: '2rem' }}>
      <h1>Full-Stack AI App</h1>
      <p>Powered by Claude Code Sandbox + Ollama</p>

      <form onSubmit={handleSubmit}>
        <textarea
          value={message}
          onChange={(e) => setMessage(e.target.value)}
          placeholder="Ask me anything..."
          rows={4}
          style={{ width: '100%', padding: '0.5rem' }}
        />
        <button
          type="submit"
          disabled={loading || !message}
          style={{ marginTop: '1rem', padding: '0.5rem 1rem' }}
        >
          {loading ? 'Thinking...' : 'Send'}
        </button>
      </form>

      {response && (
        <div style={{ marginTop: '2rem', padding: '1rem', background: '#f5f5f5', borderRadius: '4px' }}>
          <h3>Response:</h3>
          <p style={{ whiteSpace: 'pre-wrap' }}>{response}</p>
        </div>
      )}
    </div>
  )
}

export default App
```

## Setup Instructions

### 1. Prerequisites

**IMPORTANT: For AI features, you need:**
- NVIDIA GPU
- NVIDIA drivers installed on host
- nvidia-docker2 installed

### 2. Copy Template Files

```bash
cd my-fullstack-app
cp -r /path/to/template/.devcontainer .
cp /path/to/template/docker-compose.base.yml docker-compose.yml
```

### 3. Create Project Structure

```bash
mkdir -p backend/ai frontend/src/api
touch backend/main.py backend/requirements.txt backend/ai/ollama_client.py
touch frontend/package.json frontend/vite.config.ts frontend/src/App.tsx
```

### 4. Start Services

```bash
# Start infrastructure services
docker compose up -d postgres redis ollama

# Wait for Ollama to be healthy
docker compose ps

# Pull the AI model (first time only, ~5GB download)
docker exec fullstack-ollama ollama pull qwen2.5:7b
```

### 5. Open in DevContainer

```bash
code .
# Ctrl+Shift+P → "Dev Containers: Reopen in Container"
```

### 6. Set Up Backend

```bash
# Create virtual environment
cd /workspace/backend
python -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run backend
python main.py
```

Backend runs at: http://localhost:8000

### 7. Set Up Frontend

```bash
# Install dependencies (may already be done via postCreateCommand)
cd /workspace/frontend
npm install

# Run frontend
npm run dev
```

Frontend runs at: http://localhost:5173

### 8. Test AI Integration

Visit http://localhost:5173 and try chatting with the AI!

## Development Workflow

### Running Both Services

**Terminal 1 (Backend):**
```bash
cd /workspace/backend
source .venv/bin/activate
python main.py
```

**Terminal 2 (Frontend):**
```bash
cd /workspace/frontend
npm run dev
```

### Using Claude Code

```bash
claude

# Ask Claude to help:
# - "Add user authentication to the API"
# - "Create a component for displaying chat history"
# - "Optimize the database queries"
# - "Add streaming responses from Ollama"
```

## AI Model Management

### List Available Models

```bash
docker exec fullstack-ollama ollama list
```

### Pull New Model

```bash
docker exec fullstack-ollama ollama pull llama2
```

### Remove Model

```bash
docker exec fullstack-ollama ollama rm qwen2.5:7b
```

### Change Model

Edit `docker-compose.yml` or `.devcontainer/devcontainer.json`:

```yaml
environment:
  OLLAMA_MODEL: llama2  # Change this
```

Restart the backend server.

## Database Management

### Run Migrations

```bash
cd /workspace/backend

# Create migration
alembic revision --autogenerate -m "Add users table"

# Apply migration
alembic upgrade head
```

### Access Database

```bash
psql postgresql://fullstack:devpass@postgres:5432/fullstack_db
```

## API Testing

### Using curl

```bash
# Health check
curl http://localhost:8000/health

# Chat endpoint
curl -X POST http://localhost:8000/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello, AI!"}'
```

### Using httpie

```bash
http POST http://localhost:8000/api/chat message="Hello, AI!"
```

## Performance Optimization

### GPU Monitoring

```bash
# Monitor GPU usage
watch -n 1 nvidia-smi
```

### Ollama Settings

Edit `docker-compose.yml` to limit GPU usage:

```yaml
ollama:
  environment:
    OLLAMA_NUM_GPU: 1  # Limit to 1 GPU
    OLLAMA_GPU_LAYERS: 32  # Adjust for memory
```

### Frontend Build Optimization

```bash
cd /workspace/frontend
npm run build
npm run preview
```

## Troubleshooting

### Ollama won't start (No GPU)

If you don't have an NVIDIA GPU, remove the GPU configuration:

```yaml
ollama:
  image: ollama/ollama:latest
  # Remove deploy section
  ports:
    - "11434:11434"
```

Ollama will run on CPU (slower).

### Frontend can't reach backend

Check the Vite proxy configuration in `vite.config.ts`:

```typescript
server: {
  proxy: {
    '/api': {
      target: 'http://localhost:8000',  // Must match backend port
      changeOrigin: true
    }
  }
}
```

### AI responses are slow

- Use a smaller model (e.g., `qwen2.5:1.8b` instead of `qwen2.5:7b`)
- Reduce context length
- Use GPU acceleration
- Increase Ollama timeout in `ollama_client.py`

## Production Deployment

For production, consider:

1. **Backend**: Deploy to cloud with proper security
2. **Frontend**: Build and serve static files
3. **Database**: Use managed PostgreSQL (AWS RDS, etc.)
4. **AI**: Use cloud AI APIs instead of local Ollama
5. **Monitoring**: Add logging, metrics, error tracking
6. **Security**: Enable authentication, rate limiting, HTTPS

## Next Steps

- Add user authentication (JWT)
- Implement chat history storage
- Add streaming responses
- Create more complex AI workflows
- Add testing (pytest for backend, vitest for frontend)
- Set up CI/CD pipeline
- Add Docker production images

## Additional Resources

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [React Documentation](https://react.dev/)
- [Ollama Documentation](https://github.com/ollama/ollama/tree/main/docs)
- [Vite Documentation](https://vitejs.dev/)
- [SQLAlchemy Documentation](https://docs.sqlalchemy.org/)

---

**Last Updated:** 2025-12-16
**Version:** 3.0.0
