# Find installation of location of Dell OpenManage
function Get-OMReportPath {
  # Set the two most common installation locations
  $DellOMLocations = [System.Collections.ArrayList]@(
    "C:\Program Files\Dell\SysMgt\oma\bin\omreport.exe"
    "C:\Program Files (x86)\Dell\SysMgt\oma\bin\omreport.exe"
  )
  # Array list for valid locations
  $ValidDellOMLocations = [System.Collections.ArrayList]@()
  # Pull all local drives from the computer to search for the Dell software if not found in the two common installation locations
  $LocalComputerDrives = (Get-Volume | Where-Object { $_.OperationalStatus -like 'ok' -and $_.DriveLetter -notlike $null }).DriveLetter
  # Test if each location is a valid path on the system, if not remove it from the list
  foreach ($DellOMLocation in $DellOMLocations) {
    if (Test-Path -Path $DellOMLocation) {
      $ValidDellOMLocations += $DellOMLocation
    }
  }
  # If more than one location was valid give an error
  if ($ValidDellOMLocations.Count -gt 1) {
    $ErrorMessage = @(
      # General error message
      'Error Detected: Found more than one installation location for Dell OpenManage'
      # List installation locations it found
      $ValidDellOMLocations
    )
  }
  # If one location was valid than set variable to return at the end of the function
  elseif ($ValidDellOMLocations.Count -eq 1) {
    $DellOMReportPath = $ValidDellOMLocations
  }
  # If no locations were valid than search all local drive letters found using earlier '$LocalComputerDrives' command
  elseif ($ValidDellOMLocations.Count -eq 0) {
    foreach ($DriveLetter in $LocalComputerDrives) {
      # Add colon to each drive letter so the path has correct syntax
      $DriveLetter = $DriveLetter + ':'
      # Scan path provided by '$DriveLetter' for the 'omreport.exe'
      try {
        $DellOMReportPath = (Get-ChildItem -Path $DriveLetter -Include *omreport.exe -Recurse -ErrorAction SilentlyContinue).FullName
      }
      catch {
        $ErrorMessage = @(
          'Error Detected'
          $_.Exception.Message
          $_.Exception.ItemName
        )
      }
      # If search found a valid path than break out of for loop
      if (Test-Path -Path $DellOMReportPath) {
        break
      }
      # If search didn't find a valid path than continue for loop
      else {
        continue
      }
    }
  }
  # If no errors were found return installation path
  if ($ErrorMessage.Count -eq 0) {
    return $DellOMReportPath
  }
  # Else print error message and exit
  else {
    Write-Output $ErrorMessage
    Exit
  }
}

# Pull raid controller information
function Get-ControllerObject {
  try {
    $DellOMReportPath = Get-OMReportPath
    $ControllerObject = & "$DellOMReportPath" storage pdisk controller=0
  }
  catch {
    $ErrorMessage = @(
      'Error Detected'
      $_.Exception.Message
      $_.Exception.ItemName
    )
  }
  # If no errors were found return installation path
  if ($ErrorMessage.Count -eq 0) {
    return $ControllerObject
  }
  # Else print error message and exit
  else {
    Write-Output $ErrorMessage
    Exit
  }
}

# Function created based off https://stackoverflow.com/questions/662379/calculate-date-from-week-number/9064954#9064954
# Convert day of week, week of year, and year date information to standard date stamp
Function Get-DiskManufactureDate {
  param([int]$DayOfWeek, [int]$WeekOfYear, [int]$Year)
  try {
    $Jan1 = [DateTime]"$Year-01-01"
    $DaysOffset = ([DayOfWeek]::Thursday - $Jan1.DayOfWeek)
    $FirstThursday = $Jan1.AddDays($DaysOffset)
    $Calendar = ([CultureInfo]::CurrentCulture).Calendar
    $FirstWeek = $Calendar.GetWeekOfYear($FirstThursday, [System.Globalization.CalendarWeekRule]::FirstFourDayWeek, [DayOfWeek]::Monday)
    $WeekNumber = $WeekOfYear
    if ($FirstWeek -le 1) { $WeekNumber -= 1 }
    $ManufactureDate = ($FirstThursday.AddDays($WeekNumber * 7)).AddDays($DayOfWeek - 4)
  }
  catch {
    $ErrorMessage = @(
      'Error Detected'
      $_.Exception.Message
      $_.Exception.ItemName
    )
  }
  # If no errors were found return installation path
  if ($ErrorMessage.Count -eq 0) {
    return $ManufactureDate
  }
  # Else print error message and exit
  else {
    Write-Output $ErrorMessage
    Exit
  }
}

# Generate information about a disk when provided the disk ID
function Get-DiskInfo {
  param([int]$DiskID)
  # Find disk in '$Disks' using disk ID
  $Disk = $Disks | Where-Object { $_.ID -like $DiskID }
  # Set day, week, and year variables from disk information
  $Day = $Disk.ManufactureDay
  $Week = $Disk.ManufactureWeek
  $Year = $Disk.ManufactureYear
  # If manufacture dates are not available than set variable to check
  if ($Day -like "*not a*" -and $Week -like "*not a*" -and $Year -like "*not a*") {
    $ValidManufactureDate = $False
  }
  else {
    try {
      $ManufactureDate = (Get-DiskManufactureDate -DayOfWeek $Day -WeekOfYear $Week -Year $Year).ToString('MM/dd/yyyy')
      $AgeOfDisk = ((New-TimeSpan -Start $(Get-Date) -End $ManufactureDate).Days * -1)
      $ValidManufactureDate = $True
    }
    catch {
      $ErrorMessage = @(
        'Error Detected'
        $_.Exception.Message
        $_.Exception.ItemName
      )
    }
  }
  # Structure disk information as an array of strings
  $DiskInfo = @(
    if ($Disk.VendorID -notlike $null) {
      "Vendor ID: $($Disk.VendorID)"
    }
    else {
      "Vendor ID: Not Available"
    }
    if ($Disk.ProductID -notlike $null) {
      "Product ID: $($Disk.ProductID)"
    }
    else {
      "Product ID: Not Available"
    }
    if ($Disk.SerialNumber -notlike $null) {
      "Serial Number: $($Disk.SerialNumber)"
    }
    else {
      "Serial Number: Not Available"
    }
    if ($Disk.PartNumber -notlike $null) {
      "Part Number: $($Disk.PartNumber)"
    }
    else {
      "Part Number: Not Available"
    }
    # Check if manufacture dates are available
    if ($ValidManufactureDate) {
      "Estimated Date of Manufacture: $($ManufactureDate)"
      "Estimated Age of Disk: $($AgeOfDisk) days"
    }
    else {
      "Estimated Date of Manufacture: Not Available"
      "Estimated Age of Disk: Not Available"
    }
  )
  # If no errors were found return installation path
  if ($ErrorMessage.Count -eq 0) {
    return $DiskInfo
  }
  # Else print error message and exit
  else {
    Write-Output $ErrorMessage
    Exit
  }
}

try {
  # Gather raid controller information
  $ControllerObject = Get-ControllerObject

  # Count each disk ID as a separate disk
  $DiskCount = ($ControllerObject | Where-Object { $_ -like 'id*' } | Measure-Object).Count

  # Count number lines that have values to parse for disk smart data
  $LineCount = 0
  for ($i = 3; $i -lt $ControllerObject.Count; $i++) {
    if (-not ([string]::IsNullOrEmpty($ControllerObject[$i]) -or [string]::IsNullOrWhiteSpace($ControllerObject[$i]))) {
      $LineCount++
    }
    else {
      break
    }
  }
  $LineEnd = $LineCount + 2
  $LineStart = 3

  # Create main array object for all child disk objects
  $Disks = @()

  for ($i = 0; $i -lt $DiskCount; $i++) {
    # Create disk object to house smart data
    $DiskObject = New-Object System.Object
    # Parse and section each line into name and value
    foreach ($Line in $ControllerObject[$LineStart..$LineEnd]) {
      $LineName = ($Line -replace ':.*$?').Trim().replace(' ', '')
      # Remove 'No.' and replace with 'Number' for cleaner text
      if ($LineName.EndsWith('No.')) {
        $LineName = ($LineName.Trim('No.')).Trim() + 'Number'
      }
      $LineValue = ($Line -replace '^.*?:').Trim()
      # Add cleaned lines into disk object
      $DiskObject | Add-Member -MemberType NoteProperty -Name $LineName.Trim() -Value $LineValue.Trim()
    }
    # Add each disk child object into main disks parent array object
    $Disks += $DiskObject
    # Setup new section to loop through as there are two lines of white space between each
    # section of smart data in exported raid controller data
    $LineStart = $LineEnd + 2
    $LineEnd = $LineStart + ($LineCount - 1)
  }

  # Clean ID and name of each disk
  foreach ($Disk in $Disks) {
    # Convert 0:1:1 formatting of controller:disk ID to 1
    $Disk.ID = (($Disk.ID).Split(':')[-1]).Trim()
    # Keep naming of disk whether physical or virtual, remove 0:1:1 formatting
    # and adding newly cleaned ID
    $Disk.Name = (($Disk.Name).Trim(($Disk.Name).Split(' ')[-1])).Trim() + " $($Disk.ID)"
  }

  # Check if disks are certified for use in Dell systems
  $DiskCertifiedObjects = $Disks | Where-Object { $_.Certified -notlike 'yes' }
  # If there are uncertified disks
  if ($DiskCertifiedObjects.Count -gt 0) {
    foreach ($DiskCertifiedObject in $DiskCertifiedObjects) {
      # Build body of email
      $Message = @(
        "Disk $($DiskCertifiedObject.ID) may not be certified for use in Dell systems."
        "All disk details may not be available."
      )
      # Gather information about disk
      $DiskInfo = Get-DiskInfo -DiskID $DiskCertifiedObject.ID
      # Add disk info to main issue variable
      # "`n" means print new line
      $DiskIssues += $Message, $DiskInfo, "`n"
    }
  }

  # Check for status that aren't normal
  $DiskStatusObjects = $Disks | Where-Object { $_.Status -notlike 'ok' -and $_.Status -notlike 'non-critical' }
  # If there is a non-normal status
  if ($DiskStatusObjects.Count -gt 0) {
    foreach ($DiskStatusObject in $DiskStatusObjects) {
      # Build body of email
      $Message = @(
        "Disk $($DiskStatusObject.ID) status not ok."
      )
      # Gather information about disk
      $DiskInfo = Get-DiskInfo -DiskID $DiskStatusObject.ID
      # Add failures to main issue variable
      # "`n" means print new line
      $DiskIssues += $Message, $DiskInfo, "`n"
    }
  }

  $DiskPredictionObjects = $Disks | Where-Object { $_.FailurePredicted -notlike 'no' }
  # If there are predictions
  if ($DiskPredictionObjects.Count -gt 0) {
    foreach ($DiskPredictionObject in $DiskPredictionObjects) {
      # Build body of email
      $Message = @(
        "Disk $($DiskPredictionObject.ID) failure predicted."
      )
      # Gather information about disk
      $DiskInfo = Get-DiskInfo -DiskID $DiskPredictionObject.ID
      # Add disk info to main issue variable
      # "`n" means print new line
      $DiskIssues += $Message, $DiskInfo, "`n"
    }
  }

  # General message that appends to top of body in ticket
  $DellHeaderMessage = @(
    'Dell OpenManage has reported the following:'
  )
}
catch {
  $ErrorMessage = @(
    'Error Detected'
    $_.Exception.Message
    $_.Exception.ItemName
  )
}
finally {
  # If no errors were found return installation path
  if ($ErrorMessage.Count -eq 0) {
    # If there are disk issues
    if ($DiskIssues.Count -eq 0) {
      if ($DiskCount -eq 0) {
        Write-Output "No disks found."
        Exit
      }
      elseif ($DiskCount -eq 1) {
        Write-Output "Found $DiskCount disk. No issues were detected."
        Exit
      }
      elseif ($DiskCount -gt 1) {
        Write-Output "Found $DiskCount disks. No issues were detected."
        Exit
      }
    }
    elseif ($DiskIssues.Count -gt 0) {
      # "`n" means print new line
      $DiskIssues = $DellHeaderMessage, "`n", $DiskIssues
      Write-Output $DiskIssues.Trim()
      Exit
    }
  }
  # Else print error message and exit
  else {
    Write-Output $ErrorMessage
    Exit
  }
}
