@description('Specifies the Azure location where the Bastion service should be created.')
param location string = resourceGroup().location

@description('Specifies the name to use for the Bastion resource.')
param bastionname string

@description('Specifies the resource id of the subnet to connect the Bastion service to.')
param bastionsubnetref string

resource bastionip 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: '${bastionname}-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'    
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
