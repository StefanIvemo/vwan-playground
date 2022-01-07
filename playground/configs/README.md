# VWAN Playground Configs

The VWAN Playground template requires a config to deploy successfully. In the config file you can specify the number of Virtual Hubs to create and specify which services to deploy inside the hubs. You can also specify additional "landing zones" connected to each hubs and "fake" On-Premises sites connected using site-to-site VPN.

## Org configs

| Organization | Config file | Description |
|:--|:--|:--|
| Contoso | `contoso.json` | Multiple Virtual WAN hubs in different regions, landing zones and "on-premises" VNets. P2S VPN, S2S VPN, Azure Firewall. |
| Fabrikam | `fabrikam.json` | Single Virtual WAN hub, landing zone and "on-premises" VNet. P2S VPN, S2S VPN, Azure Firewall. |
| Wingtip | `wingtip.json` | Single Virtual WAN hub, landing zone. P2S VPN, Azure Firewall. |

You can modify the config file anyway you want by changing the booleans and add/remove regions, landing zones and on-prem sites. Just make sure that you don't have any overlapping address spaces.

## Point-to-site config

To successfully deploy the Azure Point-to-Site VPN you need to update the `p2sVpnAADAuth.json` config file with your tenant details and Azure VPN application id.

Docs on how to prepare your tenant by granting consent to the Azure VPN Enterprise Application. https://docs.microsoft.com/en-us/azure/virtual-wan/openvpn-azure-ad-tenant

```json
{
    "clientId": "<Azure VPN Enterprise Application App Id>",
    "tenantId": "<Tenant Id>"
}
```
