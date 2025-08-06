# HRProPS   

### About
HRProPS is a Powershell module for interacting with HR Pro via their REST API.

### Building
Use PSake to build the module:\
`Invoke-psake -buildFile .\psake.ps1 -taskList compile`

### How to use
Import the module manually:\
`Import-Module .\BuildOutput\HRProPS\%version%\HRProPS.psd1`

Or move the module to one of the PSModulePath paths for automatic import:\
`$Env:PSModulePath`

List the available commands:\
`Get-Command -Module HRProPS`

Use Powershell's native help feature to learn about each command
\
`Get-Help Get-Employees -Full`