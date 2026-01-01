# Ollama Integration

## Overview

The DevContainer includes optional Ollama integration for running local AI models. Ollama runs as a Docker service alongside your development environment.

## Quick Start

### 1. Enable Ollama Service

Ollama is available via Docker Compose profiles:

```bash
# Start DevContainer with Ollama
docker compose --profile ai up -d

# Or combine with app profile
docker compose --profile ai --profile app up -d
```

### 2. Configure Models

Set the `OLLAMA_MODELS` environment variable in `.env`:

```bash
# .env file
OLLAMA_MODELS="qwen2.5:7b codellama:7b"
```

Or skip model pre-loading and pull manually later:

```bash
# Leave OLLAMA_MODELS empty, pull models as needed
docker exec <container-name>-ollama ollama pull qwen2.5:7b
```

### 3. Use Ollama

```bash
# Inside DevContainer
curl http://ollama:11434/api/generate -d '{
  "model": "qwen2.5:7b",
  "prompt": "Why is the sky blue?"
}'

# Or use the Ollama CLI
docker exec <container-name>-ollama ollama run qwen2.5:7b
```

## Model Catalog

Pre-curated models under 10GB, sorted by popularity:

| Model | Size | Specialty | Downloads |
|-------|------|-----------|-----------|
| `llama3.2:3b` | 2.0 GB | Fast general-purpose assistant, good for chat and code | 50M |
| `qwen2.5:7b` | 4.7 GB | Strong reasoning and coding, multilingual support | 25M |
| `mistral:7b` | 4.1 GB | Balanced performance for reasoning and creative tasks | 20M |
| `codellama:7b` | 3.8 GB | Code generation and completion specialist | 15M |
| `phi3:mini` | 2.3 GB | Microsoft's compact model for reasoning tasks | 10M |
| `gemma2:9b` | 5.4 GB | Google's efficient model for diverse tasks | 8M |
| `deepseek-coder:6.7b` | 3.8 GB | Specialized for code understanding and generation | 7M |
| `neural-chat:7b` | 4.1 GB | Optimized for conversational AI applications | 5M |

Full catalog: `skills/_shared/templates/data/ollama-models.json`

## Architecture

### Service Configuration

**docker-compose-profiles.yml**:
```yaml
ollama:
  profiles: [ai]
  image: ollama/ollama:latest
  container_name: {{PROJECT_NAME}}-ollama
  restart: unless-stopped
  environment:
    OLLAMA_MODELS: ${OLLAMA_MODELS:-}
  ports:
    - "${OLLAMA_PORT:-11434}:11434"
  volumes:
    - ollama_models:/root/.ollama
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:11434/api/tags"]
    interval: 30s
    timeout: 10s
    retries: 3
    start_period: 60s
```

### Automatic Model Deployment

**setup-ollama.sh** runs during `postCreateCommand`:
1. Checks if `OLLAMA_MODELS` is set
2. Waits for Ollama service to be ready (max 60 seconds)
3. Pulls each configured model
4. Reports success/failure for each model

## Usage Patterns

### Option 1: Skip Model Selection (Recommended for Exploration)

Don't set `OLLAMA_MODELS` - just start the Ollama container and pull models manually as needed:

```bash
# Start Ollama without pre-pulling models
docker compose --profile ai up -d

# Pull models on-demand
docker exec myproject-ollama ollama pull llama3.2:3b
docker exec myproject-ollama ollama list
```

**Benefits**:
- Faster container startup
- Only download models you actually use
- Easy to experiment with different models

### Option 2: Pre-load Models (Recommended for Production)

Set `OLLAMA_MODELS` to automatically download models during container creation:

```bash
# .env
OLLAMA_MODELS="qwen2.5:7b codellama:7b"
```

**Benefits**:
- Models ready immediately
- Consistent environment across team
- No manual setup needed

### Option 3: Interactive Selection (via Quickstart Command)

When using `/sandboxxer:quickstart`, you'll be prompted to:
1. **Skip** - Create Ollama container only (Option 1 above)
2. **Select models** - Choose from top 4 models by downloads
3. **Expand list** - See all 8+ models under 10GB
4. **Custom search** - Type specific model name

## API Reference

### List Models
```bash
curl http://ollama:11434/api/tags
```

### Generate Response
```bash
curl http://ollama:11434/api/generate -d '{
  "model": "qwen2.5:7b",
  "prompt": "Write a Python function to reverse a string",
  "stream": false
}'
```

### Pull Model
```bash
curl http://ollama:11434/api/pull -d '{"name": "mistral:7b"}'
```

### Chat API
```bash
curl http://ollama:11434/api/chat -d '{
  "model": "llama3.2:3b",
  "messages": [
    {"role": "user", "content": "Hello!"}
  ]
}'
```

Full API docs: https://github.com/ollama/ollama/blob/main/docs/api.md

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `OLLAMA_MODELS` | _(empty)_ | Space-separated list of models to pre-pull |
| `OLLAMA_PORT` | `11434` | Port for Ollama API |
| `OLLAMA_ENDPOINT` | `http://ollama:11434` | Full endpoint URL (for setup script) |

## Troubleshooting

### Service not starting
```bash
# Check service status
docker compose ps

# View logs
docker compose logs ollama

# Restart service
docker compose restart ollama
```

### Models not downloading
```bash
# Check setup script logs
cat /tmp/ollama-setup.log

# Manually trigger download
docker exec myproject-ollama ollama pull qwen2.5:7b
```

### Out of disk space
```bash
# Check model sizes
docker exec myproject-ollama ollama list

# Remove unused models
docker exec myproject-ollama ollama rm <model-name>

# Clear all models and start fresh
docker volume rm myproject-ollama_models
```

### Slow inference
- Use smaller models (llama3.2:3b, phi3:mini)
- Check available RAM/CPU
- Consider GPU support (requires host GPU passthrough)

## GPU Support

To enable GPU acceleration:

```yaml
# docker-compose.yml
ollama:
  deploy:
    resources:
      reservations:
        devices:
          - driver: nvidia
            count: all
            capabilities: [gpu]
```

Requires:
- NVIDIA GPU on host
- nvidia-docker2 installed
- Docker with GPU support

## Related Issues

- **Issue #107**: Automate npm installation and Ollama deployment on container build

## Resources

- [Ollama Documentation](https://github.com/ollama/ollama)
- [Ollama Model Library](https://ollama.com/library)
- [Ollama API Reference](https://github.com/ollama/ollama/blob/main/docs/api.md)
