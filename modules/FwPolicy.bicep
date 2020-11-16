param location string {
  default: resourceGroup().location
  metadata: {
    description: 'Specifies the Azure location where the key vault should be created.'
  }
}
param policyname string {
  metadata: {
    description: 'Specifies the name to use for the Firewall Policy'
  }
}
param dnsservers array {
  default: [
    '168.63.129.16'
  ]
  metadata: {
    description: 'Specify custom DNS Servers for Azure Firewall'
  }
}

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