
param namePrefix string
param location string

var name = '${take('${namePrefix}-${uniqueString(resourceGroup().id)}',20)}-log'

resource workspaces 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: name
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

output resourceId string = workspaces.id
output resouceName string = workspaces.name
