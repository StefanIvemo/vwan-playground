#This script removes all components of the Virtual WAN Playground in the correct order.
param(
  $subscriptionID='95695240-9cfc-444f-8dcb-a7e45ce85aa2',
  $rgNames=@("contoso-global-vwan-rg", "contoso-mgmt-rg", "contoso-spoke1-rg"),
  $cleanuptemplate='.\cleanup.json'
)

#Verify if user have signed in to Azure
if ((az account list) -eq "[]") {
  Write-Host "Please sign in to Azure using your browser"
  az login
  Write-Host "Set active subscription to $subscriptionID"
  az account set --subscription $subscriptionID
}    else {
  Write-Host "User signed in, set active subscription to $subscriptionID"
  az account set --subscription $subscriptionID
}

$rgNames | ForEach-Object -Parallel {
  az deployment group create --resource-group $_ --template-file $using:cleanuptemplate --mode Complete
  Write-Host "Started cleanup deployment on scope: $_, sit back and relax!"
}

$rgNames | ForEach-Object -Parallel {
  az group delete --resource-group $_
  Write-Host "Removing resource group $_"
}
