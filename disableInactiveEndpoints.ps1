function Get-InactiveEndpoint {
    param(
    [parameter(mandatory=$true)]$Days,
    [parameter(mandatory=$true)]
    [ValidateSet('Delete','Disable')]$Action
    )
        $inactiveDate = (Get-Date).Adddays(-($Days))
        $inactiveEndpoints = Search-ADAccount -AccountInactive -DateTime $InactiveDate -ComputersOnly -SearchBase "" | Where-Object {($_.distinguishedname -like "*Mobile Devices*") -or ($_.distinguishedname -like "*Desktop Machines*")} 
        write-host $inactiveEndpoints
    
        switch ($action){
            Disable {$Computers_For_Action | Disable-ADAccount }
            Delete {$Computers_For_Action | Remove-ADComputer -Confirm:$False }
        }
    }
    
    
    Get-InactiveEndpoint -Days 180 -Action Delete 