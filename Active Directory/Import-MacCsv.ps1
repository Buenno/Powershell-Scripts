function Import-ReactiveAccounts {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Path,
        [string]$Password
    )

    begin {
        if (-not (Test-Path $Path)) {
            throw "File not found: $Path"
        }

        $data = Import-Csv $Path

        if (-not $data) {
            throw "CSV file is empty or invalid."
        }

        # Check if CSV contains Password column
        $hasPasswordColumn = $data[0].PSObject.Properties.Name -contains 'Password'

        if (-not $hasPasswordColumn -and -not $Password) {
            throw "Password parameter is required when CSV does not contain a 'Password' column."
        }

        Write-Verbose "CSV loaded. Password column present: $hasPasswordColumn"
    }

    process {
        foreach ($row in $data) {

            # Use CSV password if present, otherwise fallback to parameter
            $rowPassword = if ($row.PSObject.Properties.Name -contains 'Password') {
                $row.Password
            }
            else {
                $Password
            }

            Write-Verbose "Processing MAC: $($row.MAC) ComputerName: $($row.ComputerName)"

            New-ReactiveAccount `
                -MAC $row.MAC `
                -ComputerName $row.ComputerName `
                -Password $rowPassword
        }
    }
}