if (Test-Path -PathType Leaf "C:\Program Files (x86)\Microsoft Office\root\Office16\lync.exe") {
    if ([Environment]::Is64BitProcess) {
        $TeamsURL = "https://aka.ms/teams64bitmsi"
    }
    else {
        $TeamsURL = "https://aka.ms/teams32bitmsi"
    }
    $TempFolder = "$env:TEMP\Teams-Installer\"
    try {
        if (-not (Test-Path -PathType Container $TempFolder)) {
            New-Item -ItemType Directory -Path $TempFolder
        }
    }
    catch {
        Write-Error $_
        exit
    }
    $TeamsMSI = "$TempFolder\Teams-Installer.msi"
    try {
        Invoke-WebRequest -Uri $TeamsURL -OutFile $TeamsMSI
    }
    catch {
        Write-Error $_
        exit
    }
    try {
        Start-Process msiexec.exe -Wait -ArgumentList "/I $TeamsEXE /quiet"
    }
    catch {
        Write-Error $_
        exit
    }
}
