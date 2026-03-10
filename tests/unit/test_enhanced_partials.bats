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
