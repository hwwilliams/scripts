<#
.SYNOPSIS
    Sign into Miscrosoft services to access MS Online and Exchange Online commands.
.DESCRIPTION
    This is designed to sign you into Miscrosoft services to access MS Online and Exchange Online commands.
#>
function New-MsolConnection {
    begin {
        $O365Credentials = Get-Credential
    }
    process {
        Connect-MsolService -Credential $O365Credentials
        $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $O365Credentials -Authentication Basic -AllowRedirection
        Import-PSSession $Session -AllowClobber | Out-Null
    }
    end { }
}

Export-ModuleMember -Function "New-MsolConnection"
