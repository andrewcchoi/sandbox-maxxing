# ============================================================================
# Terraform Partial
# ============================================================================
# Infrastructure as Code tool for cloud deployments
# Uses official HashiCorp Docker image for proxy-friendly installation
# ============================================================================

USER root

# Copy Terraform binary from official HashiCorp image
COPY --from=terraform-source /bin/terraform /usr/local/bin/terraform

# Verify installation
RUN terraform --version

USER node
