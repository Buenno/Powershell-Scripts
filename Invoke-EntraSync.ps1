Function Invoke-EntraSync {
<#
.SYNOPSIS
    Syncronise on-prem AD with Entra 
 
 
.NOTES
    Name: Invoke-EntraSync
    Author: Toby Williams
    Version: 1.0
    DateCreated: 01/10/2024
 
 
.EXAMPLE
    Invoke-EntraSync
 
#>
 
    [CmdletBinding()]
    [Alias("Start-ADSyncSyncCycle")]
    [Alias("Invoke-ADSync")]
    [Alias("Invoke-AzureADSync")]
    param()
 
    BEGIN {
        $ErrorActionPreference = "Stop"
        $server = ""
    }
 
    PROCESS {
        try {
            Write-Host "Starting Entra AD sync..."
            $command = Invoke-Command -ComputerName $server -ScriptBlock {Start-ADSyncSyncCycle -PolicyType delta}
            if ($command.Result -eq "Success") {
                Write-Host "Sync completed successfully" -ForegroundColor Green
            }
            else {
                Write-Error "There was an issue executing the sync command. Check remote logs for more details." -ForegroundColor yellow
            }
        }
        catch {
            Write-Error "Sync failed. $_"
        }
    }
 
    END {}
}