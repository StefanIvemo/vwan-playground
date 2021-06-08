param p2sVpnGwName string
param location string = resourceGroup().location
param virtualHubId string
param vpnServerConfigurationId string
param associatedRouteTableId string
param propagatedRouteTablesIds array
param staticRoutes array = []
param addressPrefixes array
param enableInternetSecurity bool = true
param vpnGatewayScaleUnit int
param customDnsServers array
param isRoutingPreferenceInternet bool = false

var propagatedRouteTables = [for id in propagatedRouteTablesIds: {
  id: id
}]

resource p2sVpnGw 'Microsoft.Network/p2svpnGateways@2020-11-01' = {
  name: p2sVpnGwName
  location: location
  properties: {
    virtualHub: {
      id: virtualHubId
    }
    vpnServerConfiguration: {
      id: vpnServerConfigurationId
    }
    p2SConnectionConfigurations: [
      {
        name: 'P2SConnectionConfigDefault'
        properties: {
          routingConfiguration: {
            associatedRouteTable: {
              id: associatedRouteTableId
            }
            propagatedRouteTables: {
              ids: propagatedRouteTables
              labels: []
            }
            vnetRoutes: {
              staticRoutes: staticRoutes
            }
          }
          vpnClientAddressPool: {
            addressPrefixes: addressPrefixes
          }
          enableInternetSecurity: enableInternetSecurity
        }
      }
    ]
    vpnGatewayScaleUnit: vpnGatewayScaleUnit
    customDnsServers: customDnsServers
    isRoutingPreferenceInternet: isRoutingPreferenceInternet
  }
}
