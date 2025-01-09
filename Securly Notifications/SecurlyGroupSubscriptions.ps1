<#
.SYNOPSIS
    Disables Securly Notifications
.DESCRIPTION
    Disables Securly notifications by disabling group email notifications
    
.NOTES
    Author: Toby Williams
    Date: 02-10-2024
    Version: 1.0
            1.0: Basic Script
#>
[CmdletBinding(SupportsShouldProcess=$true)]
Param
(
    [Parameter(Mandatory=$true, 
                Position=0)]
    [ValidateSet('ALL_MAIL', 'NONE')]
    [string]$DeliverySetting
)
#requires -Modules Send-MailKitMessage

$ErrorActionPreference = 'Stop'
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
    $logPath = "$PSScriptRoot\logs\securly_group_update.log"
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

# Mail Settings
# Import-Clixml "$PSScriptRoot\credentials\credentials.xml" 
# [System.Management.Automation.PSCredential]::new("USERNAME", (ConvertTo-SecureString -String "PASSWORD" -AsPlainText -Force))

$fromAddress = [MimeKit.MailboxAddress]("")
$fromAddress.Name = "Securly Automations"

# Import Credentials
try {
    $creds = Import-Clixml "$PSScriptRoot\credentials\credentials.xml"
}
catch {
    Write-Log -Message "Unable to import credentials - $_"
    throw
}

$mailParams = @{
    "SMTPServer" = "smtp-relay.gmail.com"
    "Port" = "587"
    "Credential" = $creds
    "UseSecureConnectionIfAvailable" = $true
    "From" = $fromAddress
}

$ErrMailParams = $mailParams.Clone()
$RecipientErr = [MimeKit.InternetAddressList]::new()
$RecipientErr.Add([MimeKit.InternetAddress](""))
$ErrMailParams.Add("RecipientList", $RecipientErr)

# Create log dir if not exist
$logPath = "$PSScriptRoot\logs\"
if (!(Test-Path -Path $logPath -PathType Container)){
    New-Item -Path $logPath -ItemType Directory -Force
}

Write-Log -Message "Starting Securly group subscription update process"

# Get the Securly alerts email groups 
try {
    Write-Log -Message "Getting Securly notification groups"
    $groups = Get-GSGroup -Filter "email:securly-alerts*"
    Write-Log -Message "The following groups were returned: $($groups.Name)"
}
catch {
    Write-Log -Message "An error was encountered when attempting to get group information - $($_.Exception.InnerException.Error.Message)"
    throw
}

foreach ($group in $groups){
    $groupURL = ($group.Email -split "@")[0]
    $RecipientList = [MimeKit.InternetAddressList]::new()
    try {
        Write-Log -Message "Getting members of $($group.Name)"
        $groupMembers = Get-GSGroupMember -Identity $group.Id 
    }
    catch {
        Write-Log -Message "Unable to get members of group $($group.Name)"
        $ErrMailParams.Add("Subject", "ERROR: Securely Notifications - $($group.Name)")
        $ErrMailParams.Add("TextBody", "Unable to get members of group $($group.Name)") 
        Send-MailKitMessage @ErrMailParams 
        throw
    }    
    if ($groupMembers){
        foreach ($member in $groupMembers){
            Write-Log -Message "Updating group subscription setting for $($member.Email)"
            try {
                Update-GSGroupMember -Identity $group.Id -Member $member.Email -DeliverySettings $DeliverySetting | Out-Null
                Write-Log -Message "Subscription successfully set to $DeliverySetting"
                $RecipientList.Add([MimeKit.InternetAddress]("$($member.Email)"))
            }
            catch {
                Write-Log "Error encountered when attempting to update group subscription for $($member.Email) - $_"
                $ErrMailParams.Add("Subject", "ERROR: Securely Notifications - $($group.Name)")
                $ErrMailParams.Add("TextBody", "Error encountered when attempting to update group subscription for $($member.Email) - $_") 
                Send-MailKitMessage @ErrMailParams 
                throw
            }
        } 
        if ($DeliverySetting -eq "ALL_MAIL"){
            # Subscriptions enabled, send notification to members
            Write-Log -Message "Notifying members of subscription re-enablement"
            try {
                $notifyParams = $mailParams.Clone()    
                $notifyParams.Add("RecipientList", $RecipientList)
                $notifyParams.Add("Subject", "Securely Notifications Enabled - $($group.Name)")
                $notifyParams.Add("HTMLBody", (Get-HTMLBody -GroupName $groupURL))
                Send-MailKitMessage @notifyParams
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
Remove-Logs