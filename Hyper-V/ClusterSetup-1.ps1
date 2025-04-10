#***********************

#DO NOT FORGET TO SET THESE VARIABLES!

$serverName = "DR-1"

#***********************

# Rename the server
Rename-Computer -NewName $serverName -Force

# Install the required roles and features
# Hyper-V
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All - -NoRestart

# Hyper-V Management Toolset
Install-WindowsFeature -Name RSAT-Hyper-V-Tools

# Failover Clustering
Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools 

# File Server
Install-WindowsFeature -Name File-Services

# Multi-path IO
Install-WindowsFeature -Name Multipath-IO 

# Create new NIC team
New-NetLbfoTeam -Name TM1 -TeamMembers "Embedded FlexibleLOM 1 Port 1","Embedded FlexibleLOM 1 Port 2" -TeamingMode Lacp -LoadBalancingAlgorithm Dynamic -Confirm:$false

# Configure MPIO
New-MSDSMSupportedHw -VendorId "HPE     " -ProductId "MSA 2050 SAS    "
New-MSDSMSupportedHw -VendorId "MSFT2011" -ProductId "SASBusType_0xA  "

# Restart server
Restart-Computer -Force