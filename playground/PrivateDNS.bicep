param zoneName string
param vnetLinks array

//create the dnszone resource
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: zoneName
  location: 'global'
}

resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for link in vnetLinks: {
  name: '${zoneName}/${link.linkName}'
  location: 'global'
  dependsOn:[
    privateDnsZone
  ]
  properties: {
    registrationEnabled: link.registrationEnabled
    virtualNetwork: {
      id: link.vnetId
    }
  }
}]

output resourceId string = privateDnsZone.id
