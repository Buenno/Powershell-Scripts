Function Get-Something {
<#
.SYNOPSIS
    This is a basic overview of what the script is used for..
 
 
.NOTES
    Name: Get-Something
    Author: Toby Williams
    Version: 1.0
    DateCreated: 
 
 
.EXAMPLE
    Get-Something -UserPrincipalName "username@email.com"
 
 
.LINK
    https://URL
#>
 
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0
            )]
        [string[]]  $UserPrincipalName
    )
 
    BEGIN {
        $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
    }
 
    PROCESS {}
 
    END {}
}