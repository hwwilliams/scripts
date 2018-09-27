Function Install-PWSH {
    Param (
        [Switch] $IncludeAll,
        [Switch] $IncludeVSCode
    )

    If ($IncludeAll) {
        foreach ($Var in $("IncludeVSCode")) {
            $Var = $true
        }
    }
}

Install-PWSH -IncludeAll
Write-Output $IncludeVSCode