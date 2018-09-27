Class AzureCredential {
    [string]$UserName = 'hunter'
    [string]$Password = 'Pa11word'
}

Function Set-AzureCredential {
    return [AzureCredential]::new()
}

Export-ModuleMember -Function 'Set-AzureCredential'