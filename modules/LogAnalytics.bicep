param location string {
  default: resourceGroup().location
  metadata: {
    description: 'Specifies the Azure location where the key vault should be created.'
  }
}
param loganalyticsprefix string

var loganalyticsname = concat('${loganalyticsprefix}', uniqueString(resourceGroup().id))

resource loganalytics 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: loganalyticsname
  location: location
  properties: {
      sku: {
          name: 'PerGB2018'
      }
  }
}

output id string = loganalytics.id