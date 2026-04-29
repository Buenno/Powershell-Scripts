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

Describe "Get-HRPCompany" {
    BeforeAll {
        $testResponse = @{
            CompanyID = 12345
            Email     = "test@company.com"
        }

        Mock Invoke-HRPAPI {
            $testResponse
        }
    }
    
    Context "When the function is executed" {
        it "returns the expected response from the API" {
            $response = Get-HRPCompany

            $response | Should -BeOfType [PSCustomObject]
            $response.CompanyID | Should -Be 12345
            $response.Email | Should -Be "test@company.com"
        }
        
        It "returns nothing when API returns nothing" {
            Mock Invoke-HRPAPI { $null }
            $response = Get-HRPCompany
            $response | Should -Be $null
        }
    }
}