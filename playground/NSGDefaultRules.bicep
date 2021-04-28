@description('Specifies the Azure location where the NSG should be created.')
param location string = resourceGroup().location

@description('Specifies the name to use for the NSG')
param nsgname string

resource nsg  'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: nsgname
  location: location   
}

output id string = nsg.id
