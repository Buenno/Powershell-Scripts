function Write-Log {
  Param
  (
  [Parameter(Mandatory=$true)]
  [string]$Message
  )
  $timestamp =  Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  "$timestamp - $Message" | Tee-Object -FilePath $LocalLogFile -Append
}