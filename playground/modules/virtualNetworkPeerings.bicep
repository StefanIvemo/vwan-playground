param vNetName string
param peerName string
param peerId string

resource vnet 'Microsoft.Network/virtualNetworks@2021-03-01' existing = {
  name: vNetName
}

resource peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-03-01' = {
  name: 'peeredTo-${peerName}'
  parent: vnet
  properties: {
    allowForwardedTraffic: true
    allowVirtualNetworkAccess: true
    remoteVirtualNetwork: {
      id: peerId
    }
  }
}
