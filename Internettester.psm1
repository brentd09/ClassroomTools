function Test-Internet {
  <#
  .SYNOPSIS
    Tests the internet connection
  .DESCRIPTION
    Tests the internet connection by using the Test-NetConnection cmdlet to the IP
    address 1.1.1.1, if this fails it then tests 8.8.8.8 in case 1.1.1.1 happens to
    be down.
    It will record each attempt to access these addresses in the AllData log and in
    the Summary log it will only record major events: when the connection has dropped
    and when the connection resestablishes itself.
    The log will only continue for a number of days the number can be specified by 
    a parameter.
    If running this interactively the shell from which this is run must be left open
    otherwise the background job that is launched by this command will die. To have
    this run without the need to have the launching shell open, set up a scheduled
    task to run this test.
  .EXAMPLE
    Test-Internet -Days 4
    This will run the internet test and record the logs for 4 days
  .PARAMETER Days
    This will specify, in Days, how long the test should run for.
  .NOTES
    General notes
      Created By: Brent Denny
      Created On: 17-Jul-2019
  #>
  [CmdletBinding()]
  Param(
    [int]$Days = 1
  )
  start-job -ScriptBlock {
    $FirstTest = $true
    $LaunchDate = Get-Date
    $LaunchDateString = ($LaunchDate.ToString() ) -replace '[ :/]','-'
    $InitalTest = Test-NetConnection -ComputerName 1.1.1.1
    $InternetIsWorking = ($InitalTest).PingSucceeded
    $LogFolder = $env:HOMEDRIVE + $env:HOMEPATH + '\Documents\'
    $LogAllFilePath = $LogFolder + 'InternetLogAllData' + $LaunchDateString + '.log'
    $LogSummaryFilePath = $LogFolder + 'InternetSummaryData' + $LaunchDateString + '.log'
    $LogEndDate = $LaunchDate.AddDays($Days)
    $InitialReport = $InitalTest | Select-Object -Property ComputerName,PingSucceeded,@{n='TimeOfTest';e={$LaunchDateString}}

    '-----------------------' | Out-File -Append -FilePath $LogSummaryFilePath
    "Log began at $LaunchDateString" | Out-File -Append -FilePath $LogSummaryFilePath
    "Initial test shows:" | Out-File -Append -FilePath $LogSummaryFilePath
    $InitialReport | Out-File -Append -FilePath $LogSummaryFilePath
    '-----------------------' | Out-File -Append -FilePath $LogSummaryFilePath
    '-----------------------' | Out-File -Append -FilePath $LogAllFilePath
    "Log began at $LaunchDateString" | Out-File -Append -FilePath $LogAllFilePath
    '-----------------------' | Out-File -Append -FilePath $LogAllFilePath
    [IO.File]::ReadAllText($LogSummaryFilePath) -replace '\s+\r\n+', "`r`n" | Out-File $LogSummaryFilePath
    [IO.File]::ReadAllText($LogAllFilePath) -replace '\s+\r\n+', "`r`n" | Out-File $LogAllFilePath

    while ($LaunchDate -le $LogEndDate) {
      $TimeTested = Get-Date
      $TimeTestedString = ($TimeTested.ToString() ) -replace '[ :/]','-'
      $TestConnectionResults = Test-NetConnection -ComputerName 1.1.1.1 
      if ($TestConnectionResults.PingSucceeded -eq $false) {$TestConnectionResults = Test-NetConnection -ComputerName 8.8.8.8 }
      $TestReport = $TestConnectionResults | Select-Object -Property ComputerName,PingSucceeded,@{n='TimeOfTest';e={$TimeTestedString}}
      if ($FirstTest -eq $true) {$FirstTest = $false; $TestReport | Format-Table | Out-File -Append -FilePath $LogAllFilePath}
      else {$TestReport | Format-Table -HideTableHeaders | Out-File -Append -FilePath $LogAllFilePath}
      [IO.File]::ReadAllText($LogAllFilePath) -replace '\s+\r\n+', "`r`n" | Out-File $LogAllFilePath
      if ($InternetIsWorking -eq $false -and $TestConnectionResults.PingSucceeded -eq $true) {
        $InternetRevivedTime = Get-Date
        $InternetRevivedTimeString = ($InternetRevivedTime.ToString() ) -replace '[ :/]','-'
        $State = 'internet came back online' + $InternetRevivedTimeString
        $InternetIsWorking = $true
        $State | Out-File -Append -FilePath $LogSummaryFilePath
        '-----------------------' | Out-File -Append -FilePath $LogSummaryFilePath
        [IO.File]::ReadAllText($LogAllFilePath) -replace '\s+\r\n+', "`r`n" | Out-File $LogSummaryFilePath
      }
      if ($InternetIsWorking -eq $true -and $TestConnectionResults.PingSucceeded -eq $false) {
        $InternetDroppedTime = Get-Date
        $InternetDroppedTimeString = ($InternetDroppedTime.ToString() ) -replace '[ :/]','-'
        $State = 'internet connection droped' + $InternetDroppedTimeString
        $InternetIsWorking = $false
        '-----------------------' | Out-File -Append -FilePath $LogSummaryFilePath
        $State | Out-File -Append -FilePath $LogSummaryFilePath
        [IO.File]::ReadAllText($LogSummaryFilePath) -replace '\s+\r\n+', "`r`n" | Out-File $LogSummaryFilePath
      }
    } # whileloop
    '-----------------------' | Out-File -Append -FilePath $LogSummaryFilePath
    "Log ended at $TimeTestedString" | Out-File -Append -FilePath $LogSummaryFilePath
    '-----------------------' | Out-File -Append -FilePath $LogSummaryFilePath
    '-----------------------' | Out-File -Append -FilePath $LogAllFilePath
    "Log ended at $TimeTestedString" | Out-File -Append -FilePath $LogAllFilePath
    '-----------------------' | Out-File -Append -FilePath $LogAllFilePath
    [IO.File]::ReadAllText($LogSummaryFilePath) -replace '\s+\r\n+', "`r`n" | Out-File $LogSummaryFilePath
    [IO.File]::ReadAllText($LogAllFilePath) -replace '\s+\r\n+', "`r`n" | Out-File $LogAllFilePath
  } # startjob
}