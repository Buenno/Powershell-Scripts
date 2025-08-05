Function Set-HRPConfig {
  <#
    .SYNOPSIS
      Creates or updates a config
    .DESCRIPTION
      Creates or updates a config
    .PARAMETER ConfigName
      The friendly name for the config you are creating or updating
    .PARAMETER Username
      The username to use for authentication
    .PARAMETER Password
      The password to use for authentication
    .PARAMETER SetAsDefaultConfig
      If passed, sets the ConfigName as the default config to load on module import
    .EXAMPLE
      Set-HRProPSConfig -Username Admin -Password "AdminPassword12" -SetAsDefaultConfig
  #>

  [CmdletBinding()]
  Param(
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
    [ValidateScript( {
        if ($_ -eq "DefaultConfig") {
          throw "You must specify a ConfigName other than 'DefaultConfig'. That is a reserved value."
        }
        elseif ($_ -notmatch '^[a-zA-Z]+[a-zA-Z0-9]*$') {
          throw "You must specify a ConfigName that starts with a letter and does not contain any spaces, otherwise the Configuration will break"
        }
        else {
          $true
        }
      })]
    [string]
    $ConfigName = $Script:ConfigName,
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
    [string] $Username,
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
    [SecureString] $Password,
    [parameter(Mandatory = $false)]
    [switch]
    $SetAsDefaultConfig
  )

  Begin {}
  Process {
    $configHash = Import-Configuration -CompanyName 'The Abbey' -Name 'HRProPS'
    if (!$ConfigName) {
      $ConfigName = if ($configHash["DefaultConfig"]) {
        $configHash["DefaultConfig"]
      }
      else {
        "default"
        $configHash["DefaultConfig"] = "default"
      }
    }
    Write-Verbose "Setting config name '$ConfigName'"
    $configParams = @('Username', 'Password')
    if ($SetAsDefaultConfig -or !$configHash["DefaultConfig"]) {
      $configHash["DefaultConfig"] = $ConfigName
    }
    if (!$configHash[$ConfigName]) {
      $configHash.Add($ConfigName, (@{}))
    }
    foreach ($key in ($PSBoundParameters.Keys | Where-Object { $configParams -contains $_ })) {
      $configHash["$ConfigName"][$key] = (Invoke-HRPEncrypt $PSBoundParameters[$key])
    }
  } 
  End {
    $configHash | Export-Configuration -CompanyName 'The Abbey' -Name 'HRProPS' -Scope User
  }
}
