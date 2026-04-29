function Set-HRPCredentials {
<#
.SYNOPSIS
Prompts for HR Pro API credentials and stores them securely.

.DESCRIPTION
The Set-HRPCredentials function prompts the user for a username and password using
Get-Credential, then securely stores the resulting PSCredential object in the
SecretManagement/SecretStore vault named "HRProPS".

If the vault does not already exist, it is created automatically.  
If a credential already exists under the secret name "HRProPS", it is overwritten.

This function does not take any parameters and does not store any configuration
metadata outside of the SecretStore vault.

.EXAMPLE
Set-HRPCredentials

Prompts the user for HR Pro API credentials and stores them securely in the
"HRProPS" SecretStore vault.

.NOTES
This function requires the following modules:
- Microsoft.PowerShell.SecretManagement
- Microsoft.PowerShell.SecretStore

The credential is stored under the secret name:
HRProPS

#>
    [CmdletBinding()]
    param()

    Write-Verbose "Prompting for HR Pro API credentials."
    $cred = Get-Credential -Message "Enter username and password for HR Pro API"

    if (-not (Get-Module -ListAvailable -Name Microsoft.PowerShell.SecretManagement)) {
        throw "Microsoft.PowerShell.SecretManagement module is not installed."
    }
    if (-not (Get-Module -ListAvailable -Name Microsoft.PowerShell.SecretStore)) {
        throw "Microsoft.PowerShell.SecretStore module is not installed."
    }

    $vaultName = "HRProPS"
    $vault = Get-SecretVault -Name $vaultName -ErrorAction SilentlyContinue

    if (-not $vault) {
        Write-Verbose "Vault '$vaultName' does not exist. Creating it now."

        Register-SecretVault -Name $vaultName `
                             -ModuleName Microsoft.PowerShell.SecretStore `
                             -DefaultVault `
                             -ErrorAction Stop
    }

    $secretName = "HRProPS"
    Write-Verbose "Storing credentials in vault '$vaultName' as secret '$secretName'."

    Set-Secret -Name $secretName -Secret $cred -Vault $vaultName -ErrorAction Stop
}
