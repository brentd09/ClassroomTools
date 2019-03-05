<#
.SYNOPSIS
  Short description
.DESCRIPTION
  Long description
.EXAMPLE
  PS C:\> <example usage>
  Explanation of what the example does
.INPUTS
  Inputs (if any)
.OUTPUTS
  Output (if any)
.NOTES
  General notes
#>
[CmdletBinding()]
Param()
$WinUpdate = Get-Service -Name wuauserv

if ($WinUpdate.StartType -ne 'Manual') {Set-Service -Name wuauserv -StartupType Manual}
if ($WinUpdate.Status -ne 'Running') {Start-Service -Name wuauserv}
if ($WinUpdate.Status -eq 'Running') {Update-MpSignature}
Start-MpScan
Stop-Service -Name wuauserv

[net.servicePointManager]::SecurityProtocol = [net.SecurityProtocolType]::Tls12
$url = 'https://aka.ms/win32-x64-user-stable'
$FilePath = "$home/downloads/InstallVSCode.exe"

$WebClient = New-Object -TypeName System.Net.WebClient
$WebClient.DownloadFile($url,$FilePath)

Execute-Process -Path "$FilePath" -Parameters "/VERYSILENT /CLOSEAPPLICATIONS"

Start-Process -FilePath "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe"
Start-Sleep -Seconds 2
$CodeProcesses = get-process -Name Code
$CodeProcesses | ForEach-Object {$_.CloseMainWindow() *> $null}

# attempting to copy my UserSettings and Snippets into VSCode
try {
  Copy-Item .\settings.json $env:APPDATA\Code\User\ -ErrorAction stop
  Copy-Item .\powershell.json $env:APPDATA\Code\User\snippets\ -ErrorAction Stop
}
catch {Write-Warning "File copy did not work"}

try {
  Invoke-Command -ScriptBlock {git config --global user.name "Brent Denny"} -ErrorAction Stop
  Invoke-Command -ScriptBlock {git config --global user.email "brent.denny@ddls.com.au"} -ErrorAction Stop
}
catch {
  Write-Warning 'The git command did not work'
}
