Function Set-CentOSServerPublisher() {
    $Publisher = "Tunnelbiz"
    $PublisherOffer = "centos70-min"
    $PublisherSkus = "centos7-min"
}

Function Set-UbuntuServerPublisher() {
    $Publisher = "Canonical"
    $PublisherOffer = "UbuntuServer"
    $PublisherSkus = "16.04-LTS"
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
        $LocationName,
        $ResourceGroupName,
        $VMName,
        [ValidateSet('centos', 'ubuntu', 'Windowsdesktop', 'windowsserver')]
        $OSType
    )

    $AdminUserPassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force
    $Credential = New-Object System.Management.Automation.PSCredential ($AdminUser, $AdminUserPassword)

    $VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize

    if ($OSType -icontains ('centos', 'ubuntu')) {
        $VirtualMachine = Set-AzureRmVMOperatingSystem -VM $VirtualMachine -Linux -ComputerName $VMName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate
        if ($OSType -eq 'centos') {
            Set-CentOSServerPublisher
        }
        elseif ($OSType -eq 'ubuntu') {
            Set-UbuntuServerPublisher
        }
    }
    elseif ($OSType -ilike "windows*") {
        $VirtualMachine = Set-AzureRmVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $VMName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate
        if ($OSType -eq 'Windowsdesktop') {
            Set-WindowsDesktopPublisher
        }
        elseif ($OSType -eq 'windowsserver') {
            Set-WindowsServerPublisher
        }
    }

    $SourceImageID = (Get-AzureRmVMImageSku -Location $LocationName -PublisherName $Publisher -Offer $PublisherOffer | Where-Object { $_.Skus -eq $PublisherSkus }).Id
    $VirtualMachine = Add-AzureRmVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
    $VirtualMachine = Set-AzureRmVMSourceImage -VM $VirtualMachine -Id $SourceImageID
    New-AzureRmVM -VM $VirtualMachine -ResourceGroupName $ResourceGroupName -Location $LocationName -Verbose
}

#Export-ModuleMember -Function 'New-VirtualMachine'