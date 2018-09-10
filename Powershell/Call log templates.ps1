# Two passable script arguments
# - ConfirmSave: If this argument is passed then the script will default to saving to the directory
#   defined in the '$Move_To_Directory' variable.
# - CallLogYear: If passed with a 4 digit number ranging from 1000-2999,
#   the valid year will be appended to the file name of all Excel files created.
[CmdletBinding()]
Param (
    [Switch] $ConfirmSave = $False,
    [ValidatePattern('^[12][0-9]{3}$')]
    [Int] $Year
)

## General Dictionaries, Variables, and Other Declarations.
# The Move_To_Directory variable is the default save location, currently it makes a folder and
# saves to it within the currently logged in user's documents folder.
# Also trim any leading or trailing spaces.
$Move_To_Directory = ("C:\Users\$env:username\Documents\Call log templates$(if ($Year) {" $Year"})\").Trim()
$Valid_Path_Regex = '^[a-z]:[/\\][^{0}]*$' -f [Regex]::Escape(([IO.Path]::InvalidPathChars -Join ''))

## Excel ComObject Conditions and Operators.
Add-Type -AssemblyName Microsoft.Office.Interop.Excel
# Set default Excel workbook format to save as.
$Excel_Format = [Microsoft.Office.Interop.Excel.XlFileFormat]::xlWorkbookDefault
# Excel conditional formatting operators and conditions.
$Between_Operator = [Microsoft.Office.Interop.Excel.XlFormatConditionOperator]::xlBetween
$Cell_Value_Condition = [Microsoft.Office.Interop.Excel.XlFormatConditionType]::xlCellValue
$Equal_Operator = [Microsoft.Office.Interop.Excel.XlFormatConditionOperator]::xlEqual
$Not_Equal_Operator = [Microsoft.Office.Interop.Excel.XlFormatConditionOperator]::xlNotEqual
# Excel ComObject colors.
$RoyalBlue = [Microsoft.Office.Interop.Excel.XlRgbColor]::rgbLightSkyBlue
$LimeGreen = [Microsoft.Office.Interop.Excel.XlRgbColor]::rgbLimeGreen
$Yellow = [Microsoft.Office.Interop.Excel.XlRgbColor]::rgbYellow

## Hashtables (Dictionaries)
$A_To_K = @(); for ([byte]$i = [char]'A'; $i -le [char]'K'; $i++) { $A_To_K += [char]$i }
$Months_Days = @{
    January = 5
    # Febuary = 28
    # March = 31
    # April = 30
    # May = 31
    # June = 30
    # July = 31
    # August = 31
    # September = 30
    # October = 31
    # November = 30
    # December = 31
}
$Titles_Widths = [Ordered]@{
    'Time' = 12
    'User' = 20
    'Company' = 42
    'Issue' = 135
    'Phone/Ext' = 18
    'Owner' = 10
    'Status' = 9
    'Ticket #' = 9
    'Notes/Email' = 15
    'Router' = 7
    'Territory' = 7
}
$Values_Colors = @{
    'cb' = $LimeGreen
    'done' = $LimeGreen
    'ip' = $Yellow
}

## General functions.
# Clean-Up function removes work directory, and resets all variables.
Function Clean-Up {
    Get-ChildItem $Work_Directory -Recurse -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item $Work_Directory -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Variable * -ErrorAction SilentlyContinue
    Remove-Module * -ErrorAction SilentlyContinue
    $error.Clear()
}
# New-TemporaryDirectory function makes a new directory in the user's temp folder.
Function New-TemporaryDirectory {
    $Temp_Parent_Path = [System.IO.Path]::GetTempPath()
    [String] $Temp_Name = [System.Guid]::NewGuid()
    New-Item -ItemType Directory -Path (Join-Path -Path $Temp_Parent_Path -ChildPath $Temp_Name)
}
try {
    # Make temp work directory and 'done' subdirectory.
    $Work_Directory = New-TemporaryDirectory
    $Save_Directory = Join-Path -Path $Work_Directory -ChildPath 'Done'
    # If $Save_Directory does not exist create it.
    if (-Not (Test-Path $Save_Directory)) {
        New-Item -ItemType Directory -Path $Save_Directory
    }

    # Create Excel instance and set it to be hidden and disallow all user interaction.
    $Excel_Instance = New-Object -ComObject Excel.Application
    $Excel_Instance.Visible = $False
    $Excel_Instance.DisplayAlerts = $False
    $Excel_Instance.ScreenUpdating = $False
    $Excel_Instance.UserControl = $False
    $Excel_Instance.Interactive = $False

    # Add a workbook to the Excel instance we made and for each day in Febuary make a sheet inside that workbook.
    # We do a range of the days in Febuary minus 1 (i.e. 28-1=27) because the new workbook starts with one empty sheet and
    # when we're done that'd be a total of 28 sheets which makes up the base of our template because 28 days is
    # the lowest number of days we'd need, i.e. Febuary.
    $Workbook = $Excel_Instance.Workbooks.Add()
    ForEach ($Day in 1..4) {
        $Workbook.Worksheets.Add([System.Reflection.Missing]::Value, $Workbook.Worksheets.Item($Workbook.Worksheets.Count))
    }
    # A variable is set for the path to the new template workbook, it is then saved and closed.
    $Temp_Workbook = Join-Path -Path $Work_Directory -ChildPath "Temp Workbook.xlsx"
    $Workbook.SaveAs($Temp_Workbook, $Excel_Format)
    $Workbook.Close()
    # Note: if the Excel workbooks are not saved with the correct file extension and Excel format, and then closed after saving, the files will become corrupted.
    
    # Begin building each monthly workbook
    ForEach ($Items in $Months_Days.GetEnumerator()) {
        # Pull month and days per month from the $Months_Days hashtable (dictionary).
        $Month = $Items.Key
        $Days = $Items.Value
        # Open the template workbook we made earlier
        $Workbook = $Excel_Instance.Workbooks.Open($Temp_Workbook)
        $Missing_Sheets = $Days - $Workbook.Worksheets.Count
        # For each missing sheet, based on the number of days in the currently selected month, add a new sheet behind any other sheets
        if ($Missing_Sheets -ge 1) {
            # $Missing_Sheets plus 1 so that we can label that last sheet in each workbook as an 'Extra' in case one is needed.
            ForEach ($Missing_Sheet in 1..($Missing_Sheets + 1)) {
                $Workbook.Worksheets.Add([System.Reflection.Missing]::Value, $Workbook.Worksheets.Item($Workbook.Worksheets.Count))
            }
        }
        # For each day (sheet) in the workbook set conditional formatting.
        ForEach ($Day in 1..$Days) {
            # Set conditional formatting on column F from cell 4 to 999, activtive if they contain 'aa'.
            (($Workbook.Worksheets.Item($Day)).Range('f4:f999')).FormatConditions.Add($Cell_Value_Condition, $Equal_Operator, 'aa')
            # If conditional formatting is activtive turn the cell $LimeGreen.
            (($Workbook.Worksheets.Item($Day)).Range('f4:f999')).FormatConditions.Item(1).Interior.Color = $LimeGreen
            # If conditional formatting is activtive set text color within cell to 1 (Black).
            (($Workbook.Worksheets.Item($Day)).Range('f4:f999')).FormatConditions.Item(1).Font.ColorIndex = 1
            # If conditional formatting is activtive set text within cell to be bold.
            (($Workbook.Worksheets.Item($Day)).Range('f4:f999')).FormatConditions.Item(1).Font.Bold = $True
            # Set conditional formatting on column F from cell 4 to 999, activtive if they contain any text.
            (($Workbook.Worksheets.Item($Day)).Range('f4:f999')).FormatConditions.Add($Cell_Value_Condition, $Not_Equal_Operator, '=ISTEXT(f4:f999)')
            # If conditional formatting is activtive turn the cell $RoyalBlue.
            (($Workbook.Worksheets.Item($Day)).Range('f4:f999')).FormatConditions.Item(2).Interior.Color = $RoyalBlue
            (($Workbook.Worksheets.Item($Day)).Range('f4:f999')).FormatConditions.Item(2).Font.ColorIndex = 1
            (($Workbook.Worksheets.Item($Day)).Range('f4:f999')).FormatConditions.Item(2).Font.Bold = $True
            $Count = 1
            ForEach ($Items in $Values_Colors.GetEnumerator()) {
                $Cell_Value = $Items.Key
                $Color = $Items.Value
                # For each $Items in the $Values_Colors hashtable, get each $Cell_Value and $Color and apply to the G column as follows.
                (($Workbook.Worksheets.Item($Day)).Range('g4:g999')).FormatConditions.Add($Cell_Value_Condition, $Equal_Operator, $Cell_Value)
                (($Workbook.Worksheets.Item($Day)).Range('g4:g999')).FormatConditions.Item($Count).Interior.Color = $Color
                (($Workbook.Worksheets.Item($Day)).Range('g4:g999')).FormatConditions.Item($Count).Font.ColorIndex = 1
                (($Workbook.Worksheets.Item($Day)).Range('g4:g999')).FormatConditions.Item($Count).Font.Bold = $True
                # Add 1 to $Count for each cycle of the loop so that each conditional formatting entry doesn't overwrite the other.
                $Count++
            }
            # Set conditional formatting on column H from cell 4 to 999, activtive if they contain a number between 1 and 9999999999.
            (($Workbook.Worksheets.Item($Day)).Range('h4:h999')).FormatConditions.Add($Cell_Value_Condition, $Between_Operator, 1, 9999999999)
            (($Workbook.Worksheets.Item($Day)).Range('h4:h999')).FormatConditions.Item(1).Interior.ColorIndex = 1
            # If conditional formatting is activtive set text color within cell to 2 (White).
            (($Workbook.Worksheets.Item($Day)).Range('h4:h999')).FormatConditions.Item(1).Font.ColorIndex = 2
            # If conditional formatting is activtive set text to auto format to time.
            ($Workbook.Worksheets.Item($Day)).Columns('a').NumberFormat = "[$-x-systime]h:mm:ss AM/PM"
            # If conditional formatting is activtive set text to auto format to phone numbers.
            ($Workbook.Worksheets.Item($Day)).Columns('e').NumberFormat = "[<=9999999]###-####;(###) ###-####"
            # Set the value of cell in row 1 and columb 1 to 'CALL LOG' and make it bold.
            ($Workbook.Worksheets.Item($Day)).Cells.Item(1,1) = 'CALL LOG'
            ($Workbook.Worksheets.Item($Day)).Cells.Item(1,1).Font.Bold = $True
            $Count = 1
            ForEach ($Items in $Titles_Widths.GetEnumerator()) {
                $Title = $Items.Key
                $Width = $Items.Value
                # For each $Items in the $Titles_Widths hashtable, get each $Title and $Width and apply to row 2 and cycle through the columns per loop as follows.
                ($Workbook.Worksheets.Item($Day)).Cells.Item(2,$Count) = $Title
                ($Workbook.Worksheets.Item($Day)).Cells.Item(2,$Count).ColumnWidth = $Width
                ($Workbook.Worksheets.Item($Day)).Cells.Item(2,$Count).Interior.ColorIndex = 1
                ($Workbook.Worksheets.Item($Day)).Cells.Item(2,$Count).Font.ColorIndex = 2
                # If conditional formatting is activtive set text color within cell to 6 (Yellow).
                ($Workbook.Worksheets.Item($Day)).Cells.Item(3,$Count).Interior.ColorIndex = 6
                $Count++
            }
            ForEach ($Letter in $A_To_K) {
                # For each $Letter in the $A_To_K hashtable, cycle through the columns per loop and make each column have text centered horizontally.
                ($Workbook.Worksheets.Item($Day)).Columns("$Letter").HorizontalAlignment = -4108
            }
            # Name each sheet based on the currently selected month in short form and add the day on the end.
            $Workbook.Worksheets.Item($Day).Name = "$(
                if ($Month -eq 'September') {
                    # If $Month is equal to September then print the first four letters (Sept).
                    $Month.SubString(0,4)
                } else {
                    # Else print the first three letters (Jul for July).
                    $Month.SubString(0,3)
                }
            )-$Day"
            # Rename last sheet to 'Extra'.
            $Workbook.Worksheets.Item($Workbook.Worksheets.Count).Name = 'Extra'
        }
        # Save newly created workbook, if the $Year variable has been set then print it, and then close it.
        $Workbook.SaveAs((Join-Path -Path $Save_Directory -ChildPath "$Month$(if ($Year) { " $Year" }).xlsx"), $Excel_Format)
        $Workbook.Close()
        # Note: if the Excel workbooks are not saved with the correct file extension and Excel format, and then closed after saving, the files will become corrupted.
    }
    $Excel_Instance.Quit()

    # If $ConfirmSave is not true then do as follows.
    if (-not ($ConfirmSave)) {
        # Loop until condition is met.
    	do {
            # If $Move_To_Directory is true and contains a file or folder path that is valid, not necessary that it exists, do as follows.
            $Confirmed_Directory = $False; $Confirm_Move_To_Directory = $False
            if (($Move_To_Directory) -and ($Move_To_Directory -match $Valid_Path_Regex)) {
                # Loop until condition is met.
                do {
                    # Ask if the default save directory is okay to use, trim any leading or trailing spaces.
                    $Confirm_Move_To_Directory = (Read-Host "Call log templates will be saved to '$Move_To_Directory', is this okay? (y/n)").Trim()
                    if ($Confirm_Move_To_Directory -like "y*" -or $Confirm_Move_To_Directory -like "n*") {
                        # If $Confirm_Move_To_Directory contains some string like y or n then set $Confirmed_Directory to true.
                        $Confirmed_Directory = $True
                    } else {
                        # Else warn the user their answer must be yes or no.
                        Write-Warning "Your answer must be yes or no."
                    }
                # Condition is met if $Confirm_Move_To_Directory contains some string like y or n.
                } until ($Confirm_Move_To_Directory -like "y*" -or $Confirm_Move_To_Directory -like "n*")
            } else {
            # If $Move_To_Directory is false or does not contain a file or folder path that is valid, do as follows.
                Write-Warning '"$Move_To_Directory" was not set or contains invalid characters to use in a path.'
                # Set $Confirm_Move_To_Directory to 'n' so that it prompts the user to enter a valid path.
                $Confirm_Move_To_Directory = 'n'
                # Set $Confirmed_Directory to true so the do..until condition is met.
                $Confirmed_Directory = $True
            }
        # Condition is met if the $Confirmed_Directory is true.
        } until ($Confirmed_Directory)
        # If $Confirm_Move_To_Directory is like 'n' then do as follows.
        if ($Confirm_Move_To_Directory -like "n*") {
            # Loop until condition is met.
            do {
                # Ask which path the user would like to use as the save directory, trim any leading or trailing spaces.
                $Directory_Valid = $False; $Is_Directory = $False; $Valid_Directory = $False
                $Move_To_Directory = (Read-Host "Which directory would you like the Call log templates to be saved to? (Example: C:\Users\$env:username\Documents)").Trim()
                if ($Move_To_Directory.StartsWith('"')) {
                    # If $Move_To_Directory starts with a double quote then remove it, also trim any leading or trailing spaces.
                   $Move_To_Directory = ($Move_To_Directory.Trim('"')).Trim()
                } elseif ($Move_To_Directory.StartsWith("'")) {
                    # Else if $Move_To_Directory starts with a single quote then remove it, also trim any leading or trailing spaces.
                    $Move_To_Directory = ($Move_To_Directory.Trim("'")).Trim()
                }
                if ($Move_To_Directory -match $Valid_Path_Regex) {
                    # If $Move_To_Directory contains a file or folder path that is valid, not necessary that it exists, set $Valid_Path to true.
                    $Directory_Valid = $True
                } else {
                    # Else warn the user that the path they specified is not valid.
                    Write-Warning "The path you specified contains invalid characters and cannot be used or created."
                }
                if (Test-Path -PathType Container $Move_To_Directory) {
                    # If $Move_To_Directory contains a folder path set $Is_Directory to true.
                    $Is_Directory = $True
                } else {
                    # Else warn the user that the path they specified is not valid.
                    Write-Warning "The path you specified does not point to a directory."
                }
                # If both $Valid_Path and $Is_Directory are true then set $Valid_Directory to true.
                if (($Directory_Valid) -and ($Is_Directory)) {
                    $Valid_Directory = $True
                }
            # Condition is met if the $Valid_Directory is true.
            } until ($Valid_Directory)
        }
    }

    # If $Move_To_Directory exists then do as follows.
    $Caught_Error = $False
    if (Test-Path $Move_To_Directory) {
        # If $Move_To_Directory exists and is a directory then do as follows.
        if (Test-Path -PathType Container $Move_To_Directory) {
            # If there are files or folders within $Move_To_Directory do as follows.
            if (((Get-ChildItem $Move_To_Directory -Recurse | Measure-Object).Count) -ge 1) {
                # Loop until condition is met.
                do {
                    # Create subfolder name using current date and time.
                    $Subfolder = "New Templates ($((Get-Date -UFormat '%Y-%m-%d@%I-%M-%S-%p').ToString()))"
                # Condition is met if $Subfolder within $Move_To_Directory does not exist.
                } until (-not (Test-Path $(Join-Path -Path $Move_To_Directory -ChildPath $Subfolder)))
                Write-Warning "'$Move_To_Directory' already exists and is not empty."
                Write-Warning "To avoid possible conflicts a new subfolder will be made as with the current time and date."
                # Set new $Move_To_Directory using new $Subfolder variable.
                $Move_To_Directory = Join-Path -Path $Move_To_Directory -ChildPath $Subfolder
            }
        # Else if $Move_To_Directory exists but is not a directory do as follows.
        } else {
            try {
                # Attempt to remove all items within $Move_To_Directory.
                Get-ChildItem $Move_To_Directory -Recurse -ErrorAction Stop | Remove-Item -Recurse -Force -ErrorAction Stop
                # Attempt to remove $Move_To_Directory
                Remove-Item $Move_To_Directory -Recurse -Force -ErrorAction SilentlyContinue
            } catch [System.UnauthorizedAccessException] {
                # Write error and warning if user is not allowed to create $Move_To_Directory.
                Write-Error "Permission Denied: Cannot access '$Move_To_Directory'"
                Write-Warning "Cannot remove old save directory, script will clean up any left over files and then exit."
                $Caught_Error = $True
            }
        }
    }

    # If $Move_To_Directory doesn't exist do as follows.
    if (-not (Test-Path $Move_To_Directory)) {
        try {
            # Attempt to make new $Move_To_Directory directory.
            New-Item -ItemType Directory -Path $Move_To_Directory -ErrorAction Stop
        } catch [System.UnauthorizedAccessException] {
            # Write error and warning if user is not allowed to create $Move_To_Directory.
            Write-Error "Permission Denied: Cannot create '$Move_To_Directory'"
            Write-Warning "Cannot create save directory, script will clean up any left over files and then exit."
            $Caught_Error = $True
        }
    }

    # If $Caught_Error is not true do as follows.
    if (-not ($Caught_Error)) {
        # Get all items within $Save_Directory and move them to $Move_To_Directory
        Get-ChildItem $Save_Directory -Recurse | Move-Item -Destination $Move_To_Directory -Force
        # Open $Move_To_Directory as a folder for the user to view.
        Invoke-Item $Move_To_Directory
    }
}

finally {
    # Run Clean-Up function.
    Clean-Up
}
