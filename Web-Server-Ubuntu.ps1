Remove-Variable * -ErrorAction SilentlyContinue
Remove-Module * -ErrorAction SilentlyContinue
$error.Clear()

$Connection = Get-AutomationConnection -Name AzureRunAsConnection
Connect-AzureRmAccount -ServicePrincipal -Tenant $Connection.TenantID -ApplicationId $Connection.ApplicationID -CertificateThumbprint $Connection.CertificateThumbprint

Import-Module .\Modules\Set-AzureVMLogin
Import-Module .\Modules\Set-AzureResourceGroup
Import-Module .\Modules\New-AzureNetwork
Import-Module .\Modules\New-AzureSecurityGroup
Import-Module .\Modules\New-AzureVirtualMachine