Remove-Variable * -ErrorAction SilentlyContinue
Remove-Module * -ErrorAction SilentlyContinue
$error.Clear()

$Connection = Get-AutomationConnection -Name AzureRunAsConnection
Connect-AzureRmAccount -ServicePrincipal -Tenant $Connection.TenantID -ApplicationId $Connection.ApplicationID -CertificateThumbprint $Connection.CertificateThumbprint

Import-Module .\Modules\New-AzureVirtualMachine

$LocationName = "East US"
$NetworkName = "vNetwork"
$ResourceGroupName = "Lab01"
$VMSize = "Standard_B2s"

if (-not (Get-AzureRmResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue)) {
    New-AzureRmResourceGroup -Name $ResourceGroupName -Location $LocationName
}

if (Get-AzureRmVirtualNetwork -Name $NetworkName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue) {
    $vNet = (Get-AzureRmVirtualNetwork -Name $NetworkName -ResourceGroupName $ResourceGroupName)
} elseif (-not (Get-AzureRmVirtualNetwork -Name $NetworkName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue)) {
    $NICName = "vNIC"
    $SubnetName = "vSubnet"
    $SubnetAddressPrefix = "10.0.0.0/24"
    $vNetAddressPrefix = "10.0.0.0/16"
    $SingleSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetAddressPrefix
    $vNet = New-AzureRmVirtualNetwork -Name $NetworkName -ResourceGroupName $ResourceGroupName -Location $LocationName -AddressPrefix $vNetAddressPrefix -Subnet $SingleSubnet
}

foreach ($VM in 1..1) {
    $NIC = New-AzureRmNetworkInterface -Name "$NICName0$VM" -ResourceGroupName $ResourceGroupName -Location $LocationName -SubnetId $vNet.Subnets[0].Id
    New-AzureVirtualMachine -AdminUser Hunter -AdminPassword Pa11word -LocationName $LocationName -ResourceGroupName $ResourceGroupName -VMName "Test0$VM" -OSType Windows -NetworkInterfaceID $NIC.Id
}