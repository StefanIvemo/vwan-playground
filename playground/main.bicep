targetScope = 'subscription'

param location string = 'westeurope'
param clientId string = '41b23e61-6c1e-4545-b367-cd054e0ed4b4'
param tenantId string = 'd259a616-4e9d-4615-b83d-2e09a6636fd4'

@secure()
param adminPassword string

// Load VWAN Playground Config file
var vwanConfig = json(loadTextContent('./configs/contoso.json'))

// Resource naming
var namePrefix = vwanConfig.namePrefix
var vwanName = '${namePrefix}-vwan'

// Resource Group
resource vwanRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${namePrefix}-vwan-rg'
  location: location
}

// VWAN
module vwan 'modules/virtualWans.bicep' = {
  scope: vwanRg
  name: 'vwan-deploy'
  params: {
    name: vwanName
    location: location
  }
}

module virtualHubs 'modules/virtualHubs.bicep' = [for region in vwanConfig.regions: {
  scope: vwanRg
  name: 'virtualHubs-${region.location}-deploy'
  params: {
    name: '${vwan.outputs.name}-${region.location}-vhub'
    addressPrefix: region.hubAddressPrefix
    location: region.location
    virtualWanId: vwan.outputs.resourceId
  }
}]

module firewallPolicies 'modules/firewallPolicies.bicep' = [for (region, i) in vwanConfig.regions: if (region.deployFw) {
  scope: vwanRg
  name: 'firewallPolicies-${region.location}-deploy'
  params: {
    parentPolicyName: '${namePrefix}-${region.location}-parent-azfwp'
    childPolicyName: '${namePrefix}-${region.location}-child-azfwp'
    location: region.location
  }
}]

module azureFirewalls 'modules/azureFirewalls.bicep' = [for (region, i) in vwanConfig.regions: if (region.deployFw) {
  scope: vwanRg
  name: 'azureFirewalls-${region.location}-deploy'
  params: {
    name: '${vwan.outputs.name}-${region.location}-vhub-azfw'
    hubId: virtualHubs[i].outputs.resourceId
    location: region.location
    fwPolicyId: region.deployFw ? firewallPolicies[i].outputs.childResourceId : ''
    publicIPsCount: 1
  }
}]

module vpnGateways 'modules/vpnGateways.bicep' = [for (region, i) in vwanConfig.regions: if (region.deployVpnGw) {
  scope: vwanRg
  name: 'vpnGateways-${region.location}-deploy'
  params: {
    hubid: virtualHubs[i].outputs.resourceId
    hubvpngwname: '${virtualHubs[i].outputs.resourceName}-vpng'
    location: region.location
  }
}]

module erGateways 'modules/expressRouteGateways.bicep' = [for (region, i) in vwanConfig.regions: if (region.deployErGw) {
  scope: vwanRg
  name: 'erGateways-${region.location}-deploy'
  dependsOn: [
    vpnGateways
  ]
  params: {
    virtualHubId: virtualHubs[i].outputs.resourceId
    gwName: '${virtualHubs[i].outputs.resourceName}-erg'
    location: region.location
  }
}]

module vpnServerConfigurations 'modules/vpnServerConfigurations.bicep' = if (!empty(clientId) && !empty(tenantId)) {
  scope: vwanRg
  name: 'vpnServerConfigurations-deploy'
  params: {
    vpnConfigName: '${namePrefix}-aad-uservpn-conf'
    tenantId: tenantId
    clientId: clientId
  }
}

module p2svpnGateways 'modules/p2svpnGateways.bicep' = [for (region, i) in vwanConfig.regions: if (region.deployP2SGw) {
  scope: vwanRg
  name: 'ps2vpnGateway-${region.location}-deploy'
  dependsOn: [
    erGateways
  ]
  params: {
    virtualHubId: virtualHubs[i].outputs.resourceId
    vpnServerConfigurationId: vpnServerConfigurations.outputs.resourceId
    p2sVpnGwName: '${virtualHubs[i].outputs.resourceName}-p2sgw'
    addressPrefixes: region.p2sConfig.p2sAddressPrefixes
  }
}]

// Landing Zones
resource landingZoneRg 'Microsoft.Resources/resourceGroups@2021-04-01' = [for (region, i) in vwanConfig.regions: {
  name: '${namePrefix}-${region.landingZones.name}-rg'
  location: region.location
}]

module landingZoneVnet 'modules/landingZones/virtualNetworks.bicep' = [for (region, i) in vwanConfig.regions: {
  name: '${region.landingZones.name}-vnet-deploy'
  scope: landingZoneRg[i]
  params: {
    addressPrefix: region.landingZones.addressPrefix
    vnetName: '${region.landingZones.name}-vnet'
  }
}]

module landingZoneServer 'modules/landingZones/windowsVM.bicep' = [for (region, i) in vwanConfig.regions: {
  name: '${region.landingZones.name}-vm-deploy'
  scope: landingZoneRg[i]
  params: {
    vmName: '${region.landingZones.name}-vm'
    adminPassword: adminPassword
    subnetId: landingZoneVnet[i].outputs.subnetId
  }
}]

// Landing Zone Route Table
module lzRouteTable 'modules/hubRouteTables.bicep' = [for (region, i) in vwanConfig.regions: {
  scope: vwanRg
  name: 'lzRouteTable-${region.location}-deploy'
  params: {
    hubName: virtualHubs[i].outputs.resourceName
    labels: [
      'landingzone'
    ]
    routes: region.deployFw ? [
      {
        name: 'nextHopFW'
        destinationType: 'CIDR'
        destinations: [
          '0.0.0.0/0'
        ]
        nextHopType: 'ResourceId'
        nextHop: region.deployFw ? azureFirewalls[i].outputs.resourceId : ''
      }
    ] : []
    routeTableName: '${region.location}-lzRouteTable'
  }
}]

// Get built-in route tableIds
module builtInRouteTables 'modules/defaultRouteTable.bicep' = [for (region, i) in vwanConfig.regions: {
  scope: vwanRg
  name: 'defaultRouteTable-${region.location}-Ids'
  params: {
    hubName: virtualHubs[i].outputs.resourceName
  }
}]

// Landing Zone VNet Connection. If VHub has a firewall apply landing zone route table otherwise use the default
module lzVNetConnection 'modules/hubVirtualNetworkConnections.bicep' = [for (region, i) in vwanConfig.regions: {
  scope: vwanRg
  name: '${region.landingZones.name}-vnet-conn-deploy'
  params: {
    hubName: '${vwan.outputs.name}-${region.location}-vhub'  
    associatedRouteTableId: region.deployFw ? lzRouteTable[i].outputs.resourceId : builtInRouteTables[i].outputs.defaultRouteTableResourceId
    propagatedRouteTableIds: region.deployFw ? [
      builtInRouteTables[i].outputs.noneRouteTableResourceId
    ] : [
      builtInRouteTables[i].outputs.defaultRouteTableResourceId
    ]
    propagatedRouteTableLabels: region.deployFw ? [
      'none'
    ] : [
      'default'
    ]
    vnetId: landingZoneVnet[i].outputs.resourceId
    connectionName: 'peeredTo-${region.landingZones.name}-vnet'
  }
}]

