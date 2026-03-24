Function Invoke-GCDSSync {
    <#
    .SYNOPSIS
        Syncronise on-prem AD with Google Workspace via GCDS app 
     
    .NOTES
        Name: Invoke-GCDSSync
        Author: Toby Williams
        Version: 1.0
        DateCreated: 24/09/2025
     
    .EXAMPLE
        Invoke-GCDSSync
     
    #>
     
    [CmdletBinding()]
    param(
        [Parameter()]
        [System.Management.Automation.PSCredential]$Credential
    )
    
    BEGIN {
        $ErrorActionPreference = "Stop"
        $server = "GCDS"
        if (!$Credential){
            $Credential = Get-Credential
        }
    }
    
    PROCESS {
        try {
            Write-Verbose "Starting Entra AD sync..."
            $command = Invoke-Command -ComputerName $server -ScriptBlock {Start-ADSyncSyncCycle -PolicyType delta} -Credential $Credential
            if ($command.Result -eq "Success") {
                Write-Verbose "Sync completed successfully" -ForegroundColor Green
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