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


if 