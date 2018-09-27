<#
Run this with:
Invoke-Expression (invoke-webrequest -uri 'https://raw.githubusercontent.com/DarwinJS/CloudyWindowsAutomationCode/master/install-pwsh.ps1') ; Install-PWSH
# Include IDE
Invoke-Expression (invoke-webrequest -uri 'https://raw.githubusercontent.com/DarwinJS/CloudyWindowsAutomationCode/master/install-pwsh.ps1') ; Install-PWSH -includeide
#>

Function Install-PWSH {

    Param (
        [Switch] $IncludeAll,
        [Switch] $IncludeVSCode
    )

    If ($IncludeAll) {
        Get-Variable -Scope
    }

    If (-not (Test-Path env:chocolateyinstall)) {
        Write-Output "Installing Chocolatey..."
        Invoke-WebRequest https://chocolatey.org/install.ps1 -UseBasicParsing | Invoke-Expression
    }

    Write-Output
    choco upgrade -y powershell-core

    If ($IncludeVSCode) {
        choco upgrade -y visualstudiocode
        code --install-extension ms-vscode.powershell-core
    }
}