$targetName = "fx-CG Manager PLUS Subscription for fx-CG50series"
$uninstallPath = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"

$exeInstaller = Join-Path $PSScriptRoot "fx-CG_Manager_PLUS_Subscription_for_fx-CG50_GRAPH90_series_Ver.3.80.exe"
$patch = "License_ColorManager.lic"
$patchPath = Join-Path $PSScriptRoot $patch
$patchDestPath = Join-Path $env:ProgramData "CASIO\fx-CG Manager PLUS Subscription\"

try {
    # Uninstall existing version if present
    $app = Get-ItemProperty $uninstallPath -ErrorAction SilentlyContinue | Where-Object {
        $_.DisplayName -eq $targetName
    }

    if ($app) {
        Write-Host "Existing installation detected. Uninstalling..."

        if ($app.UninstallString -match "{.*}") {
            $productCode = $matches[0]

            $uninstallArgs = @(
                "/x$productCode"
                "/qn"
            )

            $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $uninstallArgs -Wait -PassThru

            if ($process.ExitCode -ne 0) {
                throw "Uninstall failed with exit code $($process.ExitCode)"
            }
        }
        else {
            throw "Could not extract product code from UninstallString"
        }
    }
    else {
        Write-Host "No existing installation found."
    }

    # perform installation
    Write-Host "Installing new version..."

    $arguments = @(
        "/l1033"
        "/s"
        "/v`"/qn ISX_EID=24abe-50027-13441-38c31-b04b9-c484abe`""
    )

    $process = Start-Process -FilePath $exeInstaller -ArgumentList $arguments -Wait -PassThru

    if ($process.ExitCode -ne 0) {
        throw "Installation failed with exit code $($process.ExitCode)"
    }

    # Copy licence file
    if (!(Test-Path $patchDestPath)) {
        New-Item -ItemType Directory -Path $patchDestPath -Force | Out-Null
    }

    Copy-Item -Path $patchPath -Destination $patchDestPath -Force

    Write-Host "Installation completed successfully."
}
catch {
    Write-Error $_
    exit 1
}