@description('Specifies the Azure location where the VM should be created.')
param location string = resourceGroup().location

@description('Specifies the name to use for the VM resource.')
param vmname string

@description('Specifies the name to use for the OS Disk resource.')
param diskname string

@description('Specifies the name to use for the VM network Interface resource.')
param nicname string

@description('Specifies the resource id of the subnet to connect the VM to.')
param subnetref string

@description('The local admin user name for the deployed servers')
param adminusername string = 'sysadmin'

@secure()
@description('The local admin password')
param adminpassword string

@allowed([
  '2016-Datacenter'
  '2019-Datacenter'
])
@description('The Windows version for the VM. This will pick a fully patched image of this given Windows version.')
param windowsosversion string = '2019-Datacenter'

@description('Size of the VM.')
param vmsize string = 'Standard_D2_v3'

var storagename = concat('vmlogs', uniqueString(resourceGroup().id))

resource stg  'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storagename
  location: location
  sku: {
     name: 'Standard_LRS' 
  }
  kind: 'Storage'
}

resource nic 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: nicname
  location: location

  properties: {
      ipConfigurations: [
        {
          name: 'ipconfig1'
          properties: {
            privateIPAllocationMethod: 'Dynamic'
            subnet: {
              id: subnetref
            }
          }
        }
      ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: vmname
  location: location
  properties: {
      hardwareProfile: {
          vmSize: vmsize
      }
      osProfile: {
          computerName: vmname
          adminUsername: adminusername
          adminPassword: adminpassword
      }
      storageProfile: {
          imageReference: {
          publisher: 'MicrosoftWindowsServer'
          offer: 'WindowsServer'
          sku: windowsosversion
          version: 'latest'
          }
          osDisk: {
              name: diskname
              createOption: 'FromImage'
          }              
      }
      networkProfile: {
          networkInterfaces: [
              {
                id: nic.id
              }
          ]
      }
      diagnosticsProfile: {
          bootDiagnostics: {
              enabled: true
              storageUri: stg.properties.primaryEndpoints.blob
            }
      }
  }
}

output PwrOps string = 'A towel, \'The Hitchhiker\'s Guide to the Galaxy\' says, is about the most massively useful thing an interstellar hitchhiker can have'
