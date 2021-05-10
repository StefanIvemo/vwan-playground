param spokezonename string
param spokevnetid string
param onpremvnetid string

//create the dnszone resource
resource spokeprivatednszone 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: spokezonename
  location: 'global'
}

  resource onpremvnetlink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
    name: '${spokezonename}/onprem-link'
    location: 'global'
    properties:{
      registrationEnabled : false
      virtualNetwork:{
        id: onpremvnetid
      }
    }
  }

  resource spokevnetlink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
    name: '${spokezonename}/spoke-registration'
    location:'global'
    properties :{
      registrationEnabled: true
      virtualNetwork :{
        id: spokevnetid
      }
    }
  }

output id string = spokeprivatednszone.id
