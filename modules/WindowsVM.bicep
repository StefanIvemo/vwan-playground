param location string {
  default: resourceGroup().location
  metadata: {
    description: 'Specifies the Azure location where the VM should be created.'
  }
}
param vmname string {
  metadata: {
    description: 'Specifies the name to use for the VM resource.'
  }
}
param diskname string {
  metadata: {
    description: 'Specifies the name to use for the OS Disk resource.'
  }
}
param nicname string {
  metadata: {
    description: 'Specifies the name to use for the VM network Interface resource.'
  }
}
param subnetref string {
  metadata: {
    description: 'Specifies the resource id of the subnet to connect the VM to.'
  }
}
param adminusername string {
  default :'sysadmin'
  metadata: {
      'description': 'The local admin user name for the deployed servers' 
  }
}
param adminpassword string {
  secure:true
  metadata: {
      'description': 'The local admin password' 
  }
}
param windowsosversion string {
  default :'2019-Datacenter'
  allowed : [        
      '2016-Datacenter'
      '2019-Datacenter'
    ]
    metadata: {
      'description': 'The Windows version for the VM. This will pick a fully patched image of this given Windows version.' 
    }
}
param vmsize string {
  default: 'Standard_D2_v3'
  metadata: {
    description: 'Size of the VM.'
  }
}

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