# Azure Virtual WAN Playground

Welcome to the Azure Virtual WAN Playground repository! Your one-stop shop for an awesome Azure Virtual WAN lab environment.

## What is Azure Virtual WAN Playground?

This repo is dedicated for all poor souls out there who want to play around with Azure Virtual WAN but don't have unlimited Azure Credit in their subscriptions. I've put together a template that deploys Azure Virtual WAN and all resources needed to play around with the service and test everything from Site-to-Site VPN, Routing, Secured Virtual Hub, Point-to-Site, Virtual Network connections and more. The goal is to make it easy to spin up an environment when you need to test a feature for a short period of time and then remove it all when finished.

## How it's built

The Azure Virtual WAN Playground is built using [💪Bicep](https://github.com/Azure/bicep). It consists of multiple module templates, some [config files](./playground/configs/README.md) and a main template that puts everything together.

## Deployment

The template is built using the target scope `subscription`. Create a new subscription deployment using your favorite Azure command line tool and sit back and relax.

```powershell
New-AzSubscriptionDeployment -Name vwan-playground -Location westeurope -TemplateFile .\playground\main.bicep
```

```azurecli
az deployment sub create --name vwan-playground --location westeurope --template-file .\playground\main.bicep
```

> NOTE: The deployment is complex and consist of multiple resources that takes a long time to provision. Expected deployment time is over 1 hour.

## Topology **Needs an update**

The Azure Virtual WAN Playground deploys the following topology:

- Azure Virtual WAN
  - Virtual Hub (Secured Virtual Hub)
  - Firewall Policy
    - Rule Collection Groups
  - Azure Firewall
  - Hub Route Tables
  - Virtual Network Connection (Spoke VNet)
    - Using custom route table sending branch and internet traffic to firewall
  - VPN Gateway
  - VPN Site (On-Prem VNet)
- Spoke VNet
  - Azure Bastion Service
  - Virtual Machine
- On-Prem VNet
  - Azure Bastion Service
  - Virtual Machine
  - VPN Gateway
    - Connection (On-Prem to WAN Hub)
      - Local Network Gateway
- Log Analytics Workspace (Firewall Diagnostics)  
 
<img src="https://github.com/StefanIvemo/vwan-playground/blob/main/media/vwan-playground-topology_v2.png?raw=true">

## Contributing

If you find this project interesting and want to contribute, please feel free to submit Pull Requests with suggested improvements.
