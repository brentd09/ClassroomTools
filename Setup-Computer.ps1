<#
.SYNOPSIS
  Configure my Instructor Machines ready for use
.DESCRIPTION
  This will: 
    Update Windows defender
    Install the latest version of VSCode
    Install the lasest version of Git
    Setup my VSCode preferences
    Setup my Git configs
    Create a Git root 
.EXAMPLE
  Setup-Computer
.NOTES
  General notes
  Created By: Brent Denny
  Created On: 6 Mar 2019
#>
[CmdletBinding()]
Param()
$WinUpdate = Get-Service -Name wuauserv

if ($WinUpdate.StartType -ne 'Manual') {Set-Service -Name wuauserv -StartupType Manual}
if ($WinUpdate.Status -ne 'Running') {
  Start-Service -Name wuauserv
  Update-MpSignature
}
if ( ((get-date) - (Get-MpComputerStatus).QuickScanEndTime).hours -gt 12 ) {Start-MpScan}
Stop-Service -Name wuauserv

[net.servicePointManager]::SecurityProtocol = [net.SecurityProtocolType]::Tls12
$VSCodeUrl = 'https://aka.ms/win32-x64-user-stable'
$VSCodeFilePath = "$home/downloads/InstallVSCode.exe"
$GitUrl = "https://github.com/git-for-windows/git/releases/download/v2.21.0.windows.1/Git-2.21.0-64-bit.exe"
$GitFilePath = "$home/downloads/Git64.exe"
$WebClient = New-Object -TypeName System.Net.WebClient
$WebClient.DownloadFile($VSCodeurl,$VSCodeFilePath)
$WebClient.DownloadFile($GitUrl,$GitFilePath)

Invoke-Expression -Command "$VSCodeFilePath /VERYSILENT " 
Invoke-Expression -Command "$GitFilePath /VERYSILENT " 
$currentLocation = Get-Location
Set-Location ("$env:LOCALAPPDATA\Programs\Microsoft VS Code\")
Invoke-Expression -Command (".\Code.exe")
Start-Sleep -Seconds 2


# attempting to copy my UserSettings and Snippets into VSCode
try {
  Copy-Item $currentLocation\settings.json $env:APPDATA\Code\User\ -ErrorAction stop
  Copy-Item $currentLocation\powershell.json $env:APPDATA\Code\User\snippets\ -ErrorAction Stop
}
catch {Write-Warning "File copy did not work"}

try {
  Invoke-Command -ScriptBlock {git config --global user.name "Brent Denny"} -ErrorAction Stop
  Invoke-Command -ScriptBlock {git config --global user.email "brent.denny@ddls.com.au"} -ErrorAction Stop
}
catch {
  Write-Warning 'The git command did not work'
}
Set-Location $currentLocation.Path