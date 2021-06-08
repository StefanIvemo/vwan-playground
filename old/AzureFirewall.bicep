@description('Specifies the Azure location where the Azure Firewall should be created.')
param location string = resourceGroup().location

@description('Specifies the name to use for the Azure Firewall resources.')
param fwname string

@description('Virtual Hub Resource ID')
param hubid string

@description('Firewall Policy Resource ID')
param fwpolicyid string

@description('Specifies the number of public IPs to allocate to the firewall')
param fwpublicipcount int = 2

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

output name string = firewall.name
output id string = firewall.id
output privateip string = firewall.properties.hubIPAddresses.privateIPAddress
