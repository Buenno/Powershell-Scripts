Function Get-HRPExpense {
<#
.SYNOPSIS
Returns a list of Expense objects.

.DESCRIPTION
Returns a list of Expense objects. Providing the Expense ID will return a list, `
and providing the Employee ID and Submit ID will return that specific object. 

.PARAMETER ExpenseID
The ID of the expense to retrieve.

.PARAMETER EmployeeID
The ID of the employee for whom to retrieve expenses.

.PARAMETER SubmitID
The ID of the submit for which to retrieve expenses.

.EXAMPLE
Get-HRPExpense -ExpenseID 12345

This returns an expense object which matches the given ExpenseID.

.EXAMPLE
Get-HRPExpense -EmployeeID 12345 -Submit 67890

This returns a list of expense objects for the specified EmployeeID and Submit ID.

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
