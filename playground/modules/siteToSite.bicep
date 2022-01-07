param site object
param vpnGwId string
param hubs array

@secure()
param psk string
param location string = resourceGroup().location

resource lgw 'Microsoft.Network/localNetworkGateways@2020-06-01' = [for hub in hubs: if (hub.vpnGw != null) {
  name: '${site.location}-${hub.hubName}'
  location: location
  properties: {
    localNetworkAddressSpace: {
      addressPrefixes: hub.hubAddressPrefix
    }
    gatewayIpAddress: hub.vpnGw.vpnGwPublicIp
    bgpSettings: {
      asn: hub.vpnGw.vpnGwASN
      bgpPeeringAddress: hub.vpnGw.vpnGwPrivateIp
    }
  }
}]

resource s2sconnection 'Microsoft.Network/connections@2021-02-01' = [for (hub, i) in hubs: if (hub.vpnGw != null) {
  name: '${site.location}-to-${hub.hubName}-con'
  location: location
  properties: {
    connectionType: 'IPsec'
    connectionProtocol: 'IKEv2'
    virtualNetworkGateway1: {
      id: vpnGwId
    }
    enableBgp: true
    sharedKey: psk
    localNetworkGateway2: {
      id: lgw[i].id
    }
  }
}]
