@description('Name of the environment')
param environmentName string

@description('Primary location for all resources')
param location string

@description('SKU for Container Registry')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param sku string = 'Basic'

// Generate a unique registry name (alphanumeric only, max 50 chars)
var registryName = 'acr${replace(environmentName, '-', '')}${uniqueString(resourceGroup().id)}'

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: registryName
  location: location
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: true
    publicNetworkAccess: 'Enabled'
  }
}

// Outputs
output name string = containerRegistry.name
output loginServer string = containerRegistry.properties.loginServer
output resourceId string = containerRegistry.id
