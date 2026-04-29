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

Describe "Get-HRPCredentials" {
    BeforeEach {
        Mock Get-Module {$true} -ParameterFilter { $Name -eq "Microsoft.PowerShell.SecretManagement" }
        Mock Get-Module {$true} -ParameterFilter { $Name -eq "Microsoft.PowerShell.SecretStore" }

        Mock Get-SecretVault {$null}
        Mock Get-SecretInfo {$null}
        Mock Get-Secret { 
            [PSCredential]::new("testuser", (ConvertTo-SecureString "Password123" -AsPlainText -Force))
        }
    }

    It "throws error if HRProPS vault does not exist" {
        { Get-HRPCredentials } | Should -Throw "The SecretStore vault `"HRProPS`" does not exist. Run Set-HRPCredentials first."
        Assert-MockCalled Get-SecretVault -Times 1 -Exactly
        Assert-MockCalled Get-SecretInfo -Times 0 -Exactly
        Assert-MockCalled Get-Secret -Times 0 -Exactly
    }

    It "throws error if credentials are not found in HRProPS vault" {
        Mock Get-SecretVault {@{Name = "HRProPS"}}

        { Get-HRPCredentials } | Should -Throw "No HR Pro credentials were found in vault `"HRProPS`". Run Set-HRPCredentials first."
        Assert-MockCalled Get-SecretVault -Times 1 -Exactly
        Assert-MockCalled Get-SecretInfo -Times 1 -Exactly
        Assert-MockCalled Get-Secret -Times 0 -Exactly
    }

    It "returns credentials when the vault and secret exist" {
        Mock Get-SecretVault {@{Name = "HRProPS"}}
        Mock Get-SecretInfo {@{Name = "HRProPS"}}

        $cred = Get-HRPCredentials
        $cred.Username | Should -Be "testuser"
        $cred.Password | Should -BeOfType [SecureString]
        $cred | Should -BeOfType [PSCredential]


        Assert-MockCalled Get-SecretVault -Times 1 -Exactly
        Assert-MockCalled Get-SecretInfo -Times 1 -Exactly
        Assert-MockCalled Get-Secret -Times 1 -Exactly
    }

    It "throws if SecretManagement is not installed" {
        Mock Get-Module {$false} -ParameterFilter {
            $Name -eq "Microsoft.PowerShell.SecretManagement"
        }

        { Get-HRPCredentials } | Should -Throw "Microsoft.PowerShell.SecretManagement module is not installed."
    }

    It "throws if SecretStore is not installed" {
        Mock Get-Module {$false} -ParameterFilter { 
            $Name -eq "Microsoft.PowerShell.SecretStore"
        }

        { Get-HRPCredentials } | Should -Throw "Microsoft.PowerShell.SecretStore module is not installed."
    }    
}