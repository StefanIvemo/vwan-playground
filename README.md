# Azure Virtual WAN Playground
Welcome to the Azure Virtual WAN Playground repository! Your one-stop shop for Azure Virtual WAN lab material.

## What is Azure Virtual WAN Playground?
This repo is dedicated for all poor souls out there who wants to play around with Azure Virtual WAN but don't have unlimited Azure Credit in their subscriptions. I've put together a template that deploys Azure Virtual WAN and all resources needed to play around with the service and test everything from VPN, User VPN, Routing, Secured Virtual Hub, Virtual Network connections and more.

## How it's built
The Azure Virtual WAN Playground is built using 💪Bicep which makes it so much easier to work with and read compared to ARM Templates. Azure Virtual WAN with all it's dependencies between the hub and the connected services like VPN Gateways and Firewall (Secured Virtual WAN) makes it hard to follow in pure ARM template. If you haven't tested Bicep yet check out the [Bicep repository](https://github.com/Azure/bicep) for all info needed, I guarantee you're going to love it! 

## Topology
The Azure Virtual WAN Playground deploys the following topology:

- Azure Virtual WAN
  - Virtual WAN Hub (Secured Virtual Hub)
  - Firewall Policy
  - Azure Firewall
  - VPN Site (onprem-vpnsite)
  - Virtual Network Connection (spoke1-vnet)
- Spoke VNet
  - Azure Bastion Service
  - Virtual Machine
- On-Prem VNet
  - Azure Bastion Service
  - Virtual Machine
  - VPN Gateway
    - Connection (On-Prem to WAN Hub)
      - Local Network Gateway
 
<img src="https://github.com/StefanIvemo/vwan-playground/blob/on-prem-vnet/media/vwan-playground-topology.png?raw=true">

## Improvements
Azure Virtual WAN Playground will evolve together with Bicep language. When Bicep language supports the `condition` property it will be possible to decide which features will be deployed using paramters, at the moment you will get all resources in the topology. 
