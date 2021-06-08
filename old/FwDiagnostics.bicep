@description('Specifies the Azure location where the resource should be created.')
param location string = resourceGroup().location

@description('Specifies the name of the Azure Firewall resources.')
param fwname string

@description('Specifies the Log Analtyics ID.')
param loganalyticsid string

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
