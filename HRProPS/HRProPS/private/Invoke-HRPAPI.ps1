Function Invoke-HRPAPI {
  <#
    .SYNOPSIS
       Sends a request to the HR Pro web service.
    .DESCRIPTION
      Sends a request to the HR Pro web service. This function will handle authentication headers, as well as pagination. 
    .PARAMETER Uri
      Specifies the Uniform Resource Identifier (URI) of the resource to which the web request is sent.
    .PARAMETER Method
      Specifies the method used for the web request. The acceptable values for this parameter are:
      - GET
      - PUT
      - POST
      - DELETE
    .PARAMETER Paginate
      Iterates through page numbers until all results are returned.
    .EXAMPLE
      Invoke-HRPAPI -Uri "https://api.hrapi.co.uk/api/Employees/" -Method GET -Paginate
  #>

    [CmdletBinding()]
    Param(
      [Parameter(Mandatory = $true)]
      [string] $Uri,
      [Parameter(Mandatory = $true)]
      [ValidateSet("GET","PUT","POST","DELETE")]
      [string] $Method,
      [Parameter(Mandatory = $false)]
      [switch] $Paginate
    )

  Begin {
    $retry = $true
    $retryCounter = 0
    $retryLimit = 3
  }

  Process {
    while ($retry -and $retryCounter -lt $retryLimit){
      $retryCounter++
      try {
        $response = Invoke-RestMethod -Uri $Uri -Method $Method -Headers $script:Token.Header
        $retry = $false
      }
      catch [Microsoft.PowerShell.Commands.HttpResponseException] {
        if ($_.Exception.Response.StatusCode.value__ -eq '401'){
          Write-Verbose -Message "$($_.Exception.Message) - Attempting to reauthenticate"
          Get-HRPToken
        } 
      }
      catch {
        throw $_.Exception.Message
      }
    }
    $data = [System.Collections.Generic.List[object]]::new()
    foreach ($r in $response){
      $data.Add($r)
    }

    if ($Paginate){
      <#
        The first results page number can be either '0' or '1', the results are the same. The next page after the first will always be 2. 
        We only want to go to the next page if the results count -eq '200' as this is the limit. We will continue incrementing the page number
        until no more results are returned.
      #>
      $maxResults = '200'
      if ($response.count -eq $maxResults){
        $page = 2
        do {
          $nextUri = "$Uri/$page"
          $presponse = Invoke-RestMethod -Uri $nextUri -Method $Method -Headers $script:Token.Header
          if ($presponse.Count -gt '0'){
            foreach ($p in $presponse){
              $data.Add($p)
            }
            $page++
          }
        }
        until ($presponse.Count -eq '0' -or $response.Count % 200 -ne '0')
      }
    }
    $data
  }
      
  END {}
}
