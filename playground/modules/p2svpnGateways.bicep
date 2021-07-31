param p2sVpnGwName string
param location string = resourceGroup().location
param virtualHubId string
param vpnServerConfigurationId string
param staticRoutes array = []
param addressPrefixes array
param enableInternetSecurity bool = true
param vpnGatewayScaleUnit int = 1
param customDnsServers array = []
param isRoutingPreferenceInternet bool = false

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
