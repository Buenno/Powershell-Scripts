# This section executes the server cleanup, same as what the wizard does, computer cleanup is disabled. I also had to specify the non-default port and server name as the defaults do not work.

$server = "SERVERNAME"
$SSL = $false
$port = "8530"

[reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration") | out-null
$wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer('SERVERNAME', 'false', 8530);
$cleanupScope = new-object Microsoft.UpdateServices.Administration.CleanupScope;
$cleanupScope.DeclineSupersededUpdates = $true
$cleanupScope.DeclineExpiredUpdates = $true
$cleanupScope.CleanupObsoleteUpdates = $true
$cleanupScope.CompressUpdates = $true
#$cleanupScope.CleanupObsoleteComputers = $true
$cleanupScope.CleanupUnneededContentFiles = $true
$cleanupManager = $wsus.GetCleanupManager();
$cleanupManager.PerformCleanup($cleanupScope);

# This section performs DB maintenance (indexing and such).

Start-Process -FilePath 'C:\Program Files\Microsoft SQL Server\100\Tools\Binn\SQLCMD.EXE' -ArgumentList '-S np:\\.\pipe\MSSQL$MICROSOFT##SSEE\sql\query –i D:\scripts\WSUSCleanUp.sql'
