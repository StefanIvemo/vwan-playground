param vnetName string
param addressPrefix string 
param dnsServers array = []
param tags object = {}
param location string = resourceGroup().location

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: '${vnetName}-snet-servers-nsg'
  location: location
}

resource vnet 'Microsoft.Network/virtualNetworks@2020-08-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    dhcpOptions: {
      dnsServers: dnsServers
    }    
    subnets: [
      {
        name: 'snet-servers'
        properties: {
          addressPrefix: addressPrefix
          
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

output subnetId string = vnet.properties.subnets[0].id
output resourceId string = vnet.id
