Class Credentials {
    [string]$UserName = 'hunter'
    [string]$Password = 'Pa11word'
}

Function Set-Credentials {
    return [Credentials]::new()
}

Export-ModuleMember -Function 'Set-Credentials'