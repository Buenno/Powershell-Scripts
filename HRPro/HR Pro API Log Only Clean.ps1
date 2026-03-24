[cmdletbinding()]
param()
$ErrorActionPreference = 'Stop'

$excludedUsers = Get-ADGroupMember -Identity "IT Dept Admin" | Select-Object -ExpandProperty SamAccountName

function New-UpdateTableObject {
    Param
    (
        [Parameter(Mandatory = $true)]
        [string]$Username,
        [Parameter(Mandatory = $true)]
        [string]$UPN,
        [Parameter(Mandatory = $false)]
        [string]$Fullname,
        [Parameter(Mandatory = $true)]
        [string]$Attribute,
        [Parameter(Mandatory = $false)]
        [string]$OldValue,
        [Parameter(Mandatory = $true)]
        [string]$NewValue
    )
    $UpdateTableHash = [ordered]@{
        Username  = $Username
        UPN       = $UPN
        Fullname  = $Fullname
        Attribute = $Attribute
        OldValue = $OldValue
        NewValue = $NewValue
    }
    [pscustomobject]$UpdateTableHash
}

function Write-Log {
    Param
    (
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    $fileDate = Get-Date -Format "yyyy-MM-dd-HHmmss"
    $logPath = "$PSScriptRoot\logs\$fileDate.log"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp - $Message"
    Add-Content -Path $LogPath -Value $logEntry -Force
}

$objectChanges = [System.Collections.Generic.List[object]]::new()
$studentRegex = "^[A-Z]{1}_\w+|^\w{1}\.[A-Z\-]+[0-9]{2}"
Write-Debug -Message "Getting HR Pro employee data"
$HRPEmployees = Get-HRPEmployees 

foreach ($employee in $HRPEmployees) {
    # Calculate fullname
    $fullname = "$($employee.Forenames.Trim()) $($employee.Surname.Trim())"
    $employee | Add-Member -MemberType NoteProperty -Name Fullname -Value $fullname
    # Create exclusion property
    $employee | Add-Member -MemberType NoteProperty -Name Exclude -Value $false
    # Calculate the Work Email property for missing or non-abbey values
    if (([string]::IsNullOrEmpty($employee.WorkEmail)) -or ($employee.WorkEmail -notlike "*theabbey.co.uk")) {
        $email = ("$($employee.Surname)$($employee.KnownAs.Substring(0,2))" -replace "[',\s]", "").ToLower()
        $employee.WorkEmail = "$email@theabbey.co.uk"
    }
    # Set excluded records
    if ($employee.WorkEmail.Split("@")[0] -match $studentRegex) {
        $employee.Exclude = $true
        Write-Debug -Message "$($employee.fullname): excluded student record"
    }
    if ($employee.WorkEmail.Split("@")[0] -in $excludedUsers) {
        $employee.Exclude = $true
        Write-Debug -Message "$($employee.fullname)`: excluded user"
    }
    if ($employee.Exclude -eq $false) { 
        $employee.WorkEmail = $employee.WorkEmail -replace "[\`'\s]", ""
        $employeeRecord = Get-HRPEmployee -ID $employee.ID
        if (-not [string]::IsNullOrEmpty($employeeRecord.Termination.TerminationDate)) {
            if ($employeeRecord.Termination.TerminationDate -le (Get-Date)) {
                $employee.Exclude = $true
                Write-Debug -Message "$($employee.fullname)`: excluded for termination date [$($employeeRecord.Termination.TerminationDate)]"
            }
        }
    }
    # Compare to AD attributes
    if ($employee.Exclude -eq $false) {
        $user = $employee.WorkEmail.Split("@").ToLower()[0]
        try {
            $ADUser = Get-ADUser -Identity $user -Properties *
        }
        catch {
            Write-Debug -Message "$($employee.fullname): No AD user found when searching for [$user]"
            continue
        }
        $employee | Add-Member -MemberType NoteProperty -Name ADObject -Value $ADUser

        if (-not $ADUser.Enabled){
            $employee.Exclude = $true
            Write-Debug -Message "$($employee.fullname): AD account is disabled [$user]"
        }
        else {
            # Firstly we need to calculate the expected AD properties based on the values from HR Pro.
            # We will them compare this to the actual AD data in order to decide whether an update is required.

            # Calculate location
            switch ($employee.Contract.LocationDivision) {
                "JS Teaching" { $correctLocation = "JuniorSchool TeachingStaff" }
                "JS Business and Operations" { $correctLocation = "JuniorSchool SupportStaff" }
                "SS Teaching" { $correctLocation = "SeniorSchool TeachingStaff" }
                "SS Business and Operations" { $correctLocation = "SeniorSchool SupportStaff" }
                "WS Teaching" { $correctLocation = "SeniorSchool TeachingStaff" }
                "WS Business and Operations" { $correctLocation = "SeniorSchool SupportStaff" }
            }
            
            if ($($employee.Contract.Department) -eq "Governor") {
                $correctLocation = "School Governors"
            }
            
            # Split the users AD DN in order to create location string for comparison.
            try {
                $ADDNSplit = $employee.ADObject.DistinguishedName.replace("OU=", "").Split(",")
            } 
            catch {
                Write-Debug -Message "$($employee.fullname): Unable to split AD DN [$($employee.ADObject.DistinguishedName)]"
                continue
            }
            $ADLocation = $ADDNSplit[2] + " " + $ADDNSplit[1]

            # Store the employees job into a variable so we can append to it if needed.
            $HRPDescription = $employee.Contract.job

            # if job title and role are the same, or if role is blank, do nothing.
            # Otherwise set the role and append the role to the description.
            if (($employee.Contract.job -ne $($employee.Contract.Role)) -and (-not [string]::IsNullOrEmpty($employee.Contract.Role))) {
                $HRPDescription += "/$($employee.Contract.role)"
            }

            # if any additional roles exist and don't match the job title, and dont match the role, and isn't an empty string, then append it to the description.
            foreach ($additionalRole in $($employee.Contract.AdditionalRoles)) {
                if (($additionalRole -ne $employee.Contract.job) -and ($additionalRole -ne $employee.Contract.role) -and (-not [string]::IsNullOrEmpty($additionalRole))) {
                    $HRPDescription += "/$($additionalRole)"
                }
            }

            # Get a list of groups from the template user based on the current users OU/location
            $templateUsername = (($correctLocation -split " " | ForEach-Object {($_ -split '') -cmatch '[A-Z]' -join ''}) -join '_') + "_Template"
            Write-Debug -Message "$($employee.fullname): Getting groups from template [$templateUsername]"
            $templateADUserGroups = Get-ADUser -Identity $templateUsername -Properties MemberOf | Select-Object -ExpandProperty MemberOf | ForEach-Object { ($_ -split ',')[0] -replace '^CN=' }
            # Compare the template groups with the current users
            $ADUserGroups = $employee.ADObject | Select-Object -ExpandProperty MemberOf | ForEach-Object { ($_ -split ',')[0] -replace '^CN=' }
            $missingGroups = $templateADUserGroups | Where-Object {$_ -notin $ADUserGroups}

            if ($missingGroups) {
                $UpdateTable = New-UpdateTableObject -Username $($employee.ADObject.SamAccountName) -UPN $($employee.ADObject.UserPrincipalName) -Fullname $employee.fullname -Attribute 'Groups' -OldValue "Missing" -NewValue $HRPDescription
                $objectChanges.Add($UpdateTable)
            }
            
            if ( $($employee.ADObject.description) -ne $HRPDescription) {
                $UpdateTable = New-UpdateTableObject -Username $($employee.ADObject.SamAccountName) -UPN $($employee.ADObject.UserPrincipalName) -Fullname $employee.fullname -Attribute 'Description' -OldValue $($employee.ADObject.description) -NewValue $HRPDescription
                $objectChanges.Add($UpdateTable)
            }

            if ($ADLocation -ne $correctLocation) {
                $UpdateTable = New-UpdateTableObject -Username $($employee.ADObject.SamAccountName) -UPN $($employee.ADObject.UserPrincipalName) -Fullname $employee.fullname -Attribute 'OU' -OldValue $ADLocation -NewValue $correctLocation
                $objectChanges.Add($UpdateTable)
            }

            if ($($employee.ADObject.Department) -ne $($employee.Contract.Department)) {
                $UpdateTable = New-UpdateTableObject -Username $($employee.ADObject.SamAccountName) -UPN $($employee.ADObject.UserPrincipalName) -Fullname $employee.fullname -Attribute 'Department' -OldValue $($employee.ADObject.Department) -NewValue $($employee.Contract.Department)
                $objectChanges.Add($UpdateTable)
            }
        }
    }
}

$UniqueStaff = $objectChanges | Select-Object -Unique -Property UPN
foreach ($staff in $UniqueStaff) {
    $changes = $objectChanges | where-object -property UPN -eq $staff.UPN
    foreach ($change in $changes) {
        Write-Debug -Message "$($change.Fullname): Modify $($change.Attribute) from [$($change.OldValue)] to [$($Change.NewValue)]"
    }
}

$DescriptionChanges = ($objectChanges | where-object { $_.Attribute -eq "Description" }).count
$DepartmentChanges = ($objectChanges | where-object { $_.Attribute -eq "Department" }).count
$GroupChanges = ($objectChanges | where-object { $_.Attribute -eq "Groups" }).count
$OUChanges = ($objectChanges | where-object { $_.Attribute -eq "OU" }).count
Write-Debug -Message "$($HRPEmployees.count) HR Pro records found"
Write-Debug -Message "$(($HRPEmployees | Where-Object {$_.Exclude -eq $true}).count) are excluded"
Write-Debug -Message "$(($HRPEmployees | Where-Object {$_.Exclude -eq $false}).count) to be processed"
Write-Debug -Message "Total users to modify: $($UniqueStaff.count)"
Write-Debug -Message "Total department changes to be made: $DepartmentChanges"
Write-Debug -Message "Total description changes to be made: $DescriptionChanges"
Write-Debug -Message "Total group changes to be made: $GroupChanges"
Write-Debug -Message "Total OU changes to be made: $OUChanges"
Write-Debug -Message "Total changes to be made: $($objectChanges.count)"

