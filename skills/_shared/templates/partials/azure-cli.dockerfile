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

# Bicep CLI is a .NET app and aborts at startup without ICU
# ("Couldn't find a valid ICU package installed on the system").
# The slim base image doesn't include it.
RUN apt-get update && apt-get install -y --no-install-recommends libicu72 \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Bicep CLI with retry logic (network can be flaky during build)
# `az bicep install` writes to the current user's ~/.azure/bin, which is root's
# here. Move the binary onto PATH and tell az to use it, so the node user (and
# any remapped UID) gets a working `az bicep` without downloading it again.
# (The ENV is set after the install: with it on, `az bicep install` refuses to run.)
RUN for i in 1 2 3; do \
      az bicep install && break || \
      (echo "Retry $i: az bicep install failed, waiting..." && sleep 10); \
    done && \
    install -m 0755 /root/.azure/bin/bicep /usr/local/bin/bicep && \
    rm -rf /root/.azure/bin && \
    AZURE_BICEP_USE_BINARY_FROM_PATH=true az bicep version || (echo "WARNING: Bicep CLI installation failed" && exit 1)
ENV AZURE_BICEP_USE_BINARY_FROM_PATH=true

# Add Azure CLI extensions for container deployments
# Note: containerapp-compose was deprecated and merged into containerapp extension
# Install into a shared directory owned by node, not root's ~/.azure, so the
# extension is visible to node and node can add or update extensions later.
ENV AZURE_EXTENSION_DIR=/opt/az/cliextensions
RUN mkdir -p "$AZURE_EXTENSION_DIR" && \
    az extension add --name containerapp --yes && \
    chown -R node: /opt/az

USER node

# Azure environment variables
ENV AZURE_CORE_COLLECT_TELEMETRY=false
