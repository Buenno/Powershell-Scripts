BeforeAll {
  $here = (Split-Path -Parent $PSCommandPath) -replace "Tests", "HRProPS"
  $sut = (Split-Path -Leaf $PSCommandPath) -replace ".Unit.Tests.", "."

  . (Join-Path -Path $here -ChildPath $sut)
}

Describe "Get-HRPToken" {
  BeforeAll {
    $testToken = "HtxuAa3NEelC7mFb6Y2OC3CxksxUDrRgujTkhHnNiyy0AKfjLsfiV5E6CmzZsSSCohhB7L0fjDNBgI1OjiAV01YXaEeUBJtO"

    Mock Invoke-RestMethod {
      [PSCustomObject]@{
        access_token  = $testToken
        refresh_token = "czz1lILNamKfRKuNbllxTodY82j819f0ec4ryMdKYzkhcaEToYkBdBW0g8m8bdOBCpc2cGQGbI9goUQjek7W4tjTrFpdwwjb"
      }
    }
  }

  BeforeEach {
    Get-HRPToken
  }

  Context "When the function is executed" {
    It "Stores a token object in `$Script scope variable `"Token`"" {
      $Script:Token | Should -BeOfType [System.Management.Automation.PSCustomObject]
    }
    It "Token variable contains the expected value" {
      $Script:Token.Token | Should -Be $testToken
    }
    It "Token variable contains a token of type [string]" {
      $Script:Token.Token | Should -BeOfType [string]
    }
    It "Token variable contains a header" {
      $Script:Token.Header | Should -Not -Be $null
    }
    It "Token variable contains a header of type [hashtable]" {
      $Script:Token.Header | Should -BeOfType [System.Collections.Hashtable]
    }
    It "Token variable contains a header with valid authorization property" {
      $Script:Token.Header['Authorization'] | Should -Be "Bearer $testToken"
    }
    It "Token variable contains a header with valid grant_type property" {
      $Script:Token.Header['grant_type'] | Should -Be "access_token"
    }
    It "Only sends one API call" {
      Assert-MockCalled Invoke-RestMethod -Times 1 -Exactly
    }
  }
}