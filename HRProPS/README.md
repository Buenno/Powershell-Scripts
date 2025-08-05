# HRProPS   

### About
HRProPS is a Powershell module for interacting with HR Pro via their REST API.

### Building
Use PSake to build the module.
`Invoke-psake -buildFile .\psake.ps1 -taskList compile`

### How to use
List the available commands:\
`Get-Command -Module HRProPS`

Use Powershell's native help feature to learn about each command
\
`Get-Help Get-Employees -Full`