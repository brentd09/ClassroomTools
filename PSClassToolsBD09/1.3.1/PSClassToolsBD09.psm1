function Install-VsCodeAndGit {
  <#
  .SYNOPSIS
    This command installd Git and VSCode into the AZ040 labs
  .DESCRIPTION
    This command will locate the lastest versions of Git and VSCode 
    and install them silently, without any user input. It also sets
    the font size to 16 and the tab sie to two spaces in the VSCode 
    settings file
  .PARAMETER GitFullName
    This is the name that will be set in the Git global config 
  .PARAMETER GitEmailAddress
    This is the email address that will be set in the Git global config     
  .PARAMETER GitHubRepoURL
    This is the URL that you can copy from the CODE button in the GitHub repository.
    This will be used to clone a copy of this repo into the e:\GitRoot folder.    
  .EXAMPLE
    Install-VsCodeAndGit -GitFullName "John Dowe"  -GitEmailAddress "JDowe@hotmail.com"
    This command downloads the git and vscode installer files into the temp directory 
    and then installs these applications in VERYSILENT mode. It also sets up the 
    Git Config file and sets default values for VSCode
  .EXAMPLE
    Install-VsCodeAndGit -GitFullName "John Dowe"  -GitEmailAddress "JDowe@hotmail.com" -GitHubRepoURL 'https://github.com/JohnD/MyRepo'
    This command downloads the git and vscode installer files into the temp directory 
    and then installs these applications in VERYSILENT mode. It also sets up the 
    Git Config file and sets default values for VSCode. This will also clone the 
    GitHub repository from https://github.com/JohnD/MyRepo into the e:\GitRoot folder 
  .NOTES
    General notes
      Created By: Brent Denny
      Created On: 01-Mar-2022
      Last Modified: 04-Mar-2022
    ChangeLog 
      Ver    Date        Details
      ---    ----        ------- 
      v1.0.0 01-Mar-2022 Created the tools
      V1.0.1 01-Mar-2022 Fixed a problem where the temp drive path was not working  
      v1.0.5 01-Mar-2022 Added Git config edits
      v1.1.0 01-Mar-2022 Fixed an issue with the web content object different in PS7
             01-Mar-2022 Added debug break points
      v1.1.5 01-Mar-2022 Most issues fixed, added verbose troubleshooting points
      v1.1.8 01-Mar-2022 Fixed a syntax problem that showed outerhtml on screen while the code was running
      V1.1.9 01-Mar-2022 Changed the module and function names to better reflect the purpose
      v1.2.0 01-Mar-2022 Added Code to wait until Git is completely installed before editing the config file
      v1.2.1 01-Mar-2022 Fixed logic bug
      V1.2.2 02-Mar-2022 Added Better on-screen instructions while command completes
      v1.2.5 04-Mar-2022 Added the automatic GitRoot folder and Repo clone 
      v1.2.6 04-Mar-2022 Fixed the help content to fix a typo for the GitHubURL 
      v1.2.7 14-Mar-2022 Changed the location of the GitRoot folder to be any drive available, not hardcoded to e:\Gitroot
      v1.2.8 14-Mar-2022 Fixed a stupid syntax error, not {} on an else statement
      v1.2.9 14-Mar-2022 Fixed another silly syntax error
      v1.3.0 15-Mar-2022 Stopped the output from displaying errors for the Set-Content command
      v1.3.1 15-Mar-2022 Wrapped the Set-Content in a try block to remove errors
  #>
  [cmdletbinding()]
  Param (
    [Parameter(Mandatory=$true)]
    [string]$GitFullName,
    [Parameter(Mandatory=$true)]
    [string]$GitEmailAddress,
    [string]$GitHubRepoURL
  )
  
  # Create WebClient object to be able to download files from the internet
  $WebClientObj = New-Object -TypeName System.Net.WebClient 
  if (Test-Path $env:TEMP) {$TempDrive = ($env:TEMP).Trim('\') + '\' }
  else {throw ('No temp drive to store downloads')}
  # get the contents of the git download website to discover the latest git version
  $GitWebContent = Invoke-WebRequest -Uri 'https://git-scm.com/download/win'
  Write-Progress -Activity 'Getting Ready to install Git and VSCode' -CurrentOperation 'Starting Now' -PercentComplete  50
  Write-Verbose "Web content retrieved"
  Write-Debug "Web content retrieved"
  if ($PSVersionTable.PSVersion.Major -le 5) {
    $LatestGitRef = $GitWebContent.Links | Where-Object {$_.InnerHTML -like "*64*bit*windows*setup*"}
  }
  elseif ($PSVersionTable.PSVersion.Major -ge 6) {
    $LatestGitRef = $GitWebContent.Links | Where-Object {$_ -match '64.*bit.*Windows.*Setup'}
  }
  $LatestGitLink = $LatestGitRef.href
  $LatestGitFileName = Split-Path $LatestGitLink -Leaf
  $GitFileNamePath = $TempDrive + $LatestGitFileName
  Write-Verbose "Just before deploying Git"
  Write-Debug "Just before deploying Git"
  Write-Progress -Activity 'Deploying Git' -CurrentOperation 'Downloading Git' -PercentComplete  50
  #Download latest Git file
  $WebClientObj.DownloadFile($LatestGitLink,$GitFileNamePath)
  Write-Progress -Activity 'Deploying Git' -CurrentOperation 'Downloading Git' -PercentComplete  100
  Invoke-Expression -Command "$GitFileNamePath /VERYSILENT /NORESTART" 
  $Percent = 0
  do {
    Write-Progress   -Activity 'Deploying Git' -CurrentOperation 'Installing Git' -PercentComplete $Percent
    Start-Sleep -Milliseconds 400
    $Percent++ 
  } until ($Percent -ge 100)
  $env:Path = "$env:Path;C:\Program Files\Git\cmd"
  $GitConfigFile = "c:\Program Files\Git\etc\gitconfig"
  do {
    $GitFileExists = $false
    if (Test-Path $GitConfigFile) {$GitFileExists = $true}
    if ($GitFileExists -eq $true) {$GitFileInfo = Get-ChildItem $GitConfigFile}
    Start-Sleep -Seconds 1
  } Until ($GitFileExists -eq $true -and $GitFileInfo.Length -gt 200)
  # Modify Git config
  Write-Verbose "Just before Git config"
  Write-Debug "Just before Git config"
  git config --global user.name $GitFullName
  git config --global user.email $GitEmailAddress
  $GitConfigFile = "c:\Program Files\Git\etc\gitconfig"
  $OldGitConf = Get-Content $GitConfigFile
  $NewGitConf = $OldGitConf -replace 'defaultBranch = \b.+\b','defaultBranch = main'
  try {Set-Content -Path $GitConfigFile -Value $NewGitConf -ErrorAction Stop}
  catch {Write-Verbose "The Git config file was not changed due to an error"}
  Write-Verbose "Just before deploying VSCode"
  Write-Debug "Just before deploying VSCode"
  # Cloning the GitHub Repo into the e:\GitRoot folder
  $DrivesNotC = Get-Volume | Where-Object {$_.DriveType -eq 'fixed' -and $_.DriveLetter -match '[d-z]'}
  if ($DrivesNotC.Count -eq 0) {$DriveLetter = 'C:\'}
  else {$DriveLetter = $DrivesNotC[0].DriveLetter + ':\'}
  $GitPath = $DriveLetter + 'GitRoot'

  if (Test-Path $DriveLetter) {
    if ($GitHubRepoURL -ne '') {
      if ((Test-Path $GitPath) -eq $false) {
        New-Item -Path $DriveLetter -Name 'GitRoot' -ItemType Directory -Force *> $null
      }
     Set-Location $GitPath
     git clone $GitHubRepoURL *> $null
    }
  }

  # Deploying VSCode
  $Percent = 0
  $VSCodeLink = 'https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user'
  $VSCodeFileNamePath = $TempDrive + 'VSCodeSetup.exe'
  Write-Progress -Activity 'Deploying VSCode' -CurrentOperation 'Downloading VSCode' -PercentComplete  50
  $WebClientObj.DownloadFile($VSCodeLink,$VSCodeFileNamePath)
  Write-Progress -Activity 'Deploying VSCode' -CurrentOperation 'Downloading VSCode' -PercentComplete  100
  Invoke-Expression -Command "$VSCodeFileNamePath /VERYSILENT /NORESTART" 
  do {
    Write-Progress   -Activity 'Deploying VSCode' -CurrentOperation 'Installing VSCode - Please wait until install script is complete' -PercentComplete $Percent
    Start-Sleep -Milliseconds 400
    $Percent++ 
  } until ($Percent -ge 100)
  Write-Verbose "Just before killing Code.exe process"
  Write-Debug "Just before killing Code.exe process"
  Do {
    Start-Sleep -Milliseconds 100
    $CodeProc = Get-Process | Where-Object {$_.Name -eq 'Code'}
  } until ($CodeProc.Count -ge 1)
  Stop-Process -Name Code -Force -Confirm:$false
  Write-Verbose "Just before changing VSCode config"
  Write-Debug "Just before changing VSCode config"
  #Creating the VSCode settings file
  $VSCodeSettingsObj = [PSCustomObject]@{
    "security.workspace.trust.untrustedFiles"= "open"
    "editor.fontSize"= 16
    "debug.console.fontSize"= 16
    "markdown.preview.fontSize"= 16
    "terminal.integrated.fontSize"= 16
    "editor.tabSize"= 2
  }
  Set-Content -Path "$env:APPDATA\Code\User\settings.json" -Value ($VSCodeSettingsObj | ConvertTo-Json)
}