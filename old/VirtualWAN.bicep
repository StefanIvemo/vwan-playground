@description('Specifies the Azure location where the resource should be created.')
param location string = resourceGroup().location

@allowed([
  'Standard'
  'Basic'
])
@description('Specifies the type of Virtual WAN.')
param wantype string = 'Standard'

@description('Specifies the name to use for the Virtual WAN resources.')
param wanname string = 'contoso'

resource wan 'Microsoft.Network/virtualWans@2020-06-01' = {
    name: wanname
    location: location
    properties: {
        type: wantype
        disableVpnEncryption: false
        allowBranchToBranchTraffic: true
        office365LocalBreakoutCategory: 'None'
    }
}

output id string = wan.id
