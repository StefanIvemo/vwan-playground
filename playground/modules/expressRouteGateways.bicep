param gwName string
param scaleUnits int = 1
param virtualHubId string
param erConName string
param associatedRouteTableId string
param propagatedRouteTablesIds array
param propagatedRouteTablesLabels array = []
param staticRoutes array = []
param expressRouteCircuitPeeringId string

@secure()
param authorizationKey string
param routingWeight int = 0
param enableInternetSecurity bool = false
param tags object
param location string = resourceGroup().id

var propagatedRouteTables = [for id in propagatedRouteTablesIds: {
  id: id
}]

resource expressRouteGw 'Microsoft.Network/expressRouteGateways@2021-02-01' = {
  name: gwName
  location: location
  tags: tags
  properties: {
    virtualHub: {
      id: virtualHubId
    }
    expressRouteConnections: [
      {
        name: erConName
        properties: {
          routingConfiguration: {
            associatedRouteTable: {
              id: associatedRouteTableId
            }
            propagatedRouteTables: {
              labels: propagatedRouteTablesLabels
              ids: propagatedRouteTables
            }
            vnetRoutes: {
              staticRoutes: staticRoutes
            }
          }
          expressRouteCircuitPeering: {
            id: expressRouteCircuitPeeringId
          }
          routingWeight: routingWeight
          authorizationKey: authorizationKey
          enableInternetSecurity: enableInternetSecurity
        }
      }
    ]
    autoScaleConfiguration: {
      bounds: {
        min: scaleUnits
      }
    }
  }
}

output resourceId string = expressRouteGw.id
output resourceName string = expressRouteGw.name
