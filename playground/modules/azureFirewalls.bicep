param name string
param hubId string
param fwPolicyId string
param publicIPsCount int = 1
param publicIPAddresses array = []
param workspaceId string
param location string = resourceGroup().location

var adresses = [for address in publicIPAddresses: {
  address: address
}] 

resource firewall 'Microsoft.Network/azureFirewalls@2024-01-01' = {
  name: name
  location: location
  properties: {
    sku: {
      name: 'AZFW_Hub'
      tier: 'Standard'
    }
    virtualHub: {
      id: hubId
    }
    hubIPAddresses: {
      publicIPs: {
        addresses: publicIPAddresses == [] ? null : adresses
        count: publicIPsCount
      }

    }
    firewallPolicy: {
      id: fwPolicyId
    }
  }
}

resource firewalldiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diagnostics'
  scope: firewall
  properties: {
    workspaceId: workspaceId
    logAnalyticsDestinationType: 'Dedicated'
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
  }
}

output fwName string = firewall.name
output resourceId string = firewall.id
output fwPrivateIp string = firewall.properties.hubIPAddresses.privateIPAddress
