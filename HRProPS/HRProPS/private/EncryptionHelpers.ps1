function Get-HRPDecryptedConfig {
  [CmdletBinding()]
  Param(
    [Parameter(Position = 0, ValueFromPipeline, Mandatory)]
    [object] $Config,
    [Parameter(Position = 1, Mandatory)]
    [string] $ConfigName
  )
  $Config | Select-Object -Property @(
    @{l = 'ConfigName'; e = { $ConfigName }}
    @{l = 'Username'; e = { Invoke-HRPDecrypt $_.Username } }
    @{l = 'Password'; e = { Invoke-HRPDecrypt $_.Password } }
  )
}

function Invoke-HRPDecrypt {
  Param($String)
  if ($String -is [System.Security.SecureString]) {
    [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR(
      [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR(
          $String
      )
    )
  } 
  elseif ($String -is [ScriptBlock]) {
    $String.InvokeReturnAsIs()
  } 
  else {
    $String
  }
}

Function Invoke-HRPEncrypt {
  Param($string)
  if ($string -is [System.String] -and -not [String]::IsNullOrEmpty($String)) {
    ConvertTo-SecureString -String $string -AsPlainText -Force
  } 
  else {
    $string
  }
}