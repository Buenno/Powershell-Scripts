BeforeAll {
  $here = (Split-Path -Parent $PSCommandPath) -replace "Tests", "HRProPS"
  $sut = (Split-Path -Leaf $PSCommandPath) -replace ".Unit.Tests.", "."

  . (Join-Path -Path $here -ChildPath $sut)

  $testString = "ThisIsATestString2000"
  $testSecureString = ConvertTo-SecureString -String $testString -AsPlainText -Force
}

Describe "Invoke-HRPEncrypt" {
  BeforeAll {
    $testEncryptedString = ConvertFrom-SecureString -SecureString $testSecureString
  }
  Context "When the functon is executed with string parameter" {
    It "Returns a System.Security.SecureString object" {
      Invoke-HRPEncrypt -String $testString | Should -BeOfType [System.Security.SecureString]
    }
    It "Correctly encrypts the provided string" {
      Invoke-HRPEncrypt -string $testString | ConvertFrom-SecureString -AsPlainText | Should -Be $testString
    }
  }
}

Describe "Invoke-HRPDecrypt" {
  Context "When the function is executed with string parameter" {
    It "returns a System.String object" {
      Invoke-HRPDecrypt -String $testSecureString | Should -BeOfType [string]
    }
    It "Correctly decrypts the provided string" {
      Invoke-HRPDecrypt -String $testSecureString | Should -Be $testString
    }
  }
}

Describe "Get-HRPDecryptedConfig" {
  BeforeAll {
    $testConfig = @{
      "Username"    = $testSecureString
      "Password"    = $testSecureString
    }
    $decryptedConfig = $testConfig | Get-HRPDecryptedConfig -ConfigName TestConfig
  }
  Context "When an encrypted configuration is piped into function" {
    It "Correctly decrypts the username" {
      $decryptedConfig.Username | Should -Be $testString
    }
    It "Correctly decrypts the password" {
      $decryptedConfig.Password | Should -Be $testString
    }
    It "Passes the configuration name correctly" {
      $decryptedConfig.ConfigName | Should -Be "TestConfig"
    }
  }
}