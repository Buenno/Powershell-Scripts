#***********************

#DO NOT FORGET TO SET THESE VARIABLES!

$mgmtIP = "10.1.1.31"
$clusterIP = "10.20.10.11"
$migrationIP = "10.20.11.11"
$subnetmask = "24"
$gateway = "10.1.1.1"
$dns1 = "10.1.10.11"
$dns2 = "10.1.10.12"
$vSwitchName = "VSwitch1"

#***********************

# Create new Hyper-V switch
New-VMSwitch -Name $vSwitchName -AllowManagementOS $true -NetAdapterName TM1

# Remove the vInterface that this created
Remove-VMNetworkAdapter -Name $vSwitchName -ManagementOS

# Add new Hyper-V network adapters
Add-VMNetworkAdapter -ManagementOS -SwitchName $vSwitchName -Name Mgmt
Add-VMNetworkAdapter -ManagementOS -SwitchName $vSwitchName -Name Cluster
Add-VMNetworkAdapter -ManagementOS -SwitchName $vSwitchName -Name "Live Migration"

# Configure VLAN tagging for new adapters
Get-VMNetworkAdapter -Name Mgmt -ManagementOS | Set-VMNetworkAdapterVlan -Access -VlanId 11
Get-VMNetworkAdapter -Name Cluster -ManagementOS | Set-VMNetworkAdapterVlan -Access -VlanId 2010
Get-VMNetworkAdapter -Name "Live Migration" -ManagementOS | Set-VMNetworkAdapterVlan -Access -VlanId 2011

# Configure static IP addressing for all 3 vInterfaces

$mgmtInt = Get-NetIPInterface -InterfaceAlias "vEthernet (Mgmt)" -AddressFamily IPv4
$mgmtInt | Set-NetIPInterface -Dhcp Disabled 
$mgmtInt | New-NetIPAddress -IPAddress $mgmtIP -PrefixLength $subnetmask -DefaultGateway $gateway
$mgmtInt | Set-DnsClientServerAddress -ServerAddresses ($dns1, $dns2)

$clusterInt = Get-NetIPInterface -InterfaceAlias "vEthernet (Cluster)" -AddressFamily IPv4
$clusterInt | Set-NetIPInterface -Dhcp Disabled 
$clusterInt | New-NetIPAddress -IPAddress $clusterIP -PrefixLength $subnetmask

$migrationInt = Get-NetIPInterface -InterfaceAlias "vEthernet (Live Migration)" -AddressFamily IPv4
$migrationInt | Set-NetIPInterface -Dhcp Disabled 
$migrationInt | New-NetIPAddress -IPAddress $migrationIP -PrefixLength $subnetmask

# Restart server
Restart-Computer -Force