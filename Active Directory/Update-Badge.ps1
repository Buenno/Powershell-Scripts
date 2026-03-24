Write-host "Getting 2020 intake students..."

$users = Get-ADUser -SearchBase "OU=20Intake,OU=SeniorSchool,OU=Students,OU=School,OU=Users,OU=TheAbbeySchool,DC=tas,DC=internal" -Filter * -Properties DisplayName | Sort-Object Surname

Write-Host "Found $($users.Count) users..."

foreach ($user in $users){
  Write-Host "$($user.DisplayName)" -ForegroundColor Yellow
  try {
    $card = Read-Host "Scan ID Card..."
    Set-ADUser -Identity $user.SamAccountName -Fax $card
    Write-Host "Successfully set ID card for $($user.DisplayName) to $card" -ForegroundColor Green
  }
  Catch {
    Write-Host "Unable to set ID card for $($user.DisplayName)" -ForegroundColor Red
  }
}