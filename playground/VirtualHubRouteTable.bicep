@description('Specifies the name of the Virtual Hub resources to add a route table to.')
param hubname string

@description('Specifies the name to use for the Virtual Hub Route table resources.')
param routetablename string

@description('Specifies the name custom routes to add to the route table')
param routes object

@description('Specifies the labels that the hub route table will use')
param routetabellabels string

resource hubroutetable 'Microsoft.Network/virtualHubs/hubRouteTables@2020-06-01' = {
  name: '${hubname}/${routetablename}'
  properties: {
      routes: routes.routes
      labels: [
        routetabellabels
      ]
  } 
}

output id string = hubroutetable.id
