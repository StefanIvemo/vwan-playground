targetScope='subscription'

param location string {
  default: 'westeurope'
  metadata: {
    description: 'Specifies the Azure location where the resource should be created.'
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
param regionaladdressspace string {
  default: '10.0.0.0/16'
  metadata: {
    description: 'Specifies the CIDR that contains all address spaces used in Azure, should cover the VWAN Hub and all attached VNet Spokes. Used for routing.'
  }
}
param hubaddressprefix string {
  default: '10.0.0.0/24'
  metadata: {
    description: 'Specifies the Virtual Hub Address Prefix.'
  }
}
param spokeaddressprefix string {
  default: '10.0.1.0/24'
  metadata: {
    description: 'Specify the address prefix to use for the spoke VNet'
  }
}
param spokeserversubnetprefix string {
  default: '10.0.1.0/26'
  metadata: {
    description: 'Specify the address prefix to use for server subnet in the spoke VNet'
  }
}
param spokebastionsubnetprefix string {
  default: '10.0.1.64/26'
  metadata: {
    description: 'Specify the address prefix to use for the AzureBastionSubnet in the spoke VNet'
  }
}
param onpremaddressprefix string {
  default: '10.20.0.0/24'
  metadata: {
    description: 'Specify the address prefix to use for the spoke VNet'
  }
}
param onpremserversubnetprefix string {
  default: '10.20.0.0/26'
  metadata: {
    description: 'Specify the address prefix to use for server subnet in the spoke VNet'
  }
}
param onprembastionsubnetprefix string {
  default: '10.20.0.64/26'
  metadata: {
    description: 'Specify the address prefix to use for the AzureBastionSubnet in the spoke VNet'
  }
}
param onpremvpngatewaysubnetprefix string {
  default: '10.20.0.128/26'
  metadata: {
    description: 'Specify the address prefix to use for the AzureBastionSubnet in the spoke VNet'
  }
}
param onpremfirewallsubnetprefix string {
  default: '10.20.0.192/26'
  metadata: {
    description: 'Specify the address prefix to use for the AzureBastionSubnet in the spoke VNet'
  }
}
param psk string {
  secure:true
  metadata: {
      'description': 'PSK to use for the site to site tunnel between Virtual Hub and On-Prem VNet' 
  }
}
param adminusername string {
  default :'sysadmin'
  metadata: {
      'description': 'The local admin user name for the deployed servers' 
  }
}

param adminpassword string {
  secure:true
  metadata: {
      'description': 'The local admin password' 
  }
}
param windowsosversion string {
  default :'2019-Datacenter'
  allowed : [        
      '2016-Datacenter'
      '2019-Datacenter'
    ]
    metadata: {
      'description': 'The Windows version for the VM. This will pick a fully patched image of this given Windows version.' 
    }
}
param vmsize string {
  default: 'Standard_D2_v3'
  metadata: {
    description: 'Size of the virtual machine.'
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

/*Variables for "On-Prem" VNet and VM */
var onpremvnetname = 'onprem-vnet'
var onprembastionname = '${onpremvnetname}-bastion'
var onprembastionnsgname = '${onpremvnetname}-AzureBastionSubnet-nsg'
var onpremservernsgname = '${onpremvnetname}-snet-servers-nsg'
var onprembastionipname = '${onprembastionname}-pip'
var onpremvmname = 'onprem-vm01'
var onpremnicname =  '${onpremvmname}-nic'
var onpremdiskname =  '${onpremvmname}-OSDisk'
var onpremvpngwname = '${onpremvnetname}-vpn-vgw'
var onpremvpngwpipname = '${onpremvpngwname}-pip'
var onprems2saddressprefixes = [
  hubaddressprefix 
  spokeaddressprefix
]

resource wanrg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: '${nameprefix}-vwan-rg'
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
resource onpremrg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: '${nameprefix}-onprem-rg'
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
    wanid: wan.outputs.id
    hubaddressprefix: hubaddressprefix
  }
}

module fwpolicy './FwPolicy.bicep' = {
  name: 'fwpolicydeploy'
  scope: resourceGroup(wanrg.name)
  params: {
    policyname: fwpolicyname
    location: location
  }
}

module rcgroupplatform './FwPolicyPlatformRCG.bicep' = {
  name: 'rcgroupplatformdeploy'
  scope: resourceGroup(wanrg.name)
  params: {
    fwpolicyname: fwpolicy.outputs.name
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
    fwpolicyid: fwpolicy.outputs.id
    hubid: hub.outputs.id
  }
}

module firewalldiag './FwDiagnostics.bicep' = {
  name: 'firewalldiagdeploy'
  scope: resourceGroup(wanrg.name)
  params: {
    fwname: firewall.outputs.name
    location: location
    loganalyticsid: loganlytics.outputs.id
  }
}

module defaulthubroutetable './VirtualHubRouteTable.bicep' = {
  name: 'defaulthubroutetabledeploy'
  scope: resourceGroup(wanrg.name)
  params:{
    hubname: hubname
    routetablename: 'defaultRouteTable'
    routetabellabels: 'default'
    routes:{
      routes: [
        {
          name: 'toFirewall'
          destinationType: 'CIDR'
          destinations: [
              regionaladdressspace
          ]
          nextHopType: 'ResourceId'
          nextHop: firewall.outputs.id
      }
    ]
    }
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
            nextHop: firewall.outputs.id
        }
    ]
    }
  }
}

module hubvpngw './VirtualHubVPNGateway.bicep' = {
  name: 'hubvpngwdeploy'
  scope: resourceGroup(wanrg.name)
  params: {
    hubvpngwname: hubvpngwname
    location: location
    hubid: hub.outputs.id
  }
}

module spokeservernsg './NSGDefaultRules.bicep' = {
  name: 'spokeservernsgdeploy'
  scope: resourceGroup(spokerg.name)
  params: {
    nsgname: spokeservernsgname
    location: location
  }
}

module spokebastionnsg './NSGBastion.bicep' = {
  name: 'spokebastionnsgdeploy'
  scope: resourceGroup(spokerg.name)
  params: {
    nsgname: spokebastionnsgname
    location: location
  }
}

module spokevnet './SpokeVNet.bicep' = {
  name: 'spokevnetdeploy'
  scope: resourceGroup(spokerg.name)
  params: {
    vnetname: spokevnetname
    addressprefix: spokeaddressprefix
    serversubnetprefix: spokeserversubnetprefix
    bastionsubnetprefix: spokebastionsubnetprefix
    servernsgid: spokeservernsg.outputs.id
    bastionnsgid: spokebastionnsg.outputs.id
    dnsservers: firewall.outputs.privateip
  }
}

module hubvnetconnection './VirtualHubVNetConnection.bicep' = {
  name: 'hubvnetconnectiondeploy'
  scope: resourceGroup(wanrg.name)
  params: {
    hubname: hubname
    spokeconnectionname: spokeconnectionname
    spokevnetid: spokevnet.outputs.id
    vnetroutetableid: vnethubroutetable.outputs.id
  }
}

module spokebastion './Bastion.bicep' = {
  name: 'spokebastiondeploy'
  scope: resourceGroup(spokerg.name)
  params: {
    bastionname: spokebastionname
    location: location
    bastionsubnetref: spokevnet.outputs.bastionsubnetid
  }
}

module spoekvm './WindowsVM.bicep' = {
  name: 'spokevmdeploy'
  scope: resourceGroup(spokerg.name)
  params: {
    vmname: spokevmname
    location: location
    diskname: spokediskname
    nicname: spokenicname    
    adminusername: adminusername
    adminpassword: adminpassword
    subnetref: spokevnet.outputs.serversubnetid
  }
}

module onpremvnet './HubVNet.bicep' = {
  name: 'onpremvnetdeploy'
  scope: resourceGroup(onpremrg.name)
  params: {
    vnetname: onpremvnetname
    location: location
    addressprefix: onpremaddressprefix
    serversubnetprefix: onpremserversubnetprefix
    bastionsubnetprefix: onprembastionsubnetprefix
    gatewaysubnetprefix: onpremvpngatewaysubnetprefix
    firewallsubnetprefix: onpremfirewallsubnetprefix
    servernsgid: onpremservernsg.outputs.id
    bastionnsgid: onprembastionnsg.outputs.id
    dnsservers: firewall.outputs.privateip
  }
}

module onpremservernsg './NSGDefaultRules.bicep' = {
  name: 'onpremservernsgdeploy'
  scope: resourceGroup(onpremrg.name)
  params: {
    nsgname: onpremservernsgname
    location: location
  }
}

module onprembastionnsg './NSGBastion.bicep' = {
  name: 'onprembastionnsgdeploy'
  scope: resourceGroup(onpremrg.name)
  params: {
    nsgname: onprembastionnsgname
    location: location
  }
}

module onpremvm './WindowsVM.bicep' = {
  name: 'onpremvmdeploy'
  scope: resourceGroup(onpremrg.name)
  params: {
    vmname: onpremvmname
    location: location
    diskname: onpremdiskname
    nicname: onpremnicname    
    adminusername: adminusername
    adminpassword: adminpassword
    subnetref: onpremvnet.outputs.serversubnetid
  }
}

module onpremvpngw './VNetVPNGateway.bicep' = {
  name: 'onpremvpngwdeploy'
  scope: resourceGroup(onpremrg.name)
  params: {
    vpngwname: onpremvpngwname
    vpngwpipname: onpremvpngwpipname
    location: location
    subnetref: onpremvnet.outputs.gatewaysubnetid    
  } 
}

module wanvpnsite './VirtualWANVPNSite.bicep' = {
  name: 'wanvpnsitedeploy'
  scope: resourceGroup(wanrg.name)
  params: {
    vpnsitename: onpremvpnsitename
    location: location
    addressprefix: onpremaddressprefix
    bgppeeringpddress: onpremvpngw.outputs.bgpaddress
    ipaddress: onpremvpngw.outputs.ip
    wanid: wan.outputs.id
  }
}

module hubvpnconnection './VirtualHubVPNConnection.bicep' = {
  name: 'hubvpnconnectiondeploy'
  scope: resourceGroup(wanrg.name)
  params:{
    hubvpngwname: hubvpngw.outputs.name
    psk: psk
    vpnsiteid: wanvpnsite.outputs.id
  }
}

module hubtoonprems2s './VNetVPNSiteToSite.bicep' = {
  name: 'hubtoonprems2sdeploy'
  scope: resourceGroup(onpremrg.name)
  params:{
    localnetworkgwname: 'onprem-to-vhub-cn'
    location: location
    vpngwid: onpremvpngw.outputs.id
    gwipaddress: hubvpngw.outputs.gwpublicip
    bgppeeringpddress: hubvpngw.outputs.gwprivateip
    addressprefixes: onprems2saddressprefixes
    psk: psk
  }
}
