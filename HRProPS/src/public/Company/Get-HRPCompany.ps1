Function Get-HRPCompany {
<#
.SYNOPSIS
Returns company data.

.DESCRIPTION
Returns company data.

.EXAMPLE
Get-HRPCompany

.LINK
https://api.hrapi.co.uk/swagger/ui/index#!/Company/Company_Get
#>

    [CmdletBinding()]
    Param()

  Process {
    $response = Invoke-HRPAPI -Uri "https://api.hrapi.co.uk/api/Company" -Method GET -ErrorAction Stop
    $response
  } 
}