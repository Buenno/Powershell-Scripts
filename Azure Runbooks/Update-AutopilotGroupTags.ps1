<#
.SYNOPSIS
  Updates the Autopilot devices’ group tag to match the assigned user’s department    

  .NOTES
    Author: Toby Williams
    Date: 06-03-2026
    Version: 1.3 Hide connection output
             1.2 Minor improvements
             1.0: Basic Script
#>

$DevicePrefix = "STU-"

Write-Output "Starting department tag automation"

Connect-AzAccount -Identity | Out-Null

$token = (Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com").Token

$headers = @{
    Authorization = "Bearer $token"
    "Content-Type" = "application/json"
}

Write-Output "Connected to Microsoft Graph using Automation Managed Identity"

$uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices?`$filter=startswith(deviceName,'$DevicePrefix')&`$top=100"

$devices = @()
do {
    $response = Invoke-RestMethod -Headers $headers -Uri $uri -Method GET
    $devices += $response.value
    $uri = $response.'@odata.nextLink'
} while ($uri)

Write-Output "Found $($devices.Count) STU- devices"

$autoUri = "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeviceIdentities?`$top=100"

$autopilotDevices = @()
do {
    $resp = Invoke-RestMethod -Headers $headers -Uri $autoUri -Method GET
    $autopilotDevices += $resp.value
    $autoUri = $resp.'@odata.nextLink'
} while ($autoUri)

$autopilotMap = @{}
foreach ($ap in $autopilotDevices) {
    if ($ap.managedDeviceId) {
        $autopilotMap[$ap.managedDeviceId] = $ap
    }
}

foreach ($device in $devices) {

    if (-not $device.userId) {
        Write-Output "$($device.deviceName): No primary user"
        continue
    }

    $userUri = "https://graph.microsoft.com/v1.0/users/$($device.userId)?`$select=department,displayName"
    $user = Invoke-RestMethod -Headers $headers -Uri $userUri -Method GET

    if (-not $user.department) {
        Write-Output "$($device.deviceName): User $($user.displayName) has no department"
        continue
    }

    $desiredTag = $user.department

    if (-not $autopilotMap.ContainsKey($device.id)) {
        Write-Output "$($device.deviceName): Not an Autopilot device"
        continue
    }

    $auto = $autopilotMap[$device.id]
    $autopilotId = $auto.id
    $currentTag = $auto.groupTag

    if ($currentTag -eq $desiredTag) {
        Write-Output "$($device.deviceName): Tag already correct ($desiredTag)"
        continue
    }

    Write-Output "$($device.deviceName): Updating tag from '$currentTag' to '$desiredTag'"

    $body = @{
        groupTag = $desiredTag
    } | ConvertTo-Json | Out-Null

    $updateUri = "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeviceIdentities/$autopilotId/updateDeviceProperties"

    Invoke-RestMethod -Headers $headers -Uri $updateUri -Method POST -Body $body
}

Write-Output "Runbook completed successfully"