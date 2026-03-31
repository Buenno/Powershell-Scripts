function New-ReactiveAccount {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$MAC,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$ComputerName,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [SecureString]$Password
    )

    process {
        try {
            # Normalise MAC
            $NewMac = $MAC.Replace(":", "").Replace("-", "").ToUpper()

            $Desc = "SCCMTEMP " + (Get-Date -Format "yy-MM-dd HH:mm") + " " + $env:UserName + " " + $ComputerName

            New-ADUser `
                -SamAccountName $NewMac `
                -Name ("SCCM " + $NewMac) `
                -UserPrincipalName $NewMac `
                -DisplayName ("SCCM " + $NewMac) `
                -GivenName "SCCM" `
                -Surname $NewMac `
                -Description $Desc `
                -Path "OU=SCCM, OU=Accounts, OU=Reactive, OU=TheAbbeySchool, DC=tas, DC=internal" `
                -AccountPassword $Password `
                -ChangePasswordAtLogon $False `
                -PasswordNeverExpires $True `
                -CannotChangePassword $True `
                -Enabled $True `
                -ErrorAction Stop

            Add-ADGroupMember -Identity "Reactive.TrustedOverrides" -Members $NewMac -ErrorAction Stop

            Write-Verbose "Created account for MAC: $NewMac ($ComputerName)"
        }
        catch {
            Write-Error "Failed for MAC: $MAC - $_"
        }
    }
}