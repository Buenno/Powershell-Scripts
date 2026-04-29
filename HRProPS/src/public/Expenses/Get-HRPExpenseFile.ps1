Function Get-HRPExpenseFile {
    <#
.SYNOPSIS
Returns either a single or list of ExpenseFile objects.

.DESCRIPTION
Returns either a single or list of ExpenseFile objects. Providing the ExpenseID will return a list, 
and providing the ExpenseFileID will return a single, specific object.

.PARAMETER ExpenseID
The ID of the expense for which to retrieve associated files.

.PARAMETER ExpenseFileID
The ID of the expense file to retrieve.

.EXAMPLE
Get-HRPExpenseFile -ExpenseID 12345 

This returns a list of ExpenseFile objects for the given ExpenseID.

.EXAMPLE
Get-HRPExpenseFile -ExpenseFileID 6789101112 

This returns a ExpenseFile object for the given ExpenseFileID.

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
        if ($PSCmdlet.ParameterSetName -eq "ExpenseID") {
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
