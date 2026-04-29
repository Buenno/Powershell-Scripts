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

Describe "Get-HRPToken" {
    BeforeAll {
        $username = "TestUser"
        $password = "TestPass"

        $script:HRProPS = [pscustomobject]@{
            Username = $username
            Password = $password
        }

        $testToken = "TestToken"

        Mock Invoke-RestMethod {
            [PSCustomObject]@{
                access_token  = $testToken
                refresh_token = "RefreshToken"
            }
        }
    }

    BeforeEach {
        Get-HRPToken
    }

    Context "When the function is executed" {
        It "creates a valid basic auth header" {
            $expected = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("$username` : $password"))
            Assert-MockCalled Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
                $headers["Authorization"] -eq "Basic $expected" -and
                $headers["grant_type"] -eq "password"
            }
        }
        It "stores a token object in `$Script scope variable `"Token`"" {
            $Script:Token | Should -BeOfType [System.Management.Automation.PSCustomObject]
        }
        It "sets the token variable to the expected type and value" {
            $Script:Token.Token | Should -Be $testToken
            $Script:Token.Token | Should -BeOfType [string]
        }
        It "token variable contains a token of type [string]" {
            $Script:Token.Token | Should -BeOfType [string]
        }
        It "token variable contains a valid header" {
            $Script:Token.Header | Should -Not -Be $null
            $Script:Token.Header | Should -BeOfType [System.Collections.Hashtable]
            $Script:Token.Header['Authorization'] | Should -Be "Bearer $testToken"
            $Script:Token.Header['grant_type'] | Should -Be "access_token"
        }
        It "only sends one API call with the correct parameters" {
             Assert-MockCalled Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
                $Uri -eq "https://api.hrapi.co.uk/api/token/" -and
                $Method -eq "GET"
            }
        }
        It "passes the correct parameters to Invoke-RestMethod" {
            Assert-MockCalled Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
                $Uri -eq "https://api.hrapi.co.uk/api/token/" -and
                $Method -eq "GET"     
            }
        }
        It "overwrites `$script:Token on subsequent calls" {
            $originalToken = $Script:Token
            Get-HRPToken

            $Script:Token.Token | Should -Not -Be $originalToken
            $script:Token.Token | Should -Not -BeNullOrEmpty 
        }
    }
}