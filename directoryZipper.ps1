<#

Zips all sub-directories within the specified parent directory, applying password protection and encryption. Useful for external sharing of documents and such.

#>

$parentDir = ""

$toZip = Get-ChildItem -Path $parentDir -Directory

foreach ($dir in $toZip){
  $password = Invoke-WebRequest -Uri https://www.dinopass.com/password/simple | Select-Object -ExpandProperty content
  Write-host "$($dir.name), $password"
  & $env:ProgramFiles\7-Zip\7z.exe a -t7z "$($dir.name).7z" "$($dir.FullName)\*" -p"$($password)" -mhe=on | Out-Null
  #& $env:ProgramFiles\7-Zip\7z.exe a -tzip -mem=AES256 "$($dir.name).zip" "$($dir.FullName)\*" -p$password 
}