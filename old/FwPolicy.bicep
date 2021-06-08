@description('Specifies the Azure location where the resource should be created.')
param location string = resourceGroup().location

@description('Specifies the name to use for the Firewall Policy')
param policyname string

@description('Specify custom DNS Servers for Azure Firewall')
param dnsservers array = [
  '168.63.129.16'
]

resource policy 'Microsoft.Network/firewallPolicies@2020-06-01' = {
  name: policyname
  location: location
  properties: {
      threatIntelMode: 'Alert'
      dnsSettings: {
          servers: dnsservers
          enableProxy: true
      }
  }
}

output name string = policy.name
output id string = policy.id
