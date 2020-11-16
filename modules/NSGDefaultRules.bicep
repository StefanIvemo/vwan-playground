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

resource nsg  'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: nsgname
  location: location   
}

output id string = nsg.id