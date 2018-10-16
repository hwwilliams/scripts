[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [Parameter(Position = 1)]
    [string] $URL,
    [switch] $DecodeURL
)

Add-Type -AssemblyName System.Web

if ($DecodeURL) {
    [System.Web.HttpUtility]::UrlDecode("$URL")
}
else {
    [System.Web.HttpUtility]::UrlEncode("$URL")
}
