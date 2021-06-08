@description('Specifies the Azure location where the resource should be created.')
param location string = resourceGroup().location

@description('Specifies the name to use for the Virtual Hub resources.')
param hubname string

@description('Specifies the Virtual Hub Address Prefix.')
param hubaddressprefix string = '10.0.0.0/24'

@description('Virtual WAN ID')
param wanid string

@allowed([
    'bosse'
    'kalle'
    'goran'
])
param emil string

resource hub 'Microsoft.Network/virtualHubs@2020-06-01' = {
    name: hubname
    location: location
    properties: {        
        addressPrefix: hubaddressprefix
        virtualWan: {
            id: wanid
        }      
    }    
}

output id string = hub.id
output name string = hub.name
