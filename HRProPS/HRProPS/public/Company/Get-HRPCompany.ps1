Function Get-HRPCompany {
  <#
    .SYNOPSIS
      Returns Company data
    .DESCRIPTION
      Returns Company data
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