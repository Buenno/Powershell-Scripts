Function Disable-GSUser {
    <#
    .SYNOPSIS
        Disables Google Workspace user account
    #>
     
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0
            )]
        [string[]] $User
    )
    BEGIN {
        $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
    }
    PROCESS {
        Update-GSUser -User $User -Suspended $true
    }
    
}

Function Get-GSOUFromForm {
    <#
    .SYNOPSIS
        Gets a Google Workspace OU from form name.

        There is no filter parameter available, so we must process and filter a list of OUs.
     
    .EXAMPLE
        Get-GSOUFromForm -Form "UII"
    #>
     
        [CmdletBinding()]
        param(
            [Parameter(
                Mandatory = $true,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true,
                Position = 0
                )]
            [string[]] $Form
        )

        BEGIN {
            $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
        }

        PROCESS {
            $GSOrgs = Get-GSOrganizationalUnitList -SearchBase /Students -SearchScope All

            foreach ($F in $Form){
                foreach ($Org in $GSOrgs){
                    if ($Org.OrgUnitPath -like "*$($F)/*" -and $Org.OrgUnitPath -notlike "*Generic Accounts"){
                        $Org
                    }
                }
            }
        }
    }

$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop

# Gets a list of JS students from specific OUs/forms and outputs results to CSV. 

$Forms = @("LIII", "UII", "UI", "LI", "Upper Prep", "Lower Prep")

foreach ($Form in $Forms){
    $PropertyList = @(
        "User"
        "OrgUnitPath"
        "Suspended"
    )

    try {
        $Users = Get-GSOUFromForm -Form $Form | ForEach-Object {Get-GSUserList -Filter "isSuspended -eq '$false'" -SearchBase $_.OrgUnitPath | Select-Object $PropertyList}
        $Users | Export-Csv ".\Google Workspace\TinyTerrors $($Form).csv" -NoClobber
        Write-Host -BackgroundColor yellow "Exclusion regex for $($Form)"
        $Users.User -join "|"
    }
    catch {
        Write-Error -Exception "Exception caught when processing $($Form)"
    }
}
