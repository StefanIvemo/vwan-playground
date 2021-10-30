param vnetName string
param addressPrefix string
param dnsServers array = []
param privateDnsZoneRg string
param privateDnsZoneName string
param tags object = {}
param location string = resourceGroup().location

// Create subnet address prefixes from VNet address prefix
var serverPrefix = '${split(addressPrefix, '.')[0]}.${split(addressPrefix, '.')[1]}.${split(addressPrefix, '.')[2]}.0/26'
var gatewayPrefix = '${split(addressPrefix, '.')[0]}.${split(addressPrefix, '.')[1]}.${split(addressPrefix, '.')[2]}.64/26'

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
          addressPrefix: serverPrefix
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: gatewayPrefix
        }
      }
    ]
  }
}

module privateDnsZoneLink 'privateDnsZoneLink.bicep' = {
  name: 'deploy-privatedns-vnetlink'
  scope: resourceGroup(privateDnsZoneRg)
  params: {
    privateDnsZoneName: privateDnsZoneName
    vNetId: vnet.id
    vNetName: vnet.name
  }
}

output vnetName string = vnet.name
output serverSubnetId string = vnet.properties.subnets[0].id
output gwSubnetId string = vnet.properties.subnets[1].id
output resourceId string = vnet.id
