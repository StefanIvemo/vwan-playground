param location string {
  default: resourceGroup().location
  metadata: {
    description: 'Specifies the Azure location where the Bastion service should be created.'
  }
}
param bastionname string {
  metadata: {
    description: 'Specifies the name to use for the Bastion resource.'
  }
}
param bastionsubnetref string {
  metadata: {
    description: 'Specifies the resource id of the subnet to connect the Bastion service to.'
  }
}

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
