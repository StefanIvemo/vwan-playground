param location string = resourceGroup().location
param vpnGwName string
param subnetId string

resource publicIp 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: '${vpnGwName}-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'    
  }
}

resource vpnGw 'Microsoft.Network/virtualNetworkGateways@2020-06-01' = {
  name: vpnGwName
  location: location    
  properties: {
      gatewayType: 'Vpn'
      ipConfigurations: [
          {
              name: 'default'
              properties: {
                  privateIPAllocationMethod: 'Dynamic'
                  subnet: {
                      id: subnetId
                  }
                  publicIPAddress: {
                      id: publicIp.id
                  }
              }
          }
      ]
      activeActive: false
      enableBgp: true
      bgpSettings: {
          asn: 65010
      }
      vpnType: 'RouteBased'
      vpnGatewayGeneration: 'Generation1'
      sku: {
          name: 'VpnGw1AZ'
          tier: 'VpnGw1AZ'
      }
  }
}

output resourceId string = vpnGw.id
output publicIp string = publicIp.properties.ipAddress
output bgpAddress string = vpnGw.properties.bgpSettings.bgpPeeringAddress
