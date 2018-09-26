Remove-Variable * -ErrorAction SilentlyContinue
Remove-Module * -ErrorAction SilentlyContinue
$error.Clear()

$Connection = Get-AutomationConnection -Name AzureRunAsConnection
Connect-AzureRmAccount -ServicePrincipal -Tenant $Connection.TenantID -ApplicationId $Connection.ApplicationID -CertificateThumbprint $Connection.CertificateThumbprint

Import-Module .\Modules\New-AzureVirtualMachine

$LocationName = "East US"
$NetworkName = ""
$ResourceGroupName = "Lab01"
$VMSize = "Standard_B2s"

if (-not (Get-AzureRmResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue)) {
    New-AzureRmResourceGroup -Name $ResourceGroupName -Location $LocationName
}

if (-not (Get-AzureRmNetworkInterface -Name $NetworkName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue)) {
    $NICName = "vNIC"
    $SubnetName = "vSubnet"
    $SubnetAddressPrefix = "10.0.0.0/24"
    $vNetAddressPrefix = "10.0.0.0/16"
    $SingleSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetAddressPrefix
    $vNet = New-AzureRmVirtualNetwork -Name $NetworkName -ResourceGroupName $ResourceGroupName -Location $LocationName -AddressPrefix $vNetAddressPrefix -Subnet $SingleSubnet
    $NIC = New-AzureRmNetworkInterface -Name $NICName -ResourceGroupName $ResourceGroupName -Location $LocationName -SubnetId $vNet.Subnets[0].Id
}

Add-AzureRmVMNetworkInterface -VM $($VirtualMachine) -Id $NIC.Id

New-AzureVirtualMachine -AdminUser hwadmin -AdminPassword '!{@zure}@Labs01!' -LocationName $LocationName -ResourceGroupName $ResourceGroupName -VMName Web01 -OSType ubuntu
