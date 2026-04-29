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

Describe "Get-HRPExpenseFile" {
    BeforeAll {
        $testResponse = @(
            [pscustomobject]@{
                ExpenseID = 1
                Name      = "First Expense"
            },
            [pscustomobject]@{
                ExpenseID = 2
                Name      = "Second Expense"
            }
        )

        Mock Invoke-HRPAPI {
            $testResponse
        }
    }
    
    Context "When the function is executed" {
        It "returns the expected response from the API for the ExpenseID parameter set" {
            $testResponse = Get-HRPExpenseFile -ExpenseID 12345

            $testResponse | Should -BeofType [pscustomobject]
            $testResponse.Count | Should -Be  "2"
            $testResponse[0].ExpenseID | Should -Be "1"
            $testResponse[0].Name | Should -Be "First Expense"
            $testResponse[1].ExpenseID | Should -Be "2"
            $testResponse[1].Name | Should -Be "Second Expense"
        }

        It "returns the expected response from the API for the ExpenseFileID parameter set" {
            $testResponse = @(
                [pscustomobject]@{
                    ExpenseID = 1
                    Name      = "First Expense"
                }
            )

            $testResponse = Get-HRPExpenseFile -ExpenseFileID 6789101112

            $testResponse | Should -BeofType [pscustomobject]
            $testResponse.ExpenseID | Should -Be 1
            $testResponse.Name | Should -Be "First Expense"
        }
        It "constructs the correct URI for parameter set `"ExpenseID`"" {
            $expectedUri = "https://api.hrapi.co.uk/api/ExpenseFile/Expense/12345"
            Get-HRPExpenseFile -ExpenseID 12345 

            Assert-MockCalled -CommandName Invoke-HRPAPI -Times 1 -Exactly -ParameterFilter {
                $Uri -eq $expectedUri -and
                $Method -eq "GET"
            }
        }

        It "constructs the correct URI for parameter set `"HRPExpenseFile`"" {
            $expectedUri = "https://api.hrapi.co.uk/api/ExpenseFile/6789101112"
            Get-HRPExpenseFile -ExpenseFileID 6789101112

            Assert-MockCalled -CommandName Invoke-HRPAPI -Times 1 -Exactly -ParameterFilter {
                $Uri -eq $expectedUri -and
                $Method -eq "GET"
            }
        }

        It "returns nothing when API returns nothing" {
            Mock Invoke-HRPAPI { $null }
            $response = Get-HRPExpenseFile -ExpenseFileID 6789101112
            $response | Should -Be $null
        }
    }
}