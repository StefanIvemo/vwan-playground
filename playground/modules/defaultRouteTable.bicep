param hubName string

resource vHub 'Microsoft.Network/virtualHubs@2024-01-01' existing = {
  name: hubName
}

resource noneRouteTable 'Microsoft.Network/virtualHubs/hubRouteTables@2024-01-01' existing = {
  name: 'None'
  parent: vHub
}

resource defaultRouteTable 'Microsoft.Network/virtualHubs/hubRouteTables@2024-01-01' existing = {
  name: 'defaultRouteTable'
  parent: vHub
}

output noneRouteTableResourceId string = noneRouteTable.id
output defaultRouteTableResourceId string = defaultRouteTable.id
