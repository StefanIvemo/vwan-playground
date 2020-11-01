#This script removes all components of the Virtual WAN Playground in the correct order.
param(
  $subscriptionID='',
  $rgName='',
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

az deployment group create --resource-group $rgName --template-file $cleanuptemplate --mode Complete

Write-Host "Started empty deployment on target Resource Group $rgName"