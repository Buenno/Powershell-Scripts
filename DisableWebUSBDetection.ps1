<#
.SYNOPSIS
    Disables Web USB Detection in Google Chrome for all users.
    
.NOTES
    Author: Toby Williams
    Date: 09-04-2025
    Version: 1.0
            1.0: Basic Script
#>

Function Set-ChromeFlag {
    <#
    .SYNOPSIS
        Sets a value for a Chrome flag. Updates the value if the flag already exists.
    
    .NOTES
        Name: Set-ChromeFlag
        Author: Toby Williams
        Version: 1.0
        DateCreated: 03/04/2025
    
    .EXAMPLE
        Set-ChromeFlag -Name "enabled_labs_experiments" -Value "0" -AllUsers
    #>
   
    [CmdletBinding()]
    param(
        [Parameter(
            ParameterSetName = "Single",
            Mandatory = $true
            )]
        [string] $User,

        [Parameter(
            ParameterSetName = "Single",
            Mandatory = $true,
            Position = 1
            )]
        [Parameter(
            ParameterSetName = "All",
            Mandatory = $true,
            Position = 0
            )]
        [string] $Name,

        [Parameter(
            ParameterSetName = "Single",
            Mandatory = $true,
            Position = 2
            )]
        [Parameter(
            ParameterSetName = "All",
            Mandatory = $true,
            Position = 1
            )]
        [string] $Value,

        [Parameter(
            ParameterSetName = "All",
            Mandatory = $true
            )]
        [switch] $AllUsers
    )

    BEGIN {
        $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
        # Get running Chrome processes
        $procs = Get-Process -Name "Chrome" -IncludeUserName -ErrorAction SilentlyContinue
    }

    PROCESS {
        if ($PSCmdlet.ParameterSetName -eq "Single") {
            $users = @($user)
            $procs | Where-Object {$_.UserName -like "*$User"} | Stop-Process -Force
        }
        elseif ($PSCmdlet.ParameterSetName -eq "All") {
            $users = (Get-ChildItem -Path "$env:SystemDrive\Users").Name
            $procs | Stop-Process -Force 
        }
        foreach ($u in $users){
            $configPath = "C:\Users\$u\AppData\Local\Google\Chrome\User Data\Local State"

            # Check if the Local State file exists, if not then create it. 
            if (!(Test-Path -Path $configPath)){
                $localState = New-Item -ItemType File -Path "C:\Users\$u\AppData\Local\Google\Chrome\User Data\" -Name "Local State" -Force
                $defaultContent = @{
                    "browser" = @{
                        "enabled_labs_experiments" = @()
                    }
                }
                $defaultContent | ConvertTo-Json -Depth 3 -Compress | Set-Content -Path $localState
            }

            # Get the contents of the Local State file and convert from JSON to PSObject.
            $configJSON = Get-Content $configPath | ConvertFrom-Json

            # Check if the flags element exists within the PSObject, if not then add it.
            if (!($configJSON.browser | Get-Member -MemberType NoteProperty -Name "enabled_labs_experiments")){
                $configJSON.browser | Add-Member -MemberType NoteProperty -Name "enabled_labs_experiments" -Value @()
            }

            # Load all flags into a list, this allows us to retain existing and add new.
            $flagList = New-Object System.Collections.Generic.List[System.Object]
            foreach ($flag in $configJSON.browser.enabled_labs_experiments){
                $flagList.Add($flag) | Out-Null
            }

            # Check whether the specified flag already exists within the flags element.
            if (($flagMatch = $configJSON.browser.enabled_labs_experiments -like "$($Name)*")){
                # Found a match, so remove it from the list we created.
                $flagList.Remove("$flagMatch") | Out-Null
            }

            # Add the new flag to the list.
            $flagList.Add("$Name@$Value") | Out-Null

            # Replace the flag element with the PSObject with the new list.
            $configJSON.browser.enabled_labs_experiments = $flagList

            # Convert the PSObject back into JSON and overwrite original Local State file.
            $configJSON | ConvertTo-Json -Compress -Depth 10 | Out-File -FilePath $configPath -Encoding utf8 -Force
        }
    }

    END {}
}

Set-ChromeFlag -Name "enable-webusb-device-detection" -Value "1" -AllUsers