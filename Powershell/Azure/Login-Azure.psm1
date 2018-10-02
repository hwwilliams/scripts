$RunAsConnection = Get-AutomationConnection -Name AzureRunAsConnection

try {
    Add-AzureRmAccount -ServicePrincipal -TenantId $RunAsConnection.TenantId -ApplicationId $RunAsConnection.ApplicationId -CertificateThumbprint $RunAsConnection.CertificateThumbprint -ErrorAction Stop
}
catch {
    Start-Sleep 10
    Add-AzureRmAccount -ServicePrincipal -TenantId $RunAsConnection.TenantId -ApplicationId $RunAsConnection.ApplicationId -CertificateThumbprint $RunAsConnection.CertificateThumbprint
}

Set-AzureRmContext -SubscriptionId $RunAsConnection.SubscriptionID

Connect-AzureRmAccount

Add-Type -AssemblyName System.Web
$SecurePassword = ConvertTo-SecureString -AsPlainText -String [System.Web.Security.Membership]::GeneratePassword(16, 3) -Force
$ServicePrincipal = New-AzureRmADServicePrincipal -ApplicationId (Get-AzureRmADApplication -DisplayNameStartWith 'Automation').ApplicationId -Password $SecurePassword