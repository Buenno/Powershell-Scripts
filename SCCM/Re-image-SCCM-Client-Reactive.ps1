<#
.SYNOPSIS
  Script to remove AD Reactive accounts for computers that are being imaged.
.DESCRIPTION
  This SCript will check if the Wired Auto Config Service is running to make sure the GPO has been applied. If this is TRUE the script will then get MACs from the network interfaces and
  check for AD ACcounts. If the account exists and is in the correct OU with the correct string in the decription the accoutn will be deleted.
.OUTPUTS
  Output is to console with will be logged in SMSTS log file as part of the task sequence.
.NOTES
  Version:        1.0
  Author:         James Brown
  Creation Date:  04/08/2021
  Purpose/Change: Initial script development
#>

$secpasswd = ConvertTo-SecureString -String 'blank' -AsPlainText -Force



function AddMac {
    try {
    $Newmac = $MACInput.text
    $Newmac = $Newmac.replace(":","")
    $Newmac = $Newmac.Replace("-","")
    $Desc = "SCCMTEMP " + (get-date -Format "yy-MM-dd HH:mm") +" " + $env:UserName
   
    New-ADuser -SamAccountName $NewMac -Name ("SCCM " + $NewMac) -UserPrincipalName $NewMac -DisplayName ("SCCM " + $NewMac) -GivenName "SCCM" -Surname $NewMac -Description $Desc.ToString() -path “OU=SCCM, OU=Accounts, OU=Reactive, OU=TheAbbeySchool, DC=tas, DC=internal” -AccountPassword $secpasswd -ChangePasswordAtLogon $False -PasswordNeverExpires $True -CannotChangePassword $True -Enabled $True -ErrorAction Stop
    Add-ADGroupMember -Identity "Reactive.TrustedOverrides" -members $NewMac -ErrorAction Stop
   # Enable-ADAccount -Identity $NewMac  
  [System.Windows.MessageBox]::Show("A new Reactive account has been created with the MAC: $Newmac","New MAC Added",0,64)
    }
  catch {
  [System.Windows.MessageBox]::Show($Error[0],"An Error Occured",0,16)
  }
}


# Init PowerShell Gui
Add-Type -AssemblyName System.Windows.Forms

# Create a new form
$MainForm                   = New-Object system.Windows.Forms.Form

# Define the size, title and background color
$MainForm.ClientSize         = '500,300'
$MainForm.text               = "Reactive - Temporary Trust Devices"
$MainForm.BackColor          = "#ffffff"

# Create a Title for our form. We will use a label for it.
$Title                           = New-Object system.Windows.Forms.Label
# The content of the label
$Title.text                      = "Reactive - Add Mac Address for Imaging"
# Make sure the label is sized the height and length of the content
$Title.AutoSize                  = $true
# Define the minial width and height (not nessary with autosize true)
$Title.width                     = 25
$Title.height                    = 10
# Position the element
$Title.location                  = New-Object System.Drawing.Point(20,20)
# Define the font type and size
$Title.Font                      = 'Microsoft Sans Serif,13'
# Other elemtents
$Description                     = New-Object system.Windows.Forms.Label
$Description.text                = "Enter the MAC address below in any format. The device will be added to the Trusted Overides Reactive Security Group."
$Description.AutoSize            = $false
$Description.width               = 450
$Description.height              = 50
$Description.location            = New-Object System.Drawing.Point(20,50)
$Description.Font                = 'Microsoft Sans Serif,10'

$MACInput                        = New-Object System.Windows.Forms.TextBox
$MACInput.Location               = New-Object System.Drawing.Point(20,100)
$MACInput.Size                   = New-Object System.Drawing.Size(460,60)
$MACInput.Font                   = 'Microsoft Sans Serif,26'

$AddMacButton                   = New-Object system.Windows.Forms.Button
$AddMacButton.BackColor         = "#ffffff"
$AddMacButton.text              = "Add Mac Address"
$AddMacButton.width             = 120
$AddMacButton.height            = 40
$AddMacButton.location          = New-Object System.Drawing.Point(370,250)
$AddMacButton.Font              = 'Microsoft Sans Serif,10'
$AddMacButton.ForeColor         = "#000"
$AddMAcButton.Add_Click({ AddMac })

$cancelBtn                       = New-Object system.Windows.Forms.Button
$cancelBtn.BackColor             = "#ffffff"
$cancelBtn.text                  = "Cancel"
$cancelBtn.width                 = 120
$cancelBtn.height                = 40
$cancelBtn.location              = New-Object System.Drawing.Point(240,250)
$cancelBtn.Font                  = 'Microsoft Sans Serif,10'
$cancelBtn.ForeColor             = "#000"
$cancelBtn.DialogResult          = [System.Windows.Forms.DialogResult]::Cancel



$MainForm.CancelButton = $cancelBtn
$MainForm.Controls.Add($Title)
$MainForm.Controls.Add($Description)
$MainForm.Controls.Add($MACInput)
$MainForm.Controls.Add($cancelBtn)
$MainForm.Controls.Add($AddMacButton)


# Display the form
[void]$MainForm.ShowDialog()
