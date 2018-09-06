# Two passable script arguments
# - ConfirmSave: If this argument is passed then the script will default to saving to the directory
#   defined in the '$Move_To_Directory' variable.
# - CallLogYear: If passed with a 4 digit number ranging from 1000-2999,
#   the valid year will be appended to the file name of all Excel files created.
[CmdletBinding()]
Param (
    [Switch] $ConfirmSave = $True,
    [ValidatePattern('^[12][0-9]{3}$')]
    [Int] $Year = 2018
)

## General Dictionaries, Variables, and Other Declarations
# The Move_To_Directory variable is the default save location, currently it makes a folder and
# saves to it within the currently logged in user's documents folder.
$Move_To_Directory = "C:\Users\$env:username\Documents\Call log templates$(if ($Year) {" $Year"})\"
$Valid_Directory_Regex = '^[a-z]:[/\\][^{0}]*$' -f [Regex]::Escape(([IO.Path]::InvalidPathChars -Join ''))

# Excel ComObject Conditions and Operators
Add-Type -AssemblyName Microsoft.Office.Interop.Excel
$Between_Operator = [Microsoft.Office.Interop.Excel.XlFormatConditionOperator]::xlBetween
$Cell_Value_Condition = [Microsoft.Office.Interop.Excel.XlFormatConditionType]::xlCellValue
$Equal_Operator = [Microsoft.Office.Interop.Excel.XlFormatConditionOperator]::xlEqual
$Excel_Format = [Microsoft.Office.Interop.Excel.XlFileFormat]::xlWorkbookDefault
$Excel_Instance = New-Object -ComObject Excel.Application
$Excel_Instance.Visible = $False
$Excel_Instance.DisplayAlerts = $False
$Excel_Instance.ScreenUpdating = $False
$Excel_Instance.UserControl = $False
$Excel_Instance.Interactive = $False
$Not_Equal_Operator = [Microsoft.Office.Interop.Excel.XlFormatConditionOperator]::xlNotEqual

# Excel ComObject Colors
$RoyalBlue = [Microsoft.Office.Interop.Excel.XlRgbColor]::rgbLightSkyBlue
$LimeGreen = [Microsoft.Office.Interop.Excel.XlRgbColor]::rgbLimeGreen
$Yellow = [Microsoft.Office.Interop.Excel.XlRgbColor]::rgbYellow

# Hashtables (Dictionaries)
$A_To_K = @(); for ([byte]$i = [char]'A'; $i -le [char]'K'; $i++) { $A_To_K += [char]$i }
$Months_Days = @{
    # January = 31
    Febuary = 5
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

Function New-TemporaryDirectory {
    $Temp_Parent_Path = [System.IO.Path]::GetTempPath()
    [String] $Temp_Name = [System.Guid]::NewGuid()
    New-Item -ItemType Directory -Path (Join-Path -Path $Temp_Parent_Path -ChildPath $Temp_Name)
}

Function Receive-Output($Color) {
    Process { Write-Host $_ -ForegroundColor $Color }
}

$Work_Directory = New-TemporaryDirectory
$Save_Directory = Join-Path -Path $Work_Directory -ChildPath 'Done'
if (-Not (Test-Path $Save_Directory)) {
    New-Item -ItemType Directory -Path $Save_Directory
}

# Add a workbook to the Excel instance we made and then for each day in the range of 1 to 27 make a sheet inside that workbook.
# We do 1 to 27 because the new workbook starts with one empty sheet and when we're done that'd be a total of 28 sheets which
# makes up the base of our template because 28 days is the lowest number of days we'd need, i.e. Febuary.
$Workbook = $Excel_Instance.Workbooks.Add()
ForEach ($Day in 1..$($Months_Days['Febuary'] - 1)) {
    $Workbook.Worksheets.Add([System.Reflection.Missing]::Value, $Workbook.Worksheets.Item($Workbook.Worksheets.Count))
}
# A variable is set for the path to the new template workbook, it is then saved and closed.
$Temp_Workbook = Join-Path -Path $Work_Directory -ChildPath "Temp Workbook.xlsx"
$Workbook.SaveAs($Temp_Workbook, $Excel_Format)
$Workbook.Close()

# Build each monthly workbook
ForEach ($Items in $Months_Days.GetEnumerator()) {
    $Month = $Items.Key
    $Days = $Items.Value
    $Workbook = $Excel_Instance.Workbooks.Open($Temp_Workbook)
    $Missing_Sheets = $Days - $Workbook.Worksheets.Count
    if ($Missing_Sheets -ge 1) {
        ForEach ($Missing_Sheet in 1..$Missing_Sheets) {
            $Workbook.Worksheets.Add([System.Reflection.Missing]::Value, $Workbook.Worksheets.Item($Workbook.Worksheets.Count))
        }
    }
    ForEach ($Day in 1..$Days) {
        (($Workbook.Worksheets.Item($Day)).Range('f4:f999')).FormatConditions.Add($Cell_Value_Condition, $Equal_Operator, 'aa')
        (($Workbook.Worksheets.Item($Day)).Range('f4:f999')).FormatConditions.Item(1).Interior.Color = $LimeGreen
        (($Workbook.Worksheets.Item($Day)).Range('f4:f999')).FormatConditions.Item(1).Font.ColorIndex = 1
        (($Workbook.Worksheets.Item($Day)).Range('f4:f999')).FormatConditions.Item(1).Font.Bold = $True
        (($Workbook.Worksheets.Item($Day)).Range('f4:f999')).FormatConditions.Add($Cell_Value_Condition, $Not_Equal_Operator, '=ISTEXT(f4:f999)')
        (($Workbook.Worksheets.Item($Day)).Range('f4:f999')).FormatConditions.Item(2).Interior.Color = $RoyalBlue
        (($Workbook.Worksheets.Item($Day)).Range('f4:f999')).FormatConditions.Item(2).Font.ColorIndex = 1
        (($Workbook.Worksheets.Item($Day)).Range('f4:f999')).FormatConditions.Item(2).Font.Bold = $True
        $Count = 1
        ForEach ($Items in $Values_Colors.GetEnumerator()) {
            $Cell_Value = $Items.Key
            $Color = $Items.Value
            (($Workbook.Worksheets.Item($Day)).Range('g4:g999')).FormatConditions.Add($Cell_Value_Condition, $Equal_Operator, $Cell_Value)
            (($Workbook.Worksheets.Item($Day)).Range('g4:g999')).FormatConditions.Item($Count).Interior.Color = $Color
            (($Workbook.Worksheets.Item($Day)).Range('g4:g999')).FormatConditions.Item($Count).Font.ColorIndex = 1
            (($Workbook.Worksheets.Item($Day)).Range('g4:g999')).FormatConditions.Item($Count).Font.Bold = $True
            $Count++
        }
        (($Workbook.Worksheets.Item($Day)).Range('h4:h999')).FormatConditions.Add($Cell_Value_Condition, $Between_Operator, 1, 9999999999)
        (($Workbook.Worksheets.Item($Day)).Range('h4:h999')).FormatConditions.Item(1).Interior.ColorIndex = 1
        (($Workbook.Worksheets.Item($Day)).Range('h4:h999')).FormatConditions.Item(1).Font.ColorIndex = 2
        ($Workbook.Worksheets.Item($Day)).Columns('a').NumberFormat = "[$-x-systime]h:mm:ss AM/PM"
        ($Workbook.Worksheets.Item($Day)).Columns('e').NumberFormat = "[<=9999999]###-####;(###) ###-####"
        ($Workbook.Worksheets.Item($Day)).Cells.Item(1,1) = 'CALL LOG'
        ($Workbook.Worksheets.Item($Day)).Cells.Item(1,1).Font.Bold = $True
        $Count = 1
        ForEach ($Items in $Titles_Widths.GetEnumerator()) {
            $Title = $Items.Key
            $Width = $Items.Value
            ($Workbook.Worksheets.Item($Day)).Cells.Item(2,$Count) = $Title
            ($Workbook.Worksheets.Item($Day)).Cells.Item(2,$Count).ColumnWidth = $Width
            ($Workbook.Worksheets.Item($Day)).Cells.Item(2,$Count).Interior.ColorIndex = 1
            ($Workbook.Worksheets.Item($Day)).Cells.Item(2,$Count).Font.ColorIndex = 2
            ($Workbook.Worksheets.Item($Day)).Cells.Item(3,$Count).Interior.ColorIndex = 6
            $Count++
        }
        ForEach ($Letter in $A_To_K) {
            ($Workbook.Worksheets.Item($Day)).Columns("$Letter").HorizontalAlignment = -4108
        }
        $Workbook.Worksheets.Item($Day).Name = "$(
            if ($Month -eq 'September') {
                $Month.SubString(0,4)
            } else {
                $Month.SubString(0,3)
            }
        )-$Day"
    }
    $Workbook.SaveAs((Join-Path -Path $Save_Directory -ChildPath "$Month$(if ($Year) { " $Year" }).xlsx"), $Excel_Format)
    $Workbook.Close()
}
$Excel_Instance.Quit()


if ($ConfirmSave) {
    if (Test-Path $Move_To_Directory) {
        if (Test-Path -PathType Container $Move_To_Directory) {
            if (((Get-ChildItem $Move_To_Directory -Recurse | Measure-Object).Count) -ge 1) {
                do {
                    $Subfolder = "New Templates ($((([System.Guid]::NewGuid()).ToString()).Split('-')[-1]))"
                } until (-not (Test-Path $Subfolder))
                Write-Output "'$Move_To_Directory' already exists and is not empty, to avoid possible conflicts a new subfolder will be made as '$(Join-Path -Path $Move_To_Directory -ChildPath $Subfolder)'"
                $Move_To_Directory = Join-Path -Path $Move_To_Directory -ChildPath $Subfolder
                New-Item -ItemType Directory -Path $Move_To_Directory
            }
        } else {
            Get-ChildItem $Move_To_Directory -Recurse | Remove-Item -Recurse -Force
            Remove-Item $Move_To_Directory -Recurse -Force -ErrorAction SilentlyContinue
            New-Item -ItemType Directory -Path $Move_To_Directory
        }
    } else {
        New-Item -ItemType Directory -Path $Move_To_Directory
    }
} else {
    do {
        $Confirm_Move_To_Directory = Read-Host "Call log templates will be saved to '$Move_To_Directory', is this okay? (y/n)"
        if (-not ($Confirm_Move_To_Directory -like "y*" -or $Confirm_Move_To_Directory -like "n*")) {
            Write-Warning "Your answer must be Yes or No."
        }
    } until ($Confirm_Move_To_Directory -like "y*" -or $Confirm_Move_To_Directory -like "n*")
    Switch -Wildcard ($Confirm_Move_To_Directory) {
        "y*" {
            if (-not (Test-Path $Move_To_Directory)) {
                New-Item -ItemType Directory -Path $Move_To_Directory
            }
        }
        "n*" {
            do {
                $Move_To_Directory = Read-Host "Which directory would you like the Call log templates to be saved to? (Example: C:\Users\$env:username\Documents)"
                if (-not ($Move_To_Directory -match $Valid_Directory_Regex)) {
                    Write-Warning "The directory you specified contains invalid characters and cannot be used or created."
                }
            } until ($Move_To_Directory -match $Valid_Directory_Regex)
            if (-not (Test-Path $Move_To_Directory)) {
                Write-Output "This directory does not exist yet, creating as '$Move_To_Directory'"
                New-Item -ItemType Directory -Path $Move_To_Directory
            }
        }
    }
}

Get-ChildItem -Path $Save_Directory | Move-Item -Force -Destination $Move_To_Directory
Get-ChildItem $Work_Directory -Recurse | Remove-Item -Recurse -Force
Remove-Item $Work_Directory -Recurse -Force
Invoke-Item $Move_To_Directory
Write-Output "Call log templates saved to '$Move_To_Directory'" | Receive-Output Green
Write-Output "Exiting script." | Receive-Output Green
