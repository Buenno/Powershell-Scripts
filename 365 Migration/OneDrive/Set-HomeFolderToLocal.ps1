Function Set-HomeFolderToLocal {
  <#
    .SYNOPSIS
      Changes the AD Users home folder to local.
    .DESCRIPTION
      Changes the AD Users home folder to local. Used when moving away from folder redirection.
    .PARAMETER UserType
      What type of user to target. Valid options are Staff or Student.
    .PARAMETER ExportOnly
      Export a list of AD users to be processed. Skips update process.
    .EXAMPLE
      Set-HomeFolderToLocal -UserType Staff
  #>

  [CmdletBinding()]
    Param(
      [Parameter(
        Mandatory = $true,
        ValueFromPipeline = $false,
        ValueFromPipelineByPropertyName = $false,
        Position = 0
        )]
      [ValidateSet("Staff","Student")]
      [string]$UserType,
      [switch]$ExportOnly
    )

  PROCESS {
    $examUserRegex = "^Exam(?:\d{2}|Art\d{2}|CS\d{1})$"
    $filename = "ADUserHomeDirectory.csv"

    $OU = switch ($UserType) {
            Staff { "OU=Staff,OU=School,OU=Users,OU=TheAbbeySchool,DC=tas,DC=internal" }
            Student { "OU=Students,OU=School,OU=Users,OU=TheAbbeySchool,DC=tas,DC=internal" }
          }
    Write-Verbose "Getting $($UserType) AD records"      
    $users = Get-ADUser -SearchBase $OU -Filter "HomeDirectory -like '*' -and enabled -eq 'true'" -Properties HomeDirectory | Where-Object {$_.SamAccountName -notmatch $examUserRegex}
    $users | Select-Object SamAccountName, HomeDirectory | Export-Csv -Path ./$filename -Force
    Write-Verbose "Backup exported to $((Get-Location).Path)\$filename"

    if ($ExportOnly){
      return
    }
    else {
      $decision = $Host.UI.PromptForChoice("Clear AD user home folder path", "This action will clear the home folder path and revert the setting to a blank ""local path"" for $($users.Count) users. Do you wish to proceed?", @("&Yes"; "&No"), 1)
      if ($decision -eq 0) {
        foreach ($user in $users){
          $usersProcessed++
          $user | Set-ADUser -Clear HomeDirectory 
          $percentComplete = [Math]::Round($usersProcessed/($users.Count)*100, 0)
          Write-Progress -Activity "Reverting home folder from N:\ to local path" -Status "User $usersProcessed of $($users.Count) - $percentComplete%" -PercentComplete $percentComplete
          Write-Verbose "Process complete"
        }
      } else {
          Write-Verbose 'Process aborted'
      }
    }
  }
}
