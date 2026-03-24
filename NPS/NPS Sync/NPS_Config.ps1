# NPS-Config.ps1
# Single script to import or export NPS configuration based on the -Task parameter
# Usage examples:
#   .\NPS-Config.ps1 -Task export
#   .\NPS-Config.ps1 -Task import

param (
  [Parameter(Mandatory=$true)]
  [ValidateSet("Import","Export")]
  [string]$Task
)

# Current date
$date = Get-Date -Format "ddMMyyyy"

# Paths
$Share = "\\tas.internal\admin\NPS_Config"
$ConfigShare = Join-Path $Share "Configuration\"
$LogsShare = Join-Path $Share "Logs\"
$BackupShare = Join-Path $Share "Backups\"
$LocalBackupDir = "C:\Scripts\NPS_Config\Backups\"
$LocalBackupFile = Join-Path $LocalBackupDir ("NPS_" + "$($env:COMPUTERNAME)_" +  $Task + $date + "_Backup.xml")
$ConfigFile = "NPS_Config.xml"
$ConfigPath = Join-Path $ConfigShare $ConfigFile
$LocalLogsDir = "C:\Scripts\NPS_Config\Logs"
$LocalLogFile = Join-Path $LocalLogsDir ("NPS_" + $Task + "_Log.txt")

# Keep logs for 7 days
$LogRetentionDays = 7

# Generate daily log file
$LocalLogFile = Join-Path $LocalLogsDir ("NPS_" + "$($env:COMPUTERNAME)_" + $Task + "_$date.txt")

# Logging function
function Write-Log {
  Param
  (
  [string]$Message = "",
  [switch]$BlankLine
  )

  if ($BlankLine) {
    Add-Content -Path $LocalLogFile -Value ""
    return
  }

  $timestamp =  Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  "$timestamp - $Message" | Tee-Object -FilePath $LocalLogFile -Append
}

try {
  # Ensure local log directory exists
  if (!(Test-Path $LocalLogsDir)) { 
    New-Item -ItemType Directory -Path $LocalLogsDir -Force 
  }

  # Ensure local backup directory exists
  if (!(Test-Path $LocalBackupDir)) { 
    New-Item -ItemType Directory -Path $LocalBackupDir -Force 
  }

  # Start script
  Write-Log "=== Starting NPS $Task task on $env:COMPUTERNAME ==="

  # Ensure network share exists
  if (!(Test-Path $Share)) {
    Write-Log "ERROR: Network share $Share is not accessible"
    throw
  }

  # Ensure configuration folder exists on network share
  if (!(Test-Path $ConfigShare)) {
    try {
      New-Item -ItemType Directory -Path $ConfigShare -Force
      Write-Log "Created configuration folder at $ConfigShare"
    } 
    catch {
      Write-Log "ERROR: Failed to create configuration folder at $ConfigShare. $($_.Exception.Message)"
      throw
    }
  }

  # Ensure logs folder exists on network share
  if (!(Test-Path $LogsShare)) {
    try {
      New-Item -ItemType Directory -Path $LogsShare -Force
      Write-Log "Created logs folder at $LogsShare"
    } 
    catch {
      Write-Log "ERROR: Failed to create Logs folder at $LogsShare. $($_.Exception.Message)"
      throw
    }
  }

  # Ensure backup folder exists on network share
  if (!(Test-Path $BackupShare)) {
    try {
      New-Item -ItemType Directory -Path $BackupShare -Force
      Write-Log "Created backup folder at $BackupShare"
    } 
    catch {
      Write-Log "ERROR: Failed to create backup folder at $BackupShare. $($_.Exception.Message)"
      throw
    }
  }

  # Perform task
  try {
    switch ($Task) {
      "Export" {
        Write-Log "Exporting NPS configuration to $ConfigPath"
        try {
          Export-NpsConfiguration -Path $ConfigPath -ErrorAction Stop
          Write-Log "SUCCESS: NPS configuration exported successfully"
        }
        catch {
          Write-Log "ERROR: NPS export failed. $($_.Exception.Message)"
          throw
        }
      }
      "Import" {
        # Check that configuration file exists
        if (!(Test-Path $ConfigPath)) {
          Write-Log "ERROR: Configuration file $ConfigPath does not exist"
          throw
        }

        # Backup current configuration before import
        Write-Log "Backing up existing configuration to $LocalBackupDir"
        Export-NpsConfiguration -Path $LocalBackupFile
        Write-Log "SUCCESS: Backup complete"

        # Copy backup to network share
        try {
          $DestinationBackup = Join-Path $BackupShare ([System.IO.Path]::GetFileName($LocalBackupFile))
          Copy-Item -Path $LocalBackupFile -Destination $DestinationBackup -Force
          Write-Log "Backup file copied to $BackupShare"
        } catch {
          Write-Log "ERROR: Failed to copy backup file to network share. $($_.Exception.Message)"
        }

        # Import configuration from share
        Write-Log "Importing NPS configuration from $ConfigPath"
        try {
          Import-NpsConfiguration -Path $ConfigPath
          Write-Log "SUCCESS: NPS configuration imported successfully"
        }
        catch {
          Write-Log "ERROR: NPS import failed. $($_.Exception.Message)"
          throw
        }
        # Restart NPS service
        Write-Log "Restarting NPS Service"
        try {
          Restart-Service -Name "IAS"
          Write-Log "SUCCESS: NPS service resatrted successfully"
        }
        catch {
          Write-Log "ERROR: Failed to restart NPS service. $($_.Exception.Message)"
          throw
        }
      }
    }
  } 
  catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    throw
  }

  # Remove old logs from local and remote storage
  try {
    Get-ChildItem -Path $LocalLogsDir -Filter "*.txt" -File |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$LogRetentionDays) } |
    Remove-Item -Force
  }
  catch {
    Write-Log "ERROR: Unable to remove old logs from $LocalLogsDir"
    throw
  }
  try {
    Get-ChildItem -Path $LogsShare -Filter "*.txt" -File |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$LogRetentionDays) } |
    Remove-Item -Force
  }
  catch {
    Write-Log "ERROR: Unable to remove old logs from $LogsShare"
    throw
  }
}
catch {
  Write-Log "CRITICAL FAILURE: $($_.Exception.Message)"
}
finally {
  Write-Log "=== NPS $Task task completed ==="
  Write-Log -BlankLine

  # Copy log to network share
  try {
    $DestinationLog = Join-Path $LogsShare ([System.IO.Path]::GetFileName($LocalLogFile))
    Copy-Item -Path $LocalLogFile -Destination $DestinationLog -Force
  } 
  catch {
    Write-Log "ERROR: Failed to copy log file to network share. $($_.Exception.Message)"
    Write-Log -BlankLine
  }
}