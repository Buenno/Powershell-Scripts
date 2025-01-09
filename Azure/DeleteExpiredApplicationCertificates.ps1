<#For key credentials: the normal method is to use Remove-MgServicePrincipalKey, 
however it requires a "proof of possession" for which you need to have access to 
the private key which will not always be possible. In that case, you can circumvent 
this by first obtaining the key credentials array with 
$keycredentials = (Get-MgServicePrincipal -ServicePrincipalId <objectid>).KeyCredentials, 
then removing the undesired one(s) from $keycredentials, and finally by applying this new 
array with Update-MgServicePrincipal -ServicePrincipalId <objectid> -KeyCredentials $keycredentials. 
To clear all you can use simply: Update-MgServicePrincipal -ServicePrincipalId <objectid> -KeyCredentials @().
For password credentials: Remove-MgServicePrincipalPassword (which does not have the same issue)
#>

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Directory.ReadWrite.All","Application.ReadWrite.All"

# Define the Application (Service Principal) object ID
$appName = Read-Host "Enter enterprise application name"

# Get the application certificate using Microsoft Graph API
$appCertificates = (Get-MgServicePrincipal -Filter "DisplayName eq '$appName'").KeyCredentials | Where-Object {$_.Usage -eq "Sign"}

# Get the current date and time
$currentDateTime = Get-Date

# Iterate through each certificate
foreach ($certificate in $appCertificates) {
    $expiryDate = $certificate.EndDateTime
    $params = @{
        keyId = "192147cb-3a62-43c7-bd5c-7dbd8dd302e1"
        proof = "5a17dc37-51b6-4692-92a6-31acf77835bb"
    }

    # Check if the secret has expired
    if ($expiryDate -lt $currentDateTime) {
        # Delete the expired certificate
        try {
            Remove-MgServicePrincipalKey -ServicePrincipalId $servicePrincipalId -KeyId $certificate.KeyId -ErrorAction Stop
            Write-Host "Expired certificate $($certificate.displayName) - $($certificate.EndDateTime) deleted."
    
        }
        catch {
            Write-Host $_.Exception
        }
    }
}