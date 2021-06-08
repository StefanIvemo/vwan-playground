// 2020-08-01-1

param name string

@allowed([
  'Standard'
  'Basic'
])
param wanType string = 'Standard'
param disableVpnEncryption bool = false
param allowBranchToBranchTraffic bool = true

@allowed([
  'Optimize'
  'OptimizeAndAllow'
  'All'
  'None'
])
param office365LocalBreakoutCategory string = 'None'
param location string = resourceGroup().location

//Virtaul WAN Resource
resource vwan 'Microsoft.Network/virtualWans@2020-11-01' = {
  name: name
  location: location
  properties: {
    type: wanType
    disableVpnEncryption: disableVpnEncryption
    allowBranchToBranchTraffic: allowBranchToBranchTraffic
    office365LocalBreakoutCategory: office365LocalBreakoutCategory
  }
}

output resourceId string = vwan.id
output name string = vwan.name
