Function Get-HRPToken {
  <#
    .SYNOPSIS
      Requests an Access Token for REST API authentication
    .DESCRIPTION
      Requests an Access Token for REST API authentication. Returns an object containing the token, as well as auth headers suitable for future API calls.
    .EXAMPLE
      Get-HRProAuthToken
  #>

    [CmdletBinding()]
    Param()

  Begin {
    # Get the API credentials from stored configuration
    $credentials = $script:HRProPS

    # Create headers for API call
    $auth = $credentials.Username + ':' + $credentials.Password
    $encoded = [System.Text.Encoding]::UTF8.GetBytes($auth)
    $authorizationInfo = [System.Convert]::ToBase64String($encoded)
    $headers = @{
      "Authorization" = "Basic $($authorizationInfo)"
      "grant_type"    = "password"
    }
  }
  Process {
    # Invoke API call to obtain authentication token
    $token = Invoke-RestMethod -Uri "https://api.hrapi.co.uk/api/token/" -Method GET -Headers $headers

    # Build an authentication header to be used in future API calls
    $tokenObject = [pscustomobject]@{
      Token     = $token.access_token
      Header = @{
          "Authorization" = "Bearer $($token.access_token)"
          "grant_type"    = "access_token"
      }
    }
    
    # Return authentication object
    $script:Token =  $tokenObject
  }
}
