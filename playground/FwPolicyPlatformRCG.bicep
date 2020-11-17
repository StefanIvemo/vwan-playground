
param fwpolicyname string {
    metadata: {
      description: 'Specifies the name of the FW Policy where the rule collection group should be created.'
    }
  }

resource platformrcgroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2020-06-01' = {
  name: '${fwpolicyname}/Platform-Rules'
  properties: {
      priority: 100
      ruleCollections: [
          {
          ruleCollectionType:  'FirewallPolicyFilterRuleCollection'
          name: 'Allow-Azure-KMS'
          priority: 100
          action:{
               type: 'Allow'
          }
          rules: [
              {
                  ruleType: 'NetworkRule'
                  name: 'Azure-KMS-Service'
                  description: 'Allow traffic from all Address Spaces to Azure platform KMS Service'
                  sourceAddresses: [
                      '*'
                  ]
                  sourceIpGroups: []
                  ipProtocols: [
                      'TCP'
                  ]
                  destinationPorts: [
                      '1688'
                  ]
                  destinationIpGroups: []
                  destinationAddresses: []
                  destinationFqdns: [
                      'kms.core.windows.net'
                  ]
              }                
          ]       
          }
          {
              ruleCollectionType:  'FirewallPolicyFilterRuleCollection'
              name: 'Allow-Windows-Update'
              priority: 200
              action:{
                   type: 'Allow'
              }
              rules: [
                  {
                      ruleType: 'ApplicationRule'
                      name: 'Http'
                      description: 'Allow traffic from all sources to Azure platform KMS Service'
                      sourceAddresses: [
                          '*'
                      ]
                      sourceIpGroups: []
                      protocols: [
                          {
                              protocolType:'Http'
                              port: 80   
                          }
                      ]
                      targetFqdns: []
                      fqdnTags:[
                          'WindowsUpdate'
                      ]
                  }
                  {
                  ruleType: 'ApplicationRule'
                  name: 'Https'
                  description: 'Allow traffic from all sources to Azure platform KMS Service'
                  sourceAddresses: [
                      '*'
                  ]
                  sourceIpGroups: []
                  protocols: [
                      {
                          protocolType:'Https'
                          port: 443   
                      }
                  ]
                  targetFqdns: []
                  fqdnTags:[
                      'WindowsUpdate'
                  ]
              }                
              ]       
          }
      ]
  }
}