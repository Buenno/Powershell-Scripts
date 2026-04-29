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

Describe "Get-HRPEventCalendar" {
    BeforeAll {
        $testResponse = @(
            [pscustomobject]@{
                ID = 1
                Title   = "Event 1"
            },
            [pscustomobject]@{
                ID = 2
                Title   = "Event 2"
            }
        )

        Mock Invoke-HRPAPI {
            $testResponse
        }
    }
    
    Context "When the function is executed" {
        It "returns the expected response from the API" {
            $testResponse = Get-HRPEventCalendar -ID 12345 -Year 1970

            $testResponse | Should -BeofType [pscustomobject]
            $testResponse[0].ID | Should -Be 1
            $testResponse[0].Title | Should -Be "Event 1"
            $testResponse[1].ID | Should -Be 2
            $testResponse[1].Title | Should -Be "Event 2"
        } 

        It "constructs the correct URI for parameter set `"Year`"" {
            $expectedUri = "https://api.hrapi.co.uk/api/Event-Calendar/12345/1970"
            Get-HRPEventCalendar -ID 12345 -Year (Get-Date "1970-01-01")

            Assert-MockCalled -CommandName Invoke-HRPAPI -Times 1 -Exactly -ParameterFilter {
                $Uri -eq $expectedUri -and
                $Method -eq "GET"
            }
        }

        It "constructs the correct URI for parameter set `"Date`"" {
            $expectedUri = "https://api.hrapi.co.uk/api/Event-Calendar/12345?dateFrom=1970-01-01T00:00:00&dateTo=1970-12-31T00:00:00"
            Get-HRPEventCalendar -ID 12345 -DateFrom (Get-Date "1970-01-01") -DateTo (Get-Date "1970-12-31")

            Assert-MockCalled -CommandName Invoke-HRPAPI -Times 1 -Exactly -ParameterFilter {
                $Uri -eq $expectedUri -and
                $Method -eq "GET"
            }
        }

        It "returns nothing when API returns nothing" {
            Mock Invoke-HRPAPI { $null }
            $response = Get-HRPEventCalendar -ID 12345 -Year (Get-Date "1970-01-01")
            $response | Should -Be $null
        }
    }
}