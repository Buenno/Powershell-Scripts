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

Describe "Get-HRPEmployees" {
    BeforeAll {
        $testResponse = @(
            [pscustomobject]@{
                ID = 1
                Personal = [pscustomobject]@{
                    Title   = "Mr"
                }
                Contract = [pscustomobject]@{
                    DaysPerWeek = 5
                }
                Termination = [pscustomobject]@{
                    TerminationDate = "2024-01-01"
                    LastWorkingDate = "2023-12-31"
                }
            },
            [pscustomobject]@{
                ID = 2
                Personal = [pscustomobject]@{
                    Title   = "Mrs"
                }
                Contract = [pscustomobject]@{
                    DaysPerWeek = 3
                }
                Termination = [pscustomobject]@{
                    TerminationDate = "2024-04-01"
                    LastWorkingDate = "2023-09-31"
                }
            }
        )

        Mock Invoke-HRPAPI {
            $testResponse
        }
    }

    Context "When the function is executed" {
        It "returns the expected response from the API" {
            $testResponse = Get-HRPEmployees

            $testResponse | Should -BeofType [pscustomobject]
            $testResponse.Count | Should -Be  2

            $testResponse[0].ID | Should -Be 1
            $testResponse[0].Title | Should -Be "Mr"
            $testResponse[0].Contract.DaysPerWeek | Should -Be 5
            $testResponse[0].Termination.TerminationDate | Should -Be "2024-01-01"
            $testResponse[0].Termination.LastWorkingDate | Should -Be "2023-12-31"

            $testResponse[1].ID | Should -Be 2
            $testResponse[1].Title | Should -Be "Mrs"
            $testResponse[1].Contract.DaysPerWeek | Should -Be 3
            $testResponse[1].Termination.TerminationDate | Should -Be "2024-04-01"
            $testResponse[1].Termination.LastWorkingDate | Should -Be "2023-09-31"
            
        }

        It "constructs the correct URI" {
            $expectedUri = "https://api.hrapi.co.uk/api/Employees/"
            Get-HRPEmployees

            Assert-MockCalled -CommandName Invoke-HRPAPI -Times 1 -Exactly -ParameterFilter {
                $Uri -eq $expectedUri -and
                $Method -eq "GET"
            }
        }

        It "returns nothing when API returns nothing" {
            Mock Invoke-HRPAPI { $null }
            $response = Get-HRPEmployees
            $response | Should -Be $null
        }
    }
}