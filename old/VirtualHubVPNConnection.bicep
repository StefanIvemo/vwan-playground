@description('Specifies the name of the Virtual Hub where the Vpn Vonnection should be created.')
param hubvpngwname string

@description('Specifies the PSK to use for the VPN Connection')
@secure()
param psk string

@description('Specifies the resource id to the VWAN Vpn Site to connect to')
param vpnsiteid string

resource hubvpnconnection 'Microsoft.Network/vpnGateways/vpnConnections@2020-05-01' = {
  name: '${hubvpngwname}/HubToOnPremConnection'
  properties: {
      connectionBandwidth: 10
      enableBgp: true
      sharedKey: psk
      remoteVpnSite: {
          id: vpnsiteid
      }
  }    
}
