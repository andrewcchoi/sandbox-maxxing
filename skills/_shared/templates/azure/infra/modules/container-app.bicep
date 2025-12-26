@description('Name of the environment')
param environmentName string

@description('Primary location for all resources')
param location string

@description('Container Registry name (optional)')
param containerRegistryName string = ''

@description('CPU allocation')
param cpu string = '0.5'

@description('Memory allocation')
param memory string = '1Gi'

@description('Minimum replicas')
param minReplicas int = 0

@description('Maximum replicas')
param maxReplicas int = 10

var containerAppEnvName = 'cae-${environmentName}'
var containerAppName = 'ca-${environmentName}'
var logAnalyticsWorkspaceName = 'log-${environmentName}'

// Log Analytics Workspace
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// Container Apps Environment
resource containerAppEnv 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: containerAppEnvName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  }
}

// Container App
resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: containerAppEnv.id
    configuration: {
      ingress: {
        external: true
        targetPort: 8000
        transport: 'auto'
        allowInsecure: false
      }
      registries: !empty(containerRegistryName) ? [
        {
          server: '${containerRegistryName}.azurecr.io'
          identity: 'system'
        }
      ] : []
    }
    template: {
      containers: [
        {
          name: 'devcontainer'
          image: !empty(containerRegistryName) ? '${containerRegistryName}.azurecr.io/${environmentName}:latest' : 'mcr.microsoft.com/devcontainers/base:bookworm'
          resources: {
            cpu: json(cpu)
            memory: memory
          }
          env: [
            {
              name: 'ENVIRONMENT'
              value: environmentName
            }
          ]
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
        rules: [
          {
            name: 'http-scaling'
            http: {
              metadata: {
                concurrentRequests: '10'
              }
            }
          }
        ]
      }
    }
  }
  identity: !empty(containerRegistryName) ? {
    type: 'SystemAssigned'
  } : null
}

// Assign AcrPull role to Container App if using ACR
resource acrPullRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(containerRegistryName)) {
  name: guid(containerApp.id, containerRegistryName, 'AcrPull')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
    principalId: containerApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Outputs
output name string = containerApp.name
output fqdn string = containerApp.properties.configuration.ingress.fqdn
output environmentId string = containerAppEnv.id
