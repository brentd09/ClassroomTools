﻿function Submit-ClassRoll {
  <#
  .Synopsis
     Converts DDLS Teams Attendance Sheet from CSV to HTML and reports on student attendance
  .DESCRIPTION
     From the Teams Trainer Dashboard we can export the Attendance Sheet as 
     CSV and this can then be consumed by this script to fill in the 
     attendance roll. Students can be marked as:
     - Y for Attended
     - N for No show
     - L for Late to class
     using [ENTER] key will also count as Attended
     This script then creates possibly two html tables, one for attendees and 
     no shows and another for late students. The script then opens chrome to
     reveal the attendance tables, which can then be easily copy and pasted into 
     an email 
  .PARAMETER CSVfilePath
     This is the path to the teams exported Attendance Sheet in CSV format. This 
     can be a relative or absolute path. The path must include the name of the CSV
     file to be consumed  
  .PARAMETER StudentIntro
     This is a switch parameter that changes the output of the student list to one 
     you can print to record introduction information, it will automatically space 
     the students in the table so that all fit on an A4 page when printed 
  .PARAMETER TrainerName
     The trainer name will be used to create the attendance report. The name will be 
     changed into uppercase before the report is created. 
  .EXAMPLE
     Submit-ClassRoll -CSVfilePath c:\exports\ClassList.csv
     This will consume the file c:\exports\ClassList.csv and ask about the attendance 
     status of each student, from this it will create the HTML tables showing those
     attending those that are not and those that arrived late
  .EXAMPLE
     Submit-ClassRoll -CSVfilePath c:\exports\ClassList.csv -StudentIntro
     This will consume the file c:\exports\ClassList.csv and determine the number of 
     students in the class it will then create an HTML table that can be printed so
     that introductions can be recorded regarding each student on paper. 
  .NOTES
     General notes
       Created By: Brent Denny
       Created On: 31 Aug 2020
       Changed on: 30 Oct 2020
  #>
  [CmdletBinding()]
  Param (
    [Parameter(Mandatory=$true)]
    [string]$CSVfilePath,
    [switch]$StudentIntro,
    [string]$TrainerName = 'Brent Denny'
  )
  $TrainerName = $TrainerName.ToUpper()
  $DefaultSettingPath = 'HKCU:\SOFTWARE\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice'
  $DefaultBrowserName = (Get-Item $DefaultSettingPath | Get-ItemProperty).ProgId
  $DefaultBrowserOpenCommand = (Get-Item "HKLM:SOFTWARE\Classes\$DefaultBrowserName\shell\open\command" | Get-ItemProperty).'(default)'
  $DefaultBrowserPath = [regex]::Match($DefaultBrowserOpenCommand,'\".+?\"')
  $BrowserPath = $DefaultBrowserPath.Value
  if (Test-Path -Path $CSVfilePath -PathType Leaf) {
    $LeafPath = (Split-Path $CSVfilePath -Leaf ) -replace '\s+',''
    $LeafPathNoExt = $LeafPath -replace '\.csv$',''
    $FullPathToFile = (Resolve-Path $CSVfilePath).Path | Split-Path -Parent
    if ($StudentIntro -eq $true){$ExportHTMLPath = $FullPathToFile.TrimEnd('\') +'\'+$LeafPathNoExt+'-Intro'+'.html'}
    else {$ExportHTMLPath = $FullPathToFile.TrimEnd('\') +'\'+$LeafPathNoExt+'.html'}
    if ($StudentIntro -eq $true) {$Padding = 'td {padding-bottom: 50px;} table {width: 100%}'}
    else {$Padding = ''}
    $CSS = @"
    <style>
      table, tr,td,th {border:black 1pt solid;border-collapse:collapse;}
      td,th {padding-left:4pt;padding-right:4px;}
      $Padding
    </style>
"@
    
    $Attendees = @()
    $LateAttendees = @()
    if ($StudentIntro -eq $true){
      $ConvertedFileContents = Get-Content $CSVfilePath | 
        ConvertFrom-Csv | 
        Where-Object {$_."Student Name" -notmatch '[#@%?]'} |
        Sort-Object -Property "Student Name" | 
        Select-Object -Property "Student Name"
      $ConvertedFileContents | ForEach-Object {
        $Attendees += $_
      }
    }
    else {
      $ConvertedFileContents = Get-Content $CSVfilePath | 
        ConvertFrom-Csv | 
        Where-Object {$_."Student Name" -notmatch '[#@%?]'} |
        Sort-Object -Property "Student Name" | 
        Select-Object -Property "Student Name",'Attendance' 
      $ConvertedFileContents | ForEach-Object {
        do {
          $Attendance = Read-Host -Prompt "Is `"$($_."student name")`" on the course (y - yes, n - no or l - late) Default=y"
        } until ($Attendance -in @('y','n','l',''))
        if ($Attendance -eq ''){$Attendance = 'y'}
        if ($Attendance -eq 'l'){$Attendance = 'LATE'}
        $_.Attendance = $Attendance.ToUpper()
        if ($Attendance -in @('y','n')){$Attendees += $_}
        else {$LateAttendees += $_}
      }   
    }
    $TotalStudents = $ConvertedFileContents.Count
    $Spacing = 680 / $TotalStudents
    if ($StudentIntro -eq $true) {$Padding = "td {padding-bottom: ${Spacing}px;} table {width: 100%}"}
    else {$Padding = ''}
    $CSS = @"
    <style>
      table, tr,td,th {border:black 1pt solid;border-collapse:collapse;}
      td,th {padding-left:4pt;padding-right:4px;}
      $Padding
    </style>
"@

    [string]$FragAtttend = $Attendees | Sort-Object -Property "Student Name" | ConvertTo-Html -Fragment  -PreContent '<BR><BR>' 
    [string]$FragLate = $LateAttendees | Sort-Object -Property "Student Name"  | ConvertTo-Html -Fragment -PreContent '<BR><BR>' 
    if ($StudentIntro -eq $true) {$Precontent = ' '}
    else {$Precontent = "<h2>attendance ${TrainerName}</h2>"}
    try {ConvertTo-Html -Head $CSS -PreContent $Precontent -PostContent $FragAtttend,$FragLate | Out-File $ExportHTMLPath}
    Catch {Write-Warning "$ExportHTMLPath could not be written to disk";break}
    if (Test-Path -Path "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe") {
      Start-Process -FilePath $BrowserPath -ArgumentList $ExportHTMLPath
    }
    else {
      Write-Host "The HTML Attendance information is stored $ExportHTMLPath"
    }
  }
  else {Write-Warning "$CSVfilePath does not exist as a file"}
}

function Invoke-BreakTimer {
  <#
  .Synopsis
    Calculates the end of break times in multiple cities
  .DESCRIPTION
    This program calclates break times for Brisbane, Sydney, Adelaide
    and one other timezone of your choice. Determining wheneach city 
    should return from their break relevant to their timezone
  .EXAMPLE
    Invoke-BreakTimer
    This will start a gui tool to determine end of break times
  .NOTES
    General notes
      Created By: Brent Denny
      Created On: 28 May 2020
      Last Changed: 12 Nov 2020
  #>

  [cmdletbinding()]
  Param ()
  
  function Get-RemainingMinutes {
    Param ([datetime]$FutureTime)
    $CurrentDate = Get-Date
    $TimeSpan = $FutureTime - $CurrentDate
    return $TimeSpan.TotalMinutes -as [int]
  }

  $AllTimeZones = [System.TimeZoneInfo]::GetSystemTimeZones()
  $TimeZoneIds = $AllTimeZones.id
  $TimeZoneNames = $AllTimeZones.DisplayName
  
  Add-Type -AssemblyName System.Windows.Forms
  [System.Windows.Forms.Application]::EnableVisualStyles()


  
  $LabForm                     = New-Object system.Windows.Forms.Form
  $LabForm.ClientSize          = '450,470'
  $LabForm.text                = "Class Break Timer"
  $LabForm.TopMost             = $true
  $LabForm.Select()
                               
  $CurrentTimebtn              = New-Object system.Windows.Forms.Button
  $CurrentTimebtn.text         = "Get Current Time"
  $CurrentTimebtn.width        = 150
  $CurrentTimebtn.height       = 30
  $CurrentTimebtn.location     = New-Object System.Drawing.Point(22,85)
  $CurrentTimebtn.Font         = 'Microsoft Sans Serif,10'
                           
  $CurrentTimelbl              = New-Object system.Windows.Forms.Label
  $CurrentTimelbl.text         = ""
  $CurrentTimelbl.AutoSize     = $false
  $CurrentTimelbl.width        = 80
  $CurrentTimelbl.height       = 20
  $CurrentTimelbl.location     = New-Object System.Drawing.Point(182,92)
  $CurrentTimelbl.Font         = 'Microsoft Sans Serif,10'
                               
  $HowlongLbl                  = New-Object system.Windows.Forms.Label
  $HowlongLbl.text             = "Length of break(min.)"
  $HowlongLbl.AutoSize         = $true
  $HowlongLbl.width            = 25
  $HowlongLbl.height           = 10
  $HowlongLbl.location         = New-Object System.Drawing.Point(78,42)
  $HowlongLbl.Font             = 'Microsoft Sans Serif,10'
                  
  $HowLongtbox                 = New-Object system.Windows.Forms.TextBox
  $HowLongtbox.multiline       = $false
  $HowLongtbox.width           = 40
  $HowLongtbox.height          = 60
  $HowLongtbox.location        = New-Object System.Drawing.Point(30,37)
  $HowLongtbox.Font            = 'Microsoft Sans Serif,10'
                               
  $BorderStyle                 = [System.Windows.Forms.BorderStyle]::FixedSingle
  $CountDownLbl                = New-Object system.Windows.Forms.Label
  $CountDownLbl.BorderStyle    = $BorderStyle
  $CountDownLbl.text           = $HowLongtbox.Text
  $CountDownLbl.AutoSize       = $true
  $CountDownLbl.width          = 20
  $CountDownLbl.height         = 20
  $CountDownLbl.location       = New-Object System.Drawing.Point(270,52)
  $CountDownLbl.Font           = 'Microsoft Sans Serif,70'
  $CountDownLbl.BackColor      = 'Red'
    
  $RemainingMinLbl             = New-Object system.Windows.Forms.Label
  $RemainingMinLbl.text        = "Minutes Remaining"
  $RemainingMinLbl.AutoSize    = $true
  $RemainingMinLbl.width       = 25
  $RemainingMinLbl.height      = 10
  $RemainingMinLbl.location    = New-Object System.Drawing.Point(267,29)
  $RemainingMinLbl.Font        = 'Microsoft Sans Serif,13'
  $RemainingMinLbl.ForeColor   = 'Red'
    
  $CalcEndBtn                  = New-Object system.Windows.Forms.Button
  $CalcEndBtn.text             = "Calculate Return Time"
  $CalcEndBtn.width            = 150
  $CalcEndBtn.height           = 30
  $CalcEndBtn.location         = New-Object System.Drawing.Point(22,140)
  $CalcEndBtn.Font             = 'Microsoft Sans Serif,10'
  
  $EndTimetLbl                 = New-Object system.Windows.Forms.Label
  $EndTimetLbl.text            = "Return to Course"
  $EndTimetLbl.AutoSize        = $true
  $EndTimetLbl.width           = 25
  $EndTimetLbl.height          = 10
  $EndTimetLbl.location        = New-Object System.Drawing.Point(275,198)
  $EndTimetLbl.Font            = 'Microsoft Sans Serif,10'
  
  $CityLocalLbl                = New-Object system.Windows.Forms.Label
  $CityLocalLbl.text           = "Brisbane"
  $CityLocalLbl.AutoSize       = $true
  $CityLocalLbl.width          = 25
  $CityLocalLbl.height         = 10
  $CityLocalLbl.location       = New-Object System.Drawing.Point(22,196)
  $CityLocalLbl.Font           = 'Microsoft Sans Serif,10'
  
  $CitySydLbl                  = New-Object system.Windows.Forms.Label
  $CitySydLbl.text             = "Sydney/Melbourne"
  $CitySydLbl.AutoSize         = $true
  $CitySydLbl.width            = 25
  $CitySydLbl.height           = 10
  $CitySydLbl.location         = New-Object System.Drawing.Point(22,246)
  $CitySydLbl.Font             = 'Microsoft Sans Serif,10'

  $CityAdelLbl                 = New-Object system.Windows.Forms.Label
  $CityAdelLbl.text            = "Adelaide"
  $CityAdelLbl.AutoSize        = $true
  $CityAdelLbl.width           = 25
  $CityAdelLbl.height          = 10
  $CityAdelLbl.location        = New-Object System.Drawing.Point(22,296)
  $CityAdelLbl.Font            = 'Microsoft Sans Serif,10'
  
  $CityCombo                   = New-Object system.Windows.Forms.ComboBox
  $CityCombo.text              = '(UTC+08:00) Perth'
  $CityCombo.width             = 240
  $CityCombo.height            = 20
  $CityCombo.location          = New-Object System.Drawing.Point(22,346)
  $CityCombo.Font              = 'Microsoft Sans Serif,10'
  $CityCombo.SelectedItem      = '(UTC+08:00) Perth'
  $CityCombo.DropDownStyle     = 'DropDownList'
  $TimeZoneNames | ForEach-Object {[void] $CityCombo.Items.Add($_)}
  
  $EndTimetLblSyd              = New-Object system.Windows.Forms.Label
  $EndTimetLblSyd.text         = "Return to Course"
  $EndTimetLblSyd.AutoSize     = $true
  $EndTimetLblSyd.width        = 25
  $EndTimetLblSyd.height       = 10
  $EndTimetLblSyd.location     = New-Object System.Drawing.Point(275,248)
  $EndTimetLblSyd.Font         = 'Microsoft Sans Serif,10'                       
  
  $EndTimetLblAdel             = New-Object system.Windows.Forms.Label
  $EndTimetLblAdel.text        = "Return to Course"
  $EndTimetLblAdel.AutoSize    = $true
  $EndTimetLblAdel.width       = 25
  $EndTimetLblAdel.height      = 10
  $EndTimetLblAdel.location    = New-Object System.Drawing.Point(275,298)
  $EndTimetLblAdel.Font        = 'Microsoft Sans Serif,10'
  
  $EndTimeyLblCombo            = New-Object system.Windows.Forms.Label
  $EndTimeyLblCombo.text       = "Choose a Location"
  $EndTimeyLblCombo.AutoSize   = $true
  $EndTimeyLblCombo.width      = 25
  $EndTimeyLblCombo.height     = 10
  $EndTimeyLblCombo.location   = New-Object System.Drawing.Point(275,348)
  $EndTimeyLblCombo.Font       = 'Microsoft Sans Serif,10'                       
  
  $ResetBtn                    = New-Object system.Windows.Forms.Button
  $ResetBtn.text               = "Reset"
  $ResetBtn.width              = 80
  $ResetBtn.height             = 30
  $ResetBtn.location           = New-Object System.Drawing.Point(220,410)
  $ResetBtn.Font               = 'Microsoft Sans Serif,10'
                           
  $CloseBtn                    = New-Object system.Windows.Forms.Button
  $CloseBtn.text               = "Close"
  $CloseBtn.width              = 80
  $CloseBtn.height             = 30
  $CloseBtn.location           = New-Object System.Drawing.Point(320,410)
  $CloseBtn.Font               = 'Microsoft Sans Serif,10'

  # $CountDownLbl.Text = (Get-Date).ToShortTimeString()
                           
  $LabForm.controls.AddRange(
    @(
      $HowLongtbox,
      $CurrentTimebtn,
      $CalcEndBtn,
      $HowlongLbl,
      $CurrentTimelbl,
      $EndTimetLbl,
      $EndTimetLblAdel,
      $EndTimetLblSyd,
      $EndTimeyLblCombo,
      $CitySydLbl,
      $CityAdelLbl,
      $CityCombo,
      $CityLocalLbl,
      $CloseBtn,
      $CountDownLbl,
      $RemainingMinLbl,
      $ResetBtn
    )
  )
  
  $CurrentTimebtn.Add_Click(
    { 
      $Script:Now = Get-Date
      $CurrentTimeLbl.text     = $Now.ToShortTimeString()
      $CalcEndBtn.Enabled      = $true
      $EndTimetLbl.Enabled     = $true 
      $EndTimeyLblCombo.Enabled= $true
      $EndTimetLblSyd.Enabled  = $true
      $EndTimetLblAdel.Enabled = $true
      $CitySydLbl.Enabled      = $true
      $CityAdelLbl.Enabled     = $true
      $CityCombo.Enabled       = $true
     }
  )

  $CalcEndBtn.Add_Click(
    { 
      $CountDownLbl.enabled    = $true
      $RemainingMinLbl.enabled = $true
      $CountDownLbl.Visible    = $true
      $RemainingMinLbl.Visible = $true
      if ($HowLongtbox.Text -notmatch '^\d+$') {$HowLongtbox.Text = 15}
      $TimeSpan = New-TimeSpan -Minutes ($HowLongtbox.Text -as [int])
      $Script:Futuretime = (Get-Date).AddMinutes($TimeSpan.TotalMinutes -as [int])
      $CountDownLbl.Text = Get-RemainingMinutes -FutureTime $Script:Futuretime
      $script:ReturnTimeBrisbane = $Script:Now + $TimeSpan
      $ReturnTimeSydney   = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($script:ReturnTimeBrisbane,'AUS Eastern Standard Time')
      $ReturnTimeAdeliade = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($script:ReturnTimeBrisbane,'Cen. Australia Standard Time')
      $EndTimetLbl.text   = ($ReturnTimeBrisbane.DayofWeek -as [string]) + ' ' + $ReturnTimeBrisbane.toShortTimeString()
      if ($script:ReturnTimeBrisbane) {
        $TimeZoneId = ($AllTimeZones | Where-Object {$_.DisplayName -eq $($CityCombo.SelectedItem)}).Id 
        $ReturnTimechoice   = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($script:ReturnTimeBrisbane,$TimeZoneId)
        $EndTimeyLblCombo.text = ($ReturnTimechoice.DayofWeek -as [string]) + ' ' + $ReturnTimechoice.toShortTimeString()
      }
      $EndTimetLblSyd.Text  = ($ReturnTimeSydney.DayofWeek -as [string]) + ' ' + $ReturnTimeSydney.toShortTimeString()
      $EndTimetLblAdel.Text = ($ReturnTimeAdeliade.DayofWeek -as [string]) + ' ' + $ReturnTimeAdeliade.toShortTimeString()
      $Timer=New-Object System.Windows.Forms.Timer
      $Timer.Interval=30000
      $Timer.add_Tick({$CountDownLbl.Text = Get-RemainingMinutes -FutureTime $Script:Futuretime})
      $Timer.Start()
    }
  )

  $CloseBtn.Add_Click(
    {
      [void]$LabForm.Dispose()
    }
  )

  $ResetBtn.Add_Click(
    {
      $HowLongtbox.Text        = ''
      $CurrentTimelbl.Text     = ''
      $CalcEndBtn.Enabled      = $false
      $EndTimetLbl.Text        = ''
      $EndTimetLbl.Enabled     = $false  
      $EndTimetLblSyd.Text     = ''
      $EndTimetLblSyd.Enabled  = $false
      $EndTimetLblAdel.Text    = ''
      $EndTimetLblAdel.Enabled = $false
      $CitySydLbl.Enabled      = $false
      $CityAdelLbl.Enabled     = $false
      $CityCombo.Text          = '(UTC+08:00) Perth'
      $EndTimeyLblCombo.Text   = ''
      $EndTimeyLblCombo.Enabled= $false
      $CityCombo.Enabled       = $false
      $CountDownLbl.enabled    = $false
      $RemainingMinLbl.enabled = $false
      $CountDownLbl.Visible    = $false
      $RemainingMinLbl.Visible = $false
      $HowLongtbox.Select()
    }
  )

  $CityCombo.Add_SelectedValueChanged(
    {
      if ($script:ReturnTimeBrisbane) {
        $TimeZoneId = ($AllTimeZones | Where-Object {$_.DisplayName -eq $($CityCombo.SelectedItem)}).Id 
        $ReturnTimechoice   = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($script:ReturnTimeBrisbane,$TimeZoneId)
        $EndTimeyLblCombo.text = ($ReturnTimechoice.DayofWeek -as [string]) + ' ' + $ReturnTimechoice.toShortTimeString()
      }
    }
  )

  $CityCombo.Add_Enter(
    {
      if ($script:ReturnTimeBrisbane) {
        $TimeZoneId = ($AllTimeZones | Where-Object {$_.DisplayName -eq $($CityCombo.SelectedItem)}).Id 
        $ReturnTimechoice   = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($script:ReturnTimeBrisbane,$TimeZoneId)
        $EndTimeyLblCombo.text = ($ReturnTimechoice.DayofWeek -as [string]) + ' ' + $ReturnTimechoice.toShortTimeString()
      }
    }
  )
  $LabForm.Add_Shown({
    $HowLongtbox.Text        = ''
    $CurrentTimelbl.Text     = ''
    $CalcEndBtn.Enabled      = $false
    $EndTimetLbl.Text        = ''
    $EndTimetLbl.Enabled     = $false  
    $EndTimetLblSyd.Text     = ''
    $EndTimetLblSyd.Enabled  = $false
    $EndTimetLblAdel.Text    = ''
    $EndTimetLblAdel.Enabled = $false
    $CitySydLbl.Enabled      = $false
    $CityAdelLbl.Enabled     = $false
    $CityCombo.Text          = '(UTC+08:00) Perth'
    $EndTimeyLblCombo.Text   = ''
    $EndTimeyLblCombo.Enabled= $false
    $CityCombo.Enabled       = $false
    $CountDownLbl.enabled    = $false
    $RemainingMinLbl.enabled = $false
    $CountDownLbl.Visible    = $false
    $RemainingMinLbl.Visible = $false
    $LabForm.Activate()
    $HowLongtbox.Select()
  }
  )
  
  [void]$LabForm.ShowDialog()
}