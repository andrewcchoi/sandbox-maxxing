# ============================================================================
# Azure CLI and Azure Developer CLI Partial
# ============================================================================
# Appended to base.dockerfile when user needs Azure deployment capabilities.
# Adds az CLI, azd CLI, and Bicep tools for deploying DevContainers to Azure.
# ============================================================================

USER root

# Install Azure CLI with retry logic (use --http1.1 to avoid HTTP/2 stream errors)
RUN curl --retry 5 --retry-delay 5 --retry-max-time 300 \
         --connect-timeout 30 --http1.1 \
         -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install Azure Developer CLI (azd) with retry logic (use --http1.1 to avoid HTTP/2 stream errors)
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
