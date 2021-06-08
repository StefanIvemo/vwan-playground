targetScope = 'subscription'

param namePrefix string = 'contoso'
param location string = 'westeurope'

param regions array = [
  {
    location: 'westeurope'
    hubAddressPrefix: '10.0.0.0/24'
    deployFw: true
    deployVpnGw: true
  }
  {
    location: 'northeurope'
    hubAddressPrefix: '10.10.0.0/24'
    deployFw: true
    deployVpnGw: false
  }
  {
    location: 'eastus'
    hubAddressPrefix: '10.20.0.0/24'
    deployFw: false
    deployVpnGw: true
  }
]

var vwanName = '${namePrefix}-vwan'

resource vwanRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${namePrefix}-vwan-rg'
  location: location
}

module vwan 'modules/virtualWans.bicep' = {
  scope: vwanRg
  name: 'vwan-deploy'
  params: {
    name: vwanName
    location: location
  }
}

module virtualHubs 'modules/virtualHubs.bicep' = [for region in regions: {
  scope: vwanRg
  name: 'virtualHubs-${region.location}-deploy'
  params: {
    name: '${vwan.outputs.name}-${region.location}-vhub'
    addressPrefix: region.hubAddressPrefix
    location: region.location
    virtualWanId: vwan.outputs.resourceId
  }
}]

module firewallPolicies 'modules/firewallPolicies.bicep' = [for (region, i) in regions: if (region.deployFw) {
  scope: vwanRg
  name: 'firewallPolicies-${region.location}-deploy'
  params: {
    parentPolicyName: '${namePrefix}-${region.location}-parent-azfwp'
    childPolicyName: '${namePrefix}-${region.location}-child-azfwp'
    location: region.location
  }
}]

module azureFirewalls 'modules/azureFirewalls.bicep' = [for (region, i) in regions: if (region.deployFw) {
  scope: vwanRg
  name: 'azureFirewalls-${region.location}-deploy'
  params: {
    name: '${vwan.outputs.name}-${region.location}-vhub-azfw'
    hubId: virtualHubs[i].outputs.resourceId
    location: region.location
    fwPolicyId: firewallPolicies[i].outputs.childResourceId
    publicIPsCount: 1
  }
}]

module vpnGateways 'modules/vpnGateways.bicep' = [for (region, i) in regions: if (region.deployVpnGw) {
  scope: vwanRg
  name: 'vpnGateways-${region.location}-deploy'
  params: {
    hubid: virtualHubs[i].outputs.resourceId
    hubvpngwname: '${virtualHubs[i].outputs.resourceName}-vpng'
    location: region.location
  }
}]
