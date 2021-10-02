param lgwName string
param connectionName string
param addressPrefixes array
param bgpPeeringAddress string
param vpnDeviceIpAddress string
param vpnGwId string

@secure()
param psk string
param location string = resourceGroup().location

resource lgw 'Microsoft.Network/localNetworkGateways@2020-06-01' = {
  name: lgwName
  location: location
  properties: {
    localNetworkAddressSpace: {
      addressPrefixes: addressPrefixes
    }
    gatewayIpAddress: vpnDeviceIpAddress
    bgpSettings: {
      asn: 65515
      bgpPeeringAddress: bgpPeeringAddress
    }
  }
}

resource s2sconnection 'Microsoft.Network/connections@2021-02-01' = {
  name: connectionName
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
      id: lgw.id
    }
  }
}
