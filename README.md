# Azure Virtual WAN Playground

Welcome to the Azure Virtual WAN Playground repository! Your one-stop shop for an awesome Azure Virtual WAN lab environment.

## What is Azure Virtual WAN Playground?

This repo is dedicated for all poor souls out there who wants to play around with Azure Virtual WAN but don't have unlimited Azure Credit in their subscriptions (most of us 😊). I've put together a template that deploys Azure Virtual WAN and all resources needed to play around with the service and test everything from Site-to-Site VPN, Point-to-Site VPN, Routing, Secured Virtual Hub (Azure Firewall), Virtual Network connections and more. The goal is to make it easy and fast to spin up an environment when you need to test a feature for a short period of time and then remove it all when finished.

## How it's built

The Azure Virtual WAN Playground is built using [💪Bicep](https://github.com/Azure/bicep). It consists of multiple module templates, some [config files](./playground/configs/README.md) and a main template that puts everything together.

## Deployment

The template is built using the target scope `subscription`. Create a new subscription deployment using your favorite Azure command line tool and sit back and relax.

### Pre-reqs

Before you deploy the VWAN Playground there are some prerequisites that you need to look into.

#### Config files

The template is dynamic and will deploy different environments depending on which config file is being used for your deployment. Available configs are:

| Organization | Config file | Description |
|:--|:--|:--|
| Contoso | `contoso.json` | Multiple Virtual WAN hubs in different regions, landing zones and "on-premises" VNets. P2S VPN, S2S VPN, Azure Firewall. |

> Additional configs are in the works.

Decide which config you want to use and update the `main.bicep` template to use the config file.

```bicep
// Load VWAN Playground Config file. 
var vwanConfig = json(loadTextContent('./configs/contoso.json'))
```

#### P2S Config

Before you deploy the template, make sure that you add values to the `p2sVpnAADAuth.json` for a successful Point-to-Site VPN deployment. The application ID for the Azure VPN Enterprise Application and your Tenant ID is needed to configure VPN Auth. More info about the config files can be found [here](./playground/configs/README.md).

#### Bicep

The Playground is built and tested using [Bicep v0.4.1124](https://github.com/Azure/bicep/releases/tag/v0.4.1124), make sure that you have this or a newer version installed before starting the deployment (or build the Bicep file to an ARM template).

Check installed Bicep version using Bicep CLI (will be used by Azure PowerShell module):
```azurecli
bicep --version
```

Check installed version of Bicep CLI used by Azure CLI:
```azurecli
az bicep version
```

### Create the deployment

Create the deployment using your preferred command line tool.

```powershell
$params=@{
    Name = 'vwan-playground'
    Location = 'westeurope '
    TemplateFile = '.\playground\main.bicep'
}
New-AzSubscriptionDeployment @params
```

```azurecli
az deployment sub create --name vwan-playground --location westeurope --template-file .\playground\main.bicep
```

> NOTE: The deployment is complex and consist of multiple resources that takes a long time to provision. Expected deployment time is over 1 hour.

## Topologies

The Azure Virtual WAN Playground deploys the following topologies:

### Contoso

<img src="https://github.com/StefanIvemo/vwan-playground/blob/main/media/vwan-playground-contoso-topology.png?raw=true">

## FAQ

### Can I connect to the servers in the "landing zones" and "On-Premises"?

Yes, there is a Bastion host deployed in the `<nameprefix>-sharedservices-rg` resource group. The Bastion VNet is peered with all VNets in the deployment to allow RDP connection via Bastion.

### Does name resolution work between VMs?

Yes, there is a Private DNS zone `<nameprefix>.com` that is linked to all VNets and auto registration is enabled.

### Traffic between VMs in Firewall enabled regions are not working, why?

Azure Firewall is blocking all traffic by default. You need to create Firewall rules to allow traffic between "landing zones" and "on-premises".

### Will you provide additional sample configurations?

No, but you can make your own by modifying the existing config files.

## Contributing

If you find this project interesting and want to contribute, please feel free to open issues with feature requests or open a pull request with suggested improvements.
