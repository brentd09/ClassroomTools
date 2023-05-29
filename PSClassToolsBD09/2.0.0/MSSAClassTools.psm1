function Install-VSCodeAndGit {
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
  .PARAMETER GitHubUserName
    This is the name that you signed up to GitHub with. This will be used
    as part of the Repo URL to clone the repo to your machine. 
  .PARAMETER GitHubRepoName
    This is the name of the repository that you want cloned on this computer.
    This will be used along with the GitHubUserName to clone a copy of this 
    repo into the e:\GitRoot folder. If the E: does not exist it will create
    the repo clone in your Documents folder.
  .EXAMPLE
    Install-VsCodeAndGit -GitFullName "John Dowe" -GitEmailAddress "JDowe@hotmail.com"
    This command downloads the git and vscode installer files into the temp directory
    and then installs these applications in VERYSILENT mode. It also sets up the
    Git Config file and sets default values for VSCode
  .EXAMPLE
    Install-VsCodeAndGit -GitFullName "John Dowe" -GitEmailAddress "JDowe@hotmail.com" -GitHubUserName 'JohnD' -GitHubRepoName 'MyRepo'
    This command downloads the git and vscode installer files into the temp directory
    and then installs these applications in VERYSILENT mode. It also sets up the
    Git Config file and sets default values for VSCode. This will also clone the
    GitHub repository from https://github.com/JohnD/MyRepo into the e:\GitRoot folder
  .NOTES
    General notes
      Created By: Brent Denny
      Created On: 01-Mar-2022
      Last Modified: 26-May-2023
    ChangeLog
      Ver Date Details
      --- ---- -------
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
      v1.3.2 01-Apr-2022 Changed the order of the parameters so that the URL appears first in intellisense
      v1.4.3 25-May-2023 Fixed a few changes to vscode colors
      v1.4.4 25-May-2023 Fixed the download vscode issue 
      v2.0.0 26-May-2023 Full rewrite of the code
  #>
  [cmdletbinding()]
  Param (
    [string]$GitHubUserName = '',
    [string]$GitHubRepoName = '',
    [string]$GitFullName = '',
    [string]$GitEmailAddress = ''
  )

  function Hide-Window {
    $ErrorActionPreference = 'Stop'
    try {$Procs = Get-Process -Name 'Code'}
    catch {return $False}
    
    $Win32ShowWindowAsync = Add-Type –memberDefinition @” 
[DllImport("user32.dll")] 
public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow); 
“@ -name “Win32ShowWindowAsync” -namespace Win32Functions –passThru
    foreach ($Proc in $Procs) {
      $MainWindowHandle = $Proc.MainWindowHandle
      $Win32ShowWindowAsync::ShowWindowAsync($MainWindowHandle, 6) | Out-Null
    }
  }


  Write-Progress -id 1 -Activity "Getting Git and VSCode ready for you" -PercentComplete 0 
  Write-Progress -Id 2 -Activity "Checking Internet Access"
  
  try {
    Resolve-DnsName -Name 'github.com' -ErrorAction Stop *> $null
  }
  catch {
    Write-Verbose "Internet is not reachable";break
  }

  Write-Progress -id 1 -Activity "Getting Git and VSCode ready for you" -PercentComplete 15 
  Write-Progress -Id 2 -Activity "Setting main system variables"

  # Setup all of the variable that this program requires for installing git and vscode and then cloning the repo
  $WebClientObj = New-Object -TypeName System.Net.WebClient
  $GitDownloadPath = $env:HOMEDRIVE + $env:HOMEPATH + '\Downloads\GitInstaller.exe'
  $VSCodeDownloadPath = $env:HOMEDRIVE + $env:HOMEPATH + '\Downloads\VSCodeInstaller.exe'
  $GitWebContent = try {Invoke-WebRequest -Uri 'https://git-scm.com/download/win'} catch {Write-Verbose 'Unable to download latest version of git';break}
  $GitDownloadURL = (($GitWebContent).Links | Where-Object {$_ -match '64' -and $_ -notmatch 'portable'} ).Href
  $VSCodeDownloadURL = 'https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user'
  if ($GitHubUserName -ne '' -and $GitHubRepoName -ne '') {
    $GitHubRepoURL = 'https://github.com/' + $GitHubUserName + '/' + $GitHubRepoName + '.git'
  }
  else {
    Write-Verbose 'GitHub URL was not set'
    break
  }

  Write-Progress -id 1 -Activity "Getting Git and VSCode ready for you" -PercentComplete 10 
  Write-Progress -Id 2 -Activity "Downloading the installers for Git and VSCode"

  # Try to download the Git and VSCode installers
  $ErrorActionPreference = 'Stop'
  try {
    # Git Installer download 
    $WebClientObj.DownloadFile($GitDownloadURL,$GitDownloadPath)
  }  
  catch {
    Write-Verbose "GitDownloadURL , GitDownloadPath = $GitDownloadURL  $GitDownloadPath"
    Write-Verbose 'Unable to access git download website, failed to download'
    break
  }
  try {
    # VSCode installer download
    $WebClientObj.DownloadFile($VSCodeDownloadURL,$VSCodeDownloadPath)
  }
  catch {
    Start-Sleep -Seconds 10
    try {
      # try download again if failed the first time
      $WebClientObj.DownloadFile($VSCodeDownloadURL,$VSCodeDownloadPath)
      Start-Sleep -Seconds 5
    }
    catch {
      Write-Verbose " VSCodeDownloadURL, VSCodeDownloadPath = $VSCodeDownloadURL $VSCodeDownloadPath"
      Write-Verbose 'Unable to access VSCode download website, failed to download'
      break
    }    
  }
  try {
    # Check access to the GitHub Repo
    invoke-WebRequest -Uri $GitHubRepoURL *> $null
  }
  catch {
    Write-Verbose "GitHubRepoURL = $GitHubRepoURL"
    Write-Verbose 'Unable to access Github Repository'
    break  
  }
  $ErrorActionPreference = 'Continue'

  Write-Progress -id 1 -Activity "Getting Git and VSCode ready for you" -PercentComplete 30 
  Write-Progress -Id 2 -Activity "Installing Git"

  # Install Git using downloaded installer
  try {Invoke-Expression -Command "$GitDownloadPath /VERYSILENT /NORESTART" -ErrorAction 'Stop'}
  catch {
    Write-Verbose "The Git installer has not started"
    break 
  }
  $InstallSucceeded = $false
  $Counter = 0
  do {
    $Counter++
    if ($Counter -ge 360) {
      Write-Error "The git installer failed to Install"
      throw 
    }
    Start-Sleep -Seconds 1
    if (Test-Path ($env:ProgramFiles + '\git\bin')) {
      Write-Verbose "Git path found"
      $env:Path = $env:Path + ";" + "C:\Program Files\Git\bin"
      $InstallSucceeded = $true
    }
  } until ($InstallSucceeded -eq $true)



  
  Write-Progress -id 1 -Activity "Getting Git and VSCode ready for you" -PercentComplete 45 
  Write-Progress -Id 2 -Activity "Installing VSCode"

  # Install VSCode using downloaded installer
  try {Invoke-Expression -Command "$VSCodeDownloadPath /VERYSILENT /NORESTART" -ErrorAction 'Stop'}
  catch {Write-Verbose "VSCode installer failed" }
  $InstallSucceeded = $false
  $Counter = 0
  do { 
    $Counter++
    if ($Counter -ge 360) {
      Write-Error "The VSCode installer failed to Install"
      throw 
    }
    Start-Sleep -Seconds 1
    if (Test-Path ($env:UserProfile + '\AppData\Local\Programs\Microsoft VS Code' )) {
      Write-Verbose "VSCode path found"
      $env:Path = $env:Path + ';' + $env:UserProfile + '\AppData\Local\Programs\Microsoft VS Code'
      $InstallSucceeded = $true
    }
  } until ($InstallSucceeded -eq $true)
  Start-Sleep -Seconds 60

  Write-Progress -id 1 -Activity "Getting Git and VSCode ready for you" -PercentComplete 60 
  Write-Progress -Id 2 -Activity "Configuring Git"

  # Modify Git Configuration
  try {
    $ErrorActionPreference = 'Stop'
    git config --global user.name $GitFullName
    git config --global user.email $GitEmailAddress
    $GitConfigFile = "c:\Program Files\Git\etc\gitconfig"
    $OldGitConf = Get-Content $GitConfigFile
    $NewGitConf = $OldGitConf -replace 'defaultBranch = \b.+\b','defaultBranch = main'
    try {Set-Content -Path $GitConfigFile -Value $NewGitConf -ErrorAction Stop}
    catch {Write-Verbose "The Git config file was not changed due to an error";break}
    $ErrorActionPreference = 'Continue'
  }
  catch {Write-Verbose "Git Config Failed"}

  Write-Progress -id 1 -Activity "Getting Git and VSCode ready for you" -PercentComplete 80 
  Write-Progress -Id 2 -Activity "Cloning GitHub Repository"

  # Clone Github Repo
  if (Test-Path -Path E:\) {$CloneRootPath = 'E:'}
  else {$CloneRootPath = $env:UserProfile + '\Documents'}
  $GitHubRepoClonePath = $CloneRootPath + '\GitRoot\' + $GitHubRepoName 
  Write-Verbose "GitHubRepoClonePath $GitHubRepoClonePath  GitHubRepoName  $GitHubRepoName" 
  git clone $GitHubRepoURL $GitHubRepoClonePath *> $null
  
  Write-Progress -id 1 -Activity "Getting Git and VSCode ready for you" -PercentComplete 90 
  Write-Progress -Id 2 -Activity "Configuring VSCode"

  # Modify VSCode config
  Do {
    Start-Sleep -Seconds 1
    try { $CodeProc = Get-Process -Name 'Code' -ErrorAction Stop }
    catch {}
  } until ($CodeProc.Count -ge 1)
  Hide-Window
  Stop-Process -Name Code -Force -Confirm:$false
  
  #Creating the VSCode settings file
  $VSCodeSettingsObj = [PSCustomObject]@{
    "security.workspace.trust.untrustedFiles"= "open"
    "editor.fontSize"= 16
    "debug.console.fontSize"= 16
    "markdown.preview.fontSize"= 16
    "terminal.integrated.fontSize"= 16
    "editor.tabSize"= 2
    "workbench.colorTheme" = "PowerShell ISE"
    "git.autofetch"= "true"
    "git.enableSmartCommit"= "true"
    "git.confirmSync"= "false"
    "scm.inputFontSize"= 16
    "interactiveSession.editor.fontSize"= 16
    "workbench.colorCustomizations"= @{
        "editor.lineHighlightBackground"= "#f7f6c077"
        "editor.selectionBackground"= "#fac3c3d0"
        "editor.selectionHighlightBackground"= "#f8d0d07e"
        "editor.wordHighlightBackground"= "#f5e6f0"
    }
  }
  try {Set-Content -Path "$env:APPDATA\Code\User\settings.json" -Value ($VSCodeSettingsObj | ConvertTo-Json)}
  catch {Write-Verbose "VSCode config failed"}

  Write-Progress -id 1 -Activity "Getting Git and VSCode ready for you" -PercentComplete 100 
  Write-Progress -Id 2 -Activity "Complete"

}


