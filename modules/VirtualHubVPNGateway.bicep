
param location string {
  default: resourceGroup().location
  metadata: {
    description: 'Specifies the Azure location where the key vault should be created.'
  }
}
param hubvpngwname string {
  metadata: {
    description: 'Specifies the name to use for the Virtual Hub resource.'
  }
}
param hubid string {
  metadata: {
    description: 'Virtual WAN ID'
  }
}

resource hubvpngw 'Microsoft.Network/vpnGateways@2020-06-01' = {
  name: hubvpngwname
  location: location   
  properties: {        
      virtualHub: {
          id: hubid
      }
      bgpSettings: {
          asn: 65515
      }     
  }     
}

output gwpublicip string = hubvpngw.properties.ipConfigurations[0].publicIpAddress
output gwprivateip string = hubvpngw.properties.ipConfigurations[0].privateIpAddress




