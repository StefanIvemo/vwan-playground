@description('Specifies the Azure location where the resource should be created.')
param location string = resourceGroup().location

@description('Specifies the name to use for the Virtual Hub resource.')
param hubvpngwname string

@description('Virtual WAN ID')
param hubid string

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

output id string = hubvpngw.id
output name string = hubvpngw.name
output gwpublicip string = hubvpngw.properties.ipConfigurations[0].publicIpAddress
output gwprivateip string = hubvpngw.properties.ipConfigurations[0].privateIpAddress
