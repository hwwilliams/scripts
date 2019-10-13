# Uploading to archive, not original creator

$URL = '<Enter UNIFI URL>'
$port = '<Enter Unifi Managment Port>'
$User = '<Enter Unifi Admin Username>'
$Pass = '<Enter Unifi Admin Password>'
$SiteCode = '<Site Code>' #you can enter each site here. This way when you assign the monitoring to a client you edit this to match the correct siteID.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
$controller = "https://$($URL):$($port)"
$credential = "`{`"username`":`"$User`",`"password`":`"$Pass`"`}"
try {
  $null = Invoke-Restmethod -Uri "$controller/api/login" -method post -body $credential -ContentType "application/json; charset=utf-8"  -SessionVariable myWebSession
}
catch {
  $APIerror = "Api Connection Error: $($_.Exception.Message)"
}
try {
  $APIResult = Invoke-Restmethod -Uri "$controller/api/s/$SiteCode/stat/device/" -WebSession $myWebSession
}
catch {
  $APIerror = "Query Failed: $($_.Exception.Message)"
}

$AllSites = Invoke-RestMethod -Uri "$controller/api/self/sites" -WebSession $myWebSession
foreach ($site in $AllSites.data) {
  try {
    $siteIDFromList = ($site.name)
    $APIResult = Invoke-Restmethod -Uri "$controller/api/s/$siteIDFromList/stat/device/" -WebSession $myWebSession
  }
  catch {
    $APIerror += "`nGet Devices for $siteIDFromList Failed: $($_.Exception.Message)"
  }
  foreach ($Device in $APIResult.data | where-object { $_.upgradable -eq "true" }) {
    try {
      $cmd = @"
                {
                "cmd":"upgrade",
                "mac":"$($device.MAC)"
                }
"@
      $upgrade = Invoke-RestMethod -Uri "$controller/api/s/$siteIDFromList/cmd/devmgr" -Method post -Body $cmd -WebSession $myWebSession -ErrorAction SilentlyContinue
    }
    catch {
      $UpgradeError = "Upgrade Failed for device $($device.name) with MAC $($Device.mac) : $($_.Exception.Message)"
    }
  }
}
