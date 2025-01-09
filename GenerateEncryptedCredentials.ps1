<# 
Generates an XML file which stores encrypted credentials for a specific user. 
Useful if you need to access credentials within a scheduled task as another user (service account).
#>

# Location where the credential file will be saved
$SavedFolder = "C:\Scripts\Credentials\"
$SavedFilename = "credentials.xml"
# If the "Credentials" folder doesn't exist, create it
If (!(Test-Path $SavedFolder)){
    New-Item -Path $PSScriptRoot\Credentials -ItemType Directory | out-null
}

# Get credentials for service account that runs this task
$SvcCreds = Get-Credential -message "Provide credentials for Service Account"
$SvcUname = $SvcCreds.Username.Split('\')[-1]
$SvcPasswd = $SvcCreds.GetNetworkCredential().Password
# need to validate the SVC account credentials before starting the job
Add-Type -AssemblyName System.DirectoryServices.AccountManagement
$PC = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::Domain, 'DOMAIN NAME')
# validate the credentials, and retry up to 3 times total before failing out and exiting the script. 
$Count = 1
While ((($Auth = $PC.ValidateCredentials($SvcUname,$SvcPasswd)) -eq $False) -and ($Count -le 2)){
    $Count++
    $SvcCreds = Get-Credential -message "Auth Failure. Try again. $(4 - $count) attempts left"
    $SvcUname = $SvcCreds.Username.split('\')[-1]
    $SvcPasswd = $SvcCreds.GetNetworkCredential().Password
}
If (!($Auth)){
    Write-Host "Failed to validate service account credentials. Please check and try again" -ForegroundColor Yellow
    Write-host "Hit enter to exit this script"
    Read-Host
    Exit
}

# Get credentials for the task. 
$TaskCreds = Get-Credential -message "Provide credentials for the scheduled task" 

# Save the credentials as a SecureString object that only that service account, on this computer, can decrypt for use later
Write-Host "Saving Credentials..." -ForegroundColor Yellow
$CredJob = Start-Job -ScriptBlock {$Using:TaskCreds | Export-Clixml -path ($Using:SavedFolder + $Using:SavedFilename) -Force} -Credential $SvcCreds
Wait-Job $CredJob | out-null
$t = Receive-Job -Job $CredJob

Write-Host "Credentials saved. Please hit Enter to exit this script" -ForegroundColor Yellow
Read-Host 
Exit