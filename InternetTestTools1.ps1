function Test-HomeInternetConnection {
  # Report on Home internet outages
  [cmdletbinding()]
  Param(
    [switch]$AsJob
  )
  if ($AsJob) {
    start-job -ScriptBlock {
      $StartDate = Get-Date
      $EndDate = (Get-Date).AddHours(2)
      $TimeStamp = ($StartDate.ToString()) -replace '[ :/]','-'
      $LogFile = $env:HOMEDRIVE + $env:HOMEPATH + "\documents\HomeInternet$TimeStamp.log"
      $Results = $env:HOMEDRIVE + $env:HOMEPATH + "\documents\HomeInternetAllData$TimeStamp.log"
      $PreviousInterNetStatus = Test-NetConnection -ComputerName 1.1.1.1 -InformationLevel Quiet
      '-----------' | Out-File -Append $LogFile
      'LOG STARTED' | Out-File -Append $LogFile
      ($StartDate).DateTime | Out-File -Append $LogFile
      '-----------' | Out-File -Append $LogFile
      $OutageTime = "None recorded yet"
      While ($StartDate -lt $EndDate) {
        $TestDateTime = Get-Date
        $CurrentTimeStamp = ($TestDateTime.ToString()) -replace '[ :/]','-'
        $ConnectionDetails = Test-NetConnection -ComputerName 1.1.1.1 | Select-Object -Property *,@{n='TimeStamp';e={$CurrentTimeStamp}}
        $ConnectionDetails | 
          Select-Object -Property ComputerName,InterfaceAlias,PingSucceeded,TimeStamp |
          ConvertTo-Json | 
          Out-File -Append $Results
        if ($ConnectionDetails.PingSucceeded -eq $true -and $PreviousInterNetStatus -eq $false) {
          $CurrentTimeStamp | Out-File -Append $LogFile
          'Internet came up from previous outage' | Out-File -Append $LogFile
          If ($OutageTime -is [datetime]) {$}
          $PreviousInterNetStatus = $true
        }
        if ($ConnectionDetails.PingSucceeded -eq $false -and $PreviousInterNetStatus -eq $true){
          $OutageTime = $CurrentTimeStamp
          $CurrentTimeStamp | Out-File -Append $LogFile
          'Internet experienced an outage' | Out-File -Append $LogFile
          $PreviousInterNetStatus = $false  
        }
      }
      '---------' | Out-File -Append $LogFile
      'LOG ENDED' | Out-File -Append $LogFile
      ($StartDate).DateTime | Out-File -Append $LogFile
      '---------' | Out-File -Append $LogFile
    } #Start-Job
  } # If asjob
} # function

Test-HomeInternetConnection -asjob