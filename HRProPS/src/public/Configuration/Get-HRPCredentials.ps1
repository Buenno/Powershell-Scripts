function Get-HRPCredentials {
<#
.SYNOPSIS
Retrieves the stored HR Pro API credentials.

.DESCRIPTION
The Get-HRPCredentials function retrieves the PSCredential object previously
stored in the SecretManagement/SecretStore vault named "HRProPS".

The credential must have been stored using Set-HRPCredentials.  
If the vault or secret does not exist, the function will throw a clear error.

This function does not take any parameters.

.EXAMPLE
$cred = Get-HRPCredentials

Retrieves the stored HR Pro API credentials and assigns them to $cred.

.NOTES
This function requires the following modules:
- Microsoft.PowerShell.SecretManagement
- Microsoft.PowerShell.SecretStore

The credential is expected to be stored under the secret name:
HRProPS

#>
    [CmdletBinding()]
    param()

    $vaultName = "HRProPS"
    $secretName = "HRProPS"

    if (-not (Get-Module -ListAvailable -Name Microsoft.PowerShell.SecretManagement)) {
        throw "Microsoft.PowerShell.SecretManagement module is not installed."
    }
    if (-not (Get-Module -ListAvailable -Name Microsoft.PowerShell.SecretStore)) {
        throw "Microsoft.PowerShell.SecretStore module is not installed."
    }

    $vault = Get-SecretVault -Name $vaultName -ErrorAction SilentlyContinue
    if (-not $vault) {
        throw "The SecretStore vault `"$vaultName`" does not exist. Run Set-HRPCredentials first."
    }

    $secretExists = Get-SecretInfo -Vault $vaultName -Name $secretName -ErrorAction SilentlyContinue
    if (-not $secretExists) {
        throw "No HR Pro credentials were found in vault `"$VaultName`". Run Set-HRPCredentials first."
    }

    Write-Verbose "Retrieving HR Pro API credentials from vault '$vaultName'."
    Get-Secret -Name $secretName -Vault $vaultName -ErrorAction Stop
}
