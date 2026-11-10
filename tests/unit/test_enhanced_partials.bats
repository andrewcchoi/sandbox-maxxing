#!/usr/bin/env bats

# Test enhanced partials for yolo-docker-maxxing

load '../helpers/test_helper.bash'

@test "terraform.dockerfile: contains Terraform installation" {
  local partial="$PLUGIN_ROOT/skills/_shared/templates/partials/terraform.dockerfile"
  [ -f "$partial" ]

  grep -q "COPY --from=terraform-source" "$partial"
  grep -q "terraform --version" "$partial"
}

@test "tailscale.dockerfile: contains Tailscale binaries" {
  local partial="$PLUGIN_ROOT/skills/_shared/templates/partials/tailscale.dockerfile"
  [ -f "$partial" ]

  grep -q "COPY --from=tailscale-source.*tailscale " "$partial"
  grep -q "COPY --from=tailscale-source.*tailscaled" "$partial"
  grep -q "/var/lib/tailscale" "$partial"
}

@test "pdf-tools.dockerfile: contains all PDF/OCR tools" {
  local partial="$PLUGIN_ROOT/skills/_shared/templates/partials/pdf-tools.dockerfile"
  [ -f "$partial" ]

  # Verify all tools are present
  grep -q "poppler-utils" "$partial"
  grep -q "ghostscript" "$partial"
  grep -q "qpdf" "$partial"
  grep -q "tesseract-ocr" "$partial"
  grep -q "ocrmypdf" "$partial"
  grep -q "pdftk" "$partial"
}

@test "base.dockerfile: uses bat instead of git-delta" {
  local base="$PLUGIN_ROOT/skills/_shared/templates/base.dockerfile"
  [ -f "$base" ]

  # Should have bat
  grep -q "apt-get install.*bat" "$base"

  # Should NOT have git-delta
  ! grep -q "git-delta" "$base"
  ! grep -q "dandavison/delta" "$base"
}

@test "base.dockerfile: contains Terraform and Tailscale stages" {
  local base="$PLUGIN_ROOT/skills/_shared/templates/base.dockerfile"
  [ -f "$base" ]

  grep -q "FROM hashicorp/terraform:latest AS terraform-source" "$base"
  grep -q "FROM tailscale/tailscale:latest AS tailscale-source" "$base"
}

@test "azure-cli.dockerfile: installs libicu before Bicep (#383)" {
  local partial="$PLUGIN_ROOT/skills/_shared/templates/partials/azure-cli.dockerfile"
  [ -f "$partial" ]
  local icu_line bicep_line
  icu_line=$(grep -n 'apt-get install.*libicu' "$partial" | head -1 | cut -d: -f1)
  bicep_line=$(grep -n 'az bicep install' "$partial" | head -1 | cut -d: -f1)
  [ -n "$icu_line" ]
  [ -n "$bicep_line" ]
  [ "$icu_line" -lt "$bicep_line" ]
}

@test "azure-cli.dockerfile: Bicep and extensions are usable by node, not only root (#383)" {
  local partial="$PLUGIN_ROOT/skills/_shared/templates/partials/azure-cli.dockerfile"
  # Bicep binary moved onto PATH, and az told to use it
  grep -q 'install -m 0755 /root/.azure/bin/bicep /usr/local/bin/bicep' "$partial"
  # The ENV must come after `az bicep install`: with it set, the install refuses to run
  local env_line bicep_line
  env_line=$(grep -n '^ENV AZURE_BICEP_USE_BINARY_FROM_PATH=true' "$partial" | cut -d: -f1)
  bicep_line=$(grep -n 'az bicep install' "$partial" | head -1 | cut -d: -f1)
  [ -n "$env_line" ]
  [ "$env_line" -gt "$bicep_line" ]
  # Extensions go to a shared dir owned by node, set before `az extension add`
  local ext_env_line ext_add_line
  ext_env_line=$(grep -n '^ENV AZURE_EXTENSION_DIR=' "$partial" | cut -d: -f1)
  ext_add_line=$(grep -n 'az extension add' "$partial" | head -1 | cut -d: -f1)
  [ -n "$ext_env_line" ]
  [ "$ext_env_line" -lt "$ext_add_line" ]
  grep -q 'chown -R node: /opt/az' "$partial"
}
