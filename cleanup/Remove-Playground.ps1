#This script removes all components of the Virtual WAN Playground
param(
  $subscriptionID='',
  $rgNames=@("contoso-vwan-rg", "contoso-mgmt-rg", "contoso-spoke1-rg", "contoso-onprem-rg"),
  $cleanuptemplate='.\cleanup.json'
)

#Select subscription
Select-AzSubscription -SubscriptionId $subscriptionID

#Remove all resources by deploying and emtpy template using Complete mode
$jobs = foreach($rg in $rgNames) {
  New-AzResourceGroupDeployment -Name "cleanup-$rg" -ResourceGroupName $rg -TemplateFile .\cleanup.json -Mode Complete -Force -AsJob
}

#Remove all resource groups
$rgNames | ForEach-Object -Parallel {
  Remove-AzResourceGroup -Name $_ -Force
}