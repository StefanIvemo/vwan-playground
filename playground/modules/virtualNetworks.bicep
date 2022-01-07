param vnetName string
param addressPrefix string
param deployBastionSubnet bool = false
param deployGatewaySubnet bool = true
param dnsServers array = []
param sharedServicesRg string
param privateDnsZoneName string
param peerName string = ''
param peerId string = ''
param tags object = {}
param location string = resourceGroup().location

// Create subnet address prefixes from VNet address prefix
var serverPrefix = '${split(addressPrefix, '.')[0]}.${split(addressPrefix, '.')[1]}.${split(addressPrefix, '.')[2]}.0/26'
var gatewayPrefix = '${split(addressPrefix, '.')[0]}.${split(addressPrefix, '.')[1]}.${split(addressPrefix, '.')[2]}.64/26'
var bastionPrefix = '${split(addressPrefix, '.')[0]}.${split(addressPrefix, '.')[1]}.${split(addressPrefix, '.')[2]}.128/26'

var bastionNSGRules = json(loadTextContent('./nsgRules/azureBastionNSGRules.json'))

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: '${vnetName}-snet-servers-nsg'
  location: location
}

resource bastionNsg 'Microsoft.Network/networkSecurityGroups@2021-02-01' = if (deployBastionSubnet) {
  name: '${vnetName}-snet-azurebastionsubnet-nsg'
  location: location
  properties: {
    securityRules: bastionNSGRules
  }
}

var standardSubnet = [
  {
    name: 'snet-servers'
    properties: {
      addressPrefix: serverPrefix
      networkSecurityGroup: {
        id: nsg.id
      }
    }
  }
]

var gatewaySubnet = [
  {
    name: 'GatewaySubnet'
    properties: {
      addressPrefix: gatewayPrefix
    }
  }
]

var bastionSubnet = [
  {
    name: 'AzureBastionSubnet'
    properties: {
      addressPrefix: bastionPrefix
      networkSecurityGroup: {
        id: deployBastionSubnet ? bastionNsg.id : ''
      }
    }
  }
]

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
    subnets: deployBastionSubnet && deployGatewaySubnet ? union(standardSubnet, gatewaySubnet, bastionSubnet) : deployBastionSubnet && !deployGatewaySubnet ? union(standardSubnet, bastionSubnet) : deployGatewaySubnet && !deployBastionSubnet ? union(standardSubnet, gatewaySubnet) : standardSubnet
  }
}

// Create peering to bastion vnet
resource peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-03-01' = if (peerName != '' && peerId != '') {
  name: 'peeredTo-${peerName}'
  parent: vnet
  properties: {
    allowForwardedTraffic: true
    allowVirtualNetworkAccess: true
    remoteVirtualNetwork: {
      id: peerId
    }
  }
}

// Create a peering to this vnet in bastion vnet
module remotePeering 'virtualNetworkPeerings.bicep' = if (peerName != '' && peerId != '') {
  name: 'peeredTo-${vnet.name}'
  scope: resourceGroup(sharedServicesRg)
  dependsOn: [
    peering
  ]
  params: {
    peerId: vnet.id
    peerName: vnet.name
    vNetName: peerName
  }
}

module privateDnsZoneLink 'privateDnsZoneLink.bicep' = {
  name: 'deploy-vnetlink${vnet.name}'
  scope: resourceGroup(sharedServicesRg)
  dependsOn: [
    remotePeering
  ]
  params: {
    privateDnsZoneName: privateDnsZoneName
    vNetId: vnet.id
    vNetName: vnet.name
  }
}

output vnetName string = vnet.name
output serverSubnetId string = vnet.properties.subnets[0].id
output gwSubnetId string = vnet.properties.subnets[1].id
output bastionSubnetId string = deployBastionSubnet && deployGatewaySubnet ? vnet.properties.subnets[2].id : vnet.properties.subnets[1].id
output resourceId string = vnet.id
