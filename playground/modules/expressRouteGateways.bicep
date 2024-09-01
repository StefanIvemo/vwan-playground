param gwName string
param scaleUnits int = 1
param virtualHubId string
param workspaceId string
param tags object = {}
param location string = resourceGroup().location

resource expressRouteGw 'Microsoft.Network/expressRouteGateways@2024-01-01' = {
  name: gwName
  location: location
  tags: tags
  properties: {
    virtualHub: {
      id: virtualHubId
    }    
    autoScaleConfiguration: {
      bounds: {
        min: scaleUnits
      }
    }
  }
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diagnostics'
  scope: expressRouteGw
  properties: {
    logs: [
      {
        enabled: true
        categoryGroup: 'allLogs'
        retentionPolicy: {
          days: 0
          enabled: false 
        }
      }
    ]
    metrics: [
      {
        enabled: true
        category: 'AllMetrics'
        retentionPolicy: {
          days: 0
          enabled: false 
        }
      }
    ]
    workspaceId: workspaceId
    logAnalyticsDestinationType: 'Dedicated'
  }
}

output resourceId string = expressRouteGw.id
output resourceName string = expressRouteGw.name
