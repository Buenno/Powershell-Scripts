function Get-HRPDecryptedConfig {
  [CmdletBinding()]
  Param(
    [Parameter(Position = 0, ValueFromPipeline, Mandatory)]
    [object] $Config,
    [Parameter(Position = 1, Mandatory)]
    [string] $ConfigName
  )
  $Config | Select-Object -Property @(
    @{l = 'ConfigName'; e = { $ConfigName }}
    @{l = 'Username'; e = { Invoke-HRPDecrypt $_.Username } }
    @{l = 'Password'; e = { Invoke-HRPDecrypt $_.Password } }
  )
}

function Invoke-HRPDecrypt {
  Param($String)
  if ($String -is [System.Security.SecureString]) {
    [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR(
      [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR(
          $String
      )
    )
  } 
  elseif ($String -is [ScriptBlock]) {
    $String.InvokeReturnAsIs()
  } 
  else {
    $String
  }
}

Function Invoke-HRPEncrypt {
  Param($string)
  if ($string -is [System.String] -and -not [String]::IsNullOrEmpty($String)) {
    ConvertTo-SecureString -String $string -AsPlainText -Force
  } 
  else {
    $string
  }
}
Function Invoke-HRPAPI {
  <#
    .SYNOPSIS
       Sends a request to the HR Pro web service.
    .DESCRIPTION
      Sends a request to the HR Pro web service. This function will handle authentication headers, as well as pagination. 
    .PARAMETER Uri
      Specifies the Uniform Resource Identifier (URI) of the resource to which the web request is sent.
    .PARAMETER Method
      Specifies the method used for the web request. The acceptable values for this parameter are:
      - GET
      - PUT
      - POST
      - DELETE
    .PARAMETER Paginate
      Iterates through page numbers until all results are returned.
    .EXAMPLE
      Invoke-HRPAPI -Uri "https://api.hrapi.co.uk/api/Employees/" -Method GET -Paginate
  #>

    [CmdletBinding()]
    Param(
      [Parameter(Mandatory = $true)]
      [string] $Uri,
      [Parameter(Mandatory = $true)]
      [ValidateSet("GET","PUT","POST","DELETE")]
      [string] $Method,
      [Parameter(Mandatory = $false)]
      [switch] $Paginate
    )

  Begin {
    $retry = $true
    $retryCounter = 0
    $retryLimit = 3
  }

  Process {
    while ($retry -and $retryCounter -lt $retryLimit){
      $retryCounter++
      try {
        $response = Invoke-RestMethod -Uri $Uri -Method $Method -Headers $script:Token.Header
        $retry = $false
      }
      catch [Microsoft.PowerShell.Commands.HttpResponseException] {
        if ($_.Exception.Response.StatusCode.value__ -eq '401'){
          Write-Verbose -Message "$($_.Exception.Message) - Attempting to reauthenticate"
          Get-HRPToken
        } 
      }
      catch {
        throw $_.Exception.Message
      }
    }
    $data = [System.Collections.Generic.List[object]]::new()
    foreach ($r in $response){
      $data.Add($r)
    }

    if ($Paginate){
      <#
        The first results page number can be either '0' or '1', the results are the same. The next page after the first will always be 2. 
        We only want to go to the next page if the results count -eq '200' as this is the limit. We will continue incrementing the page number
        until no more results are returned.
      #>
      $maxResults = '200'
      if ($response.count -eq $maxResults){
        $page = 2
        do {
          $nextUri = "$Uri/$page"
          $presponse = Invoke-RestMethod -Uri $nextUri -Method $Method -Headers $script:Token.Header
          if ($presponse.Count -gt '0'){
            foreach ($p in $presponse){
              $data.Add($p)
            }
            $page++
          }
        }
        until ($presponse.Count -eq '0' -or $response.Count % 200 -ne '0')
      }
    }
    $data
  }
      
  END {}
}

Function Get-HRPToken {
  <#
    .SYNOPSIS
      Requests an Access Token for REST API authentication
    .DESCRIPTION
      Requests an Access Token for REST API authentication. Returns an object containing the token, as well as auth headers suitable for future API calls.
    .EXAMPLE
      Get-HRProAuthToken
  #>

    [CmdletBinding()]
    Param()

  Begin {
    # Get the API credentials from stored configuration
    $credentials = $script:HRProPS

    # Create headers for API call
    $auth = $credentials.Username + ':' + $credentials.Password
    $encoded = [System.Text.Encoding]::UTF8.GetBytes($auth)
    $authorizationInfo = [System.Convert]::ToBase64String($encoded)
    $headers = @{
      "Authorization" = "Basic $($authorizationInfo)"
      "grant_type"    = "password"
    }
  }
  Process {
    # Invoke API call to obtain authentication token
    $token = Invoke-RestMethod -Uri "https://api.hrapi.co.uk/api/token/" -Method GET -Headers $headers

    # Build an authentication header to be used in future API calls
    $tokenObject = [pscustomobject]@{
      Token     = $token.access_token
      Header = @{
          "Authorization" = "Bearer $($token.access_token)"
          "grant_type"    = "access_token"
      }
    }
    
    # Return authentication object
    $script:Token =  $tokenObject
  }
}

Export-ModuleMember -Function 'Get-HRPToken'
Function Get-HRPCompany {
  <#
    .SYNOPSIS
      Returns Company data
    .DESCRIPTION
      Returns Company data
    .EXAMPLE
      Get-HRPCompany
    .LINK
      https://api.hrapi.co.uk/swagger/ui/index#!/Company/Company_Get
  #>

    [CmdletBinding()]
    Param()

  Process {
    $response = Invoke-HRPAPI -Uri "https://api.hrapi.co.uk/api/Company" -Method GET -ErrorAction Stop
    $response
  } 
}
Export-ModuleMember -Function 'Get-HRPCompany'
function Get-HRPConfig {
  <#
  .SYNOPSIS
  Loads the specified HRProPS config

  .DESCRIPTION
  Loads the specified HRProPS config

  .PARAMETER ConfigName
  The config name to load

  .PARAMETER PassThru
  If specified, returns the config after loading it

  .PARAMETER NoImport
  If $true, just returns the specified config but does not import it in the current session

  .EXAMPLE
  Get-HRProPSConfig -ConfigName personalDomain -PassThru

  This will load the config named "personalDomain" and return it as a PSObject
  #>
    [CmdletBinding()]
    Param(
      [Parameter(Mandatory = $false,Position = 0)]
      [String] $ConfigName,
      [Parameter(Mandatory = $false)]
      [Switch] $PassThru,
      [Parameter(Mandatory = $false)]
      [Switch] $NoImport
    )

  Process {
    $fullConf = Import-Configuration -CompanyName 'The Abbey' -Name 'HRProPS'
    if (!$ConfigName) {
      $choice = $fullConf["DefaultConfig"]
      Write-Verbose "Importing default config: $choice"
    }
    else {
      $choice = $ConfigName
      Write-Verbose "Importing config: $choice"
    }
    $encConf = [PSCustomObject]($fullConf[$choice])
        
    $decryptParams = @{
      ConfigName = $choice
    }
    $decryptedConfig = $encConf | Get-HRPDecryptedConfig @decryptParams
    Write-Verbose "Retrieved configuration '$choice'"
    if (!$NoImport) {
      $script:HRProPS = $decryptedConfig
    }
    if ($PassThru) {
      $decryptedConfig
    }
  }
}
Export-ModuleMember -Function 'Get-HRPConfig'
Function Set-HRPConfig {
  <#
    .SYNOPSIS
      Creates or updates a config
    .DESCRIPTION
      Creates or updates a config
    .PARAMETER ConfigName
      The friendly name for the config you are creating or updating
    .PARAMETER Username
      The username to use for authentication
    .PARAMETER Password
      The password to use for authentication
    .PARAMETER SetAsDefaultConfig
      If passed, sets the ConfigName as the default config to load on module import
    .EXAMPLE
      Set-HRProPSConfig -Username Admin -Password "AdminPassword12" -SetAsDefaultConfig
  #>

  [CmdletBinding()]
  Param(
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
    [ValidateScript( {
        if ($_ -eq "DefaultConfig") {
          throw "You must specify a ConfigName other than 'DefaultConfig'. That is a reserved value."
        }
        elseif ($_ -notmatch '^[a-zA-Z]+[a-zA-Z0-9]*$') {
          throw "You must specify a ConfigName that starts with a letter and does not contain any spaces, otherwise the Configuration will break"
        }
        else {
          $true
        }
      })]
    [string]
    $ConfigName = $Script:ConfigName,
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
    [string] $Username,
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
    [SecureString] $Password,
    [parameter(Mandatory = $false)]
    [switch]
    $SetAsDefaultConfig
  )

  Begin {}
  Process {
    $configHash = Import-Configuration -CompanyName 'The Abbey' -Name 'HRProPS'
    if (!$ConfigName) {
      $ConfigName = if ($configHash["DefaultConfig"]) {
        $configHash["DefaultConfig"]
      }
      else {
        "default"
        $configHash["DefaultConfig"] = "default"
      }
    }
    Write-Verbose "Setting config name '$ConfigName'"
    $configParams = @('Username', 'Password')
    if ($SetAsDefaultConfig -or !$configHash["DefaultConfig"]) {
      $configHash["DefaultConfig"] = $ConfigName
    }
    if (!$configHash[$ConfigName]) {
      $configHash.Add($ConfigName, (@{}))
    }
    foreach ($key in ($PSBoundParameters.Keys | Where-Object { $configParams -contains $_ })) {
      $configHash["$ConfigName"][$key] = (Invoke-HRPEncrypt $PSBoundParameters[$key])
    }
  } 
  End {
    $configHash | Export-Configuration -CompanyName 'The Abbey' -Name 'HRProPS' -Scope User
  }
}

Export-ModuleMember -Function 'Set-HRPConfig'
Function Get-HRPEmployee {
  <#
    .SYNOPSIS
      Retreive a specific employee records from HR Pro using the employee ID number
    .DESCRIPTION
      Retreive a specific employee records from HR Pro using the employee ID number
    .EXAMPLE
      Get-HRPEmployees
    .LINK
      https://api.hrapi.co.uk/swagger/ui/index#!/Employee/Employee_Get
  #>

    [CmdletBinding()]
    Param(
      [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
      [string] $ID
    )

  Process {
    $response = Invoke-HRPAPI -Uri "https://api.hrapi.co.uk/api/Employee/$ID" -Method GET -ErrorAction Stop
    
    foreach ($r in $response){
      $termination = [pscustomobject]@{
        TerminationDate = $r.Termination.TerminationDate
        LastWorkingDate = $r.Termination.LastWorkingDate
      }
      $contract = [pscustomobject]@{
        StartDate           = $r.Contract.StartDate
        ContServiceDate     = $r.Contract.ContServiceDate
        IsLineManager       = $r.Contract.IsLineManager
        Job                 = $r.Contract.Job.Value
        Company             = $r.Contract.Company.Value
        Country             = $r.Contract.Country.Value
        LocationDivision    = $r.Contract.LocationDivision.Value
        Department          = $r.Contract.Department.Value
        Team                = $r.Contract.Team.Value
        LineManager         = $r.Contract.LineManager.Value
        ContractType        = $r.Contract.ContractType.Value
        EmployeeType        = $r.Contract.EmployeeType
        PersonalGrade       = $r.Contract.PersonalGrade.Value
        Role                = $r.Contract.Role.Value
        AdditionalRoles     = $r.Contract.AdditionalRoles.Value
        ImmigrationStatus   = $r.Contract.ImmigrationStatus.Value
        HoursPerWeek        = $r.Contract.HoursPerWeek
        DaysPerWeek         = $r.Contract.DaysPerWeek
        FTE                 = $r.Contract.FTE
        WorkPattern         = $r.Contract.WorkPattern.Value
        Volunteer           = $r.Contract.Volunteer
        ISamsExclude        = $r.Contract.ISamsExclude
        ProbationaryPeriod  = $r.Contract.ProbationaryPeriod.Value
        NoticePeriod        = $r.Contract.NoticePeriod.Value
        CompanyDirector     = $r.Contract.CompanyDirector
        JobShare            = $r.Contract.JobShare
        SraRegistered       = $r.Contract.SraRegistered
        Overtime            = $r.Contract.Overtime
      }

      $employee = [pscustomobject]@{
        ID                    = $r.ID
        Title                 = $r.Personal.Title
        KnownAs               = $r.Personal.KnownAs
        Forenames             = $r.Personal.Forenames
        Surname               = $r.Personal.Surname
        Address               = $r.address
        Gender                = $r.Personal.Gender
        Pronouns              = $r.Personal.Pronouns.Value
        MaritalStatus         = $r.Personal.MaritalStatus
        DateOfBirth           = $r.Personal.DateOfBirth
        EmployeeNumber        = $r.Personal.EmployeeNumber
        WorkEmail             = $r.Personal.WorkEmail
        PersonalEmail         = $r.Personal.PersonalEmail
        PersonalMobile        = $r.Personal.PersonalMobile
        DefaultEmailPrivate   = $r.Personal.DefaultEmailPrivate
        EmergencyContact      = $r.Personal.EmergencyContact
        EmergencyPhone        = $r.Personal.EmergencyPhone
        EmergencyAddress      = $r.Personal.EmergencyAddress
        EmergencyRelationship = $r.Personal.EmergencyRelationship
        EthnicOrigin          = $r.Personal.EthnicOrigin.Value
        Disability            = $r.Personal.Disability.Value
        GenderIdentity        = $r.Personal.GenderIdentity.Value
        Nationality           = $r.Personal.Nationality.Value
        Contract              = $contract
        Termination           = $termination
      }
      $employee
    }
  } 
}

Export-ModuleMember -Function 'Get-HRPEmployee'
Function Get-HRPEmployees {
  <#
    .SYNOPSIS
      Retreive employee records from HR Pro
    .DESCRIPTION
      Retreive employee records from HR Pro
    .EXAMPLE
      Get-HRPEmployees
    .LINK
      https://api.hrapi.co.uk/swagger/ui/index#!/Employees/Employees_Get
  #>

    [CmdletBinding()]
    Param()

  Process {
    $response = Invoke-HRPAPI -Uri "https://api.hrapi.co.uk/api/Employees/" -Method GET -Paginate -ErrorAction Stop
    
    foreach ($r in $response){
      $contract = [pscustomobject]@{
        StartDate           = $r.Contract.StartDate
        ContServiceDate     = $r.Contract.ContServiceDate
        IsLineManager       = $r.Contract.IsLineManager
        Job                 = $r.Contract.Job.Value
        Company             = $r.Contract.Company.Value
        Country             = $r.Contract.Country.Value
        LocationDivision    = $r.Contract.LocationDivision.Value
        Department          = $r.Contract.Department.Value
        Team                = $r.Contract.Team.Value
        LineManager         = $r.Contract.LineManager.Value
        ContractType        = $r.Contract.ContractType.Value
        EmployeeType        = $r.Contract.EmployeeType
        PersonalGrade       = $r.Contract.PersonalGrade.Value
        Role                = $r.Contract.Role.Value
        AdditionalRoles     = $r.Contract.AdditionalRoles.Value
        ImmigrationStatus   = $r.Contract.ImmigrationStatus.Value
        HoursPerWeek        = $r.Contract.HoursPerWeek
        DaysPerWeek         = $r.Contract.DaysPerWeek
        FTE                 = $r.Contract.FTE
        WorkPattern         = $r.Contract.WorkPattern.Value
        Volunteer           = $r.Contract.Volunteer
        ISamsExclude        = $r.Contract.ISamsExclude
        ProbationaryPeriod  = $r.Contract.ProbationaryPeriod.Value
        NoticePeriod        = $r.Contract.NoticePeriod.Value
        CompanyDirector     = $r.Contract.CompanyDirector
        JobShare            = $r.Contract.JobShare
        SraRegistered       = $r.Contract.SraRegistered
        Overtime            = $r.Contract.Overtime
      }

      $employee = [pscustomobject]@{
        ID                    = $r.ID
        Title                 = $r.Personal.Title
        KnownAs               = $r.Personal.KnownAs
        Forenames             = $r.Personal.Forenames
        Surname               = $r.Personal.Surname
        Address               = $address
        Gender                = $r.Personal.Gender
        Pronouns              = $r.Personal.Pronouns.Value
        MaritalStatus         = $r.Personal.MaritalStatus
        DateOfBirth           = $r.Personal.DateOfBirth
        EmployeeNumber        = $r.Personal.EmployeeNumber
        WorkEmail             = $r.Personal.WorkEmail
        PersonalEmail         = $r.Personal.PersonalEmail
        PersonalMobile        = $r.Personal.PersonalMobile
        DefaultEmailPrivate   = $r.Personal.DefaultEmailPrivate
        EmergencyContact      = $r.Personal.EmergencyContact
        EmergencyPhone        = $r.Personal.EmergencyPhone
        EmergencyAddress      = $r.Personal.EmergencyAddress
        EmergencyRelationship = $r.Personal.EmergencyRelationship
        EthnicOrigin          = $r.Personal.EthnicOrigin.Value
        Disability            = $r.Personal.Disability.Value
        GenderIdentity        = $r.Personal.GenderIdentity.Value
        Nationality           = $r.Personal.Nationality.Value
        Contract              = $contract
      }
      $employee
    }
  } 
}
Export-ModuleMember -Function 'Get-HRPEmployees'
Function Get-HRPEventCalendar {
  <#
    .SYNOPSIS
      Returns a list of Event Calendar items for the specified employee
    .DESCRIPTION
      Returns a list of Event Calendar items for the specified employee.
    .EXAMPLE
      Get-HRPEventCalendar -ID 63635 
    .LINK
      https://api.hrapi.co.uk/swagger/ui/index#!/EventCalendar/EventCalendar_Get
  #>

    [CmdletBinding(DefaultParameterSetName = 'Year')]
    Param(
      [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
      [Alias('EmployeeID')]
      [string] $ID,
      [Parameter(Mandatory = $true, ParameterSetName = 'Year', ValueFromPipelineByPropertyName = $true)]
      [datetime] $Year,
      [Parameter(Mandatory = $true, ParameterSetName = 'Date', ValueFromPipelineByPropertyName = $true)]
      [datetime] $DateFrom,
      [Parameter(Mandatory = $true, ParameterSetName = 'Date', ValueFromPipelineByPropertyName = $true)]
      [datetime] $DateTo
    )
  Begin {
    if ($PSCmdlet.ParameterSetName -eq "Year"){
      $Uri = "https://api.hrapi.co.uk/api/Event-Calendar/$ID/$($Year.Year)"
    }
    else {
      $from = $DateFrom.ToString("yyyy-MM-ddT00:00:00")
      $to = $DateTo.ToString("yyyy-MM-ddT00:00:00")
      $Uri = "https://api.hrapi.co.uk/api/Event-Calendar/$($ID)?dateFrom=$From&dateTo=$To"
    }
  }
  Process {
    $response = Invoke-HRPAPI -Uri $Uri -Method GET -ErrorAction Stop
    $response
  } 
}

Export-ModuleMember -Function 'Get-HRPEventCalendar'
Function Get-HRPExpense {
  <#
    .SYNOPSIS
      Returns a list of Expense objects.
    .DESCRIPTION
      Returns a list of Expense objects. Providing the Expense ID will return a list, 
      and providing the Employee ID and Submit ID will return that specific object. 

    .EXAMPLE
      Get-HRPExpense -ExpenseID 73534534

      This returns an Expense object which matches the given Expense ID.
    .EXAMPLE
      Get-HRPExpense -EmployeeID 951356 -Submit 3466342

      This returns a list of Expense objects for the specified Employee ID and Submit ID.
    .LINK
      https://api.hrapi.co.uk/swagger/ui/index#!/Expense/Expense_Get
  #>
    [CmdletBinding(DefaultParameterSetName = 'ExpenseID')]
    Param(
      [Parameter(Mandatory = $true, ParameterSetName = 'ExpenseID', ValueFromPipelineByPropertyName = $true)]
      [string] $ExpenseID,
      [Parameter(Mandatory = $true, ParameterSetName = 'EmployeeID', ValueFromPipelineByPropertyName = $true)]
      [string] $EmployeeID,
      [Parameter(Mandatory = $false, ParameterSetName = 'EmployeeID', ValueFromPipelineByPropertyName = $true)]
      [string] $SubmitID
    )
  Begin {
    if ($PSCmdlet.ParameterSetName -eq "ExpenseID"){
      $Uri = "https://api.hrapi.co.uk/api/Expense/$ExpenseID"
    }
    else {
      $Uri = "https://api.hrapi.co.uk/api/Expense/Employee/$EmployeeID/Submit/$SubmitID"
    }
  }
  Process {
    $response = Invoke-HRPAPI -Uri $Uri -Method GET -ErrorAction Stop
    $response
  } 
}

Export-ModuleMember -Function 'Get-HRPExpense'
Function Get-HRPExpenseFile {
  <#
    .SYNOPSIS
      Returns either a single or list of ExpenseFile objects.
    .DESCRIPTION
      Returns either a single or list of ExpenseFile objects. Providing the Expense ID will return a list, 
      and providing the ExpenseFile ID will return that specific object. 

    .EXAMPLE
      Get-HRPExpenseFile -ExpenseID 487436356 

      This returns a list of ExpenseFile objects which match the given Expense ID.
    .EXAMPLE
      Get-HRPExpenseFile -ExpenseFileID 35764667345 

      This returns a ExpenseFile object which matches the given ExpenseFile ID.
    .LINK
      https://api.hrapi.co.uk/swagger/ui/index#!/ExpenseFile/ExpenseFile_GetByExpenseId
  #>
    [CmdletBinding(DefaultParameterSetName = 'ExpenseID')]
    Param(
      [Parameter(Mandatory = $true, ParameterSetName = 'ExpenseID', ValueFromPipelineByPropertyName = $true)]
      [string] $ExpenseID,
      [Parameter(Mandatory = $true, ParameterSetName = 'ExpenseFileID', ValueFromPipelineByPropertyName = $true)]
      [string] $ExpenseFileID
    )
  Begin {
    if ($PSCmdlet.ParameterSetName -eq "ExpenseID"){
      $Uri = "https://api.hrapi.co.uk/api/ExpenseFile/Expense/$ExpenseID"
    }
    else {
      $Uri = "https://api.hrapi.co.uk/api/ExpenseFile/$ExpenseFileID"
    }
  }
  Process {
    $response = Invoke-HRPAPI -Uri $Uri -Method GET -ErrorAction Stop
    $response
  } 
}

Export-ModuleMember -Function 'Get-HRPExpenseFile'
try {
    Get-HRPConfig -ErrorAction Stop
}
catch {
    Write-Warning "There was no config returned! Please make sure you are using the correct key or have a configuration already saved."
}
