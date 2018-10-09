Function New-AzureNetwork {
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateSet('East US', 'East US 2', 'West US', 'West US 2', 'Central US',
            'South Central US', 'North Central US', 'West Central US')]
        $LocationName,
        [Parameter(Mandatory = $true)]
        $NetworkName,
        [Parameter(Mandatory = $true)]
        $NetworkSecurityGroupName,
        [Parameter(Mandatory = $true)]
        $SubnetName,
        [Parameter(Mandatory = $true)]
        $SubnetAddressPrefix,
        [Parameter(Mandatory = $true)]
        $ResourceGroupName,
        [Parameter(Mandatory = $true)]
        $VMName,
        [Parameter(Mandatory = $true)]
        $vNetAddressPrefix
    )
    if (-not (Get-AzureRmVirtualNetwork -Name $NetworkName -ErrorAction SilentlyContinue)) {
        $SingleSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetAddressPrefix
        $vNet = New-AzureRmVirtualNetwork -Name $NetworkName -ResourceGroupName $ResourceGroupName -Location $LocationName -AddressPrefix $vNetAddressPrefix -Subnet $SingleSubnet
    }
    if (-not (Get-AzureRmNetworkSecurityGroup -Name $NetworkSecurityGroupName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue)) {
        $NetworkSecurityGroup = New-AzureRmNetworkSecurityGroup -Name $NetworkSecurityGroupName -ResourceGroupName $ResourceGroupName -Location $LocationName
    }
    if (-not ($NIC.NetworkSecurityGroup.Id)) {
        $NIC.NetworkSecurityGroup.Id = $NetworkSecurityGroup.Id
        $NIC | Set-AzureRmNetworkInterface
    }
    return $NetworkSecurityGroup, $vNet
}

Export-ModuleMember -Function 'New-AzureNetwork'