BeforeAll {
    # Dot-source public functions
    Get-ChildItem "$PSScriptRoot\..\..\src\public\*\*.ps1" |
        ForEach-Object {
            . $_.FullName
        }

    # Dot-source private functions
    Get-ChildItem "$PSScriptRoot\..\..\src\private\*.ps1" |
        ForEach-Object {
            . $_.FullName
        }
}

Describe "Invoke-HRPAPI" {
    BeforeEach {
        Mock Invoke-RestMethod {
            @(
                "Test1",
                "Test1"
            )
        }

        Mock Get-HRPToken { 
            $script:Token = @{ 
                Header = @{ 
                    Authorization = "Bearer newtoken" 
                } 
            } 
        }
    }

    Context "When executing the function" {
        It "calls Invoke-RestMethod with the correct parameters" {
            Invoke-HRPAPI -Uri "https://testurl.co.uk" -Method Get

            Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
                $URI -eq "https://testurl.co.uk" -and 
                $Method -eq "GET"
            }
        }

        It "returns data when a successful call is made on first attempt" {
            $result = Invoke-HRPAPI -Uri "https://testurl.co.uk" -Method Get

            $result.Count | Should -Be 2
            Assert-MockCalled Invoke-RestMethod -Times 1 -Exactly
            Assert-MockCalled Get-HRPToken -Times 0 -Exactly
        }
    }

    Context "When retrying" {
        It "retries once and refreshes token on 401" {
            $script:callCount = 0

            Mock Invoke-RestMethod {
                $script:callCount++
                $message = "Unauthorised"
                $object = New-Object System.Net.Http.HttpResponseMessage(401)
                throw [Microsoft.PowerShell.Commands.HttpResponseException]::new($message, $object)
            } -ParameterFilter {$callCount -eq 0}

            Mock Invoke-RestMethod { 
                $script:callCount++
                @("item1")
            } -ParameterFilter { $callCount -eq 1 }

            $result = Invoke-HRPAPI -Uri "https://testurl.co.uk" -Method Get

            $result.Count | Should -Be 1
            Assert-MockCalled Get-HRPToken -Times 1 -Exactly
            Assert-MockCalled Invoke-RestMethod -Times 2 -Exactly
        }

        It "throws after 3 retries" {
            Mock Invoke-RestMethod {
                $message = "Unauthorised"
                $object = New-Object System.Net.Http.HttpResponseMessage(400)
                throw [Microsoft.PowerShell.Commands.HttpResponseException]::new($message, $object)
            }

            $result = Invoke-HRPAPI -Uri "https://testurl.co.uk" -Method Get

            $result.Count | Should -Be 0
            Assert-MockCalled Get-HRPToken -Times 0 -Exactly
            Assert-MockCalled Invoke-RestMethod -Times 3 -Exactly
        }
    }

    Context "When paginating with -Paginate" {
        BeforeEach {
            Mock Invoke-RestMethod {
                1..200 | ForEach-Object {"item$_"}
            } -ParameterFilter {$Uri -eq "https://testurl.co.uk/"}

            Mock Invoke-RestMethod {
                201..250 | ForEach-Object {"item_$_"}
            } -ParameterFilter {$Uri -eq "https://testurl.co.uk/2"}

            Mock Invoke-RestMethod {
                @()
            } -ParameterFilter {$Uri -eq "https://testurl.co.uk/3"}
        }
        It "paginates if first page has 200 items" {
            $results = Invoke-HRPAPI -Uri "https://testurl.co.uk" -Method Get -Paginate

            $results.Count | Should -Be 250 
            Assert-MockCalled Invoke-RestMethod -Times 2 -Exactly
        }

        It "does not paginate when first page has less than 200 results" {
            Mock Invoke-RestMethod {
                1..50 | ForEach-Object {"item$_"}
            } -ParameterFilter {$Uri -eq "https://testurl.co.uk"}

            $results = Invoke-HRPAPI -Uri "https://testurl.co.uk" -Method Get -Paginate

            $results.Count | Should -Be 50 
            Assert-MockCalled Invoke-RestMethod -Times 1 -Exactly
        }

        It "stops when next page is empty" {
            Mock Invoke-RestMethod {
                1..200 | ForEach-Object {"item$_"}
            } -ParameterFilter {$Uri -eq "https://testurl.co.uk/"}

            Mock Invoke-RestMethod {
                @()
            } -ParameterFilter {$Uri -eq "https://testurl.co.uk/2"}

            $results = Invoke-HRPAPI -Uri "https://testurl.co.uk" -Method Get -Paginate

            $results.Count | Should -Be 200 
            Assert-MockCalled Invoke-RestMethod -Times 2 -Exactly
        }

        It "does not paginate when -Paginate is not supplied" {
            $results = Invoke-HRPAPI -Uri "https://testurl.co.uk" -Method Get

            $results.Count | Should -Be 200 
            Assert-MockCalled Invoke-RestMethod -Times 1 -Exactly
        }
    }
}