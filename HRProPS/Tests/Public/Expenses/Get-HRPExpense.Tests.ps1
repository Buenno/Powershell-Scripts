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

Describe "Get-HRPExpense" {
    BeforeAll {
        $testResponse = @(
            [pscustomobject]@{
                ID = 1
                ParentID   = 12
            }
        )

        Mock Invoke-HRPAPI {
            $testResponse
        }
    }

    Context "When the function is executed" {
        It "returns the expected response from the API for the ExpenseID parameter set" {
            $testResponse = Get-HRPExpense -ExpenseID 12345

            $testResponse | Should -BeofType [pscustomobject]
            $testResponse.Count | Should -Be  1
            $testResponse[0].ID | Should -Be 1
            $testResponse[0].ParentID | Should -Be 12
            
        }

        It "returns the expected response from the API for the EmployeeID parameter set" {
            $testResponse = @(
                [pscustomobject]@{
                    ID = 1
                    ParentID   = 12
                },
                [pscustomobject]@{
                    ID = 2
                    ParentID   = 22
                }
            )

            $testResponse = Get-HRPExpense -ExpenseID 12345

            $testResponse | Should -BeofType [pscustomobject]
            $testResponse.Count | Should -Be  2
            $testResponse[0].ID | Should -Be 1
            $testResponse[0].ParentID | Should -Be 12
            $testResponse[1].ID | Should -Be 2
            $testResponse[1].ParentID | Should -Be 22
        }

        It "constructs the correct URI for parameter set `"ExpenseID`"" {
            $expectedUri = "https://api.hrapi.co.uk/api/Expense/12345"
            Get-HRPExpense -ExpenseID 12345 

            Assert-MockCalled -CommandName Invoke-HRPAPI -Times 1 -Exactly -ParameterFilter {
                $Uri -eq $expectedUri -and
                $Method -eq "GET"
            }
        }

        It "constructs the correct URI for parameter set `"EmployeeID`"" {
            $expectedUri = "https://api.hrapi.co.uk/api/Expense/Employee/12345/Submit/67890"
            Get-HRPExpense -EmployeeID 12345 -Submit 67890

            Assert-MockCalled -CommandName Invoke-HRPAPI -Times 1 -Exactly -ParameterFilter {
                $Uri -eq $expectedUri -and
                $Method -eq "GET"
            }
        }

        It "returns nothing when API returns nothing" {
            Mock Invoke-HRPAPI { $null }
            $response = Get-HRPExpense -EmployeeID 12345 -Submit 67890
            $response | Should -Be $null
        }
    }
}