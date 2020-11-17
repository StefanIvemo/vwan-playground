param hubname string {
  metadata: {
    description: 'Specifies the name to use for the Virtual Hub resources.'
  }
}
param spokeconnectionname string {
  metadata: {
    description: 'Specifies the name to use for the Virtual Network Connection'
  }
}
param spokevnetid string {
  metadata: {
    description: 'Specifies the resource id of the VNet to connect to the Virtual Hub'
  }
}
param vnetroutetableid string {
  metadata: {
    description: 'Specifies the resource id of the VNet to connect to the Virtual Hub'
  }
}

resource connection 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2020-06-01' = {
  name: '${hubname}/${spokeconnectionname}'
  properties: {
    remoteVirtualNetwork: {
      id: spokevnetid
    }
    allowHubToRemoteVnetTransit: true
    allowRemoteVnetToUseHubVnetGateways: true
    enableInternetSecurity: true
    routingConfiguration: {
      associatedRouteTable: {
        id: vnetroutetableid
      }
      propagatedRouteTables: {
        labels: [
          'VNet'
        ]
        ids: [
          {
            id: vnetroutetableid
          }
        ]
      }
    }
  }
}