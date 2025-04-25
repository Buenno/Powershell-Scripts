Function Get-TermStatus {
    <#
    .SYNOPSIS
        Returns the current term status (In Term, Holiday, Half Term etc.)
     
    .NOTES
        Name: Get-TermStatus
        Author: Toby Williams
        Version: 1.0
        DateCreated: 25/04/2025
     
    .EXAMPLE
        Get-TermStatus
    #>
     
    [CmdletBinding()]
    param()
    
    BEGIN {
        $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
    }
    
    PROCESS {
        $url = ""
        $html = ConvertFrom-HTML -Url $url -Engine AngleSharp

        $termHeadings = $html.GetElementsByTagName("H3") | Where-Object {$_.InnerHTML -like "*Term*"}
        $events = New-Object System.Collections.Generic.List[PSObject]  

        foreach ($heading in $termHeadings){
            $termYear = $heading.TextContent.Split(" ")[2]
            # Parse the unordered list below each heading
            # Use a switch statement to avoid overdoing it with if/else statements
            foreach ($row in $heading[0].NextElementSibling.TextContent.Trim("").Split("`n")){
                switch -Wildcard ($row){
                    "*Induction Day*"           {$eventType =  "Induction"}
                    "*Term begins for pupils*"  {$eventType = "In Term"}
                    "*Term ends*"               {$eventType = "Term End"}
                    "*Last day of school*"      {$eventType = "Term End"}
                    "Half Term*"                {$eventType = "Half Term"}
                    "*Bank Holiday"             {$eventType = "Bank Holiday"}
                    default                     {$eventType = "Skip"}
                }
                # Half term records start and end are on the same row, so these must be split
                if ($eventType -eq "Half Term"){
                    $eventObj = [PSCustomObject]@{
                        Type = "Half Term"
                        Date = [datetime]::ParseExact(($row.Split(" ")[2..4] + $termYear), "dddd d MMMM yyyy", $null)
                        Term = $heading.TextContent.Split(" ")[0]
                    }
                    $events.Add($eventObj)
                    
                    $eventObj = [PSCustomObject]@{
                        Type = "In Term"
                        Date = [datetime]::ParseExact(($row.Split(" ")[6..8] + $termYear), "dddd d MMMM yyyy", $null).AddDays(1)
                        Term = $heading.TextContent.Split(" ")[0]
                    }
                    $events.Add($eventObj)
                }
                elseif ($eventType -eq "Term End"){
                    $eventObj = [PSCustomObject]@{
                        Type = "Holiday"
                        Date = [datetime]::ParseExact(($row.Split(" ")[0..2] + $termYear), "dddd d MMMM yyyy", $null).AddDays(1)
                        Term = $heading.TextContent.Split(" ")[0]
                    }
                    $events.Add($eventObj)
                }
                elseif ($eventType -eq "Bank Holiday"){
                    $eventObj = [PSCustomObject]@{
                        Type = "Bank Holiday"
                        Date = [datetime]::ParseExact(($row.Split(" ")[0..2] + $termYear), "dddd d MMMM yyyy", $null)
                        Term = $heading.TextContent.Split(" ")[0]
                    }
                    $events.Add($eventObj)
                    $eventObj = [PSCustomObject]@{
                        Type = "In Term"
                        Date = [datetime]::ParseExact(($row.Split(" ")[0..2] + $termYear), "dddd d MMMM yyyy", $null).AddDays(1)
                        Term = $heading.TextContent.Split(" ")[0]
                    }
                    $events.Add($eventObj)
                }
                elseif ($eventType -ne "Skip") {
                    $eventObj = [PSCustomObject]@{
                        Type = $eventType
                        Date = [datetime]::ParseExact(($row.Split(" ")[0..2] + $termYear), "dddd d MMMM yyyy", $null)
                        Term = $heading.TextContent.Split(" ")[0]
                    }
                    $events.Add($eventObj)
                }
            }
        }

        $currentDate = Get-Date

        for (($a = 0), ($b = 1); $b -lt $events.Count; $a++, $b++){
            if (($events[$a].Type -eq "Induction") -and ($events[$b].Type -eq "In Term")){
                $events[$b].Date = $events[$a].Date
                $events.RemoveAt($a)
            }
            if (($currentDate -ge $events[$a].Date) -and ($currentDate -le $events[$b].Date)){
                return $events[$a].Type
            }
        }
    }
    
    END {}
}