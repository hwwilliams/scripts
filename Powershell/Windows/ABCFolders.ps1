$Directory = ""

$NumberArray = @(); for ([byte]$i = [char]'0'; $i -le [char]'9'; $i++) { $NumberArray += [char]$i }
$LetterArray = @(); for ([byte]$i = [char]'A'; $i -le [char]'Z'; $i++) { $LetterArray += [char]$i }
$CharacterArray = $NumberArray + $LetterArray

foreach ($Character in $CharacterArray)
{
  if ($FolderNames = Get-ChildItem $Directory -Directory | Where-Object {
      (($_.Name).Length -ne 1) -and ($_.Name -imatch "^$Character")
    })
  {
    $CharacterFolder = Join-Path -Path $Directory -ChildPath $Character
    if (-not (Test-Path $CharacterFolder))
    {
      New-Item -ItemType Directory -Path $CharacterFolder | Out-Null
    }
    foreach ($FolderName in $FolderNames)
    {
      $FolderPath = Join-Path -Path $Directory -ChildPath $FolderName.Name
      Move-Item -Path $FolderPath -Destination $CharacterFolder -Force -Verbose
    }
  }
}
