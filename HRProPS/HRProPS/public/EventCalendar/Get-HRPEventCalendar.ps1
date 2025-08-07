Function Get-HRPEventCalendar {
  <#
    .SYNOPSIS
      Returns a list of Event Calendar items for the specified employee
    .DESCRIPTION
      Returns a list of Event Calendar items for the specified employee.
    .EXAMPLE
      Get-HRPEventCalendar -ID 63635 
    .LINK
      https://api.hrapi.co.uk/swagger/ui/index#!/EventCalendar/EventCalendar_Get
  #>

    [CmdletBinding(DefaultParameterSetName = 'Year')]
    Param(
      [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
      [Alias('EmployeeID')]
      [string] $ID,
      [Parameter(Mandatory = $true, ParameterSetName = 'Year', ValueFromPipelineByPropertyName = $true)]
      [datetime] $Year,
      [Parameter(Mandatory = $true, ParameterSetName = 'Date', ValueFromPipelineByPropertyName = $true)]
      [datetime] $DateFrom,
      [Parameter(Mandatory = $true, ParameterSetName = 'Date', ValueFromPipelineByPropertyName = $true)]
      [datetime] $DateTo
    )
  Begin {
    if ($PSCmdlet.ParameterSetName -eq "Year"){
      $Uri = "https://api.hrapi.co.uk/api/Event-Calendar/$ID/$($Year.Year)"
    }
    else {
      $from = $DateFrom.ToString("yyyy-MM-ddT00:00:00")
      $to = $DateTo.ToString("yyyy-MM-ddT00:00:00")
      $Uri = "https://api.hrapi.co.uk/api/Event-Calendar/$($ID)?dateFrom=$From&dateTo=$To"
    }
  }
  Process {
    $response = Invoke-HRPAPI -Uri $Uri -Method GET -ErrorAction Stop
    $response
  } 
}
