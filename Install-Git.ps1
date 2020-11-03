#
# Quick and dirty unattended Git installer for classes
#
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
$GitDownloadSite = Invoke-WebRequest -Uri 'https://git-scm.com/download/win' -UseBasicParsing 
$RawLink = ($GitDownloadSite.Links | where {$_ -like '*64-bit Git for Windows Setup*'}).OuterHtml
$DownloadUrl = $RawLink -replace '^.+"(.+)".+$','$1'
$DownloadsDir = ([System.Environment]::GetFolderPath('desktop')) -replace 'desktop','downloads'
$GitExeFile = $DownloadUrl -replace '.+\/',''
$GitExeFilePath = $DownloadsDir.TrimEnd('\') + '\' + $GitExeFile
$WebClientObj = [System.Net.WebClient]::new()
$WebClientObj.DownloadFile($DownloadUrl,$GitExeFilePath)
Start-Sleep -Seconds 10
$InstallString = "$GitExeFilePath /VERYSILENT /NORESTART"
Invoke-Expression -Command $InstallString