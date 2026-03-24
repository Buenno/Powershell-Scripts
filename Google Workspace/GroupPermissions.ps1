# Get a list of all groups
#$groups = Get-GSGroupList

# Get each groups settings
$groupSettings = [System.Collections.Generic.List[object]]::new()

foreach ($group in $groups){
  try {
    $groupSettings.Add((Get-GSGroupSettings -Identity $group.Email -ErrorAction Stop))
  }
  catch {
    Write-Host "Unable to get group settings for $($group.Email)"
  }
}