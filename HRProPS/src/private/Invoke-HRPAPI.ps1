Function Invoke-HRPAPI {
<#
.SYNOPSIS
Sends a request to the HR Pro web service.

.DESCRIPTION
Sends a request to the HR Pro web service. The function will attempt to reauthenticate and retry the request up to 3 times if a 401 Unauthorized response is received.

.PARAMETER Uri
Specifies the Uniform Resource Identifier (URI) of the resource to which the web request is sent.

.PARAMETER Method
Specifies the method used for the web request. The acceptable values for this parameter are:
- GET
- PUT
- POST
- DELETE

.PARAMETER Paginate
Iterates through page numbers until all results are returned. If not supplied, only the first page of results will be returned.

.EXAMPLE
Invoke-HRPAPI -Uri "https://api.hrapi.co.uk/api/Employees/" -Method GET -Paginate

This command retrieves all employee records from the HR Pro API, handling pagination to ensure that all records are returned.
#>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string] $Uri,
        [Parameter(Mandatory = $true)]
        [ValidateSet("GET", "PUT", "POST", "DELETE")]
        [string] $Method,
        [Parameter(Mandatory = $false)]
        [switch] $Paginate
    )

    Begin {
        $retry          = $true
        $retryCounter   = 0
        $retryLimit     = 3
        $pageSize       = 200
    }

    Process {
        while ($retry -and $retryCounter -lt $retryLimit) {
            $retryCounter++
            try {
                $response = Invoke-RestMethod -Uri $Uri -Method $Method -Headers $script:Token.Header
                $retry = $false
            }
            catch [Microsoft.PowerShell.Commands.HttpResponseException] {
                if ($_.Exception.Response.StatusCode.value__ -eq '401') {
                    $status = $_.Exception.Response.StatusCode.value__

                    if ($status -eq 401) {
                        Write-Verbose "401 Unauthorized - attempting reauthentication"
                        Get-HRPToken
                    }
                    else {
                        throw $_.Exception
                    }
                } 
            }
            catch {
                throw $_.Exception
            }
        }

        if (-not $response) {
            [System.Collections.Generic.List[object]]::new()
        }

        $data = [System.Collections.Generic.List[object]]::new()
        if ($response -is [System.Collections.IEnumerable] -and -not ($response -is [string])) {
            $data.AddRange($response)
        }
        else {
            $data.Add($response)
        }

        if ($Paginate -and $response.Count -eq $pageSize) {
            $page = 2

            do {
                $nextUri = "$Uri/$page"
                $presponse = Invoke-RestMethod -Uri $nextUri -Method $Method -Headers $script:Token.Header

                if ($presponse.Count -gt '0') {
                    $data.AddRange($presponse)
                    $page++
                }
            }
            while ($presponse.Count -eq $pageSize)
        }
        $data
    }
}