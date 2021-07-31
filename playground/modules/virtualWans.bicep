param name string

@allowed([
  'Standard'
  'Basic'
])
param wanType string = 'Standard'
param disableVpnEncryption bool = false
param allowBranchToBranchTraffic bool = true
param location string = resourceGroup().location

//Virtaul WAN Resource
resource vwan 'Microsoft.Network/virtualWans@2020-11-01' = {
  name: name
  location: location
  properties: {
    type: wanType
    disableVpnEncryption: disableVpnEncryption
    allowBranchToBranchTraffic: allowBranchToBranchTraffic
  }
}

output resourceId string = vwan.id
output name string = vwan.name
