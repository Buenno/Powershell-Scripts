function Get-NpsUserEvents {
<#
.SYNOPSIS
Retrieves NPS (Network Policy Server) authentication events for a specific user from a remote server.

.DESCRIPTION
This function queries the Security event log on a specified NPS server using Invoke-Command.
It retrieves common NPS-related event IDs (6272, 6273, 6278, 6279) and extracts structured
properties such as username, NAS identifier, network policy, and authentication details.

The output can be controlled using the View parameter:
- Info: returns a minimal set of commonly used fields
- Detailed: returns all parsed fields except the full message
- Full: returns all fields including the full raw event message

.PARAMETER Username
The username to search for in NPS event logs.

.PARAMETER NpsServer
The name of the remote NPS server to query. This is passed to Invoke-Command.

.PARAMETER View
Controls the amount of detail returned.
Valid values:
- Info (default): Returns Time, Username, NASID, NetworkPolicy, Summary
- Detailed: Returns all properties except FullMessage
- Full: Returns all properties including FullMessage

.EXAMPLE
Get-NpsUserEvents -Username "jdoe" -NpsServer "NPS01"

Returns a summarized view of NPS events for user 'jdoe'.

.EXAMPLE
Get-NpsUserEvents -Username "jdoe" -NpsServer "NPS01" -View Detailed

Returns detailed NPS event data excluding the full message text.

.EXAMPLE
Get-NpsUserEvents -Username "jdoe" -NpsServer "NPS01" -View Full

Returns full NPS event data including the raw event message.

.NOTES
- Requires appropriate permissions to read the Security log on the remote server.
- Uses PowerShell remoting (WinRM), which must be enabled on the target server.
- Event property indexes are based on standard NPS schema and may vary slightly
  between Windows Server versions.

#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Username,

        [Parameter(Mandatory = $true)]
        [string]$NpsServer,

        [ValidateSet("Info","Detailed","Full")]
        [string]$View = "Info"
    )

    Invoke-Command -ComputerName $NpsServer -ScriptBlock {
        param ($Username, $View)

        $eventIds = 6272, 6273, 6278, 6279

        Get-WinEvent -FilterHashtable @{
            LogName = 'Security'
            Id      = $eventIds
        } | ForEach-Object {

            $props   = $_.Properties
            $message = $_.Message
            $summary = ($message -split "`r?`n")[0]

            $fullObj = [PSCustomObject]@{
                Time             = $_.TimeCreated
                EventID          = $_.Id
                Username         = $props[1].Value
                NASID            = $props[11].Value
                NASIP            = $props[9].Value
                RadiusClientID   = $props[14].Value
                RadiusClientIP   = $props[15].Value
                ConnectionPolicy = $props[16].Value
                NetworkPolicy    = $props[17].Value
                AuthServer       = $props[19].Value
                AuthType         = $props[20].Value
                EAPType          = $props[21].Value
                ReasonCode       = $props[13].Value
                Summary          = $summary
                FullMessage      = $message
            }

            if ($fullObj.Username -ne $Username) {
                return
            }

            switch ($View) {
                "Info" {
                    [PSCustomObject]@{
                        Time          = $fullObj.Time
                        Username      = $fullObj.Username
                        NASID         = $fullObj.NASID
                        NetworkPolicy = $fullObj.NetworkPolicy
                        Summary       = $fullObj.Summary
                    }
                }

                "Detailed" {
                    $fullObj | Select-Object * -ExcludeProperty FullMessage
                }

                "Full" {
                    $fullObj
                }
            }

        }

    } -ArgumentList $Username, $View |
    Select-Object * -ExcludeProperty PSComputerName, RunspaceId, PSShowComputerName
}