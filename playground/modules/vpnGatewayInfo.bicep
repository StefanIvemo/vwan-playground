param hubs array

resource vpnGw 'Microsoft.Network/vpnGateways@2021-03-01' existing = [for (hub, i) in hubs: if (hub.vpnEnabled) {
  name: '${hub.name}-vpng'
}]

output hubs array = [for (hub, i) in hubs: {
  hubName: hub.name
  hubAddressPrefix: [
    hub.addressPrefix
  ]
  vpnEnabled: hub.vpnEnabled ? true : false
  vpnGw: !hub.vpnEnabled ? null : {
    vpnGwName: vpnGw[i].name
    vpnGwResourceId: vpnGw[i].id
    vpnGwPublicIp: vpnGw[i].properties.ipConfigurations[0].publicIpAddress
    vpnGwPrivateIp: vpnGw[i].properties.ipConfigurations[0].privateIpAddress
    vpnGwASN: vpnGw[i].properties.bgpSettings.asn
  }
}]
