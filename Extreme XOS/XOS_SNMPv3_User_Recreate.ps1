<# 
    This script will delete and recreate an ExtremeOS SNMPv3 user and group on target switches, 
    associate the new user with the newly created group, and configure SNMP OIDs access. 

    This script assumes the same SSH username and password is used on all switches, 
    and that the defined group is already configured to access SNMP OIDs.
#>
$credentials = Get-Credential

$username = ""
$authType = "sha"
$authPass = ""
$privType = "aes"
$privPass = ""

$groupName = ""

$switches = @("")

foreach ($switch in $switches){
    $session = New-SSHSession -Host $switch -Credential $credentials -AcceptKey:$true

    # Delete existing SNMPv3 users
    $delUserCMD = "configure snmpv3 delete user all"
    Invoke-SSHCommand -SSHSession $session -Command $delUserCMD 

    # Create new user
    $createCMD = "configure snmpv3 add user $username authentication $authType $authPass privacy $privPass $privType"
    Invoke-SSHCommand -SSHSession $session -Command $createCMD

    # Delete existing group members
    $delGroupCMD = "configure snmpv3 delete group $groupName user all-non-defaults"
    Invoke-SSHCommand -SSHSession $session -Command $delGroupCMD

    # Add user to group
    $addGroupUserCMD = "configure snmpv3 add group $groupName user $username sec-model usm"
    Invoke-SSHCommand -SSHSession $session -Command $addGroupUserCMD

    # Save config
    $saveCMD = "save primary"
    Invoke-SSHCommand -SSHSession $session -Command $saveCMD
    
    Remove-SSHSession -SSHSession $session
}