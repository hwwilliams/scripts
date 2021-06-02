# Path to the directory containing incorrectly ordered permission files
$Path = ""

# Build list of files have corrupt permissions
$Files = @()
Get-ChildItem $Path -Recurse | ForEach-Object {
  try
  {
    $Files += Get-Acl $_.FullName | Where-Object { $_.AreAccessRulesProtected } | ForEach-Object { Convert-Path $_.Path }
  }
  catch
  {
    Write-Error ("Get-Acl error: {0}" -f $_.Exception.Message)
    return
  }
}

# Reset permisisons and force permission inheritance on the file
foreach ($File in $Files)
{
  icacls.exe $($File | Out-String).Trim() /reset /t /c
}
