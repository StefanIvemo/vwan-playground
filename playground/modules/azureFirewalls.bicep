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

resource firewall 'Microsoft.Network/azureFirewalls@2021-02-01' = {
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
        addresses: publicIPAddresses == [] ? json('null') : adresses
        count: publicIPsCount
      }

    }
    firewallPolicy: {
      id: fwPolicyId
    }
  }
}

resource firewalldiag 'Microsoft.Network/azureFirewalls/providers/diagnosticSettings@2017-05-01-preview' = {
  name: '${firewall.name}/Microsoft.Insights/diagnostics'
  location: location
  properties: {
    workspaceId: workspaceId
    logs: [
      {
        category: 'AzureFirewallApplicationRule'
        enabled: true
      }
      {
        category: 'AzureFirewallNetworkRule'
        enabled: true
      }
      {
        category: 'AzureFirewallDnsProxy'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output fwName string = firewall.name
output resourceId string = firewall.id
output fwPrivateIp string = firewall.properties.hubIPAddresses.privateIPAddress
