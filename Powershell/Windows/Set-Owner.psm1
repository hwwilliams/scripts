<#
.SYNOPSIS
    Recursively take ownership of folders/files and remove them from a system. Requires administrative privileges.
.DESCRIPTION
    This is designed to take ownership of folders/files, recursively if needed. It can also remove those
    files once ownership has been taken.
.PARAMETER Path
    Specify the path to the folder or files you wish to take ownership.
.PARAMETER Recurse
    Specify if to run the script recursively.
.PARAMETER Remove
    Specify to remove folders/files where ownership has been taken.
.EXAMPLE
    Set-Owner -Path "C:\Program Files" -Recurse -Remove
.EXAMPLE
    Set-Owner -Path "C:\Program Files" -Recurse
.EXAMPLE
    Set-Owner -Path "C:\Program Files" -Remove
.EXAMPLE
    Set-Owner -Path "C:\Program Files"
#>

function Set-Owner {
    Param (
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipeline = $True)]
        [string] $Path,
        [Parameter(Position = 1, Mandatory = $False, ValueFromPipeline = $True)]
        [switch] $Recurse,
        [Parameter(Position = 3, Mandatory = $False, ValueFromPipeline = $True)]
        [switch] $Remove
    )
    begin {}
    process {
        if ($Recurse -eq $True) {
            takeown /f $Path /r /a /d Y
            icacls $Path /t /g administrators:f
            if ($Remove -eq $True) {
                Remove-Item -Path $Path -Recurse -Force
            }
        }
        else {
            takeown /f $Path /a /d Y
            icacls $Path /g administrators:f
            if ($Remove -eq $True) {
                Remove-Item -Path $Path -Force
            }
        }
    }
    end {}
}

Export-ModuleMember -Function "Set-Owner"