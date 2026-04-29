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

Describe "Get-HRPEmployee" {
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
            }
        )

        Mock Invoke-HRPAPI {
            $testResponse
        }
    }

    Context "When the function is executed" {
        It "returns the expected response from the API" {
            $testResponse = Get-HRPEmployee -ID 1

            $testResponse | Should -BeofType [pscustomobject]
            $testResponse.Count | Should -Be  1
            $testResponse.ID | Should -Be 1
            $testResponse.Title | Should -Be "Mr"
            $testResponse.Contract.DaysPerWeek | Should -Be 5
            $testResponse.Termination.TerminationDate | Should -Be "2024-01-01"
            $testResponse.Termination.LastWorkingDate | Should -Be "2023-12-31"

            
        }

        It "constructs the correct URI" {
            $expectedUri = "https://api.hrapi.co.uk/api/Employee/1"
            Get-HRPEmployee -ID 1

            Assert-MockCalled -CommandName Invoke-HRPAPI -Times 1 -Exactly -ParameterFilter {
                $Uri -eq $expectedUri -and
                $Method -eq "GET"
            }
        }

        It "returns nothing when API returns nothing" {
            Mock Invoke-HRPAPI { $null }
            $response = Get-HRPEmployee -ID 2
            $response | Should -Be $null
        }
    }
}