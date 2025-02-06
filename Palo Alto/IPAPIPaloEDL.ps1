$ErrorActionPreference = 'Stop'

Function Expand-Tarball {     
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('FullName')]
        $File,
        [string]$Destination
    )
    PROCESS {
        # Tarball requires double extraction
        & $env:ProgramFiles\7-Zip\7z.exe e $File -o"$($Destination)" -r
        $tar = Get-ChildItem "$($Destination)\*" -Include *.tar
        & $env:ProgramFiles\7-Zip\7z.exe e $tar.FullName -o"$($Destination)" -r

        # Cleanup 
        $tar | Remove-Item -Force
    }
}

$paloScriptDir = "C:\Scripts\Palo"
$VPNIPDir = "$($paloScriptDir)\VPN_IP"
$workingDir = "$($VPNIPDir)\workingDir"

$dataURL = "https://ipapi.is/app/getData?type=ipToVpn&format=csv&apiKey=APIKEYHERE"

# Create directory structure

if (!(Test-Path -Path $VPNIPDir)){
  New-Item -Path $VPNIPDir -ItemType Directory
}

if (!(Test-Path -Path $workingDir)){
  New-Item -Path $workingDir -ItemType Directory
}

# Download data archive to working directory
Invoke-WebRequest -Uri $dataURL -OutFile "$workingDir\IPtoVPNDatabase.tar.gz"

# Extract data archive 
$tarball = Get-ChildItem -Path $workingDir\* -Include "*.tar.gz"
$tarball | Expand-Tarball -Destination "$workingDir"

# Remove archive
$tarball | Remove-Item -Force

# Get the 3 valid VPN lists
$vpnLists = Get-ChildItem -Path $workingDir | Where-Object {$_.name -match "^(?!\._)(\w+-\w+)(\.csv)"}

# Each file contains data in differing formats so must be handled separately. 
foreach ($list in $vpnLists){
  if ($list.Name -like "enumerated*"){
    $data = Import-Csv -Path $list.FullName
    $list = New-Object Collections.Generic.List[string]
    foreach ($row in $data){
      $list.Add("$($row.startIp) IPAPI - $($row.serviceName) exit node")
    }
    Set-Content -Path "$($VPNIPDir)\enumerated.txt" -Value $list
  }
  elseif ($list.Name -like "assumed*"){
    $data = Import-Csv -Path $list.FullName
    $list = New-Object Collections.Generic.List[string]
    foreach ($row in $data){
      $list.Add("$($row.startIp)-$($row.EndIp) IPAPI - Assumed VPN service")
    }
    Set-Content -Path "$($VPNIPDir)\assumed.txt" -Value $list
  }
  elseif ($list.Name -like "interpolated*"){
    $data = Import-Csv -Path $list.FullName
    $list = New-Object Collections.Generic.List[string]
    foreach ($row in $data){
      $list.Add("$($row.startIp)-$($row.EndIp) IPAPI - Interpolated VPN service")
    }
    Set-Content -Path "$($VPNIPDir)\interpolated.txt" -Value $list
  }
}

# Remove working directory
Remove-Item -Path $workingDir -Recurse -Force