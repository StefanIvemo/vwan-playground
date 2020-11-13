targetScope='subscription'

param location string {
  default: 'westeurope'
  metadata: {
    description: 'Specifies the Azure location where the key vault should be created.'
  }
}
param nameprefix string {
  default: 'contoso'
  metadata: {
    description: 'Specifies the naming prefix to use for the Virtual WAN resources.'
  }
}
param wantype string {
  default: 'Standard'
  allowed: [
    'Standard'
    'Basic'
  ]
  metadata: {
    description: 'Specifies the type of Virtual WAN.'
  }
}

/*Variables for VWAN */
var wanname = '${nameprefix}-vwan'
var hubname = '${nameprefix}-vhub-${location}'
var fwname = '${nameprefix}-fw-${location}'
var hubvpngwname = '${nameprefix}-vhub-${location}-vpngw'
var fwpolicyname = '${fwname}-policy'
var onpremvpnsitename = 'onprem-vpnsite'
var spokeconnectionname = '${nameprefix}-spoke1-vnet-connection'
var loganalyticsprefix = 'fwlogs'

/*Variables for spoke VNet and VM */
var spokevnetname = 'spoke1-vnet'
var spokebastionname = '${spokevnetname}-bastion'
var spokebastionnsgname = '${spokevnetname}-AzureBastionSubnet-nsg'
var spokeservernsgname = '${spokevnetname}-snet-servers-nsg'
var spokebastionipname = '${spokebastionname}-pip'
var spokevmname = 'spoke1-vm01'
var spokenicname =  '${spokevmname}-nic'
var spokediskname =  '${spokevmname}-OSDisk'

param hubaddressprefix string {
  default: '10.0.0.0/24'
  metadata: {
    description: 'Specifies the Virtual Hub Address Prefix.'
  }
}

resource wanrg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: '${nameprefix}-global-vwan-rg'
  location: location
}

resource logsrg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: '${nameprefix}-mgmt-rg'
  location: location
}
resource spokerg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: '${nameprefix}-spoke1-rg'
  location: location
}

module wan './VirtualWAN.bicep' = {
  name: 'vwandeploy'
  scope: resourceGroup(wanrg.name)
  params: {
    wanname: wanname
    location: location
    wantype: wantype
  }
}

module hub './VirtualHub.bicep' = {
  name: 'vhubdeploy'
  scope: resourceGroup(wanrg.name)
  params: {
    hubname: hubname
    location: location
    wanid: wan.outputs.wanid
    hubaddressprefix: hubaddressprefix
  }
}

module fwpolicy './FwPolicy.bicep' = {
  name: 'fwpolicydeploy'
  scope: resourceGroup(wanrg.name)
  params: {
    fwpolicyname: fwpolicyname
    location: location
  }
}

module rcgroupplatform './FwPolicyPlatformRCG.bicep' = {
  name: 'rcgroupplatformdeploy'
  scope: resourceGroup(wanrg.name)
  params: {
    fwpolicyname: fwpolicyname
  }
}

module loganlytics './LogAnalytics.bicep' = {
  name: 'loganalyticsdeploy'
  scope: resourceGroup(logsrg.name)
  params: {
    loganalyticsprefix: loganalyticsprefix
    location: location
  }
}

module firewall './AzureFirewall.bicep' = {
  name: 'firewalldeploy'
  scope: resourceGroup(wanrg.name)
  params: {
    fwname: fwname
    location: location
    fwpublicipcount: 3
    fwpolicyid: fwpolicy.outputs.fwpolicyid
    hubid: hub.outputs.hubid
    hubaddressprefix: hubaddressprefix
  }
}

module firewalldiag './FwDiagnostics.bicep' = {
  name: 'firewalldiagdeploy'
  scope: resourceGroup(wanrg.name)
  params: {
    fwname: fwname
    location: location
    loganalyticsid: loganlytics.outputs.loganlyticsid
  }
}

module hubvpngw './VPNGateway.bicep' = {
  name: 'hubvpngwdeploy'
  scope: resourceGroup(wanrg.name)
  params: {
    hubvpngwname: hubvpngwname
    location: location
    hubid: hub.outputs.hubid
  }
}

module spokeservernsg './NSGDefaultRules.bicep' = {
  name: 'spokensgdeploy'
  scope: resourceGroup(spokerg.name)
  params: {
    nsgname: spokeservernsgname

  }
}

module spokebasionnsg './NSGBastion.bicep' = {
  name: 'spokensgdeploy'
  scope: resourceGroup(spokerg.name)
  params: {
    nsgname: spokebastionnsgname
    location: location
  }
}

module spokevnet './VNet.bicep' = {
  name: 'spokevnetdeploy'
  scope: resourceGroup(spokerg.name)
  params: {
    vnetname: spokevnetname
    addressprefix: '10.0.1.0/24'
    serversubnetprefix: '10.0.1.0/26'
    bastionsubnetprefix: '10.0.1.64/26'
    servernsgid: spokeservernsg.outputs.nsgid
    bastionnsgid: spokebasionnsg.outputs.nsgid
    dnsservers: firewall.outputs.fwprivateip
  }
}

module vnethubroutetable './VirtualHubRouteTable.bicep' = {
  name: 'vnethubroutetabledeploy'
  scope: resourceGroup(wanrg.name)
  params:{
    hubname: hubname
    routetablename: 'RT_VNet'
    routetabellabels: 'VNet'
    routes:{
      routes: [
        {
            name: 'toFirewall'
            destinationType: 'CIDR'
            destinations: [
                '0.0.0.0/0'
            ]
            nextHopType: 'ResourceId'
            nextHop: firewall.outputs.firewallid
        }
    ]
    }
  }
}

module hubvnetconnection './VirtualHubVNetConnection.bicep' = {
  name: 'hubvnetconnectiondeploy'
  scope: resourceGroup(wanrg.name)
  params: {
    hubname: hubname
    spokeconnectionname: spokeconnectionname
    spokevnetid: spokevnet.outputs.vnetid
    vnetroutetableid: vnethubroutetable.outputs.routetableid
  }
}