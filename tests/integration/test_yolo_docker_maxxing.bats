#!/usr/bin/env bats

# Integration tests for yolo-docker-maxxing command

load '../helpers/test_helper.bash'

@test "yolo-docker-maxxing: assembles Dockerfile with all partials" {
  # Setup test directory
  local test_dir="$BATS_TEST_TMPDIR/yolo-enhanced-test"
  mkdir -p "$test_dir"
  cd "$test_dir"

  # Mock plugin root
  export CLAUDE_PLUGIN_ROOT="$BATS_TEST_DIRNAME/../.."

  # Run yolo-docker-maxxing command logic (just the Dockerfile assembly part)
  TEMPLATES="$CLAUDE_PLUGIN_ROOT/skills/_shared/templates"
  mkdir -p .devcontainer

  cat "$TEMPLATES/base.dockerfile" > .devcontainer/Dockerfile
  echo "" >> .devcontainer/Dockerfile
  echo "# === YOLO-DOCKER-MAXXING ENHANCEMENTS ===" >> .devcontainer/Dockerfile
  cat "$TEMPLATES/partials/go.dockerfile" >> .devcontainer/Dockerfile
  cat "$TEMPLATES/partials/azure-cli.dockerfile" >> .devcontainer/Dockerfile
  cat "$TEMPLATES/partials/terraform.dockerfile" >> .devcontainer/Dockerfile
  cat "$TEMPLATES/partials/tailscale.dockerfile" >> .devcontainer/Dockerfile
  cat "$TEMPLATES/partials/pdf-tools.dockerfile" >> .devcontainer/Dockerfile

  # Verify Dockerfile contains all expected components
  [ -f .devcontainer/Dockerfile ]

  # Check for base components
  grep -q "FROM node:20-bookworm-slim" .devcontainer/Dockerfile
  grep -q "COPY --from=python-source" .devcontainer/Dockerfile
  grep -q "COPY --from=aws-cli-source" .devcontainer/Dockerfile

  # Check for Go partial
  grep -q "COPY --from=go-source /usr/local/go" .devcontainer/Dockerfile
  grep -q "GOROOT=/usr/local/go" .devcontainer/Dockerfile

  # Check for Azure CLI partial (uses pip install, not multi-stage copy)
  grep -q "pip install.*azure-cli" .devcontainer/Dockerfile
  grep -q "Azure Developer CLI" .devcontainer/Dockerfile

  # Check for Terraform partial
  grep -q "COPY --from=terraform-source /bin/terraform" .devcontainer/Dockerfile

  # Check for Tailscale partial
  grep -q "COPY --from=tailscale-source" .devcontainer/Dockerfile
  grep -q "/var/lib/tailscale" .devcontainer/Dockerfile

  # Check for PDF tools partial
  grep -q "poppler-utils" .devcontainer/Dockerfile
  grep -q "tesseract-ocr" .devcontainer/Dockerfile
  grep -q "ocrmypdf" .devcontainer/Dockerfile
  grep -q "pdftk" .devcontainer/Dockerfile

  # Verify bat instead of git-delta
  grep -q "apt-get install.*bat" .devcontainer/Dockerfile
  ! grep -q "git-delta" .devcontainer/Dockerfile
}
