# ============================================================================
# Azure CLI and Azure Developer CLI Partial
# ============================================================================
# Appended to base.dockerfile when user needs Azure deployment capabilities.
# Uses official Microsoft Azure CLI Docker image for proxy-friendliness.
# Adds az CLI, azd CLI, and Bicep tools for deploying DevContainers to Azure.
# ============================================================================

USER root

# Copy Azure CLI from official Microsoft image (proxy-friendly)
# This avoids downloading from aka.ms during build
COPY --from=azure-cli-source /opt/az /opt/az
COPY --from=azure-cli-source /usr/local/bin/az /usr/local/bin/az

# Install Python dependencies needed for Azure CLI
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-pip \
    python3-venv \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create symlink for az command
RUN ln -sf /opt/az/bin/az /usr/local/bin/az 2>/dev/null || true

# Install Azure Developer CLI (azd) with retry logic (use --http1.1 to avoid HTTP/2 stream errors)
# NOTE: azd doesn't have an official Docker image yet, requires direct download
RUN curl --retry 5 --retry-delay 5 --retry-max-time 300 \
         --connect-timeout 30 --http1.1 \
         -fsSL https://aka.ms/install-azd.sh | bash

# Install Bicep CLI
RUN az bicep install

# Add Azure CLI extensions for container deployments
RUN az extension add --name containerapp --yes && \
    az extension add --name containerapp-compose --yes

USER node

# Azure environment variables
ENV AZURE_CORE_COLLECT_TELEMETRY=false
