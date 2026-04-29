Function Get-HRPToken {
<#
.SYNOPSIS
Requests an Access Token for REST API authentication.

.DESCRIPTION
Requests an Access Token for REST API authentication. Returns an object containing the token, as well as auth headers suitable for future API calls.
Credentials are obtained from the configuration stored in the `$script:HRProPS` variable, which is populated by Get-HRPConfig.

.EXAMPLE
Get-HRProAuthToken

.LINK
https://api.hrapi.co.uk/swagger/ui/index#!/Token/Token_Get
#>

    [CmdletBinding()]
    Param()

    Begin {
        # Get the API credentials from stored configuration
        $credentials = $script:HRProPS

        # Create headers for API call
        $auth = "{0} : {1}" -f $credentials.Username, $credentials.Password
        $encoded = [Text.Encoding]::UTF8.GetBytes($auth)
        $authorizationInfo = [Convert]::ToBase64String($encoded)
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
            Token  = $token.access_token
            Header = @{
                "Authorization" = "Bearer $($token.access_token)"
                "grant_type"    = "access_token"
            }
        }
    
        # Store authentication object
        $script:Token = $tokenObject
    }
}
