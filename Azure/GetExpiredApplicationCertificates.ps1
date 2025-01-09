# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Directory.Read.All","Application.Read.All" -NoWelcome

# Get the application certificate using Microsoft Graph API
$apps = Get-MgServicePrincipal 

# Get the current date and time
$currentDateTime = Get-Date

# Iterate through each certificate
foreach ($app in $apps) {
    foreach ($key in ($app.KeyCredentials | Where-Object {$_.Usage -eq "Sign"})){
        $expiryDate = $key.EndDateTime
        if ($expiryDate -lt $currentDateTime) {
            # Delete the expired certificate
            try {
                Write-Host "Expired certificate exists for app `"$($app.displayName)`" with an expiry date of $($key.EndDateTime)."
            }
            catch {
                Write-Host $_.Exception
            }
        }
    }
}