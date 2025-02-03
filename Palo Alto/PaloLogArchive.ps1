$ErrorActionPreference = 'Stop'

## Archive daily Palo logs - these files are created via the Palo log exporter.

Function Add-FileTo7Zip {     
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('FullName')]
        $File,
        [string]$Destination
    )
    PROCESS {
        & $env:ProgramFiles\7-Zip\7z.exe a -t7z -sdel $Destination $File
    }
}

###### Settings ######

$logDir = "F:\Logs"
$archiveDir = "F:\LogArchive"

######################

# Get logs older than 1 day
$date = (get-date).AddDays(-1)
$logFiles = Get-ChildItem -Path $logDir -Include *.csv -Recurse | Where-Object {$_.LastWriteTime -le $date}

# Create working directory
$workingDir = "$archiveDir\InProgress"

if (!(Test-Path -Path $workingDir)){
    New-Item -Path $workingDir -ItemType Directory
}

# Move logs into working directory
# These are organised by date, firewall, and log type, essentially retaining the directory structure of the source prior to the move
foreach ($log in $logFiles){
    $dateDir = "$workingDir\$($log.LastWriteTime.Date.ToString(`"yyyy_MM_dd`"))"
    $firewallDir = "$dateDir\$($log.Directory.Parent.Name)"
    $logTypeDir = "$firewallDir\$($log.Directory.Name)"
    $workDest = "$logTypeDir\$($log.Name)"

    if (!(Test-Path -Path $dateDir)){
        New-Item -Path $dateDir -ItemType Directory
    }

    if (!(Test-Path -Path $firewallDir)){
        New-Item -Path $firewallDir -ItemType Directory
    }

    if (!(Test-Path -Path $logTypeDir)){
        New-Item -Path $logTypeDir -ItemType Directory
    }

    Move-Item -Path $log -Destination $workDest -Force
}

# Create an archive for each dated directory (one archive for each day), deleting the source data in the process
$dateDirs = Get-ChildItem -Path $workingDir -Directory
foreach ($dir in $dateDirs){
    Get-ChildItem -Path $dir.FullName | Add-FileTo7Zip -Destination "$archiveDir\$($dir.Name).7z"
    if (!(Get-ChildItem -Path $dir.FullName)){
        Remove-Item -Path $dir.FullName -Force
    }
}

# Delete the working directory if it's empty
if (!(Get-ChildItem -Path $workingDir)){
    Remove-Item -Path $workingDir -Force
}