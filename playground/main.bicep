targetScope = 'subscription'

@secure()
param vmAdminPassword string

@secure()
param psk string

// Load VWAN Playground Config file. 
var vwanConfig = json(loadTextContent('./configs/contoso.json'))
var location = vwanConfig.defaultLocation

// Load P2S AAD Auth Config file
var p2sAuthConfig = json(loadTextContent('./configs/p2sVpnAADAuth.json'))
var clientId = p2sAuthConfig.clientId
var tenantId = p2sAuthConfig.tenantId

// Resource naming
var namePrefix = vwanConfig.namePrefix
var vwanName = '${namePrefix}-vwan'

// Shared Services
// Resource Group for shared services
resource sharedg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${namePrefix}-sharedservices-rg'
  location: location
}

// Log Analytics Workspace
module workspace 'modules/workspaces.bicep' = {
  scope: sharedg
  name: 'workspace-deploy'
  params: {
    location: location
    namePrefix: namePrefix
  }
}

// Private DNS Zone - Used by all VNets (LZ and "on-prem") for name resolution
module privateDnsZone 'modules/privateDnsZones.bicep' = {
  scope: sharedg
  name: 'private-dns-deploy'
  params: {
    namePrefix: namePrefix
  }
}

// VNet for shared bastion host
module bastionVnet 'modules/virtualNetworks.bicep' = {
  scope: sharedg
  name: 'bastion-vnet-deploy'
  params: {
    addressPrefix: vwanConfig.sharedServices.addressPrefix
    privateDnsZoneName: privateDnsZone.outputs.resourceName
    privateDnsZoneRg: sharedg.name
    vnetName: '${namePrefix}-sharedservices-${vwanConfig.defaultLocation}-vnet'
    deployBastionSubnet: true
    deployGatewaySubnet: false
  }
}

// VWAN
// Resource Group
resource vwanRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${namePrefix}-vwan-rg'
  location: location
}

// Deploy Virtual VWAN
module vwan 'modules/virtualWans.bicep' = {
  scope: vwanRg
  name: 'vwan-deploy'
  params: {
    name: vwanName
    location: location
  }
}

// Deploy Virtual Hubs
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

// Deploy Firewall Policies for Firewall enabled hubs
module firewallPolicies 'modules/firewallPolicies.bicep' = [for (region, i) in vwanConfig.regions: if (region.deployFw) {
  scope: vwanRg
  name: 'firewallPolicies-${region.location}-deploy'
  params: {
    parentPolicyName: '${namePrefix}-${region.location}-parent-azfwp'
    childPolicyName: '${namePrefix}-${region.location}-child-azfwp'
    location: region.location
  }
}]

// Deploy Firewalls for firewall enabled hubs
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

// Deploy VPN Gateway for VPN enabled hubs
module vpnGateways 'modules/vpnGateways.bicep' = [for (region, i) in vwanConfig.regions: if (region.deployVpnGw) {
  scope: vwanRg
  name: 'vpnGateways-${region.location}-deploy'
  params: {
    hubid: virtualHubs[i].outputs.resourceId
    hubvpngwname: '${virtualHubs[i].outputs.resourceName}-vpng'
    location: region.location
  }
}]

// Deploy ExpressRoute Gateways for ExpressRoute enabled hubs
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

// Deploy User VPN Configuration if clientId and tenantId is provided
module vpnServerConfigurations 'modules/vpnServerConfigurations.bicep' = if (!empty(clientId) && !empty(tenantId)) {
  scope: vwanRg
  name: 'vpnServerConfigurations-deploy'
  params: {
    vpnConfigName: '${namePrefix}-aad-uservpn-conf'
    tenantId: tenantId
    clientId: clientId
  }
}

// Deploy Point-to-site Gateways for P2S enabled hubs
module p2svpnGateways 'modules/p2svpnGateways.bicep' = [for (region, i) in vwanConfig.regions: if (region.deployP2SGw) {
  scope: vwanRg
  name: 'p2svpnGateway-${region.location}-deploy'
  dependsOn: [
    erGateways
  ]
  params: {
    virtualHubId: virtualHubs[i].outputs.resourceId
    vpnServerConfigurationId: (!empty(clientId) && !empty(tenantId)) ? '' : vpnServerConfigurations.outputs.resourceId
    p2sVpnGwName: '${virtualHubs[i].outputs.resourceName}-p2sgw'
    addressPrefixes: region.p2sConfig.p2sAddressPrefixes
  }
}]

// Landing Zones
// Deploy "landing zone" resource groups
resource landingZoneRg 'Microsoft.Resources/resourceGroups@2021-04-01' = [for (region, i) in vwanConfig.regions: {
  name: '${namePrefix}-${region.landingZones.name}-rg'
  location: region.location
}]

// Deploy "landing zone" VNets
module landingZoneVnet 'modules/virtualNetworks.bicep' = [for (region, i) in vwanConfig.regions: {
  name: '${region.landingZones.name}-vnet-deploy'
  scope: landingZoneRg[i]
  params: {
    addressPrefix: region.landingZones.addressPrefix
    vnetName: '${region.landingZones.name}-vnet'
    privateDnsZoneName: privateDnsZone.outputs.resourceName
    privateDnsZoneRg: sharedg.name
  }
}]

// Deploy "landing zone" servers
module landingZoneServer 'modules/windowsVM.bicep' = [for (region, i) in vwanConfig.regions: {
  name: '${region.landingZones.name}-vm-deploy'
  scope: landingZoneRg[i]
  params: {
    vmName: '${region.landingZones.name}-vm'
    adminPassword: vmAdminPassword
    subnetId: landingZoneVnet[i].outputs.serverSubnetId
  }
}]

// Deploy Virtual Hub Route tables for Landing Zones
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

// Landing Zone VNet Connection. If the hub has a firewall apply landing zone route table otherwise use the default
@batchSize(1)
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
    vnetId: landingZoneVnet[i].outputs.resourceId
    connectionName: 'peeredTo-${region.landingZones.name}-vnet'
  }
}]

// On-Prem
// Deploy "on-prem" resource groups
resource onPremRG 'Microsoft.Resources/resourceGroups@2021-04-01' = [for (site, i) in vwanConfig.onPremSites: {
  name: '${namePrefix}-site-${site.location}-rg'
  location: site.location
}]

// Deploy "on-prem" VNets
module onPremVnet 'modules/virtualNetworks.bicep' = [for (site, i) in vwanConfig.onPremSites: {
  name: 'site-${site.location}-vnet-deploy'
  scope: onPremRG[i]
  params: {
    addressPrefix: site.addressPrefix
    vnetName: '${namePrefix}-site-${site.location}-vnet'
    privateDnsZoneName: privateDnsZone.outputs.resourceName
    privateDnsZoneRg: sharedg.name
  }
}]

//Deploy "on-prem" servers
module onPremServer 'modules/windowsVM.bicep' = [for (site, i) in vwanConfig.onPremSites: if (site.deployVM) {
  name: 'site-${site.location}-vm-deploy'
  scope: onPremRG[i]
  params: {
    vmName: '${site.location}01'
    adminPassword: vmAdminPassword
    subnetId: onPremVnet[i].outputs.serverSubnetId
  }
}]

// Deploy "on-prem" VPN Gateway
module onPremVPNGw 'modules/virtualNetworkGateways.bicep' = [for (site, i) in vwanConfig.onPremSites: {
  name: 'site-${site.location}-vpnGw-deploy'
  scope: onPremRG[i]
  params: {
    vpnGwName: '${onPremVnet[i].outputs.vnetName}-vgw'
    subnetId: onPremVnet[i].outputs.gwSubnetId
  }
}]

// Deploy "on-Prem" site in VWAN
module vpnSites 'modules/vpnSites.bicep' = [for (site, i) in vwanConfig.onPremSites: {
  name: 'site-${site.location}-vpnSite-deploy'
  scope: vwanRg
  params: {
    siteName: '${site.location}-vpnSite'
    siteAddressPrefix: site.addressPrefix
    bgpPeeringAddress: onPremVPNGw[i].outputs.bgpAddress
    vpnDeviceIpAddress: onPremVPNGw[i].outputs.publicIp
    wanId: vwan.outputs.resourceId
  }
}]

// Hubs with VPN Gw Enabled
var hubs = [for region in vwanConfig.regions: {
  name: '${vwanName}-${region.location}-vhub'
  vpnEnabled: region.deployVpnGw
  addressPrefix: region.hubAddressPrefix
}]

// Get all vHubs with S2S gateway enabled and create an array output
module vpnGws 'modules/vpnGatewayInfo.bicep' = {
  scope: vwanRg
  dependsOn: [
    vpnGateways
  ]
  name: 'getAllVPNGws'
  params: {
    hubs: hubs
  }
}

// Create VPN Connections in VWAN for each "on-prem" site
@batchSize(1)
module vpnConnection 'modules/vpnConnections.bicep' = [for (site, i) in vwanConfig.onPremSites: {
  name: 'site-${site.location}-vpnConnection-deploy'
  scope: vwanRg
  params: {
    hubs: vpnGws.outputs.hubs
    vpnSiteId: vpnSites[i].outputs.resourceId
    siteName: vpnSites[i].outputs.resourceName
    psk: psk
  }
}]

// Create local network gateways and site to site connections for each hub in the "on-prem" sites
module siteToSite 'modules/siteToSite.bicep' = [for (site, i) in vwanConfig.onPremSites: {
    name: 'site-${site.location}-s2s-deploy'
   scope: onPremRG[i]
    params: {
      site: site
      hubs: vpnGws.outputs.hubs
      vpnGwId: onPremVPNGw[i].outputs.resourceId
      psk: psk      
    }
  }]
