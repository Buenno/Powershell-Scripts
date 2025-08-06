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
