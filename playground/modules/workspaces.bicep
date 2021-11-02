
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

// Deploy Network Security Dashboard for Security Center
module networkSecurityDashboard '../workbooks/networkSecurityWorkbook.json' = {
  name: 'networkSecurityDashboard-deploy'
}

// Workbook have been added as is from the Azure-Network-Security repo
module fwWorkBook '../workbooks/azureFirewallWorkbook.json' = {
  name: 'fwWorkBook-deploy'
  params: {
    DiagnosticsWorkspaceName: workspaces.name
    DiagnosticsWorkspaceResourceGroup: resourceGroup().id
    DiagnosticsWorkspaceSubscription: subscription().id
  }
}

output resourceId string = workspaces.id
output resouceName string = workspaces.name
