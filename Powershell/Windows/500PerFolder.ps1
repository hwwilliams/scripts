$SourcePath = "O:\unchecked\gifs"
$NumberArray = @(); for ([byte]$i = [char]'0'; $i -le [char]'9'; $i++) { $NumberArray += [char]$i }

foreach ($Number in $NumberArray)
{
  Get-ChildItem -Path $SourcePath | Select-Object -First 500 | Move-Item -Destination (Join-Path -Path $SourcePath -ChildPath $Number)
}
