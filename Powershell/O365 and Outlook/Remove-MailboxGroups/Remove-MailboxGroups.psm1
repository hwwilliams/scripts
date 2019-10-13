
[CmdletBinding(DefaultParameterSetName = 'ByAll')]
Param (
    [Parameter(Position = 0, Mandatory = $True, ValueFromPipeline = $true)]
    [ValidateSet("Distribution", "Group")]
    [string] $UnitType,
    [Parameter(Position = 1, Mandatory = $True, ValueFromPipeline = $true, ParameterSetName = 'ByAll')]
    [switch] $All,
    [Parameter(Position = 2, Mandatory = $True, ValueFromPipeline = $true, ParameterSetName = 'ByName')]
    [string] $Name,
    [Parameter(Position = 3, Mandatory = $false, ValueFromPipeline = $true)]
    [string] $O365Username
)