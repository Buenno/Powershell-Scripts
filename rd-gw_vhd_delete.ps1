$files = Get-ChildItem -Path D:\ -Filter *.vhdx | Where-Object {$_.BaseName -notlike "*template"}

foreach ($file in $files){
    # Get user SID from file name
    $sid = $file.BaseName.Substring(5)
    # Get AD User data
    $adUser = Get-ADUser -Identity $sid
    if ($adUser.Enabled -eq $false){
        $file | Remove-Item -Force
    }
}