function LogFile ($Message) {
    $LogDate = Get-Date -UFormat "%D %T"
    Add-Content -Value "$($LogDate) - $($Message)" -Path $ERAPath$LogName
}

Function Mailer($MError) { 
$Message = @"
There seems to have been a problem with the ESET_RA backup. Please investigate.

Error - $MError  
     
Cheers,
ESET Backup
"@        
$emailto = "" #Gmail group
$subject = "WARNING - ESET Backup Failure"   
$emailFrom = "" 
$smtpserver = "" 
$smtp = new-object Net.Mail.SmtpClient($smtpServer)
$smtp.Send($emailFrom, $emailTo, $subject, $message) 
} 

##############################################################

            <# Lets define some variables #>

$ERAPath = "$env:ProgramData\ESET\ESET Remote Administrator\"
# Generate date of week as int for file names
$DayDigit = (get-date).dayofweek.value__
# Build log file name
$LogName = "ERAServerBak.$($DayDigit).log"
# Build bak name
$BakName = "ERAServerBak.$($DayDigit)"

###############################################################


# Check if log already exists, if so then delete
if (Test-Path -Path $ERAPath$LogName){
    Remove-Item -Path $ERAPath$LogName -Force
}
LogFile -Message "Backup started..."
# Get ERA services
try {
    $ERAServ = get-service | where {$_.name -eq 'ERA_SERVER'}
}
# Log error if no service was found
catch {
    $ErrorLog = "The ERA_SERVER service was not found."
    LogFile -Message $ErrorLog
    Mailer -MError $ErrorLog
    Exit
}
# Log message if the service was already stopped
if ($ERAServ.Status -eq 'Stopped'){
    LogFile -Message "The ERA_SERVER service is already in the stopped state."
}
elseif ($ERAServ.Status -eq 'Running') {
    # Stop services and add to log
    try {
        LogFile -Message "Attempting to stop $($ERAServ.Name) service."
        Stop-Service $($ERAServ.Name) -ErrorAction stop
        LogFile -Message "Service $($ERAServ.Name) stopped."
    }
    # If the service/s cannot be stopped then log error and quit
    catch {
        $ErrorLog = "The service $($ERAServ.Name) cannot be stopped - $($_.exception.innerexception.innerexception.message)."
        LogFile -Message $ErrorLog
        Mailer -MError $ErrorLog
        Exit
    }
}
# Now the ERA services are stopped we can copy/archive the application data
# Make a copy of the application data
LogFile -Message "Copying Data..."
try {
    Copy-Item -Path ($ERAPath + "Server\") -Destination ($ERAPath + "ERAServerBak\") -Recurse -ErrorAction stop
    LogFile "Successfully copied application data from $($ERAPath + "Server\")."
}
catch {
    LogFile "Error when copying Eset application data, restarting service then aborting."
    try {
        Start-Service $($ERAServ.Name) -ErrorAction stop
        LogFile -Message "Service $($ERAServ.Name) restarted."
    }
    # If the service/s cannot be started then log error and quit
    catch {
        $ErrorLog = "The ESET_Server service was stopped but cannot be started."
        LogFile -Message $ErrorLog
        Mailer -MError $ErrorLog
        Exit
    }
}
# Start services back up once copy is complete
try {
    Start-Service $($ERAServ.Name) -ErrorAction stop
    LogFile -Message "Service $($ERAServ.Name) started."
}
# If the service cannot be started then log error and quit
catch {
    $ErrorLog = "The ESET_Server service was stopped but cannot be started."
    LogFile -Message $ErrorLog
    Mailer -MError $ErrorLog
    Exit
}
# Create 7-zip archive from copied data
LogFile -Message "Attempting to create 7-Zip archive..."
try {
    & $env:ProgramFiles'\7-Zip\7za.exe' a -t7z ($ERAPath + $BakName + '.7z') -mx9 ($ERAPath + 'ERAServerBak\') -r 
    LogFile -Message "Files successfully added to archive."
}
catch {
    $ErrorLog = "Unable to create 7-Zip archive."
    LogFile -Message $ErrorLog
    Mailer -MError $ErrorLog
    Exit
}
LogFile -Message "Attempting to remove data copy..."
# Once the archive is built we can delete the data we copied
try{
    Remove-Item ($ERAPath + "ERAServerBak\") -Recurse -Force -ErrorAction stop
    LogFile -Message "Data successfully removed."
}
catch { 
    $ErrorLog = "Unable to remove old data after archive was built."
    LogFile -Message $ErrorLog
    Mailer -MError $ErrorLog
    Exit
}
# Move archive to storage.
LogFile -Message "Attempting to move archive."
cmd.exe /c "C:\Program Files (x86)\cwRsync\ERAServerBak.cmd" | Out-Null
if ($lastexitcode -ne '0'){
	$ErrorLog = "Rsync failed with exit code $lastexitcode."
	LogFile -Message $ErrorLog
    Mailer -MError $ErrorLog
}	
Else {
	LogFile -Message "Successfully moved archive."
    # Delete archive from local storage
    try {
        Remove-Item ($ERAPath + $BakName + '.7z') -Force
    }
    catch {
        $ErrorLog = "Unable to delete archive."
        LogFile -Message $ErrorLog
        Mailer -MError $ErrorLog
        Exit    
    }
}
LogFile -Message "Backup complete."









