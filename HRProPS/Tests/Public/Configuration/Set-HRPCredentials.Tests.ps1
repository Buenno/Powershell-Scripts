BeforeAll {
    # Dot-source public functions
    Get-ChildItem "$PSScriptRoot\..\..\..\src\public\*\*.ps1" |
        ForEach-Object {
            . $_.FullName
        }

    # Dot-source private functions
    Get-ChildItem "$PSScriptRoot\..\..\..\src\private\*.ps1" |
        ForEach-Object {
            . $_.FullName
        }
}

Describe "Set-HRPCredentials" {
    BeforeEach {
        $cred = [PSCredential]::new("testuser", (ConvertTo-SecureString "Password123" -AsPlainText -Force))

        Mock Get-Module {$true} -ParameterFilter { $Name -eq "Microsoft.PowerShell.SecretManagement" }
        Mock Get-Module {$true} -ParameterFilter { $Name -eq "Microsoft.PowerShell.SecretStore" }

        Mock Get-SecretVault {$null}
        Mock Register-SecretVault {@{Name = "HRProPS"}}
        Mock Set-Secret {$true}
        Mock Get-Credential { 
            $cred
        }
    }

    It "creates the vault if it does not exist" {
        Set-HRPCredentials | Out-Null

        Assert-MockCalled Register-SecretVault -Times 1 -Exactly
        Assert-MockCalled Set-Secret -Times 1 -Exactly
    }

    It "does not attempt to create the vault if it exists" {
        Mock Get-SecretVault {@{Name = "HRProPS"}}

        Set-HRPCredentials

        Assert-MockCalled Register-SecretVault -Times 0 -Exactly
        Assert-MockCalled Set-Secret -Times 1 -Exactly
    }

    It "stores the credentials in the vault" {
        Set-HRPCredentials

        Assert-MockCalled Set-Secret -Times 1 -Exactly -ParameterFilter {
            $Name -eq "HRProPS" -and
            $Secret -eq $cred
            $Vault -eq "HRProPS"
        }
    }

    It "throws if SecretManagement is not installed" {
        Mock Get-Module {$false} -ParameterFilter {
            $Name -eq "Microsoft.PowerShell.SecretManagement"
        }

        { Set-HRPCredentials } | Should -Throw "Microsoft.PowerShell.SecretManagement module is not installed."
    }

    It "throws if SecretStore is not installed" {
        Mock Get-Module {$false} -ParameterFilter { 
            $Name -eq "Microsoft.PowerShell.SecretStore"
        }

        { Set-HRPCredentials } | Should -Throw "Microsoft.PowerShell.SecretStore module is not installed."
    }
}