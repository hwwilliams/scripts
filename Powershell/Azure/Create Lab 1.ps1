$Connection = Get-AutomationConnection -Name AzureRunAsConnection
Connect-AzureRmAccount -ServicePrincipal -Tenant $Connection.TenantID -ApplicationId $Connection.ApplicationID -CertificateThumbprint $Connection.CertificateThumbprint

Import-Module .\Modules\New-VirtualMachine

$LocationName = "East US"
$NetworkName = "Lab_1_vNetwork"
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

foreach ($VM in 1..3) {
    New-VirtualMachine -AdminUser Hunter -AdminPassword Pa11word -LocationName $LocationName -ResourceGroupName $ResourceGroupName -VMName "Test0$VM" -OSType Windows
}