param onpremzonename string
param spokevnetid string
param onpremvnetid string

//create the dnszone resource
resource onpremprivatednszone 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: onpremzonename
  location: 'global'
  }

resource spokevnetlink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${onpremzonename}/spoke-link'
  location: 'global'
  properties :{
    registrationEnabled: false
    virtualNetwork :{
      id: spokevnetid
    }
  }
}

resource onpremvnetlink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${onpremzonename}/onprem-registration'
  location: 'global'
  properties:{
    registrationEnabled : true
    virtualNetwork:{
      id: onpremvnetid
    }
  }
}
output id string = onpremprivatednszone.id
