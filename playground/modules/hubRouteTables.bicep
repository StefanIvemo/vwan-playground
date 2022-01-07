param hubName string
param routeTableName string
param routes array
param labels array

resource vHub 'Microsoft.Network/virtualHubs@2021-02-01' existing = {
  name: hubName
}

resource hubRouteTable 'Microsoft.Network/virtualHubs/hubRouteTables@2021-02-01' = {
  name: routeTableName
  parent: vHub
  properties: {
      routes: routes
      labels: labels
  } 
}

output resourceId string = hubRouteTable.id
