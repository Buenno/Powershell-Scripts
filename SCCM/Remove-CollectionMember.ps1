# Import Configurtion Manager module.
Import-Module configurationmanager 

# Site configuration
$SiteCode = "TAS"
$ProviderMachineName = "sccm1.tas.internal"
$creds = Get-Credential

# Connect to the site's drive if it is not already present
if($null -eq (Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue)) {
  New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName -Credential $creds
}

# Set the current location to be the site code.
Set-Location "$($SiteCode):\"

# Array of device assets to operate on. Could also import from CSV.
$assets = @("") 

foreach ($asset in $assets){
  # Get CM device object
  try {
    $device = Get-CMDevice -Name "*$($asset)*" -ErrorAction Stop
  }
  catch {
    Write-Host "Device '$asset' not found." -ForegroundColor Red
    return
  }
  
  # Get all collections that the device is a direct member of
  $collections = $device | Get-CMResultantCollection
  foreach ($collection in $collections){
    foreach ($rule in ($collection | Select-Object -ExpandProperty CollectionRules)){
      if ($rule.RuleName -eq $device.Name){
        Write-Host "Removing $($device.Name) from $($collection.Name)" -ForegroundColor Yellow
        Remove-CMDeviceCollectionDirectMembershipRule -CollectionId $collection.CollectionID -ResourceId $device.ResourceID -Force
      }
    }
  }
}