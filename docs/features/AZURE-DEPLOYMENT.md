# Azure Deployment

Deploy your DevContainer environment to Azure Container Apps for cloud-based development, CI/CD runners, or shared team environments.

## Overview

The `/sandboxxer:deploy-to-azure` command enables you to deploy your local DevContainer configuration to Azure as a fully managed, scalable container application. This is useful for:

- **Cloud Development Environments** - Access your dev environment from anywhere (like GitHub Codespaces, but on Azure)
- **CI/CD Runners** - Use your exact DevContainer configuration as a build/test environment
- **Team Shared Environments** - Provide consistent development environments for your entire team
- **Remote Development** - Connect via VS Code Remote to cloud-hosted containers

## Architecture

The deployment creates the following Azure resources:

```
Azure Subscription
└── Resource Group (rg-{environment})
    ├── Container Apps Environment
    │   └── Container App (your DevContainer)
    ├── Azure Container Registry (optional)
    ├── Log Analytics Workspace
    └── Application Insights (monitoring)
```

**Technology Stack:**
- **Azure Developer CLI (`azd`)** - Preferred deployment tool
- **Azure CLI (`az`)** - Fallback option
- **Bicep** - Infrastructure-as-Code (declarative templates)
- **Azure Container Apps** - Serverless container hosting

## Prerequisites

### Required

1. **Azure Subscription**
   - Active Azure subscription with appropriate permissions
   - Sign up: https://azure.microsoft.com/free/

2. **Docker**
   - Docker Desktop or Docker Engine running locally
   - Download: https://www.docker.com/products/docker-desktop

3. **Existing DevContainer**
   - Must have `.devcontainer/devcontainer.json` configured
   - Create one with: `/sandboxxer:quickstart`

4. **Azure CLI or Azure Developer CLI**
   - **Recommended:** Azure Developer CLI (`azd`)
     ```bash
     curl -fsSL https://aka.ms/install-azd.sh | bash
     ```
     - Documentation: https://learn.microsoft.com/azure/developer/azure-developer-cli/

   - **Alternative:** Azure CLI (`az`)
     ```bash
     curl -sL https://aka.ms/InstallAzureCLIDeb | bash
     ```
     - Documentation: https://learn.microsoft.com/cli/azure/

### Permissions

Your Azure account needs:
- **Contributor** role on subscription or resource group
- Ability to create:
  - Resource Groups
  - Container Apps
  - Container Registries
  - Log Analytics Workspaces

Reference: https://learn.microsoft.com/azure/role-based-access-control/built-in-roles

## Usage

### Quick Start

```bash
# 1. Create DevContainer (if not already done)
/sandboxxer:quickstart

# 2. Deploy to Azure
/sandboxxer:deploy-to-azure
```

The command will guide you through:
1. Pre-flight validation
2. Azure authentication
3. Subscription selection
4. Environment configuration
5. Container Apps settings
6. Infrastructure generation
7. Deployment

### Step-by-Step Wizard

#### Step 0: Pre-flight Validation

The command automatically checks:
- ✓ Docker is running
- ✓ DevContainer configuration exists
- ✓ Azure CLI/azd is installed
- ✓ Azure authentication status

**If validation fails:**
- Docker not running → Start Docker Desktop
- No DevContainer → Run `/sandboxxer:quickstart`
- Azure CLI missing → Install using commands above
- Not authenticated → Wizard will guide you through login

#### Step 1: Authentication

**Interactive Login (Local Development):**
```bash
# azd opens browser for authentication
azd auth login

# Or with az CLI
az login
```

**Service Principal (CI/CD):**

For automated deployments, set environment variables:
```bash
export AZURE_CLIENT_ID="your-client-id"
export AZURE_CLIENT_SECRET="your-client-secret"
export AZURE_TENANT_ID="your-tenant-id"
```

Reference: https://learn.microsoft.com/azure/developer/azure-developer-cli/azure-developer-cli-authentication

#### Step 2: Environment Configuration

**Environment Name:**
- Used for resource naming (e.g., `my-dev-env`)
- Alphanumeric and hyphens only
- Maximum 24 characters
- Default: Current directory name

**Azure Region:**

Recommended regions for Container Apps:

| Region | Location | Best For |
|--------|----------|----------|
| `eastus` | Virginia, USA | East Coast US, low latency |
| `westus2` | Washington, USA | West Coast US |
| `westeurope` | Netherlands | Europe |
| `southeastasia` | Singapore | Asia Pacific |

Full list: https://azure.microsoft.com/global-infrastructure/geographies/

**Resource Group:**
- Auto-generated: `rg-{environment-name}`
- Or specify existing resource group

#### Step 3: Container Apps Configuration

**Workload Profile:**
- **Consumption (Recommended)** - Pay-per-use, auto-scaling, scales to zero
- **Dedicated** - Reserved capacity, predictable performance

Reference: https://learn.microsoft.com/azure/container-apps/plans

**CPU and Memory:**

| CPU | Memory | Best For |
|-----|--------|----------|
| 0.5 vCPU | 1 Gi | Dev environments (recommended) |
| 1.0 vCPU | 2 Gi | Medium workloads |
| 2.0 vCPU | 4 Gi | Heavy workloads |

**Auto-scaling:**

| Option | Min | Max | Best For |
|--------|-----|-----|----------|
| Scale to zero | 0 | 10 | Cost-efficient dev (default) |
| Always-on | 1 | 10 | Faster response time |
| High availability | 2 | 20 | Production workloads |

Reference: https://learn.microsoft.com/azure/container-apps/scale-app

#### Step 4: Optional Services

**Azure Container Registry (ACR):**
- ✓ **Yes (Recommended)** - Private container image storage
- ✗ No - Use public registry (less secure)

Reference: https://learn.microsoft.com/azure/container-registry/

#### Step 5: Generated Files

The wizard creates:

```
.
├── azure.yaml              # Azure Developer CLI manifest
└── infra/                  # Infrastructure-as-Code
    ├── main.bicep          # Main template
    └── modules/            # Resource modules
        ├── container-app.bicep
        └── container-registry.bicep
```

**azure.yaml:**
```yaml
name: my-dev-env
metadata:
  template: sandboxxer-devcontainer@4.6.0
services:
  devcontainer:
    project: .
    language: docker
    host: containerapp
infra:
  provider: bicep
  path: ./infra
```

Reference: https://learn.microsoft.com/azure/developer/azure-developer-cli/azd-schema

#### Step 6: Deployment

**Option 1: Deploy Now**
- Provisions all Azure resources
- Builds and pushes container image
- Deploys to Container Apps
- Takes 5-10 minutes

**Option 2: Generate Files Only**
- Creates infrastructure files
- No deployment
- Review/customize before deploying

Reference: https://learn.microsoft.com/azure/developer/azure-developer-cli/azd-up-workflow

#### Step 7: Post-Deployment

After successful deployment, you'll receive:

```
========================================
Deployment Successful!
========================================

Your DevContainer is now running in Azure!

Resource Group: rg-my-dev-env
Container App URL: https://ca-my-dev-env.eastus.azurecontainerapps.io
Azure Portal: https://portal.azure.com/#@/resource/...

Next steps:
  1. Visit the Container App URL to access your dev environment
  2. Use VS Code Remote - Containers to connect
  3. View logs: azd monitor --environment my-dev-env
  4. Update deployment: azd deploy --environment my-dev-env
  5. Clean up resources: azd down --environment my-dev-env
```

## Post-Deployment Management

### Viewing Logs

**Real-time logs:**
```bash
azd monitor --environment my-dev-env
```

**Azure Portal:**
1. Navigate to Container App in Azure Portal
2. Select "Log stream" or "Logs" blade
3. Query using Log Analytics

Reference: https://learn.microsoft.com/azure/container-apps/log-streaming

### Updating Deployment

After changing your DevContainer configuration:

```bash
azd deploy --environment my-dev-env
```

This rebuilds the container and deploys updates.

### Scaling

**Manual scaling:**
```bash
az containerapp update \
  --name ca-my-dev-env \
  --resource-group rg-my-dev-env \
  --min-replicas 2 \
  --max-replicas 20
```

**Auto-scaling rules:**
Edit `infra/modules/container-app.bicep` to add custom scaling rules.

Reference: https://learn.microsoft.com/azure/container-apps/scale-app

### Monitoring

**Azure Portal:**
- Container Apps → Your app → Metrics
- Application Insights for detailed telemetry
- Log Analytics for queries

**CLI:**
```bash
# View metrics
az containerapp metrics show \
  --name ca-my-dev-env \
  --resource-group rg-my-dev-env

# View deployments
azd env list
```

Reference: https://learn.microsoft.com/azure/container-apps/observability

### Clean Up Resources

**Delete environment:**
```bash
azd down --environment my-dev-env
```

**Delete resource group:**
```bash
az group delete --name rg-my-dev-env --yes
```

**Warning:** This permanently deletes all resources and data. Cannot be undone.

## CI/CD Integration

### GitHub Actions

Create `.github/workflows/deploy-azure.yml`:

```yaml
name: Deploy to Azure

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install azd
        run: curl -fsSL https://aka.ms/install-azd.sh | bash

      - name: Azure Login
        run: |
          azd auth login --client-id ${{ secrets.AZURE_CLIENT_ID }} \
            --client-secret ${{ secrets.AZURE_CLIENT_SECRET }} \
            --tenant-id ${{ secrets.AZURE_TENANT_ID }}

      - name: Deploy
        run: azd deploy --environment production
```

**Required secrets:**
- `AZURE_CLIENT_ID`
- `AZURE_CLIENT_SECRET`
- `AZURE_TENANT_ID`

Reference: https://learn.microsoft.com/azure/developer/azure-developer-cli/configure-devops-pipeline

### Azure DevOps

Create `azure-pipelines.yml`:

```yaml
trigger:
  - main

pool:
  vmImage: 'ubuntu-latest'

steps:
  - script: curl -fsSL https://aka.ms/install-azd.sh | bash
    displayName: 'Install azd'

  - task: AzureCLI@2
    inputs:
      azureSubscription: 'your-service-connection'
      scriptType: 'bash'
      scriptLocation: 'inlineScript'
      inlineScript: |
        azd deploy --environment $(environment)
    displayName: 'Deploy to Azure'
```

Reference: https://learn.microsoft.com/azure/devops/pipelines/

## Troubleshooting

### Authentication Issues

**Problem:** `Not logged into Azure`

**Solution:**
```bash
# Interactive login
azd auth login
# OR
az login

# Verify authentication
az account show
```

**Problem:** `Service Principal login failed`

**Solution:**
- Verify environment variables are set correctly
- Check Service Principal has correct permissions
- Test credentials: `az login --service-principal -u $CLIENT_ID -p $CLIENT_SECRET --tenant $TENANT_ID`

### Deployment Failures

**Problem:** `Insufficient permissions on subscription`

**Solution:**
- Request Contributor role on subscription/resource group
- Verify: `az role assignment list --assignee YOUR_EMAIL`

**Problem:** `Resource quota exceeded`

**Solution:**
- Check Azure quotas: https://portal.azure.com/#view/Microsoft_Azure_Capacity/QuotaMenuBlade
- Request quota increase or choose different region

**Problem:** `Name conflicts with existing resources`

**Solution:**
- Choose different environment name
- Delete existing resources if no longer needed

**Problem:** `Region not available for Container Apps`

**Solution:**
- Container Apps availability: https://azure.microsoft.com/global-infrastructure/services/?products=container-apps
- Choose supported region (eastus, westus2, westeurope recommended)

### Networking Issues

**Problem:** Container App URL not accessible

**Solution:**
1. Check ingress is enabled: Azure Portal → Container App → Ingress
2. Verify target port matches your application
3. Check firewall rules in NSG (if using VNet integration)

Reference: https://learn.microsoft.com/azure/container-apps/ingress-overview

## Cost Estimation

### Consumption Plan (Recommended for Dev)

**Container Apps:**
- Free tier: 180,000 vCPU-seconds + 360,000 GiB-seconds per month
- After free tier: ~$0.000012/vCPU-second + ~$0.000003/GiB-second
- **Scale to zero = $0 when not running**

**Azure Container Registry (Basic):**
- $5/month for 10 GB storage
- $0.10/GB for additional storage

**Log Analytics:**
- First 5 GB/month free
- $2.30/GB after

**Example: Dev Environment (0.5 vCPU, 1 GiB, 40 hours/month usage):**
- Container Apps: ~$0.00 (within free tier)
- ACR: $5.00/month
- Logs: ~$0.00 (within free tier)
- **Total: ~$5/month**

**Pricing Calculator:** https://azure.microsoft.com/pricing/calculator/

Reference: https://azure.microsoft.com/pricing/details/container-apps/

## Security Considerations

### Network Security

**Firewall Configuration:**
Azure deployment domains are automatically included in the firewall allowlist when using network restrictions:

```json
{
  "azure_deployment": [
    "management.azure.com",
    "login.microsoftonline.com",
    "*.azurecr.io",
    "*.azurecontainerapps.io"
  ]
}
```

**VNet Integration (Advanced):**
For additional isolation, Container Apps can be deployed into Azure Virtual Networks.

Reference: https://learn.microsoft.com/azure/container-apps/vnet-custom

### Secrets Management

**Azure Key Vault Integration:**

1. Create Key Vault:
   ```bash
   az keyvault create --name kv-my-dev-env --resource-group rg-my-dev-env
   ```

2. Add secrets:
   ```bash
   az keyvault secret set --vault-name kv-my-dev-env --name my-secret --value "secret-value"
   ```

3. Reference in Container App environment variables

Reference: https://learn.microsoft.com/azure/container-apps/manage-secrets

### Managed Identity

Container Apps automatically create a system-assigned managed identity for:
- Pulling images from ACR
- Accessing Azure resources without credentials
- Enhanced security without storing secrets

Reference: https://learn.microsoft.com/azure/container-apps/managed-identity

## Reference Links

### Azure Documentation

- **Azure Container Apps:** https://learn.microsoft.com/azure/container-apps/
- **Azure Developer CLI:** https://learn.microsoft.com/azure/developer/azure-developer-cli/
- **Azure CLI:** https://learn.microsoft.com/cli/azure/
- **Bicep Language:** https://learn.microsoft.com/azure/azure-resource-manager/bicep/
- **Azure Container Registry:** https://learn.microsoft.com/azure/container-registry/

### Deployment & Operations

- **azd up Workflow:** https://learn.microsoft.com/azure/developer/azure-developer-cli/azd-up-workflow
- **Container Apps Scaling:** https://learn.microsoft.com/azure/container-apps/scale-app
- **Container Apps Plans:** https://learn.microsoft.com/azure/container-apps/plans
- **Log Streaming:** https://learn.microsoft.com/azure/container-apps/log-streaming
- **Observability:** https://learn.microsoft.com/azure/container-apps/observability

### Authentication & Security

- **azd Authentication:** https://learn.microsoft.com/azure/developer/azure-developer-cli/azure-developer-cli-authentication
- **Azure RBAC:** https://learn.microsoft.com/azure/role-based-access-control/built-in-roles
- **Managed Identity:** https://learn.microsoft.com/azure/container-apps/managed-identity
- **Key Vault Integration:** https://learn.microsoft.com/azure/container-apps/manage-secrets
- **VNet Integration:** https://learn.microsoft.com/azure/container-apps/vnet-custom

### Pricing & Regions

- **Pricing Calculator:** https://azure.microsoft.com/pricing/calculator/
- **Container Apps Pricing:** https://azure.microsoft.com/pricing/details/container-apps/
- **Regional Availability:** https://azure.microsoft.com/global-infrastructure/services/?products=container-apps
- **Azure Geographies:** https://azure.microsoft.com/global-infrastructure/geographies/

### CI/CD

- **Configure DevOps Pipeline:** https://learn.microsoft.com/azure/developer/azure-developer-cli/configure-devops-pipeline
- **GitHub Actions:** https://docs.github.com/actions
- **Azure DevOps Pipelines:** https://learn.microsoft.com/azure/devops/pipelines/

### Additional Resources

- **Azure Free Account:** https://azure.microsoft.com/free/
- **Azure Portal:** https://portal.azure.com
- **Azure Status:** https://status.azure.com
- **Azure Support:** https://azure.microsoft.com/support/

## Examples

### Deploy with Custom Configuration

**Modify Bicep template before deployment:**

```bash
# Generate files only
/sandboxxer:deploy-to-azure  # Choose "Generate files only"

# Edit infra/modules/container-app.bicep
# Add custom environment variables, ports, etc.

# Deploy manually
azd up
```

### Deploy to Multiple Environments

```bash
# Development
azd env new dev
azd env set AZURE_LOCATION eastus
azd up

# Staging
azd env new staging
azd env set AZURE_LOCATION westus2
azd up

# Production
azd env new prod
azd env set AZURE_LOCATION westeurope
azd up
```

### Connect VS Code Remote

1. Deploy DevContainer to Azure
2. Install VS Code extension: **Remote - SSH**
3. Configure SSH access to Container App
4. Connect via Remote Explorer

Reference: https://code.visualstudio.com/docs/remote/ssh

## Next Steps

After deploying to Azure:

1. **Explore Azure Portal** - View resources, metrics, and logs
2. **Set up CI/CD** - Automate deployments with GitHub Actions
3. **Add Custom Domains** - Map custom domains to Container App
4. **Enable Authentication** - Add Azure AD authentication
5. **Configure Scaling** - Fine-tune auto-scaling rules
6. **Monitor Costs** - Set up cost alerts and budgets

## Getting Help

- **Azure Support:** https://azure.microsoft.com/support/
- **Stack Overflow:** https://stackoverflow.com/questions/tagged/azure-container-apps
- **Microsoft Q&A:** https://learn.microsoft.com/answers/tags/azure-container-apps
- **GitHub Issues:** Report issues with this plugin at the repository
