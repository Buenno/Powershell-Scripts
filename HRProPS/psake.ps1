properties {
    $moduleName = "HRProPS"
    $modulePath = "$PSScriptRoot\$moduleName\"
    $moduleManifestPath = "$modulePath\$moduleName.psd1"
    $moduleManifest = Import-PowerShellDataFile -Path $moduleManifestPath
    $outputDir = "$PSScriptRoot\BuildOutput"
    $outputModDir = Join-Path -Path $outputDir -ChildPath $moduleName
    $outputModVerDir = Join-Path -Path $outputModDir -ChildPath $moduleManifest.ModuleVersion
}

task default -depends Test

#task Test -depends Compile, Clean {
#  $testMessage
#}

task Compile -depends Clean {
    # Create module output directory
    $functionsToExport = @()
    if (-not (Test-Path $outputModVerDir)) {
        New-Item -Path $outputModDir -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
        New-Item -Path $outputModVerDir -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
    }

    # Append items to psm1
    Write-Host 'Creating psm1...'
    $psm1 = Copy-Item -Path (Join-Path -Path $modulePath -ChildPath 'HRProPS.psm1') -Destination $outputModVerDir -PassThru

    foreach ($scope in @('Private', 'Public')) {
        Write-Host "Copying contents from files in source folder to PSM1: $($scope)"
        $gciPath = Join-Path -Path $modulePath -ChildPath $scope
        if (Test-Path $gciPath) {
            Get-ChildItem -Path $gciPath -Filter "*.ps1" -Recurse -File | ForEach-Object {
                Write-Host "Working on: $scope$([System.IO.Path]::DirectorySeparatorChar)$($_.FullName.Replace("$gciPath$([System.IO.Path]::DirectorySeparatorChar)",'') -replace '\.ps1$')"
                [System.IO.File]::AppendAllText($psm1, ("$([System.IO.File]::ReadAllText($_.FullName))`n"))
                if ($scope -eq 'Public') {
                    $functionsToExport += $_.BaseName
                    [System.IO.File]::AppendAllText($psm1, ("Export-ModuleMember -Function '$($_.BaseName)'`n"))
                }
            }
        }
    }

    @"
try {
    Get-HRPConfig -ErrorAction Stop
}
catch {
    Write-Warning "There was no config returned! Please make sure you are using the correct key or have a configuration already saved."
}
"@ | Add-Content -Path $psm1 -Encoding UTF8

    # Copy over manifest
    Copy-Item -Path $moduleManifestPath -Destination $outputModVerDir

    # Update FunctionsToExport on manifest
    Update-ModuleManifest -Path (Join-Path -Path $outputModVerDir -ChildPath "$moduleName.psd1") -FunctionsToExport ($functionsToExport | Sort-Object)

} -Description "Compiles module"

task Clean {
    if (Test-Path -Path $outputModDir){
        Write-Host "Removing module output directory [$outputModDir]"
        Remove-Item -Path $outputModDir -Recurse -Force
    }
} -Description "Cleans module output directory"

