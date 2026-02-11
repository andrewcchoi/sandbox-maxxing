#!/usr/bin/env bash
# ============================================================================
# Kroki Setup Script - Service Validation
# ============================================================================
# Validates Kroki diagram service is accessible from the DevContainer
# Runs optionally when diagrams profile is enabled
# ============================================================================

set -euo pipefail

KROKI_ENDPOINT="${KROKI_URL:-http://kroki:8000}"
KROKI_ENABLED="${ENABLE_KROKI:-false}"

# Skip if Kroki not enabled
if [ "$KROKI_ENABLED" != "true" ]; then
  echo "[Kroki] Not enabled (ENABLE_KROKI != true), skipping..."
  echo "[Kroki] To enable: docker compose --profile diagrams up -d"
  exit 0
fi

echo "[Kroki] Service validation starting..."
echo "[Kroki] Endpoint: $KROKI_ENDPOINT"

# Wait for Kroki service to be ready
echo "[Kroki] Waiting for Kroki service..."
MAX_ATTEMPTS=15
ATTEMPT=0

until curl -sf "$KROKI_ENDPOINT/health" > /dev/null 2>&1; do
  ATTEMPT=$((ATTEMPT + 1))
  if [ $ATTEMPT -ge $MAX_ATTEMPTS ]; then
    echo "[Kroki] Warning: Timeout waiting for Kroki service after ${MAX_ATTEMPTS} attempts"
    echo "[Kroki] Start manually with: docker compose --profile diagrams up -d"
    exit 0
  fi
  echo "[Kroki] Waiting... (attempt $ATTEMPT/$MAX_ATTEMPTS)"
  sleep 2
done

echo "[Kroki] Service is ready!"

# Test Mermaid rendering
echo "[Kroki] Testing Mermaid rendering..."
if curl -sf -X POST "$KROKI_ENDPOINT/mermaid/svg" \
    -H "Content-Type: text/plain" \
    -d "graph TD; A-->B" | grep -q "<svg"; then
  echo "[Kroki] Mermaid rendering works"
else
  echo "[Kroki] Warning: Mermaid test failed (kroki-mermaid may not be ready)"
fi

# Display available engines
echo "[Kroki] Available engines:"
echo "  mermaid   - Flowcharts, sequence diagrams, ERDs"
echo "  plantuml  - UML, C4 architecture (safe mode: ${KROKI_SAFE_MODE:-secure})"
echo "  graphviz  - Graph visualization, dependency trees"
echo "  ditaa     - ASCII art to diagrams"
echo "  blockdiag - Block diagrams"
echo "  erd       - Entity-Relationship diagrams"

echo "[Kroki] Setup complete!"
echo "[Kroki] Usage: curl -X POST $KROKI_ENDPOINT/<engine>/svg -d '<diagram>'"

exit 0
