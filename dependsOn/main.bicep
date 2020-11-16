targetScope='subscription'

param location string {
  default: 'westeurope'
  metadata: {
    description: 'Specifies the Azure location where the key vault should be created.'
  }
}

/*Variables for VWAN */
var fwpolicyname = 'fw-${location}-policy'

resource wanrg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: 'fwpolicy-rg'
  location: location
}

module fwpolicy './FwPolicy.bicep' = {
  name: 'fwpolicydeploy'
  scope: resourceGroup(wanrg.name)
  params: {
    policyname: fwpolicyname
    location: location
  }
}

module rcgroupplatform './FwPolicyPlatformRCG.bicep' = {
  name: 'rcgroupplatformdeploy'
  scope: resourceGroup(wanrg.name)
  params: {
    fwpolicyname: fwpolicy.outputs.fwpolicyname
  }
}