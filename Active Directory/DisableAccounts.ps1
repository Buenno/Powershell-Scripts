$names = Import-Csv -Path $PSScriptRoot\terminate.csv | Select-Object -ExpandProperty Name

foreach ($name in $names){
  Write-Host "Getting $name from AD"
  # Get AD record
  $adUser = Get-ADUser -Filter {DisplayName -like $name}
  # Get group membership for AD record
  Write-Host "Getting group membership"
  $adGroups = $adUser | Get-ADPrincipalGroupMembership | Where-Object {$_.Name -ne "Domain Users"}
  # Disable AD account
  Write-Host "Disabling AD account"
  $aduser | Disable-ADAccount
  # Remove AD record group memberships
  foreach ($group in $adGroups){
    Write-Host "Removing $name from $($group.Name)"
    Remove-ADGroupMember -Identity $group.DistinguishedName -Members $adUser -Confirm:$false
  }
  # Move AD record
  Write-Host "Moving AD user to xDisabled OU"
  Move-ADObject -Identity $adUser.DistinguishedName -TargetPath "OU=xDisabled,OU=Staff,OU=School,OU=Users,OU=TheAbbeySchool,DC=tas,DC=internal"

  Write-Host "Moving GS user to xInactive OU"
  Update-GSUser "$($adUser.SamAccountName)@theabbey.co.uk" -OrgUnitPath "/Staff/xInactive Staff Accounts" -Confirm:$false | Out-Null
}