param privateDnsZoneName string
param vNetName string
param vNetId string

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: privateDnsZoneName
}

resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'linkedTo-${vNetName}'
  parent: privateDnsZone
  location: 'global'  
  properties: {
    registrationEnabled: true
    virtualNetwork: {
      id: vNetId
    }
  }
}
