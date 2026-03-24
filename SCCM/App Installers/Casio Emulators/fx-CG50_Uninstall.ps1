$msiProductCode = "{02987FA0-BC9D-49DC-9EA5-3E8ED55FA43C}"
$patchDestPath = Join-Path $env:ProgramData "CASIO\fx-CG Manager PLUS Subscription\"

try {
    $arguments = @(
        "/x$msiProductCode"
        "/qn"
    )

    $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $arguments -Wait -PassThru

    if ($process.ExitCode -ne 0) {
        throw "Uninstallation failed with exit code $($process.ExitCode)"
    }

    # Remove leftover license file/folder
    if (Test-Path $patchDestPath) {
        Remove-Item -Path $patchDestPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}
catch {
    Write-Error $_
    exit 1
}