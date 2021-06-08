param vpnConfigName string
param rootCertName string

@secure()
param publicCertData string

@secure()
param tenantId string

@secure()
param clientId string
param location string = resourceGroup().location

var aadAuthenticationParameters = {
  aadTenant: 'https://login.microsoftonline.com/${tenantId}/'
  aadAudience: clientId
  aadIssuer: 'https://sts.windows.net/${tenantId}/'
}

var vpnClientRootCertificates = [
  {
    name: rootCertName
    publicCertData: publicCertData
  }
]

resource vpnServerConfigurations 'Microsoft.Network/vpnServerConfigurations@2020-11-01' = {
  name: vpnConfigName
  location: location
  properties: {
    vpnProtocols: [
      'OpenVPN'
    ]
    vpnAuthenticationTypes: [
      'AAD'
      'Certificate'
    ]
    vpnClientRootCertificates: vpnClientRootCertificates
    vpnClientRevokedCertificates: []
    radiusServers: []
    radiusServerRootCertificates: []
    radiusClientRootCertificates: []
    aadAuthenticationParameters: aadAuthenticationParameters
    vpnClientIpsecPolicies: []
  }
}
