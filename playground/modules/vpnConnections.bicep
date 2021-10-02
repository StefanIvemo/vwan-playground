param hubs array
@secure()
param psk string
param siteName string
param vpnSiteId string

resource vpnConnection 'Microsoft.Network/vpnGateways/vpnConnections@2021-02-01' = [for hub in hubs: if (hub.vpnEnabled) {
  name: '${hub}/${hub}-to-${siteName}-vpn'
  properties: {
    connectionBandwidth: 10
    enableBgp: true
    sharedKey: psk
    remoteVpnSite: {
      id: vpnSiteId
    }
  }
}]
