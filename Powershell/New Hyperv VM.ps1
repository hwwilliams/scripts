# This powershell script is designed to be a
# template to make VMs. I will be
# using it to automatically make VMs
# in the future through ansible.
#
# There are four variables that need to be called when
# running the script and one additional optional variable.
#
# The four required variables are as follows:
# $VMName: The name of the VM and VHD.
#
# $DriveType: Different VMs set to different types of drives.
#
# $OS: The OS to use for the VM, CentOS7, Ubuntu LTS, Ubuntu, pfSense,
# Windows 10, Windows 10 LTSB, and Windows Server 2016.
#
# $vSwitch: The name of the virtual switch the VM will use
#
# There is one optional variable:
# $UseParent: If this variable is called it is assumed you want to use 
# a parent disk as the base for the vm, if this variable is not 
# called a completely new VHD is used to install the OS.

# Usage example: .\new_vm_hyperv.ps1 -UseParent -VMName centos7-test -DriveType hdd -OS centos7 -vSwitch public

[CmdletBinding()]
param (
# Regular params go here
# Variable for VM name
        [Parameter(Mandatory = $true)]
        [string]$VMName,
# Variable for drive type for VM, hdd puts it on a hard drive, ssh puts it on an SSD.
        [Parameter(Mandatory = $true)]
        [ValidateSet('hdd','ssd','plex')]
        [string]$DriveType,
# Variable to set whether or not to use parent disk when making vhd
        [switch]$UseParent,
# Variable to set the OS
        [Parameter(Mandatory = $true)]
        [ValidateSet('centos7','ubuntu-lts','ubuntu','pfsense','windows-10','windows-10-ltsb','windows-server-2016')]
        [string]$OS
      )

# Dynamic param processor
dynamicparam {
    $params = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()
        $attributes = [System.Collections.Generic.List[Attribute]]::new()
        $parameterAttribute = [Parameter]::new()
        $parameterAttribute.Mandatory = $true
        $attributes.Add($parameterAttribute)
# Set $validValues to grab virtual switch names from Hyper-V
        [String[]]$validValues = Get-VMSwitch | Select-Object -ExpandProperty name
        $validateSetAttribute = [ValidateSet]::new($validValues)
            $attributes.Add($validateSetAttribute)
# The name of the parameter that we will reference later, 'vSwitch' in this case, should be set here:
            $param = [System.Management.Automation.RuntimeDefinedParameter]::new(
                    'vSwitch',
                    [String],
                    $attributes
                    )
            $params.Add($param.Name, $param)
            return $params
}
end {
# Set variable to point to our dynamic parameter
    $vSwitch = $psboundparameters['vSwitch']

# Code to execute begins from here on
# Set $OS to choose parent disk and iso file
        switch ($OS) {
            centos7 {
                $Parent = 'C:\Users\Public\Documents\Hyper-V\Virtual hard disks\Parent\linux\CentOS-Parent.vhdx'
                $ISO = 'D:\Hyper-V\VHDs\ISO\linux\centos-7-x86_64-DVD-1708.iso'
            }
            centos7-gui {
                $Parent = 'D:\Hyper-V\VHDs\Parent\linux\CentOS7_GUI.vhdx'
                $ISO = 'D:\Hyper-V\VHDs\ISO\linux\centos-7-x86_64-DVD-1708.iso'
            }
            ubuntu-lts {
                $Parent = 'D:\Hyper-V\VHDs\Parent\linux\ubuntu-lts-parent.vhdx'
                $ISO = 'D:\Hyper-V\VHDs\ISO\linux\ubuntu-16.04.4-server-amd64.iso'
            }
            ubuntu {
                $Parent = 'D:\Hyper-V\VHDs\Parent\linux\ubuntu-parent.vhdx'
                $ISO = 'D:\Hyper-V\VHDs\ISO\linux\ubuntu-17.10.1-server-amd64.iso'
            }
            pfsense {
                $ISO = 'D:\Hyper-V\VHDs\ISO\other\pfsense2.4.3-amd64.iso'
            }
            windows-10-ltsb {
                $Parent = 'D:\Hyper-V\VHDs\Parent\windows\LTSB.vhdx'
            }
            windows-10 {
                $Parent = 'D:\Hyper-V\VHDs\Parent\windows\Win10Eval.vhdx'
            }
            windows-server-2016 {
                $Parent = 'D:\Hyper-V\VHDs\Parent\windows\Serv2016Eval.vhdx'
            }
        }
# Set $VMPath based on $DriveType
    $VMPath = switch ($DriveType) {
        hdd {'D:\Hyper-V\VHDs\'}
        ssd {'C:\Users\Public\Documents\Hyper-V\Virtual hard disks\'}
        plex {'E:\'}
    }

# Decide if parent disk will be used
    switch ($UseParent) {
        true {New-VHD -ParentPath $Parent -Path "$VMPath\$VMName.vhdx"}
        false {New-VHD -Path "$VMPath\$VMName.vhdx" -SourceDisk $ISO}
    }

# Determine arch generation option using $OS variable
    $VMGen = switch ($OS) {
        pfsense {Write-Output '1'}
        default {Write-Output '2'}
    }

# Determine SecureBoot option using $OS variable
    $NonWindows = 'centos7','centos7-gui','ubuntu-lts','ubuntu','pfsense'
    $Windows = 'windows-10-ltsb','windows-10','windows-server-2016'
    $SecBoot = switch ($OS) {
        {$NonWindows -eq $_} {Write-Output 'off'}
        {$Windows -eq $_} {Write-Output 'on'}
    }

# Create new VM, get VM name, virtual switch, VHD path, and set arch gen from variables
    New-VM -Name $VMName -SwitchName $vSwitch -VHDPath "$VMPath\$VMName.vhdx" -Generation $VMGen

# Enable dynamic memory for the VM set startup memory, and minimum and maximum memory for dynamic memory
    Set-VMMemory -VMName $VMName -DynamicMemoryEnabled $true -StartupBytes 1GB -MinimumBytes 512MB -MaximumBytes 10GB

# Set VM firmware based on variable
    Set-VMFirmware -VMName $VMName -EnableSecureBoot $SecBoot

# Start VM
    Start-VM -VMName $VMName

}
