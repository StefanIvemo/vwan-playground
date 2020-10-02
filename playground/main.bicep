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
param wanaddressprefix string {
    default: '10.0.0.0/24'
    metadata: {
      description: 'Specifies the Virtual Hub Address Prefix.'
    }
}
param fwpublicipcount int {
    default: 1
    metadata: {
      description: 'Specify the amount of public IPs for the FIrewall'
    }
}
param firewallid string {
    default: ''
    metadata: {
      description: 'Specify the firewall resource ID when running the template to update the Virtual WAN, leave blank for first time deployment'
    }
}
param vnetaddressprefix string {
    default: '10.0.1.0/24'
    metadata: {
      description: 'Specify the address prefix to use for the spoke VNet'
    }
}
param vnetserversubnetprefix string {
    default: '10.0.1.0/26'
    metadata: {
      description: 'Specify the address prefix to use for server subnet in the spoke VNet'
    }
}
param vnetbastionsubnetprefix string {
    default: '10.0.1.64/26'
    metadata: {
      description: 'Specify the address prefix to use for the AzureBastionSubnet in the spoke VNet'
    }
}
param onpremvnetaddressprefix string {
    default: '10.0.2.0/24'
    metadata: {
      description: 'Specify the address prefix to use for the spoke VNet'
    }
}
param onpremvnetserversubnetprefix string {
    default: '10.0.2.0/26'
    metadata: {
      description: 'Specify the address prefix to use for server subnet in the spoke VNet'
    }
}
param onpremvnetbastionsubnetprefix string {
    default: '10.0.2.64/26'
    metadata: {
      description: 'Specify the address prefix to use for the AzureBastionSubnet in the spoke VNet'
    }
}
param onpremvnetgatewysubnetprefix string {
    default: '10.0.2.128/26'
    metadata: {
      description: 'Specify the address prefix to use for the AzureBastionSubnet in the spoke VNet'
    }
}
param adminusername string
param adminpassword string {
    secure:true
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
var policyname = '${nameprefix}-fw-policy-global'
var hubfirewallid = {
    azureFirewall: {
        id: firewallid
    }
}
var storagename = concat('vm01', uniqueString(resourceGroup().id))
var loganalyticsname = concat('fwlogs', uniqueString(resourceGroup().id))

/*Variables for spoke VNet and VM */
var vnetname = 'spoke1-vnet'
var connectionname = '${nameprefix}-spoke1-vnet-connection'
var bastionname = '${vnetname}-bastion'
var bastionnsgname = '${vnetname}-AzureBastionSubnet-nsg'
var bastionipname = '${bastionname}-pip'
var vmname = 'spoke1-vm01'
var nicname =  '${vmname}-nic'
var diskname =  '${vmname}-OSDisk'
var vmsubnetref = '${vnet.id}/subnets/snet-servers'
var bastionsubnetref = '${vnet.id}/subnets/AzureBastionSubnet'

/*Variables for "On-Prem" VNet and VM */
var onpremvnetname = 'onprem-vnet'
var onprembastionname = '${onpremvnetname}-bastion'
var onprembastionnsgname = '${onpremvnetname}-AzureBastionSubnet-nsg'
var onprembastionipname = '${onprembastionname}-pip'
var onpremvmname = 'onprem-vm01'
var onpremnicname =  '${onpremvmname}-nic'
var onpremdiskname =  '${onpremvmname}-OSDisk'
var onpremvmsubnetref = '${onpremvnet.id}/subnets/snet-servers'
var onprembastionsubnetref = '${onpremvnet.id}/subnets/AzureBastionSubnet'

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
        addressPrefix: wanaddressprefix
        virtualWan: {
            id: wan.id
        }
        azureFirewall:  empty(firewallid) ? json('null') : hubfirewallid.azureFirewall        
    }    
}

resource connection 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2020-05-01' = {
    name: '${hubname}/${connectionname}'
    properties: {
        remoteVirtualNetwork :{
            id: vnet.id
        }
        allowHubToRemoteVnetTransit: true
        allowRemoteVnetToUseHubVnetGateways: true
        enableInternetSecurity: true      
    }
    dependsOn: [
        hub
        firewall
    ]     
}

resource policy 'Microsoft.Network/firewallPolicies@2020-05-01' = {
    name: policyname
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

  resource vnet 'Microsoft.Network/virtualNetworks@2020-05-01' = {
    name: vnetname
    location: location
    properties: {
        addressSpace: {
            addressPrefixes: [
                vnetaddressprefix
            ]
        }
        subnets: [
            {
                name: 'snet-servers'
                properties: {
                    addressPrefix: vnetserversubnetprefix                 
                }            
            }
            {
                name: 'AzureBastionSubnet'
                properties: {
                    addressPrefix: vnetbastionsubnetprefix                 
                }            
            }             
        ]
    }
}

resource bastionnsg 'Microsoft.Network/networkSecurityGroups@2019-08-01' = {
    name: bastionnsgname
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

resource bastion 'Microsoft.Network/bastionHosts@2020-05-01' = {
    name: bastionname  
    location: location  
    properties: {
        ipConfigurations: [
            {
                name: 'IPConf'
                properties: {
                    subnet: {
                        id: bastionsubnetref
                    }
                    publicIPAddress: {
                        id: bastionip.id
                    }
                }
            }
        ]
    }
}

resource bastionip 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
    name: bastionipname
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
                onpremvnetaddressprefix
            ]
        }
        subnets: [
            {
                name: 'snet-servers'
                properties: {
                    addressPrefix: onpremvnetserversubnetprefix                 
                }            
            }
            {
                name: 'AzureBastionSubnet'
                properties: {
                    addressPrefix: onpremvnetbastionsubnetprefix                 
                }            
            }
            {
                name: 'GatewaySubnet'
                properties: {
                    addressPrefix: onpremvnetgatewysubnetprefix                 
                }            
            }             
        ]
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

resource nic 'Microsoft.Network/networkInterfaces@2020-05-01' = {
    name: nicname
    location: location

    properties: {
        ipConfigurations: [
          {
            name: 'ipconfig1'
            properties: {
              privateIPAllocationMethod: 'Dynamic'
              subnet: {
                id: vmsubnetref
              }
            }
          }
        ]
      }
    }

    resource vm 'Microsoft.Compute/virtualMachines@2019-12-01' = {
        name: vmname
        location: location
        properties: {
          hardwareProfile: {
              vmSize: vmsize
            }
            osProfile: {
              computerName: vmname
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
                name: diskname
                createOption: 'FromImage'
              }              
            }
            networkProfile: {
              networkInterfaces: [
                {
                  id: nic.id
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
    

/*
resource wanvnetroutetable 'Microsoft.Network/virtualHubs/routeTables@2020-05-01' = {
    name: '${hubname}/VNetRouteTable'
    location: location
    properties: {
        routes: [
            {
                destinationType: 'CIDR'
                    destinations: [
                        vnetaddressprefix
                        '0.0.0.0/0'
                    ]
                    nextHopType: 'IPAddress'
                        nextHops: [
                            '10.0.0.68'
                        ]
            }
        ]
        attachedConnections: [
            'All_Vnets'
        ]
    }        
}

resource wanbranchroutetable 'Microsoft.Network/virtualHubs/routeTables@2020-05-01' = {
    name: '${hubname}/BranchRouteTable'
    location: location
    properties: {
        routes: [
            {
                destinationType: 'CIDR'
                    destinations: [
                        vnetaddressprefix
                    ]
                    nextHopType: 'IPAddress'
                        nextHops: [
                            '10.0.0.68'
                        ]
            }
        ]
        attachedConnections: [
            'All_Branches'
        ]
    }        
}*/