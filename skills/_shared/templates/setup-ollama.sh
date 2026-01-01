#!/bin/bash
# ============================================================================
# Ollama Setup Script - Model Deployment
# ============================================================================
# Waits for Ollama service and pulls configured models
# Issue #107: Automates Ollama model deployment on container startup
# ============================================================================

set -e

OLLAMA_ENDPOINT="${OLLAMA_ENDPOINT:-http://ollama:11434}"
MODELS="${OLLAMA_MODELS:-}"

# Skip if no models configured
if [ -z "$MODELS" ]; then
  echo "[Ollama] No models configured, skipping..."
  exit 0
fi

echo "[Ollama] Model deployment starting..."
echo "[Ollama] Endpoint: $OLLAMA_ENDPOINT"
echo "[Ollama] Models to pull: $MODELS"

# Wait for Ollama service to be ready
echo "[Ollama] Waiting for Ollama service..."
MAX_ATTEMPTS=30
ATTEMPT=0

until curl -sf "$OLLAMA_ENDPOINT/api/tags" > /dev/null 2>&1; do
  ATTEMPT=$((ATTEMPT + 1))
  if [ $ATTEMPT -ge $MAX_ATTEMPTS ]; then
    echo "[Ollama] ⚠️  Timeout waiting for Ollama service after ${MAX_ATTEMPTS} attempts"
    echo "[Ollama] You can manually pull models later with: ollama pull <model-name>"
    exit 0
  fi
  echo "[Ollama] Waiting... (attempt $ATTEMPT/$MAX_ATTEMPTS)"
  sleep 2
done

echo "[Ollama] ✓ Service is ready!"

# Pull each model
for model in $MODELS; do
  echo "[Ollama] Pulling $model..."
  if curl -sf "$OLLAMA_ENDPOINT/api/pull" -d "{\"name\":\"$model\"}" > /dev/null 2>&1; then
    echo "[Ollama] ✓ $model pulled successfully"
  else
    echo "[Ollama] ⚠️  Failed to pull $model (you can pull it manually later)"
  fi
done

echo "[Ollama] ✓ All configured models processed!"
echo "[Ollama] Available models:"
curl -sf "$OLLAMA_ENDPOINT/api/tags" | jq -r '.models[].name' 2>/dev/null || echo "  (unable to list models)"

exit 0
