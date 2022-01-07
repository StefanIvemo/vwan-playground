$params=@{
    Name = 'vwan-deploy3'
    Location = 'westeurope'
    TemplateFile = 'C:\git\StefanIvemo\vwan-playground\playground\main.bicep'
}

New-AzSubscriptionDeployment @params -Verbose