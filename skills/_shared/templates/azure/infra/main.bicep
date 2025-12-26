targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Resource group name prefix')
param resourceGroupName string = 'rg-${environmentName}'

@description('Enable Azure Container Registry')
param enableContainerRegistry bool = true

@description('Container Apps environment configuration')
param containerAppConfig object = {
  cpu: '0.5'
  memory: '1Gi'
  minReplicas: 0
  maxReplicas: 10
}

// Resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: {
    Environment: environmentName
    ManagedBy: 'azd'
    Purpose: 'DevContainer'
  }
}

// Azure Container Registry (optional)
module acr './modules/container-registry.bicep' = if (enableContainerRegistry) {
  name: 'container-registry'
  scope: rg
  params: {
    environmentName: environmentName
    location: location
  }
}

// Container Apps Environment + App
module containerApp './modules/container-app.bicep' = {
  name: 'container-app'
  scope: rg
  params: {
    environmentName: environmentName
    location: location
    containerRegistryName: enableContainerRegistry ? acr.outputs.name : ''
    cpu: containerAppConfig.cpu
    memory: containerAppConfig.memory
    minReplicas: containerAppConfig.minReplicas
    maxReplicas: containerAppConfig.maxReplicas
  }
}

// Outputs
output AZURE_RESOURCE_GROUP string = rg.name
output AZURE_LOCATION string = location
output CONTAINER_REGISTRY_ENDPOINT string = enableContainerRegistry ? acr.outputs.loginServer : ''
output CONTAINER_APP_NAME string = containerApp.outputs.name
output CONTAINER_APP_URL string = containerApp.outputs.fqdn
