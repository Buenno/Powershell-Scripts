function Get-HRPConfig {
  <#
  .SYNOPSIS
  Loads the specified HRProPS config

  .DESCRIPTION
  Loads the specified HRProPS config

  .PARAMETER ConfigName
  The config name to load

  .PARAMETER PassThru
  If specified, returns the config after loading it

  .PARAMETER NoImport
  If $true, just returns the specified config but does not import it in the current session

  .EXAMPLE
  Get-HRProPSConfig -ConfigName personalDomain -PassThru

  This will load the config named "personalDomain" and return it as a PSObject
  #>
    [CmdletBinding()]
    Param(
      [Parameter(Mandatory = $false,Position = 0)]
      [String] $ConfigName,
      [Parameter(Mandatory = $false)]
      [Switch] $PassThru,
      [Parameter(Mandatory = $false)]
      [Switch] $NoImport
    )

  Process {
    $fullConf = Import-Configuration -CompanyName 'The Abbey' -Name 'HRProPS'
    if (!$ConfigName) {
      $choice = $fullConf["DefaultConfig"]
      Write-Verbose "Importing default config: $choice"
    }
    else {
      $choice = $ConfigName
      Write-Verbose "Importing config: $choice"
    }
    $encConf = [PSCustomObject]($fullConf[$choice])
        
    $decryptParams = @{
      ConfigName = $choice
    }
    $decryptedConfig = $encConf | Get-HRPDecryptedConfig @decryptParams
    Write-Verbose "Retrieved configuration '$choice'"
    if (!$NoImport) {
      $script:HRProPS = $decryptedConfig
    }
    if ($PassThru) {
      $decryptedConfig
    }
  }
}