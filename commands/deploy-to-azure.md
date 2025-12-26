---
description: Deploy DevContainer environment to Azure Container Apps for cloud-based development
argument-hint: ""
allowed-tools: [Bash, AskUserQuestion, Read]
---

# Deploy DevContainer to Azure

Deploy your DevContainer environment to Azure Container Apps for cloud-based development, CI/CD runners, or shared team environments.

**What this does:**
- Deploys your DevContainer to Azure as a cloud-hosted development environment
- Uses Azure Developer CLI (`azd`) for infrastructure provisioning and deployment
- Creates Azure Container Registry, Container Apps Environment, and Container App

**Prerequisites:**
- Azure subscription with appropriate permissions
- Docker running locally
- Existing DevContainer configuration (`.devcontainer/`)

![Azure Deployment Flow](../docs/diagrams/svg/azure-deployment-flow.svg)

*Multi-step Azure Container Apps deployment pipeline from pre-flight validation to post-deployment verification.*

## Step 0: Pre-flight Validation

Run these checks before proceeding.

```bash
echo "Running pre-flight checks for Azure deployment..."
VALIDATION_FAILED=false

# Initialize plugin root
PLUGIN_ROOT=""
if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ]; then
  PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT//\\//}"
fi

# Check 1: Docker daemon running
if ! docker info > /dev/null 2>&1; then
  echo "ERROR: Docker is not running"
  echo "  Fix: Start Docker Desktop or run 'sudo systemctl start docker'"
  VALIDATION_FAILED=true
else
  echo "  ✓ Docker is running"
fi

# Check 2: DevContainer configuration exists
if [ ! -f ".devcontainer/devcontainer.json" ]; then
  echo "ERROR: No DevContainer configuration found"
  echo "  Fix: Run /sandboxxer:quickstart first to create a DevContainer"
  VALIDATION_FAILED=true
else
  echo "  ✓ DevContainer configuration exists"
fi

# Check 3: Azure CLI availability
AZD_AVAILABLE=false
AZ_AVAILABLE=false

if command -v azd > /dev/null 2>&1; then
  AZD_AVAILABLE=true
  echo "  ✓ Azure Developer CLI (azd) available"
elif command -v az > /dev/null 2>&1; then
  AZ_AVAILABLE=true
  echo "  ✓ Azure CLI (az) available"
else
  echo "ERROR: Neither Azure Developer CLI (azd) nor Azure CLI (az) found"
  echo ""
  echo "  Install Azure Developer CLI (recommended):"
  echo "    curl -fsSL https://aka.ms/install-azd.sh | bash"
  echo ""
  echo "  Or install Azure CLI:"
  echo "    curl -sL https://aka.ms/InstallAzureCLIDeb | bash"
  echo ""
  VALIDATION_FAILED=true
fi

# Check 4: Azure authentication status
NEEDS_LOGIN=false
if [ "$AZD_AVAILABLE" = "true" ]; then
  if ! azd auth login --check-status > /dev/null 2>&1; then
    echo "  ⚠ Not logged into Azure (will guide through login)"
    NEEDS_LOGIN=true
  else
    echo "  ✓ Authenticated with Azure"
  fi
elif [ "$AZ_AVAILABLE" = "true" ]; then
  if ! az account show > /dev/null 2>&1; then
    echo "  ⚠ Not logged into Azure (will guide through login)"
    NEEDS_LOGIN=true
  else
    echo "  ✓ Authenticated with Azure"
  fi
fi

# Exit if critical checks failed
if [ "$VALIDATION_FAILED" = "true" ]; then
  echo ""
  echo "Pre-flight checks failed. Please fix the errors above and try again."
  exit 1
fi

echo ""
echo "Pre-flight checks passed!"
echo ""
```

## Step 1: Azure Authentication

Handle Azure authentication for interactive and CI/CD scenarios.

```bash
# Detect CI/CD environment
CI_DETECTED=false
if [ -n "$CI" ] || [ -n "$GITHUB_ACTIONS" ] || [ -n "$AZURE_PIPELINES" ]; then
  CI_DETECTED=true
  echo "CI/CD environment detected"
fi

# Service Principal authentication for CI/CD
if [ "$CI_DETECTED" = "true" ]; then
  echo "Checking for Service Principal credentials..."
  if [ -z "$AZURE_CLIENT_ID" ] || [ -z "$AZURE_CLIENT_SECRET" ] || [ -z "$AZURE_TENANT_ID" ]; then
    echo "ERROR: Service Principal credentials required in CI/CD"
    echo ""
    echo "Set these environment variables:"
    echo "  AZURE_CLIENT_ID"
    echo "  AZURE_CLIENT_SECRET"
    echo "  AZURE_TENANT_ID"
    exit 1
  fi

  echo "Logging in with Service Principal..."
  az login --service-principal \
    -u "$AZURE_CLIENT_ID" \
    -p "$AZURE_CLIENT_SECRET" \
    --tenant "$AZURE_TENANT_ID"

  if [ $? -ne 0 ]; then
    echo "ERROR: Service Principal login failed"
    exit 1
  fi
  echo "  ✓ Authenticated with Service Principal"
fi

# Interactive login
if [ "$NEEDS_LOGIN" = "true" ] && [ "$CI_DETECTED" = "false" ]; then
  echo "Azure authentication required. Opening browser for login..."
  echo ""

  if [ "$AZD_AVAILABLE" = "true" ]; then
    azd auth login
  else
    az login
  fi

  if [ $? -ne 0 ]; then
    echo "ERROR: Azure login failed"
    exit 1
  fi
  echo ""
  echo "  ✓ Successfully authenticated with Azure"
  echo ""
fi
```

## Step 1.5: Subscription Selection

List available Azure subscriptions and let the user select one.

```bash
# Get list of subscriptions
if [ "$AZD_AVAILABLE" = "true" ]; then
  SUBSCRIPTION_LIST=$(az account list --query "[].{name:name, id:id, isDefault:isDefault}" -o json)
else
  SUBSCRIPTION_LIST=$(az account list --query "[].{name:name, id:id, isDefault:isDefault}" -o json)
fi

SUBSCRIPTION_COUNT=$(echo "$SUBSCRIPTION_LIST" | jq 'length')

if [ "$SUBSCRIPTION_COUNT" = "0" ]; then
  echo "ERROR: No Azure subscriptions found"
  echo "Visit https://portal.azure.com to create or activate a subscription"
  exit 1
fi

# Show current subscription
CURRENT_SUBSCRIPTION=$(az account show --query "name" -o tsv 2>/dev/null)
echo "Current Azure subscription: $CURRENT_SUBSCRIPTION"
echo ""

# If multiple subscriptions, offer to change
if [ "$SUBSCRIPTION_COUNT" -gt 1 ]; then
  echo "Multiple subscriptions available. Continue with current subscription?"
  # User can manually run 'az account set --subscription <name>' if they want to change
fi
```

Use AskUserQuestion:

```
Would you like to proceed with the current subscription '$CURRENT_SUBSCRIPTION'?
1. Yes, use current subscription
2. No, let me change it first (use 'az account set --subscription <name>')
```

Store as `SUBSCRIPTION_CHOICE`.

```bash
if [ "$SUBSCRIPTION_CHOICE" = "No, let me change it first (use 'az account set --subscription <name>')" ]; then
  echo ""
  echo "To change subscription, run:"
  echo "  az account set --subscription <subscription-name-or-id>"
  echo ""
  echo "Then re-run this command."
  exit 0
fi
```

## Step 2: Environment Configuration

Configure the Azure deployment environment.

Use AskUserQuestion:

```
What is the environment name? (used for resource naming)
```

Provide a text input field with default value as the current directory name.

Store as `ENVIRONMENT_NAME`.

```bash
# Sanitize environment name (alphanumeric and hyphens only)
ENVIRONMENT_NAME=$(echo "$ENVIRONMENT_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/^-*//' | sed 's/-*$//')

# Validate length
if [ ${#ENVIRONMENT_NAME} -gt 24 ]; then
  echo "WARNING: Environment name truncated to 24 characters"
  ENVIRONMENT_NAME=${ENVIRONMENT_NAME:0:24}
fi

echo "Environment name: $ENVIRONMENT_NAME"
```

## Step 2.5: Azure Region Selection

Use AskUserQuestion:

```
Select an Azure region for deployment:
1. East US (Virginia) - Low latency for East Coast
2. West US 2 (Washington) - Low latency for West Coast
3. West Europe (Netherlands) - Primary European region
4. Southeast Asia (Singapore) - Asia Pacific region
5. Other region (will prompt for region code)
```

Store as `REGION_CHOICE`.

```bash
case "$REGION_CHOICE" in
  "East US (Virginia) - Low latency for East Coast")
    AZURE_LOCATION="eastus"
    ;;
  "West US 2 (Washington) - Low latency for West Coast")
    AZURE_LOCATION="westus2"
    ;;
  "West Europe (Netherlands) - Primary European region")
    AZURE_LOCATION="westeurope"
    ;;
  "Southeast Asia (Singapore) - Asia Pacific region")
    AZURE_LOCATION="southeastasia"
    ;;
  "Other region (will prompt for region code)")
    echo "Enter Azure region code (e.g., eastus, westus2, westeurope):"
    read -r AZURE_LOCATION
    ;;
esac

echo "Azure region: $AZURE_LOCATION"
```

## Step 3: Container Apps Configuration

Configure Container Apps deployment settings.

Use AskUserQuestion:

```
Select workload profile for Container Apps:
1. Consumption (pay-per-use, auto-scaling) - Recommended for dev environments
2. Dedicated (reserved capacity, predictable performance)
```

Store as `WORKLOAD_PROFILE`.

```bash
if [ "$WORKLOAD_PROFILE" = "Consumption (pay-per-use, auto-scaling) - Recommended for dev environments" ]; then
  WORKLOAD_TYPE="consumption"
else
  WORKLOAD_TYPE="dedicated"
fi

echo "Workload profile: $WORKLOAD_TYPE"
```

Use AskUserQuestion:

```
Select CPU allocation:
1. 0.5 vCPU (recommended for dev)
2. 1.0 vCPU
3. 2.0 vCPU
```

Store as `CPU_CHOICE`.

```bash
case "$CPU_CHOICE" in
  "0.5 vCPU (recommended for dev)")
    CONTAINER_CPU="0.5"
    CONTAINER_MEMORY="1Gi"
    ;;
  "1.0 vCPU")
    CONTAINER_CPU="1.0"
    CONTAINER_MEMORY="2Gi"
    ;;
  "2.0 vCPU")
    CONTAINER_CPU="2.0"
    CONTAINER_MEMORY="4Gi"
    ;;
esac

echo "CPU: $CONTAINER_CPU, Memory: $CONTAINER_MEMORY"
```

Use AskUserQuestion:

```
Configure auto-scaling replicas:
1. Scale to zero (0 min, 10 max) - Cost-efficient for dev
2. Always-on (1 min, 10 max) - Faster response
3. High availability (2 min, 20 max)
```

Store as `SCALING_CHOICE`.

```bash
case "$SCALING_CHOICE" in
  "Scale to zero (0 min, 10 max) - Cost-efficient for dev")
    MIN_REPLICAS=0
    MAX_REPLICAS=10
    ;;
  "Always-on (1 min, 10 max) - Faster response")
    MIN_REPLICAS=1
    MAX_REPLICAS=10
    ;;
  "High availability (2 min, 20 max)")
    MIN_REPLICAS=2
    MAX_REPLICAS=20
    ;;
esac

echo "Scaling: min=$MIN_REPLICAS, max=$MAX_REPLICAS"
```

## Step 4: Optional Services

Use AskUserQuestion:

```
Include Azure Container Registry? (for storing container images)
1. Yes (recommended)
2. No (will use public registry)
```

Store as `INCLUDE_ACR`.

```bash
if [ "$INCLUDE_ACR" = "Yes (recommended)" ]; then
  ENABLE_ACR="true"
else
  ENABLE_ACR="false"
fi

echo "Container Registry: $ENABLE_ACR"
```

## Step 5: Generate Infrastructure Files

Create Azure infrastructure-as-code files from templates.

```bash
echo ""
echo "Generating Azure infrastructure files..."
echo ""

TEMPLATES="$PLUGIN_ROOT/skills/_shared/templates"
AZURE_TEMPLATES="$TEMPLATES/azure"

# Detect current version (optional)
VERSION="4.6.0"  # Could be read from plugin.json

# Create azure.yaml
if [ -f "$AZURE_TEMPLATES/azure.yaml" ]; then
  cp "$AZURE_TEMPLATES/azure.yaml" ./azure.yaml
  sed -i "s/{{PROJECT_NAME}}/$ENVIRONMENT_NAME/g" ./azure.yaml
  sed -i "s/{{VERSION}}/$VERSION/g" ./azure.yaml
  echo "  ✓ Created azure.yaml"
else
  echo "  ERROR: azure.yaml template not found"
  exit 1
fi

# Create infra directory
mkdir -p infra/modules

# Copy main.bicep
if [ -f "$AZURE_TEMPLATES/infra/main.bicep" ]; then
  cp "$AZURE_TEMPLATES/infra/main.bicep" ./infra/main.bicep
  echo "  ✓ Created infra/main.bicep"
else
  echo "  ERROR: main.bicep template not found"
  exit 1
fi

# Copy modules
if [ -d "$AZURE_TEMPLATES/infra/modules" ]; then
  cp -r "$AZURE_TEMPLATES/infra/modules/"* ./infra/modules/
  echo "  ✓ Created Bicep modules"
else
  echo "  ERROR: Bicep modules not found"
  exit 1
fi

echo ""
echo "Infrastructure files created:"
echo "  - azure.yaml (Azure Developer CLI manifest)"
echo "  - infra/main.bicep (main infrastructure template)"
echo "  - infra/modules/*.bicep (resource modules)"
echo ""
```

## Step 6: Deploy to Azure

Use AskUserQuestion:

```
Ready to deploy to Azure?
1. Deploy now (provisions infrastructure and deploys container)
2. Generate files only (manual deployment later)
```

Store as `DEPLOY_CHOICE`.

```bash
if [ "$DEPLOY_CHOICE" = "Generate files only (manual deployment later)" ]; then
  echo ""
  echo "=========================================="
  echo "Files Generated Successfully"
  echo "=========================================="
  echo ""
  echo "To deploy manually, run:"
  echo "  azd env new $ENVIRONMENT_NAME"
  echo "  azd env set AZURE_LOCATION $AZURE_LOCATION"
  echo "  azd up"
  echo ""
  exit 0
fi
```

Deploy now:

```bash
echo ""
echo "=========================================="
echo "Starting Azure Deployment"
echo "=========================================="
echo ""
echo "Environment: $ENVIRONMENT_NAME"
echo "Location: $AZURE_LOCATION"
echo "This may take 5-10 minutes..."
echo ""

# Create azd environment
if [ "$AZD_AVAILABLE" = "true" ]; then
  # Initialize azd environment
  azd env new "$ENVIRONMENT_NAME" --subscription "$CURRENT_SUBSCRIPTION" --location "$AZURE_LOCATION" 2>/dev/null || true

  # Set environment variables
  azd env set AZURE_LOCATION "$AZURE_LOCATION"

  # Set container configuration parameters
  azd env set CONTAINER_CPU "$CONTAINER_CPU"
  azd env set CONTAINER_MEMORY "$CONTAINER_MEMORY"
  azd env set MIN_REPLICAS "$MIN_REPLICAS"
  azd env set MAX_REPLICAS "$MAX_REPLICAS"
  azd env set ENABLE_ACR "$ENABLE_ACR"

  # Run azd up (provision + deploy)
  echo "Running azd up..."
  if azd up --environment "$ENVIRONMENT_NAME" 2>&1 | tee deployment.log; then
    DEPLOYMENT_SUCCESS=true
  else
    DEPLOYMENT_SUCCESS=false
  fi
else
  echo "ERROR: Azure Developer CLI (azd) required for deployment"
  echo "Install: curl -fsSL https://aka.ms/install-azd.sh | bash"
  exit 1
fi
```

## Step 7: Post-Deployment Summary

```bash
if [ "$DEPLOYMENT_SUCCESS" = "true" ]; then
  echo ""
  echo "=========================================="
  echo "Deployment Successful!"
  echo "=========================================="
  echo ""

  # Get deployment outputs
  RESOURCE_GROUP=$(azd env get-values --output json | jq -r '.AZURE_RESOURCE_GROUP // empty')
  CONTAINER_APP_URL=$(azd env get-values --output json | jq -r '.CONTAINER_APP_URL // empty')

  echo "Your DevContainer is now running in Azure!"
  echo ""
  echo "Resource Group: $RESOURCE_GROUP"
  echo "Container App URL: https://$CONTAINER_APP_URL"
  echo "Azure Portal: https://portal.azure.com/#@/resource/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP"
  echo ""
  echo "Next steps:"
  echo "  1. Visit the Container App URL to access your dev environment"
  echo "  2. Use VS Code Remote - Containers to connect"
  echo "  3. View logs: azd monitor --environment $ENVIRONMENT_NAME"
  echo "  4. Update deployment: azd deploy --environment $ENVIRONMENT_NAME"
  echo "  5. Clean up resources: azd down --environment $ENVIRONMENT_NAME"
  echo ""
else
  echo ""
  echo "=========================================="
  echo "Deployment Failed"
  echo "=========================================="
  echo ""
  echo "Check deployment.log for details"
  echo ""
  echo "Common issues:"
  echo "  - Insufficient permissions on subscription"
  echo "  - Resource quota exceeded in region"
  echo "  - Name conflicts with existing resources"
  echo "  - Region not available for Container Apps"
  echo ""
  echo "Troubleshooting:"
  echo "  azd down --environment $ENVIRONMENT_NAME  # Clean up partial deployment"
  echo "  az group delete -n $RESOURCE_GROUP --yes  # Delete resource group"
  echo ""
  exit 1
fi
```

---

## Manual Deployment Commands

If you generated files only, use these commands to deploy manually:

```bash
# Initialize environment
azd env new <environment-name>

# Set location
azd env set AZURE_LOCATION <region>

# Deploy
azd up

# Monitor
azd monitor

# Update
azd deploy

# Clean up
azd down
```
