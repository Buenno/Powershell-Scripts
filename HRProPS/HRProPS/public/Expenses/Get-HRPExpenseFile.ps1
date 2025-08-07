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
