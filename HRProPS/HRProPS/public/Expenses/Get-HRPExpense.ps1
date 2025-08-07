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
