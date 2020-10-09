param location string {
    default: resourceGroup().location
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
param fwpublicipcount int {
    default: 2
    metadata: {
      description: 'Specify the amount of public IPs for the FIrewall'
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
param onpremvpngatewysubnetprefix string {
    default: '10.20.0.128/26'
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
var loganalyticsname = concat('fwlogs', uniqueString(resourceGroup().id))
var storagename = concat('vmlogs', uniqueString(resourceGroup().id))

/*Variables for spoke VNet and VM */
var spokevnetname = 'spoke1-vnet'
var spokebastionname = '${spokevnetname}-bastion'
var spokebastionnsgname = '${spokevnetname}-AzureBastionSubnet-nsg'
var spokeservernsgname = '${spokevnetname}-snet-servers-nsg'
var spokebastionipname = '${spokebastionname}-pip'
var spokevmname = 'spoke1-vm01'
var spokenicname =  '${spokevmname}-nic'
var spokediskname =  '${spokevmname}-OSDisk'
var spokevmsubnetref = '${spokevnet.id}/subnets/snet-servers'
var spokebastionsubnetref = '${spokevnet.id}/subnets/AzureBastionSubnet'


/*Variables for "On-Prem" VNet and VM */
var onpremvnetname = 'onprem-vnet'
var onprembastionname = '${onpremvnetname}-bastion'
var onprembastionnsgname = '${onpremvnetname}-AzureBastionSubnet-nsg'
var onpremservernsgname = '${onpremvnetname}-snet-servers-nsg'
var onprembastionipname = '${onprembastionname}-pip'
var onpremvmname = 'onprem-vm01'
var onpremnicname =  '${onpremvmname}-nic'
var onpremdiskname =  '${onpremvmname}-OSDisk'
var onpremvmsubnetref = '${onpremvnet.id}/subnets/snet-servers'
var onprembastionsubnetref = '${onpremvnet.id}/subnets/AzureBastionSubnet'
var onpremvpngwname = '${onpremvnetname}-vpn-vgw'
var onpremvpngwpipname = '${onpremvpngwname}-pip'
var onpremvpngwsubnetref = '${onpremvnet.id}/subnets/GatewaySubnet'


resource wan 'Microsoft.Network/virtualWans@2020-05-01' = {
    name: wanname
    location: location
    properties: {
        type: wantype
        disableVpnEncryption: false
        allowBranchToBranchTraffic: true
        office365LocalBreakoutCategory: 'None'
    }
}

resource hub 'Microsoft.Network/virtualHubs@2020-05-01' = {
    name: hubname
    location: location
    properties: {        
        addressPrefix: hubaddressprefix
        virtualWan: {
            id: wan.id
        }      
    }    
}

resource connection 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2020-05-01' = {
    name: '${hubname}/${spokeconnectionname}'
    properties: {
        remoteVirtualNetwork :{
            id: spokevnet.id
        }
        allowHubToRemoteVnetTransit: true
        allowRemoteVnetToUseHubVnetGateways: true
        enableInternetSecurity: true
        routingConfiguration: {
            associatedRouteTable: {
                id: vnetroutetable.id
            }
            propagatedRouteTables: {
                labels: [
                    'VNet'
                ]
                ids: [
                    {
                        id: vnetroutetable.id
                    }
                ]
            }
        }
    }
    dependsOn: [
        hub
        firewall
    ]     
}

resource onpremvpnsite 'Microsoft.Network/vpnSites@2020-05-01' = {
    name: onpremvpnsitename
    location: location
    properties: {
        addressSpace :{
            addressPrefixes: onpremaddressprefix
        }
        bgpProperties: {
            asn: 65010
            bgpPeeringAddress: onpremvpngw.properties.BgpSettings.BgpPeeringAddress
            peerWeight: 0
        }
        deviceProperties: {
            linkSpeedInMbps: 0
        }
        ipAddress: onpremvpngwpip.properties.IpAddress
        virtualWan: {
            id: wan.id
        }        
    }       
}

resource hubvpngw 'Microsoft.Network/vpnGateways@2020-05-01' = {
    name: hubvpngwname
    location: location   
    properties: {
        connections: [
            {
                name: 'HubToOnPremConnection'
                properties: {
                    connectionBandwidth: 10
                    enableBgp: true
                    sharedKey: psk
                    remoteVpnSite: {
                        id: onpremvpnsite.id
                    }
                }
            }
        ]
        virtualHub: {
            id: hub.id
        }
        bgpSettings: {
            asn: 65515
        }     
    }
    dependsOn: [        
        firewall
        connection
    ]        
}

resource policy 'Microsoft.Network/firewallPolicies@2020-05-01' = {
    name: fwpolicyname
    location: location
    properties: {
        threatIntelMode: 'Alert'
        threatIntelWhitelist: {
            ipAddresses: []
        }
    }
}

resource loganalytics 'Microsoft.OperationalInsights/workspaces@2020-03-01-preview' = {
    name: loganalyticsname
    location: location
    properties: {
        sku: {
            name: 'pergb2018'
        }
    }
}

resource firewall 'Microsoft.Network/azureFirewalls@2020-05-01' = {
    name: fwname
    location: location
    properties: {
        sku: {
            name: 'AZFW_Hub'
            tier: 'Standard'
        }
        virtualHub: {
            id: hub.id
        }
        hubIPAddresses: {            
            publicIPs: {
                count: fwpublicipcount
            }
        }
        firewallPolicy: {
            id: policy.id
        }             
    }
  } 

  resource firewalldiag 'Microsoft.Network/azureFirewalls/providers/diagnosticSettings@2017-05-01-preview' = {
    name: '${fwname}/Microsoft.Insights/diagnostics'
    location: location
    properties: {
        workspaceId: loganalytics.id
        logs: [
            {
                category: 'AzureFirewallApplicationRule'
                enabled: true
            }
            {
                category: 'AzureFirewallNetworkRule'
                enabled: true
            }
            {
                category: 'AzureFirewallDnsProxy'
                enabled: true
            }
        ]
        metrics: [
            {
                category: 'AllMetrics'
                enabled: true
            }
        ]         
    }
    dependsOn: [
        firewall
    ]     
}

resource spokevnet 'Microsoft.Network/virtualNetworks@2020-05-01' = {
    name: spokevnetname
    location: location
    properties: {
        addressSpace: {
            addressPrefixes: [
                spokeaddressprefix
            ]
        }
        subnets: [
            {
                name: 'snet-servers'
                properties: {
                    addressPrefix: spokeserversubnetprefix   
                    networkSecurityGroup: {
                        id: spokeservernsg.id
                    }              
                }            
            }
            {
                name: 'AzureBastionSubnet'
                properties: {
                    addressPrefix: spokebastionsubnetprefix
                    networkSecurityGroup: {
                        id: spokebastionnsg.id
                    }                 
                }            
            }             
        ]
    }
}

resource onpremvpngwpip 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
    name: onpremvpngwpipname
    location: location
    sku: {
      name: 'Standard'
    }
    properties: {
      publicIPAllocationMethod: 'Static'    
    }
}

resource onpremvpngw 'Microsoft.Network/virtualNetworkGateways@2020-05-01' = {
    name: onpremvpngwname
    location: location    
    properties: {
        gatewayType: 'vpn'
        ipConfigurations: [
            {
                name: 'default'
                properties: {
                    privateIPAllocationMethod: 'Dynamic'
                    subnet: {
                        id: onpremvpngwsubnetref
                    }
                    publicIPAddress: {
                        id: onpremvpngwpip.id
                    }
                }
            }
        ]
        activeActive: false
        enableBgp: true
        bgpSettings: {
            asn: 65010
        }
        vpnType: 'RouteBased'
        vpnGatewayGeneration: 'Generation1'
        sku: {
            name: 'VpnGw1AZ'
            tier: 'VpnGw1AZ'
        }
    }
}

resource localnetworkgw 'Microsoft.Network/localNetworkGateways@2020-05-01' = {
    name: 'onprem-hub-lgw'
    location: location    
    properties: {
        localNetworkAddressSpace:{
            AddressPrefixes: [
                spokeaddressprefix
                hubaddressprefix
            ]
        }
        gatewayIpAddress: hubvpngw.properties.ipConfigurations[0].publicIpAddress
        bgpSettings: {
            asn: 65515
            bgpPeeringAddress: hubvpngw.properties.ipConfigurations[0].privateIpAddress
        }
    }
}

resource s2sconnection 'Microsoft.Network/connections@2020-05-01' = {
    name: 'onprem-hub-cn'
    location: location    
    properties: {
        connectionType: 'IPsec'
        connectionProtocol: 'IKEv2'
        virtualNetworkGateway1: {
            id: onpremvpngw.id
        }
        enableBgp: true
        sharedKey: psk
        localNetworkGateway2: {
            id: localnetworkgw.id
        }

        
    }
}

resource spokeservernsg  'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
    name: spokeservernsgname
    location: location
    properties: {

    }    
}

resource spokebastionnsg 'Microsoft.Network/networkSecurityGroups@2019-08-01' = {
    name: spokebastionnsgname
    location: location
    properties: {
        securityRules: [
            {
                name: 'bastion-in-allow'
                properties: {
                    protocol: 'Tcp'
                    sourcePortRange: '*'
                    sourceAddressPrefix: '*'
                    destinationPortRange: 443
                    destinationAddressPrefix: '*'
                    access: 'Allow'
                    priority: 100
                    direction: 'Inbound'
                }
            }
            {
                name: 'bastion-control-in-allow'
                properties: {
                    protocol: 'Tcp'
                    sourcePortRange: '*'
                    sourceAddressPrefix: 'GatewayManager'
                    destinationPortRanges: [
                        443
                        4443
                    ]
                    destinationAddressPrefix: '*'
                    access: 'Allow'
                    priority: 120
                    direction: 'Inbound'
                }
            }
            {
                name: 'bastion-in-deny'
                properties: {
                    protocol: '*'
                    sourcePortRange: '*'
                    destinationPortRange: '*'
                    sourceAddressPrefix: '*'
                    destinationAddressPrefix: '*'
                    access: 'Deny'
                    priority: 4096
                    direction: 'Inbound'
                }
            }
            {
                name: 'bastion-vnet-ssh-out-allow'
                properties: {
                    protocol: 'Tcp'
                    sourcePortRange: '*'
                    sourceAddressPrefix: '*'
                    destinationPortRange: 22
                    destinationAddressPrefix: 'VirtualNetwork'
                    access: 'Allow'
                    priority: 100
                    direction: 'Outbound'
                }
            }
            {
                name: 'bastion-vnet-rdp-out-allow'
                properties: {
                    protocol: 'Tcp'
                    sourcePortRange: '*'
                    sourceAddressPrefix: '*'
                    destinationPortRange: 3389
                    destinationAddressPrefix: 'VirtualNetwork'
                    access: 'Allow'
                    priority: 110
                    direction: 'Outbound'
                }
            }
            {
                name: 'bastion-azure-out-allow'
                properties: {
                    protocol: 'Tcp'
                    sourcePortRange: '*'
                    sourceAddressPrefix: '*'
                    destinationPortRange: 443
                    destinationAddressPrefix: 'AzureCloud'
                    access: 'Allow'
                    priority: 120
                    direction: 'Outbound'
                }
            }
        ]
    }
  }

resource spokebastion 'Microsoft.Network/bastionHosts@2020-05-01' = {
    name: spokebastionname  
    location: location  
    properties: {
        ipConfigurations: [
            {
                name: 'IPConf'
                properties: {
                    subnet: {
                        id: spokebastionsubnetref
                    }
                    publicIPAddress: {
                        id: spokebastionip.id
                    }
                }
            }
        ]
    }
}

resource spokebastionip 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
    name: spokebastionipname
    location: location
    sku: {
      name: 'Standard'
    }
    properties: {
      publicIPAllocationMethod: 'Static'    
    }
}

resource onpremvnet 'Microsoft.Network/virtualNetworks@2020-05-01' = {
    name: onpremvnetname
    location: location
    properties: {
        addressSpace: {
            addressPrefixes: [
                onpremaddressprefix
            ]
        }
        subnets: [
            {
                name: 'snet-servers'
                properties: {
                    addressPrefix: onpremserversubnetprefix
                    networkSecurityGroup: {
                        id: onpremservernsg.id
                    }                  
                }            
            }
            {
                name: 'AzureBastionSubnet'
                properties: {
                    addressPrefix: onprembastionsubnetprefix
                    networkSecurityGroup: {
                        id: onprembastionnsg.id
                    }                   
                }            
            }
            {
                name: 'GatewaySubnet'
                properties: {
                    addressPrefix: onpremvpngatewysubnetprefix                 
                }            
            }             
        ]
    }
}

resource onpremservernsg  'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
    name: onpremservernsgname
    location: location
    properties: {

    }    
}

resource onprembastionnsg 'Microsoft.Network/networkSecurityGroups@2019-08-01' = {
    name: onprembastionnsgname
    location: location
    properties: {
        securityRules: [
            {
                name: 'bastion-in-allow'
                properties: {
                    protocol: 'Tcp'
                    sourcePortRange: '*'
                    sourceAddressPrefix: '*'
                    destinationPortRange: 443
                    destinationAddressPrefix: '*'
                    access: 'Allow'
                    priority: 100
                    direction: 'Inbound'
                }
            }
            {
                name: 'bastion-control-in-allow'
                properties: {
                    protocol: 'Tcp'
                    sourcePortRange: '*'
                    sourceAddressPrefix: 'GatewayManager'
                    destinationPortRanges: [
                        443
                        4443
                    ]
                    destinationAddressPrefix: '*'
                    access: 'Allow'
                    priority: 120
                    direction: 'Inbound'
                }
            }
            {
                name: 'bastion-in-deny'
                properties: {
                    protocol: '*'
                    sourcePortRange: '*'
                    destinationPortRange: '*'
                    sourceAddressPrefix: '*'
                    destinationAddressPrefix: '*'
                    access: 'Deny'
                    priority: 4096
                    direction: 'Inbound'
                }
            }
            {
                name: 'bastion-vnet-ssh-out-allow'
                properties: {
                    protocol: 'Tcp'
                    sourcePortRange: '*'
                    sourceAddressPrefix: '*'
                    destinationPortRange: 22
                    destinationAddressPrefix: 'VirtualNetwork'
                    access: 'Allow'
                    priority: 100
                    direction: 'Outbound'
                }
            }
            {
                name: 'bastion-vnet-rdp-out-allow'
                properties: {
                    protocol: 'Tcp'
                    sourcePortRange: '*'
                    sourceAddressPrefix: '*'
                    destinationPortRange: 3389
                    destinationAddressPrefix: 'VirtualNetwork'
                    access: 'Allow'
                    priority: 110
                    direction: 'Outbound'
                }
            }
            {
                name: 'bastion-azure-out-allow'
                properties: {
                    protocol: 'Tcp'
                    sourcePortRange: '*'
                    sourceAddressPrefix: '*'
                    destinationPortRange: 443
                    destinationAddressPrefix: 'AzureCloud'
                    access: 'Allow'
                    priority: 120
                    direction: 'Outbound'
                }
            }
        ]
    }
  }

resource onprembastion 'Microsoft.Network/bastionHosts@2020-05-01' = {
    name: onprembastionname  
    location: location  
    properties: {
        ipConfigurations: [
            {
                name: 'IPConf'
                properties: {
                    subnet: {
                        id: onprembastionsubnetref
                    }
                    publicIPAddress: {
                        id: onprembastionip.id
                    }
                }
            }
        ]
    }
}

resource onprembastionip 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
    name: onprembastionipname
    location: location
    sku: {
      name: 'Standard'
    }
    properties: {
      publicIPAllocationMethod: 'Static'    
    }
}

resource stg  'Microsoft.Storage/storageAccounts@2019-06-01' = {
    name: storagename
    location: location
    sku: {
       name: 'Standard_LRS' 
    }
    kind: 'Storage'
}

resource spokenic 'Microsoft.Network/networkInterfaces@2020-05-01' = {
    name: spokenicname
    location: location

    properties: {
        ipConfigurations: [
          {
            name: 'ipconfig1'
            properties: {
              privateIPAllocationMethod: 'Dynamic'
              subnet: {
                id: spokevmsubnetref
              }
            }
          }
        ]
    }
}

resource spokevm 'Microsoft.Compute/virtualMachines@2019-12-01' = {
    name: spokevmname
    location: location
    properties: {
        hardwareProfile: {
            vmSize: vmsize
        }
        osProfile: {
            computerName: spokevmname
            adminUsername: adminusername
            adminPassword: adminpassword
        }
        storageProfile: {
            imageReference: {
            publisher: 'MicrosoftWindowsServer'
            offer: 'WindowsServer'
            sku: windowsosversion
            version: 'latest'
            }
            osDisk: {
                name: spokediskname
                createOption: 'FromImage'
            }              
        }
        networkProfile: {
            networkInterfaces: [
                {
                  id: spokenic.id
                }
            ]
        }
        diagnosticsProfile: {
            bootDiagnostics: {
                enabled: true
                storageUri: stg.properties.primaryEndpoints.blob
              }
        }
    }
}

resource onpremnic 'Microsoft.Network/networkInterfaces@2020-05-01' = {
    name: onpremnicname
    location: location    
    properties: {
        ipConfigurations: [
            {
                name: 'ipconfig1'
                properties: {
                  privateIPAllocationMethod: 'Dynamic'
                  subnet: {
                    id: onpremvmsubnetref
                  }
                }
            }
        ]
    }
}
    
resource onpremvm 'Microsoft.Compute/virtualMachines@2019-12-01' = {
    name: onpremvmname
    location: location
    properties: {
        hardwareProfile: {
            vmSize: vmsize
        }
        osProfile: {
            computerName: onpremvmname
            adminUsername: adminusername
            adminPassword: adminpassword
        }
        storageProfile: {
            imageReference: {
                publisher: 'MicrosoftWindowsServer'
                offer: 'WindowsServer'
                sku: windowsosversion
                version: 'latest'
            }
            osDisk: {
                name: onpremdiskname
                createOption: 'FromImage'
            }              
        }
        networkProfile: {
            networkInterfaces: [
                {
                    id: onpremnic.id
                }
            ]
        }
        diagnosticsProfile: {
            bootDiagnostics: {
                enabled: true
                storageUri: stg.properties.primaryEndpoints.blob
            }
        }
    }
}

resource vnetroutetable 'Microsoft.Network/virtualHubs/hubRouteTables@2020-05-01' = {
    name: '${hubname}/RT_VNet'
    location: location
    properties: {
        routes: [
            {
                name: 'toFirewall'
                destinationType: 'CIDR'
                destinations: [
                    '0.0.0.0/0'
                ]
                nextHopType: 'ResourceId'
                nextHop: firewall.id
            }
        ]
        labels: [
            'VNet'
        ]
    }
    dependsOn: [
        defaultroutetable
    ]         
}

resource defaultroutetable 'Microsoft.Network/virtualHubs/hubRouteTables@2020-05-01' = {
    name: '${hubname}/defaultRouteTable'
    location: location
    properties: {
        routes: [
            {
                name: 'toFirewall'
                destinationType: 'CIDR'
                destinations: [
                    regionaladdressspace
                ]
                nextHopType: 'ResourceId'
                nextHop: firewall.id
            }
        ]
        labels: [
            'default'
        ]
    }         
}