@description('Specifies the name of Local Network Gateway')
param localnetworkgwname string

@description('Specifies the Azure location where the resources should be created.')
param location string = resourceGroup().location

@description('Specifices the address prefixes of the remote site')
param addressprefixes array

@description('Specifices the VPN Sites BGP Peering IP Addresses')
param bgppeeringpddress string

@description('Specifices the VPN Sites VPN Device IP Address')
param gwipaddress string

@description('Specifices the resource ID of the VPN Gateway to connect to the site to site vpn')
param vpngwid string

@description('Specifies the PSK to use for the VPN Connection')
@secure()
param psk string

resource localnetworkgw 'Microsoft.Network/localNetworkGateways@2020-06-01' = {
  name: localnetworkgwname
  location: location
  properties: {
    localNetworkAddressSpace: {
      addressPrefixes: addressprefixes
    }
    gatewayIpAddress: gwipaddress
    bgpSettings: {
      asn: 65515
      bgpPeeringAddress: bgppeeringpddress
    }
  }
}

resource s2sconnection 'Microsoft.Network/connections@2020-06-01' = {
  name: 'onprem-hub-cn'
  location: location
  properties: {
    connectionType: 'IPsec'
    connectionProtocol: 'IKEv2'
    virtualNetworkGateway1: {
      id: vpngwid
    }
    enableBgp: true
    sharedKey: psk
    localNetworkGateway2: {
      id: localnetworkgw.id
    }
  }
}
