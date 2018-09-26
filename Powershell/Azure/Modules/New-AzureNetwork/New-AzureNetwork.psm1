Function New-AzureNetwork() {
    Param(
        $NetworkName,
        $NSGName,
        $NICName,
        $SubnetName,
        $SubnetAddressPrefix,
        $vNetAddressPrefix
    )

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

    if (-not (Get-AzureRmNetworkInterface -Name $VMName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue)) {
        $NIC = New-AzureRmNetworkInterface -Name $VMName -ResourceGroupName $ResourceGroupName -Location $LocationName -SubnetId $vNet.Subnets[0].Id -NetworkSecurityGroupId $NetworkSecurityGroup.Id
    }

    if (-not ((Get-AzureRmNetworkInterface -Name $VMName -ResourceGroupName $ResourceGroupName).IpConfigurations[0].PublicIpAddress.IpAddress)) {
        $NIC.IpConfigurations[0].PublicIpAddress = $PublicIP.IpAddress
        Set-AzureRmNetworkInterface -NetworkInterface $NIC
    }
}