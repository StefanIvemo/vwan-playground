param location string {
    default: resourceGroup().location
    metadata: {
      description: 'Specifies the Azure location where the NSG should be created.'
    }
  }
  param nsgname string {
    metadata: {
      description: 'Specifies the name to use for the NSG'
    }
  }

resource bastionnsg 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: nsgname
  location: location
  properties: {
      securityRules: [
          {
              name: 'bastion-in-allow'
              properties: {
                  protocol: 'Tcp'
                  sourcePortRange: '*'
                  sourceAddressPrefix: '*'
                  destinationPortRange: '443'
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
                      '443'
                      '4443'
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
                  destinationPortRange: '22'
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
                  destinationPortRange: '3389'
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
                  destinationPortRange: '443'
                  destinationAddressPrefix: 'AzureCloud'
                  access: 'Allow'
                  priority: 120
                  direction: 'Outbound'
              }
          }
      ]
  }
}

output id string = bastionnsg.id