function Test-Internet {
  [CmdletBinding()]
  Param()
  start-job -ScriptBlock {
    $FirstTest = $true
    $LaunchDate = Get-Date
    $LaunchDateString = ($LaunchDate.ToString() ) -replace '[ :/]','-'
    $InternetIsWorking = Test-NetConnection -ComputerName 1.1.1.1 -InformationLevel Quiet
    $LogFolder = $env:HOMEDRIVE + $env:HOMEPATH + '\Documents\'
    $LogAllFilePath = $LogFolder + 'InternetLogAllData' + $LaunchDateString + '.log'
    $LogSummaryFilePath = $LogFolder + 'InternetSummaryData' + $LaunchDateString + '.log'
    $LogEndDate = $LaunchDate.AddDays(1)
    '-----------------------' | Out-File -Append -FilePath $LogSummaryFilePath
    "Log begins at $LaunchDateString" | Out-File -Append -FilePath $LogSummaryFilePath
    '-----------------------' | Out-File -Append -FilePath $LogSummaryFilePath
    '-----------------------' | Out-File -Append -FilePath $LogAllFilePath
    "Log begins at $LaunchDateString" | Out-File -Append -FilePath $LogAllFilePath
    '-----------------------' | Out-File -Append -FilePath $LogAllFilePath
    while ($LaunchDate -le $LogEndDate) {
      $TimeTested = Get-Date
      $TimeTestedString = ($TimeTested.ToString() ) -replace '[ :/]','-'
      $TestConnectionResults = Test-NetConnection -ComputerName 1.1.1.1 
      $TestReport = $TestConnectionResults | Select-Object -Property ComputerName,PingSucceeded,@{n='TimeOfTest';e={$TimeTestedString}}
      if ($FirstTest -eq $true) {$FirstTest = $false; $TestReport | Format-Table | Out-File -Append -FilePath $LogAllFilePath}
      else {$TestReport | Format-Table -HideTableHeaders | Out-File -Append -FilePath $LogAllFilePath}
      [IO.File]::ReadAllText($LogAllFilePath) -replace '\s+\r\n+', "`r`n" | Out-File $LogAllFilePath
      if ($TestConnectionResults.PingSucceeded -eq $false) {$TestConnectionResults = Test-NetConnection -ComputerName 8.8.8.8}
      if ($InternetIsWorking -eq $false -and $TestConnectionResults.PingSucceeded -eq $true) {
        $InternetRevivedTime = Get-Date
        $InternetRevivedTimeString = ($InternetRevivedTime.ToString() ) -replace '[ :/]','-'
        $State = 'internet came back online' + $InternetRevivedTimeString
        $InternetIsWorking = $true
        $State | Out-File -Append -FilePath $LogSummaryFilePath
        '-----------------------' | Out-File -Append -FilePath $LogSummaryFilePath
      }
      if ($InternetIsWorking -eq $true -and $TestConnectionResults.PingSucceeded -eq $false) {
        $InternetDroppedTime = Get-Date
        $InternetDroppedTimeString = ($InternetDroppedTime.ToString() ) -replace '[ :/]','-'
        $State = 'internet connection droped' + $InternetDroppedTimeString
        $InternetIsWorking = $false
        '-----------------------' | Out-File -Append -FilePath $LogSummaryFilePath
        $State | Out-File -Append -FilePath $LogSummaryFilePath
      }
    }
  }
}

Test-Internet