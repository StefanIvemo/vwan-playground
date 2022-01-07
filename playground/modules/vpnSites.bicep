param siteName string

@description('Specifices the VPN Sites local IP Addresses')
param siteAddressPrefix string

@description('Specifices the VPN Sites BGP Peering IP Addresses')
param bgpPeeringAddress string

@description('Specifices the VPN Sites VPN Device IP Address')
param vpnDeviceIpAddress string

@description('Specifices the resource ID of the Virtual WAN where the VPN Site should be created')
param wanId string
param location string = resourceGroup().location

resource vpnSite 'Microsoft.Network/vpnSites@2020-06-01' = {
  name: siteName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        siteAddressPrefix
      ]
    }
    bgpProperties: {
      asn: 65010
      bgpPeeringAddress: bgpPeeringAddress
      peerWeight: 0
    }
    deviceProperties: {
      linkSpeedInMbps: 0
    }
    ipAddress: vpnDeviceIpAddress
    virtualWan: {
      id: wanId
    }
  }
}

output resourceId string = vpnSite.id
output resourceName string = vpnSite.name
