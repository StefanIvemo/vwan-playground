@description('Specifies the Azure location where the resource should be created.')
param location string = resourceGroup().location

@description('Specifies the name to use for the VNet.')
param vnetname string

@description('Specifies the VNet Address Prefix.')
param addressprefix string = '10.0.1.0/24'

@description('Specifies the DNS Servers to use for the VNet')
param dnsservers string

@description('Specifies the Subnet Address Prefix for the server subnet')
param serversubnetprefix string = '10.0.1.0/26'

@description('Specifies the Subnet Address Prefix for the bastion subnet')
param bastionsubnetprefix string = '10.0.1.64/26'

@description('Specifies the Subnet Address Prefix for the GatewaySubnet')
param gatewaysubnetprefix string = '10.0.1.128/26'

@description('Specifies the Subnet Address Prefix for the AzureFirewallSubnet')
param firewallsubnetprefix string = '10.0.1.192/26'

@description('Specifies the resource id to the nsg used by the server subnet')
param servernsgid string

@description('Specifies the resource id to the nsg used by the bastion subnet')
param bastionnsgid string

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
