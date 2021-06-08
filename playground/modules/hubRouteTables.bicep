param hubName string
param routeTableName string
param routes array
param labels array

resource hubRouteTable 'Microsoft.Network/virtualHubs/hubRouteTables@2021-02-01' = {
  name: '${hubName}/${routeTableName}'
  properties: {
      routes: routes
      labels: labels
  } 
}

output resourceId string = hubRouteTable.id
