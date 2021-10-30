param namePrefix string

var name = '${namePrefix}.com'

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: name
  location: 'global'
}

output resourceId string = privateDnsZone.id
output resourceName string = privateDnsZone.name
