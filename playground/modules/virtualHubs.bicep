// 2020-08-01-1

param name string
@allowed([
  'Basic'
  'Standard'
])
param sku string = 'Standard'
param addressPrefix string
param virtualRouterAsn int = 0
param virtualRouterIps array = []
param virtualWanId string
param vpnGatewayId string = ''
param p2SVpnGatewayId string = ''
param expressRouteGatewayId string = ''
param azureFirewallId string = ''
param securityPartnerProviderId string = ''
param securityProviderName string = ''
param allowBranchToBranchTraffic bool = true
param tags object = {}
param location string = resourceGroup().location

resource hub 'Microsoft.Network/virtualHubs@2020-11-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    virtualWan: {
      id: virtualWanId
    }
    addressPrefix: addressPrefix
    virtualRouterAsn: virtualRouterAsn == 0 ? json('null') : virtualRouterAsn
    virtualRouterIps: virtualRouterIps == [] ? json('null') : virtualRouterIps
    sku: sku
    vpnGateway: vpnGatewayId == '' ? json('null') : {
      id: vpnGatewayId
    }
    p2SVpnGateway: p2SVpnGatewayId == '' ? json('null') : {
      id: p2SVpnGatewayId
    }
    expressRouteGateway: expressRouteGatewayId == '' ? json('null') : {
      id: expressRouteGatewayId
    }
    azureFirewall: azureFirewallId == '' ? json('null') : {
      id: azureFirewallId
    }
    securityPartnerProvider: securityPartnerProviderId == '' ? json('null') : {
      id: securityPartnerProviderId
    }
    securityProviderName: securityProviderName == '' ? json('null') : securityProviderName
    allowBranchToBranchTraffic: allowBranchToBranchTraffic
  }
}

output resourceId string = hub.id
output resourceName string = hub.name
output virtualRouterIps array = hub.properties.virtualRouterIps
output virtualRouterAsn int = hub.properties.virtualRouterAsn
