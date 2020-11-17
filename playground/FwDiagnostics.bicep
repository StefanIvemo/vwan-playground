param location string {
  default: resourceGroup().location
  metadata: {
    description: 'Specifies the Azure location where the resource should be created.'
  }
}
param fwname string {
  metadata: {
    description: 'Specifies the name of the Azure Firewall resources.'
  }
}
param loganalyticsid string {
  metadata: {
    description: 'Specifies the Log Analtyics ID.'
  }
}

resource firewalldiag 'Microsoft.Network/azureFirewalls/providers/diagnosticSettings@2017-05-01-preview' = {
  name: '${fwname}/Microsoft.Insights/diagnostics'
  location: location
  properties: {
    workspaceId: loganalyticsid
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