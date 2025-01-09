$ErrorActionPreference = "SilentlyContinue"

# Migrate Google Drive files from one Workspace account to another

# Define source and target gMail accounts.  
$Source = "SOURCE ADDRESS"
$Target = "TARGET ADDRESS"
$SUsername = $Source.split("@")[0]
$TUsername = $Target.split("@")[0]
$SDomain = $Source.split("@")[1]
$TDomain = $Target.split("@")[1]

$StorageDir = $env:userprofile + "STORAGE DIR"

# Create empty objects for storing data.
$SourceFile = $null
$SourceFiles = $null
$SourceTempData = $null
$Line = $null
$SourceFile = New-Object psobject
$SourceFile | Add-Member NoteProperty -Name Owner -Value $null
$SourceFile | Add-Member NoteProperty -Name title -Value $null
$SourceFile | Add-Member NoteProperty -Name trashed -Value $null
$SourceFile | Add-Member NoteProperty -Name writersCanShare -Value $null
$SourceFile | Add-Member NoteProperty -Name shared -Value $null
$SourceFile | Add-Member NoteProperty -Name alternateLink -Value $null
$SourceFile | Add-Member NoteProperty -Name DLID -Value $null
$Sourcefile | Add-Member NoteProperty -Name DLName -Value $null
$Sourcefile | Add-Member NoteProperty -Name DLSuccess -Value $false
$Sourcefile | Add-Member NoteProperty -Name Extension -Value $null
$Sourcefile | Add-Member NoteProperty -Name ULID -Value $null
$SourceFiles =  New-Object System.Collections.Generic.List[System.Object]

Set-GAMDomain "SOURCE DOMAIN NAME"
$SourceTempData = gam user $Source show filelist query "'me' in owners and mimeType != 'application/vnd.google-apps.folder'" title trashed writerscanshare shared alternatelink id
$ErrorActionPreference = "Continue"
$GAMHeaders = "Owner,title,trashed,writersCanShare,shared,alternateLink,id"

# Create migration folder in target account
Set-GAMDomain "TARGET DOMAIN NAME"
$CreateFolder = gam user $Target add drivefile drivefilename "Migrated" mimetype gfolder
if ($CreateFolder -match "Successful"){
    Write-Host "Migration folder created successfully for $Target"
    $FolderID = $CreateFolder.Substring($CreateFolder.LastIndexOf(" ") + 1)
    Write-Host "migrated folder id is" $FolderID
    foreach ($Line in $SourceTempData){
        if ($Line -eq $GAMHeaders){
            # Do nothing so we don't add returned headers to object.
    }
    else{
        # Split returned comma separated data at each comma and build array.
        $LineData = $Line -split ","
        # Select individual item from array.
        $SourceEntry = $SourceFile | Select-Object *
        $SourceEntry.Owner = $LineData[0]
        $SourceEntry.title = $LineData[1]
        $SourceEntry.trashed = $LineData[2]
        $SourceEntry.writersCanShare = $LineData[3]
        $SourceEntry.shared = $LineData[4]
        $SourceEntry.alternateLink = $LineData[5]
        $SourceEntry.DLID = $LineData[6]
        [void]$SourceFiles.Add($SourceEntry)      
    }
}

    #$FilesFound = $SourceFiles | ? {$_.trashed -eq "False"}
    Write-Host ($SourceFiles).count "file/s found."
    Write-Host "Ignoring" $($SourceFiles | ? {$_.trashed -eq "True"}).count "in trash." 
    Write-Host "Attempting to process" $($SourceFiles | ? {$_.trashed -eq "False"}).count "file/s."

    #Download Files.
    $FileCounter = 0
    foreach ($File in $SourceFiles){
        if ($File.trashed -eq "False"){
            $FileCounter++
            # Attempt one file at a time and store result
            Write-Host "$FileCounter of $(($SourceFiles | ? {$_.trashed -eq "False"}).count) - downloading $($File.title)"
            Set-GAMDomain "SOURCE DOMAIN NAME"
            $DLResult = gam user ($File.owner) get drivefile id $File.DLID targetfolder $StorageDir format microsoft
            if ($DLResult.Split(" ")[0] -match "Downloading"){
                # Handle duplicate file names
                # Build downloaded file name
                $Split = ($DLResult.Split('\')[-1])
                $File.DLName = $Split.Substring(0, ($Split.LastIndexOf(".")))
                $File.Extension = gci -Path $StorageDir | ? {$_.Basename -eq $File.DLname} | select -ExpandProperty Extension
                $File.DLSuccess = $True
                Write-Host "Success - $($File.DLName)" 
                # Get permission list and process
                $SFilePerm = $null
                $SPermTempData = $null
                $SFilePerms = $null
                $SFilePerms = @()
                if ($File.shared -eq "True"){
                    Write-Host "File is shared, getting permissions..."
                    $SPermTempData = gam user $Source show drivefileacl $File.DLID
                    foreach ($PLine in $SPermTempData){
                        if ($Pline -eq ""){
                            $SFilePerms += $SPermEntry
                            $SPermEntry = New-Object psobject
                        }
                        else {
                            $PLine = $PLine.trim(" ")
                            if ($PLine.contains(":")){
                                $PLineParts = $PLine.Split(":", 2)
                                $PProperty = $PLineParts[0].TrimEnd("")
                                $PValue = $PLineParts[1].Trim()
                                if ($PValue -ne $null){
                                    $SPermEntry | Add-Member NoteProperty -Name $PProperty -Value $PValue
                                }
                            }
                            else {
                                $SPermEntry | Add-Member NoteProperty -Name User -Value $PLine.trim()
                            }
                        }
                    }
                }
                else {
                    write-host "File not shared."
                } 
            }
            else {
                Write-Host "Error - Unable to download file with id $($File.id)." 
            }
            # Attempt to upload the downloaded files. 
            if ($File.Extention -eq ".xlsx" -or ".docx"){
                Write-Host "Attempting to upload $($File.DLName)."
                Set-GAMDomain "TARGET DOMAIN NAME"
                $ULFB = gam user $Target add drivefile localfile ($StorageDir + $File.DLName + $File.Extension) convert drivefilename $File.title parentid $FolderID
            }
            else {
                Write-Host "Attempting to upload $($File.DLName)."
                $ULFB = gam user $Target add drivefile localfile ($StorageDir + $File.DLName + $File.Extension) drivefilename $File.title parentid $FolderID
            }
            # Check if successful
            if ($ULFB.Split(" ")[0] -eq "Successfully"){
                Write-Host "$($file.DLName) successfully uploaded as $($File.title)."
                # Set upload ID
                $File.ULID = $ULFB.substring($ULFB.LastIndexOf(" ") + 1)
                if ($File.shared -eq "true"){
                    # Attempt to set share permissions on uploaded file. 
                    Write-Host "Re-applying share permissions..."
                    foreach ($Perm in $SFilePerms){
                        if ($Perm.emailaddress.split("@")[0] -eq $SUsername){
                            # Migrating from source, why share back? 
                        }
                        elseif ($Perm.emailaddress.split("@")[0] -eq $TUsername){
                            # Migrating to target, why share with yourself? 
                        }
                        else {
                            # Check if commenter perm exists
                            if ($Perm.additionalroles -match "commenter"){
                                $Perm.role = "commenter"
                            }
                            Write-Host "Attempting to share $($File.title) with $($Perm.emailAddress)."
                            $ShareResult = gam user $Target add drivefileacl $File.ULID user $Perm.emailaddress role $Perm.role 

                        }
                    }
                }
                else {
                    write-host "No share permissions to apply."
                }
            }
            else {
                Write-Host "Error - Upload of $($file.DLName) failed"
            }
        }
    }
}
else {
    Write-Host "Error when creating migration folder for $Target, aborting."
}
