$params=@{
    Name = 'vwan-deploy'
    Location = 'westeurope'
    TemplateFile = 'C:\git\StefanIvemo\vwan-playground\playground\contoso-vwan.bicep'
}

New-AzSubscriptionDeployment @params -Verbose