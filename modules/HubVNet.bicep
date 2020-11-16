param location string {
  default: resourceGroup().location
  metadata: {
    description: 'Specifies the Azure location where the key vault should be created.'
  }
}
param vnetname string {
  metadata: {
    description: 'Specifies the name to use for the VNet.'
  }
}
param addressprefix string {
  default: '10.0.1.0/24'
  metadata: {
    description: 'Specifies the VNet Address Prefix.'
  }
}
param dnsservers string {
  metadata: {
    description: 'Specifies the DNS Servers to use for the VNet'
  }
}
param serversubnetprefix string {
  default: '10.0.1.0/26'
  metadata: {
    description: 'Specifies the Subnet Address Prefix for the server subnet'
  }
}
param bastionsubnetprefix string {
  default: '10.0.1.64/26'
  metadata: {
    description: 'Specifies the Subnet Address Prefix for the bastion subnet'
  }
}
param gatewaysubnetprefix string {
  default: '10.0.1.128/26'
  metadata: {
    description: 'Specifies the Subnet Address Prefix for the GatewaySubnet'
  }
}
param firewallsubnetprefix string {
  default: '10.0.1.192/26'
  metadata: {
    description: 'Specifies the Subnet Address Prefix for the AzureFirewallSubnet'
  }
}
param servernsgid string {
  metadata: {
    description: 'Specifies the resource id to the nsg used by the server subnet'
  }
}
param bastionnsgid string {
  metadata: {
    description: 'Specifies the resource id to the nsg used by the bastion subnet'
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: vnetname
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressprefix
      ]
    }
    dhcpOptions: {
      dnsServers: [
        dnsservers
      ]
    }
    subnets: [
      {
        name: 'snet-servers'
        properties: {
          addressPrefix: serversubnetprefix
          networkSecurityGroup: {
            id: servernsgid
          }
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: bastionsubnetprefix
          networkSecurityGroup: {
            id: bastionnsgid
          }
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: gatewaysubnetprefix
        }
      }
      {
        name: 'AzurFirewallSubnet'
        properties: {
          addressPrefix: firewallsubnetprefix
        }
      }
    ]
  }
}

output id string = vnet.id
output serversubnetid string = '${vnet.id}/subnets/snet-servers'
output bastionsubnetid string = '${vnet.id}/subnets/AzureBastionSubnet'
output gatewaysubnetid string = '${vnet.id}/subnets/GatewaySubnet'
output firewallsubnetid string = '${vnet.id}/subnets/AzureFirewallSubnet'