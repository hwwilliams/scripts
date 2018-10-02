$Search_Directory = "Z:\Plex"

do {
    $Empty_Directories = Get-ChildItem $Search_Directory -directory -recurse | Where-Object { (Get-ChildItem $_.fullName -Force).count -eq 0 } | Select-Object -expandproperty FullName
    $Empty_Directories | Foreach-Object { Remove-Item $_ }
} while ($Empty_Directories.count -gt 0)
