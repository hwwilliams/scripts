Remove-Variable * -ErrorAction SilentlyContinue
Remove-Module * -ErrorAction SilentlyContinue
$error.Clear()

$Connection = Get-AutomationConnection -Name AzureRunAsConnection
Connect-AzureRmAccount -ServicePrincipal -Tenant $Connection.TenantID -ApplicationId $Connection.ApplicationID -CertificateThumbprint $Connection.CertificateThumbprint

$Publisher = "MicrosoftWindowsServer"
$PublisherOffer = "WindowsServer"
$PublisherSkus = "2016-Datacenter"

$AdminUser = 'hunter'
$AdminPassword = '!{Tw1x}@AzureLabs517!'

$LocationName = 'East US'
$ResourceGroupName = 'TestLab1'
$VMName = 'Web'
$VMSize = "Standard_B2s"

$NetworkName = "vNetwork"
$NSGName = "$VMName-NSG"
$NICName = "vNIC"
$SubnetName = "vSubnet"
$SubnetAddressPrefix = "10.0.0.0/24"
$vNetAddressPrefix = "10.0.0.0/16"

$AdminUserPassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($AdminUser, $AdminUserPassword)

if (-not (Get-AzureRmResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue)) {
    New-AzureRmResourceGroup -Name $ResourceGroupName -Location $LocationName
}

if (-not (Get-AzureRmVirtualNetwork -Name $NetworkName -ErrorAction SilentlyContinue)) {
    $SingleSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetAddressPrefix
    $vNet = New-AzureRmVirtualNetwork -Name $NetworkName -ResourceGroupName $ResourceGroupName -Location $LocationName -AddressPrefix $vNetAddressPrefix -Subnet $SingleSubnet
}

if (-not (Get-AzureRmPublicIpAddress -Name "Public-$VMName" -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue)) {
    $PublicIP = New-AzureRmPublicIpAddress -Name "Public-$VMName" -ResourceGroupName $ResourceGroupName -Location $LocationName -AllocationMethod Dynamic
}

if (-not (Get-AzureRmNetworkSecurityGroup -Name $NSGName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue)) {
$AllowRDP = New-AzureRmNetworkSecurityRuleConfig -Name rdp-rule -Description "Allow RDP" -Access Allow -Protocol Tcp -Direction Inbound `
-Priority 100 -SourceAddressPrefix '96.66.217.173' -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389

$AllowHTTP = New-AzureRmNetworkSecurityRuleConfig -Name web-rule -Description "Allow HTTP" -Access Allow -Protocol Tcp -Direction Inbound `
-Priority 101 -SourceAddressPrefix '96.66.217.173' -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 80

$NetworkSecurityGroup = New-AzureRmNetworkSecurityGroup -Name $NSGName -ResourceGroupName $ResourceGroupName -Location $LocationName -SecurityRules $AllowRDP,$AllowHTTP
}

if (-not (Get-AzureRmNetworkInterface -Name $VMName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue)) {
    $NIC = New-AzureRmNetworkInterface -Name $VMName -ResourceGroupName $ResourceGroupName -Location $LocationName -SubnetId $vNet.Subnets[0].Id
}

if (-not ((Get-AzureRmNetworkInterface -Name $VMName -ResourceGroupName $ResourceGroupName).IpConfigurations[0].PublicIpAddress.IpAddress)) {
    $NIC.IpConfigurations[0].PublicIpAddress = $PublicIP.IpAddress
    $NIC | Set-AzureRmNetworkInterface
}

if (-not ($NIC.NetworkSecurityGroup.Id)) {
    $NIC.NetworkSecurityGroup.Id = $NetworkSecurityGroup.Id
    $NIC | Set-AzureRmNetworkInterface
}

$VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize

$VirtualMachine = Set-AzureRmVMOperatingSystem -VM $($VirtualMachine) -Windows -ComputerName $VMName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate

$VirtualMachine = Add-AzureRmVMNetworkInterface -VM $($VirtualMachine) -Id $NIC.Id

$VirtualMachine = Set-AzureRmVMSourceImage -VM $($VirtualMachine) -PublisherName $Publisher -Offer $PublisherOffer -Skus $PublisherSkus -Version latest

New-AzureRmVM -VM $($VirtualMachine) -ResourceGroupName $ResourceGroupName -Location $LocationName -Verbose
