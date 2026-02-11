# Kroki Integration

## Overview

The DevContainer includes optional Kroki integration for self-hosted diagram rendering. Kroki supports multiple diagram types including Mermaid, PlantUML, GraphViz, and more, all running locally without external dependencies.

## Quick Start

### 1. Enable Kroki Service

Kroki is available via Docker Compose profiles:

```bash
# Start DevContainer with Kroki
docker compose --profile diagrams up -d

# Or combine with AI profile (Ollama)
docker compose --profile diagrams --profile ai up -d
```

### 2. Verify Service Health

```bash
# Check service status
docker compose --profile diagrams ps

# Test health endpoint
curl http://localhost:8010/health
```

### 3. Render a Diagram

```bash
# Inside DevContainer - render Mermaid diagram
curl -X POST http://kroki:8000/mermaid/svg \
  -H "Content-Type: text/plain" \
  -d "graph TD; A-->B"

# From host - same request to mapped port
curl -X POST http://localhost:8010/mermaid/svg \
  -H "Content-Type: text/plain" \
  -d "graph TD; A-->B"
```

## Engine Catalog

Supported diagram engines, all under 400MB total:

| Engine | Description | Output Formats |
|--------|-------------|----------------|
| `mermaid` | Flowcharts, sequence diagrams, ERDs, state diagrams | svg, png, pdf |
| `plantuml` | UML diagrams, C4 architecture, wireframes | svg, png, pdf, txt |
| `graphviz` | Graph visualization, dependency trees | svg, png, pdf |
| `ditaa` | ASCII art to diagrams | svg, png |
| `blockdiag` | Block diagrams for architecture | svg, png, pdf |
| `erd` | Entity-Relationship diagrams | svg, png, pdf |
| `nomnoml` | Simple UML-style diagrams | svg |
| `c4plantuml` | C4 architecture using PlantUML | svg, png, pdf |

Full catalog: `skills/_shared/templates/data/kroki-engines.json`

## Architecture

### Service Configuration

**docker-compose-profiles.yml**:
```yaml
kroki:
  profiles: [diagrams]
  image: yuzutech/kroki:latest
  container_name: {{PROJECT_NAME}}-kroki
  restart: unless-stopped
  environment:
    KROKI_SAFE_MODE: ${KROKI_SAFE_MODE:-secure}
    KROKI_MERMAID_HOST: kroki-mermaid
  ports:
    - "${KROKI_PORT:-8010}:8000"
  volumes:
    - kroki-cache:/var/cache/kroki
  healthcheck:
    test: ["CMD-SHELL", "wget -q --spider http://localhost:8000/health || exit 1"]
    interval: 30s
    timeout: 10s
    retries: 3
    start_period: 30s
  depends_on:
    - kroki-mermaid

kroki-mermaid:
  profiles: [diagrams]
  image: yuzutech/kroki-mermaid:latest
  container_name: {{PROJECT_NAME}}-kroki-mermaid
  expose:
    - "8002"
```

### Container Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Host Machine                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              Docker Network                      │   │
│  │  ┌─────────────┐    ┌──────────────────────┐   │   │
│  │  │  DevContainer│    │    kroki             │   │   │
│  │  │  (app)       │───▶│  :8000 (internal)    │   │   │
│  │  │              │    │  :8010 (host mapped) │   │   │
│  │  └─────────────┘    │                      │   │   │
│  │                      │  ┌────────────────┐  │   │   │
│  │                      │  │ PlantUML (JVM) │  │   │   │
│  │                      │  │ GraphViz       │  │   │   │
│  │                      │  │ Ditaa          │  │   │   │
│  │                      │  └────────────────┘  │   │   │
│  │                      └──────────┬───────────┘   │   │
│  │                                 │               │   │
│  │                      ┌──────────▼───────────┐   │   │
│  │                      │   kroki-mermaid      │   │   │
│  │                      │   :8002 (internal)   │   │   │
│  │                      │  ┌────────────────┐  │   │   │
│  │                      │  │ Puppeteer      │  │   │   │
│  │                      │  │ (Chromium)     │  │   │   │
│  │                      │  └────────────────┘  │   │   │
│  │                      └──────────────────────┘   │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

- **kroki**: Main service handling requests and routing to appropriate engines
- **kroki-mermaid**: Companion container for Mermaid (requires Puppeteer/Chromium)
- **Internal network**: `kroki-mermaid` is not exposed to host, only accessible via `kroki`

## Safe Mode (Security)

### The PlantUML Security Risk

PlantUML supports `!include` directives that can read arbitrary files:

```plantuml
@startuml
!include /etc/passwd
' This would expose sensitive file contents in the diagram output
@enduml
```

### KROKI_SAFE_MODE Configuration

| Mode | Value | Description |
|------|-------|-------------|
| **Secure** (default) | `secure` | Disables `!include`, `!import`, and external URL access |
| Unsafe | `unsafe` | Full PlantUML functionality (not recommended) |

**Default configuration** (in `.env`):
```bash
KROKI_SAFE_MODE=secure
```

### Verifying Safe Mode

Test that dangerous includes are blocked:

```bash
# This should fail or return sanitized output
curl -X POST http://localhost:8010/plantuml/svg \
  -H "Content-Type: text/plain" \
  -d "@startuml
!include /etc/passwd
@enduml"
```

With `KROKI_SAFE_MODE=secure`, this returns an error or sanitized diagram without file contents.

## API Reference

### Render Diagram

```bash
# POST /<engine>/<format>
curl -X POST http://kroki:8000/mermaid/svg \
  -H "Content-Type: text/plain" \
  -d "graph TD; A-->B"
```

### Supported Endpoints

| Endpoint | Description |
|----------|-------------|
| `POST /<engine>/<format>` | Render diagram (body = diagram source) |
| `GET /health` | Health check |
| `GET /<engine>/<format>/<encoded>` | GET with base64-encoded diagram |

### Output Formats

- `svg` - Scalable Vector Graphics (recommended for web)
- `png` - Portable Network Graphics
- `pdf` - PDF document
- `txt` - ASCII text (PlantUML only)

### Examples

**Mermaid Sequence Diagram**:
```bash
curl -X POST http://localhost:8010/mermaid/svg \
  -H "Content-Type: text/plain" \
  -d "sequenceDiagram
    Alice->>Bob: Hello
    Bob-->>Alice: Hi!"
```

**PlantUML Class Diagram**:
```bash
curl -X POST http://localhost:8010/plantuml/svg \
  -H "Content-Type: text/plain" \
  -d "@startuml
class User {
  +name: String
  +email: String
  +login()
}
@enduml"
```

**GraphViz Directed Graph**:
```bash
curl -X POST http://localhost:8010/graphviz/svg \
  -H "Content-Type: text/plain" \
  -d "digraph G {
    A -> B -> C
    B -> D
}"
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `KROKI_PORT` | `8010` | Host port for Kroki API |
| `KROKI_SAFE_MODE` | `secure` | Security mode (`secure` or `unsafe`) |
| `KROKI_URL` | `http://kroki:8000` | Internal URL (in containerEnv) |

## Troubleshooting

### Service not starting

```bash
# Check service status
docker compose --profile diagrams ps

# View logs
docker compose --profile diagrams logs kroki
docker compose --profile diagrams logs kroki-mermaid

# Restart services
docker compose --profile diagrams restart
```

### Mermaid diagrams failing

The Mermaid container requires Puppeteer (headless Chromium), which needs more memory:

```bash
# Check kroki-mermaid logs
docker compose --profile diagrams logs kroki-mermaid

# Verify container health
docker inspect <project>-kroki-mermaid --format='{{.State.Health.Status}}'
```

### Connection refused from DevContainer

Ensure you're using the internal hostname:

```bash
# Inside container - use service name
curl http://kroki:8000/health

# NOT localhost (which refers to the container itself)
# curl http://localhost:8000/health  # Wrong!
```

### Diagram syntax errors

Kroki returns HTTP 400 with error details for syntax issues:

```bash
# Check response for error message
curl -v -X POST http://localhost:8010/mermaid/svg \
  -H "Content-Type: text/plain" \
  -d "invalid diagram syntax"
```

## Integration Patterns

### Python Usage

```python
import requests

def render_mermaid(diagram: str) -> bytes:
    """Render a Mermaid diagram to SVG."""
    response = requests.post(
        "http://kroki:8000/mermaid/svg",
        headers={"Content-Type": "text/plain"},
        data=diagram
    )
    response.raise_for_status()
    return response.content

# Usage
svg = render_mermaid("graph TD; A-->B")
```

### JavaScript/Node.js Usage

```javascript
async function renderMermaid(diagram) {
  const response = await fetch('http://kroki:8000/mermaid/svg', {
    method: 'POST',
    headers: { 'Content-Type': 'text/plain' },
    body: diagram
  });
  if (!response.ok) throw new Error(`Kroki error: ${response.status}`);
  return await response.text();
}

// Usage
const svg = await renderMermaid('graph TD; A-->B');
```

### Documentation Generation

Integrate with documentation tools:

```bash
# Convert all .mmd files to SVG
for f in docs/*.mmd; do
  curl -X POST http://kroki:8000/mermaid/svg \
    -H "Content-Type: text/plain" \
    -d "$(cat "$f")" > "${f%.mmd}.svg"
done
```

## Security Considerations

| Concern | Mitigation |
|---------|------------|
| PlantUML file inclusion | `KROKI_SAFE_MODE=secure` (default) |
| Network exposure | `kroki-mermaid` internal only, Kroki on configurable port |
| Resource exhaustion | Health checks with restart policy |
| Container privileges | No elevated privileges required |

## Resources

- [Kroki Documentation](https://kroki.io/)
- [Mermaid Syntax Guide](https://mermaid.js.org/intro/)
- [PlantUML Reference](https://plantuml.com/)
- [GraphViz DOT Language](https://graphviz.org/doc/info/lang.html)

---
