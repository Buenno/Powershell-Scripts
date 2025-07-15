<#
.SYNOPSIS
    Enables or disables group notifications for Securly alert group members
    
.NOTES
    Author: Toby Williams
    Date: 02-10-2024
    Version: 1.2
            1.0: Basic Script
            1.1: Added Get-TermStatus function to make script more dynamic. Can now determine term status so you no longer need to pass in the status manually
            1.2: Switched out Send-MailKitMessage for Send-GmailMessage due to conflicting BouncyCastle.Cryptography assemblies 
#>

$ErrorActionPreference = 'Stop'

Function Get-TermStatus {
    <#
    .SYNOPSIS
        Returns the current term status (In Term, Holiday, Half Term etc.)
     
    .NOTES
        Name: Get-TermStatus
        Author: Toby Williams
        Version: 1.0
        DateCreated: 25/04/2025
     
    .EXAMPLE
        Get-TermStatus
    #>
     
    [CmdletBinding()]
    param()
    
    BEGIN {
        $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
    }
    
    PROCESS {
        $url = "https://theabbey.co.uk/the-abbey-all-girls/term-dates/"
        $html = ConvertFrom-HTML -Url $url -Engine AngleSharp

        $termHeadings = $html.GetElementsByTagName("H3") | Where-Object {$_.InnerHTML -like "*Term*"}
        $events = New-Object System.Collections.Generic.List[PSObject]  

        foreach ($heading in $termHeadings){
            $termYear = $heading.TextContent.Split(" ")[2]
            # Parse the unordered list below each heading
            # Use a switch statement to avoid overdoing it with if/else statements
            foreach ($row in $heading[0].NextElementSibling.TextContent.Trim("").Split("`n")){
                switch -Wildcard ($row){
                    "*Induction Day*"           {$eventType =  "Induction"}
                    "*Term begins for pupils*"  {$eventType = "In Term"}
                    "*Term ends*"               {$eventType = "Term End"}
                    "*Last day of school*"      {$eventType = "Term End"}
                    "Half Term*"                {$eventType = "Half Term"}
                    "*Bank Holiday"             {$eventType = "Bank Holiday"}
                    default                     {$eventType = "Skip"}
                }
                # Half term records start and end are on the same row, so these must be split
                if ($eventType -eq "Half Term"){
                    $eventObj = [PSCustomObject]@{
                        Type = "Half Term"
                        Date = [datetime]::ParseExact(($row.Split(" ")[2..4] + $termYear), "dddd d MMMM yyyy", $null)
                        Term = $heading.TextContent.Split(" ")[0]
                    }
                    $events.Add($eventObj)
                    
                    $eventObj = [PSCustomObject]@{
                        Type = "In Term"
                        Date = [datetime]::ParseExact(($row.Split(" ")[6..8] + $termYear), "dddd d MMMM yyyy", $null).AddDays(1)
                        Term = $heading.TextContent.Split(" ")[0]
                    }
                    $events.Add($eventObj)
                }
                elseif ($eventType -eq "Term End"){
                    $eventObj = [PSCustomObject]@{
                        Type = "Holiday"
                        Date = [datetime]::ParseExact(($row.Split(" ")[0..2] + $termYear), "dddd d MMMM yyyy", $null).AddDays(1)
                        Term = $heading.TextContent.Split(" ")[0]
                    }
                    $events.Add($eventObj)
                }
                elseif ($eventType -eq "Bank Holiday"){
                    $eventObj = [PSCustomObject]@{
                        Type = "Bank Holiday"
                        Date = [datetime]::ParseExact(($row.Split(" ")[0..2] + $termYear), "dddd d MMMM yyyy", $null)
                        Term = $heading.TextContent.Split(" ")[0]
                    }
                    $events.Add($eventObj)
                    $eventObj = [PSCustomObject]@{
                        Type = "In Term"
                        Date = [datetime]::ParseExact(($row.Split(" ")[0..2] + $termYear), "dddd d MMMM yyyy", $null).AddDays(1)
                        Term = $heading.TextContent.Split(" ")[0]
                    }
                    $events.Add($eventObj)
                }
                elseif ($eventType -ne "Skip") {
                    $eventObj = [PSCustomObject]@{
                        Type = $eventType
                        Date = [datetime]::ParseExact(($row.Split(" ")[0..2] + $termYear), "dddd d MMMM yyyy", $null)
                        Term = $heading.TextContent.Split(" ")[0]
                    }
                    $events.Add($eventObj)
                }
            }
        }

        $currentDate = Get-Date

        for (($a = 0), ($b = 1); $b -lt $events.Count; $a++, $b++){
            if (($events[$a].Type -eq "Induction") -and ($events[$b].Type -eq "In Term")){
                $events[$b].Date = $events[$a].Date
                $events.RemoveAt($a)
            }
            if (($currentDate -ge $events[$a].Date) -and ($currentDate -le $events[$b].Date)){
                return $events[$a].Type
            }
        }
    }
    
    END {}
}

function Get-HTMLBody {
    Param
    (
    [Parameter(Mandatory=$true)]
    [string]$GroupName
    )
    $htmlBody = Get-Content -Encoding UTF8 "$PSScriptRoot\emailTemplate.html" | Out-String
    $htmlBody = $htmlBody.Replace("{0}","$GroupName")
    
    return $htmlBody 
}

function Write-Log {
    Param
    (
    [Parameter(Mandatory=$true)]
    [string]$Message
    )
    $fileDate = Get-Date -Format "yyyy-MM-dd"
    $logPath = "$PSScriptRoot\logs\securly_group_update_$fileDate.log"
    $timestamp =  Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp - $Message"
    Add-Content -Path $LogPath -Value $logEntry -Force
}

function Remove-Logs {
    $filesToKeep = 14
    $logPath = "$PSScriptRoot\logs\"
    $logs = Get-ChildItem -Path $logPath -Filter *.log
    if ($logs.count -gt $filesToKeep){
        $toDelete = ($logs.count - $filesToKeep)
        $logs | Sort-Object LastWriteTime | Select-Object -First $toDelete | Remove-Item -Force
    }
}

Import-Module PSGSuite, PSParseHTML -ErrorAction SilentlyContinue
Write-Log -Message "Module import complete"

# Create log dir if not exist
$logPath = "$PSScriptRoot\logs\"
if (!(Test-Path -Path $logPath -PathType Container)){
    New-Item -Path $logPath -ItemType Directory -Force
}

# Define email params for errors
$ErrMailParams = @{
    "To" =  "williamsto+error@theabbey.co.uk"    
}

# Calculate the $deliverySetting based on day of week and term status
$date = Get-Date
$start = Get-Date "08:00"
$end = Get-Date "17:00"
$isWeekend = $false
$isSchoolTime = $false

try {
    $termStatus = Get-TermStatus
}
catch {
    $errTxt = "Error encountered when attempting to obtain term status information"
    Write-Log $errTxt
    $ErrMailParams.Add("Subject", "ERROR: Securely Notifications")
    $ErrMailParams.Add("TextBody", $errTxt) 
    Send-GmailMessage @ErrMailParams
    throw 
}

if ($date.DayOfWeek -match "Saturday|Sunday"){
    $isWeekend = $true
}

if (($start.TimeOfDay -le $date.TimeOfDay) -and ($end.TimeOfDay -ge $date.TimeOfDay)){
    $isSchoolTime = $true
}

if (($termStatus -eq "In Term") -and (!$isWeekend) -and ($isSchoolTime)){
    # Enable Notifications
    $deliverySetting = "ALL_MAIL"
}
else {
    # It's either the weekend, half term, or holiday so disable notifications
    $deliverySetting = "NONE"
}
Write-Log -Message "Term status = $termStatus, isWeekend = $isWeekend, isSchoolTime = $isSchoolTime"
Write-Log -Message "Starting Securly group subscription update process"

# Get the Securly alerts email groups 
try {
    Write-Log -Message "Getting Securly notification groups"
    $groups = Get-GSGroup -Filter "email:securly-alerts*" -
    Write-Log -Message "The following groups were returned: $($groups.Name)"
}
catch {
    Write-Log -Message "An error was encountered when attempting to get group information - $($_.Exception.InnerException.Message)"
    throw
}

foreach ($group in $groups){
    $groupURL = ($group.Email -split "@")[0]
    $RecipientList = New-Object System.Collections.ArrayList  
    try {
        Write-Log -Message "Getting members of $($group.Name)"
        $groupMembers = Get-GSGroupMember -Identity $group.Id | Out-Null
    }
    catch {
        Write-Log -Message "Unable to get members of group $($group.Name)"
        $ErrMailParams.Add("Subject", "ERROR: Securely Notifications - $($group.Name)")
        $ErrMailParams.Add("TextBody", "Unable to get members of group $($group.Name)") 
        Send-GmailMessage @ErrMailParams 
        throw
    }    
    if ($groupMembers){
        foreach ($member in $groupMembers){
            Write-Log -Message "Updating group subscription setting for $($member.Email)"
            try {
                Update-GSGroupMember -Identity $group.Id -Member $member.Email -DeliverySettings $deliverySetting | Out-Null
                Write-Log -Message "Subscription successfully set to $deliverySetting"
                $RecipientList.Add("$($member.Email)")
            }
            catch {
                Write-Log "Error encountered when attempting to update group subscription for $($member.Email) - $_"
                $ErrMailParams.Add("Subject", "ERROR: Securely Notifications - $($group.Name)")
                $ErrMailParams.Add("TextBody", "Error encountered when attempting to update group subscription for $($member.Email) - $_") 
                Send-GmailMessage @ErrMailParams 
                throw
            }
        } 
        if ($deliverySetting -eq "ALL_MAIL"){
            # Subscriptions enabled, send notification to members
            Write-Log -Message "Notifying members of subscription re-enablement"
            try {
                Send-GmailMessage -To $RecipientList -Subject "Securely Notifications Enabled - $($group.Name)" -BodyAsHtml "$(Get-HTMLBody -GroupName $groupURL)"
                Write-Log -Message "Email sent"
            }
            catch {
                Write-Log -Message "Error encountered when attempting to send notification email - $_"
                throw
            }
        }
    }
    else {
        # No members in this group
        Write-Log -Message "No members found"
    }
}
Write-Log -Message "Process complete"
Remove-Logs