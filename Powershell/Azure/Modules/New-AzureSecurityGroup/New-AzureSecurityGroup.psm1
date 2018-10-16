Function New-AzureSecurityGroup {
    Param (
        [Parameter(Mandatory = $true)]
        $LocationName,
        [Parameter(Mandatory = $true)]
        $NSGName,
        [Parameter(Mandatory = $true)]
        $ResourceGroupName
    )
    if (-not (Get-AzureRmNetworkSecurityGroup -Name $NSGName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue)) {
        $AllowRDP = New-AzureRmNetworkSecurityRuleConfig -Name rdp-rule -Description "Allow RDP" -Access Allow -Protocol Tcp -Direction Inbound `
            -Priority 100 -SourceAddressPrefix '96.66.217.173' -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389
        $AllowHTTP = New-AzureRmNetworkSecurityRuleConfig -Name web-rule -Description "Allow HTTP" -Access Allow -Protocol Tcp -Direction Inbound `
            -Priority 101 -SourceAddressPrefix '96.66.217.173' -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 80
        $NetworkSecurityGroup = New-AzureRmNetworkSecurityGroup -Name $NSGName -ResourceGroupName $ResourceGroupName -Location $LocationName -SecurityRules $AllowRDP, $AllowHTTP
    }
    return $NetworkSecurityGroup
}