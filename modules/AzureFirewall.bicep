
param location string {
  default: resourceGroup().location
  metadata: {
    description: 'Specifies the Azure location where the Azure Firewall should be created.'
  }
}
param fwname string {
  metadata: {
    description: 'Specifies the name to use for the Azure Firewall resources.'
  }
}
param hubid string {
  metadata: {
    description: 'Virtual Hub Resource ID'
  }
}
param fwpolicyid string {
  metadata: {
    description: 'Firewall Policy Resource ID'
  }
}
param fwpublicipcount int {
  default: 2
  metadata: {
    description: 'Specifies the number of public IPs to allocate to the firewall'
  }
}
resource firewall 'Microsoft.Network/azureFirewalls@2020-06-01' = {
  name: fwname
  location: location
  properties: {
      sku: {
          name: 'AZFW_Hub'
          tier: 'Standard'
      }
      virtualHub: {
          id: hubid
      }
      hubIPAddresses: {            
          publicIPs: {
              count: fwpublicipcount
          }
      }
      firewallPolicy: {
          id: fwpolicyid
      }             
  }
} 

output firewallid string = firewall.id
output fwprivateip string = firewall.properties.hubIPAddresses.privateIPAddress
