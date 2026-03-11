# ============================================================================
# Azure CLI and Azure Developer CLI Partial
# ============================================================================
# Appended to base.dockerfile when user needs Azure deployment capabilities.
# Installs az CLI via pip (the officially supported method).
# Adds az CLI, azd CLI, and Bicep tools for deploying DevContainers to Azure.
#
# NOTE: Multi-stage copy from mcr.microsoft.com/azure-cli was removed because
# Microsoft changed the image structure - /opt/az no longer exists in latest.
# pip install is more reliable and is the officially documented method.
# ============================================================================

USER root

# Install Azure CLI via pip (officially supported installation method)
# Uses the Python 3.12 already installed in the base image
RUN pip install --no-cache-dir azure-cli

# Install Azure Developer CLI (azd) with retry logic (use --http1.1 to avoid HTTP/2 stream errors)
# NOTE: azd doesn't have an official Docker image yet, requires direct download
RUN curl --retry 5 --retry-delay 5 --retry-max-time 300 \
         --connect-timeout 30 --http1.1 \
         -fsSL https://aka.ms/install-azd.sh | bash

# Install Bicep CLI
RUN az bicep install

# Add Azure CLI extensions for container deployments
# Note: containerapp-compose was deprecated and merged into containerapp extension
RUN az extension add --name containerapp --yes

USER node

# Azure environment variables
ENV AZURE_CORE_COLLECT_TELEMETRY=false
