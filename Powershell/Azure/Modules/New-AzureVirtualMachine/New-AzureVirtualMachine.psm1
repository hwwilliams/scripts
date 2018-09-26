Function Set-UbuntuServerPublisher() {
    $Publisher = "Canonical"
    $PublisherOffer = "UbuntuServer"
    $PublisherSkus = "16.04-LTS"
}

Function Set-CentOSServerPublisher() {
    $Publisher = "Tunnelbiz"
    $PublisherOffer = "centos70-min"
    $PublisherSkus = "centos7-min"
}

Function Set-WindowsDesktopPublisher() {
    $Publisher = "MicrosoftWindowsDesktop"
    $PublisherOffer = "Windows-10"
    $PublisherSkus = "rs4-pror"
}

Function Set-WindowsServerPublisher() {
    $Publisher = "MicrosoftWindowsServer"
    $PublisherOffer = "WindowsServer"
    $PublisherSkus = "2016-Datacenter"
}

Function New-VirtualMachine() {
    Param(
    $AdminUser,
    $AdminPassword,
    [Switch] $Desktop,
    $LocationName,
    $ResourceGroupName,
    $VMName,
    [ValidateSet('Linux','Windows')]
    $OSType
    )

    $AdminUserPassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
    $Credential = New-Object System.Management.Automation.PSCredential ($AdminUser, $AdminUserPassword)

    $VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize

    if ($OSType -eq "Linux") {
        $VirtualMachine = Set-AzureRmVMOperatingSystem -VM $VirtualMachine -Linux -ComputerName $VMName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate
        Set-LinuxPublisher
    } elseif ($OSType -eq "Windows") {
        $VirtualMachine = Set-AzureRmVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $VMName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate
        if ($Desktop) {
            Set-WindowsDesktopPublisher
        } else {
            Set-WindowsServerPublisher
        }
    }

    $VirtualMachine = Add-AzureRmVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
    $VirtualMachine = Set-AzureRmVMSourceImage -VM $VirtualMachine -PublisherName $Publisher -Offer $PublisherOffer -Skus $PublisherSkus -Version latest
    New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $LocationName -VM $VirtualMachine -Verbose
}

#Export-ModuleMember -Function 'New-VirtualMachine'