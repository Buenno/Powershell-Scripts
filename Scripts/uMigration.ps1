$u_drives = Get-ChildItem E:\drive_u

foreach ($drive in $u_drives){
    # Create an empty folder for storing contents and store the response
    $newU = New-GSDriveFile -User $drive.Name -Name u_drive -Description 'migrated U:\ drive data' -MimeType DriveFolder
    # Start the file upload to the new U: drive in Google Drive
    Write-Host "Starting upload for $($drive.name) to folder $($newU.Id)"
    Start-GSDriveFileUpload -Path "E:\drive_u\$($drive.Name)" -Recurse -User $drive.Name -Parents $newU.Id 
    Write-Host "Upload complete!"
}