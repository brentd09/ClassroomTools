function Submit-ClassRoll {
  <#
  .SYNOPSIS
    Converts DDLS student list into web output
  .DESCRIPTION
    Extract the list of students from the Teams trainer portal as a CSV file. Once this has been done
    you can then run this script which will ask you for attendance for each student and produce a report
    that you can paste into an email sent to Training.
    This script also has the ability to print an intoduction list that allows you to write down information
    about each of the students as they introduce themselves, it also gives you the ability to print
    a list of labs that you can tick off as the class members finish their labs.
  .EXAMPLE
    Submit-ClassRoll -CsvFileName students.csv -TrainerName 'Brent Denny' -PathToFiles 'c:\class'
    This will ask for confirmation for each students attendance on the course and then produce a report 
    which we need to email to training.
  .EXAMPLE
    Submit-ClassRoll -CsvFileName students.csv -StudentIntro -PathToFiles 'c:\class'
    This will produce a report that allows writing space beside each students name to record the info
    from their introduction. 
  .EXAMPLE
    Submit-ClassRoll -CsvFileName students.csv -LabList -NumberOfLabs 12 -PathToFiles 'c:\class'
    This will produce a report showing a list of lab number next to each student so that you can track 
    which labs they have finished in the course.   
  .PARAMETER CsvFileName
    This points to the file path of the CSV file that we export from the Teams trainer portal.
  .PARAMETER TrainerName
    This is the name of the trainer that gets added to the attendance report so that when we paste
    this into the body of the email, we can then cut the "Attendance BRENT DENNY" from the body and 
    this into the mail subject, as required.
  .PARAMETER StudentIntro
    This will create a report to record the introduction information from the students as they 
    talk about themselves.
  .PARAMETER LabList
    This will create a report that will list lab numbers per student that we can tick off as they
    finish each lab. 
  .PARAMETER NumberOfLabs
    This will give you the ability to specify how many lab numbers show on the web page, the default
    is 18, this was chosen as it would cover most courses, not many courses exceed 18 labs.  
  .PARAMETER PathToFiles
    This is the path to find the CSV file and where this script will create the reports to be opened
    by the systems default browser, this is the folder path not the file names, the default path
    points to your current Downloads directory.  
  .NOTES
    General notes
      Created By: Brent Denny
      Created On: 19 Jan 2021
      Last Change: 04 Feb 2021
  #>
  [CmdletBinding(DefaultParameterSetName='DefaultParams')]
  Param(
    [Parameter(Mandatory=$true)]
    [string]$CsvFileName,
    [string]$TrainerName = 'Brent Denny',
    [switch]$StudentIntro,
    [switch]$LabList,
    [int]$NumberOfLabs = 18,
    [string]$PathToFiles = ((New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path)
  )
  # Extracting failename from  $CsvFileName
  $CsvFileName = $CsvFileName | Split-Path -leaf
  # Setup file paths
  $CsvFullPath = $PathToFiles.TrimEnd('\') + '\' + $CsvFileName
  if (Test-Path -Path $CsvFullPath -PathType Leaf) {
    $AttendanceReportPath = $PathToFiles.TrimEnd('\') + '\ClassAttendance.html'
    $LabListReportPath = $PathToFiles.TrimEnd('\') + '\ClassLabList.html'
    $IntroReportPath = $PathToFiles.TrimEnd('\') + '\ClassIntro.html'
    $UpCaseTrainer = $TrainerName.ToUpper()
    # Locate the default browser on the computer
    $DefaultSettingPath = 'HKCU:\SOFTWARE\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice'
    $DefaultBrowserName = (Get-Item $DefaultSettingPath | Get-ItemProperty).ProgId
    $DefaultBrowserOpenCommand = (Get-Item "HKLM:SOFTWARE\Classes\$DefaultBrowserName\shell\open\command" | Get-ItemProperty).'(default)'
    $DefaultBrowserPath = [regex]::Match($DefaultBrowserOpenCommand,'\".+?\"')
    $BrowserPath = $DefaultBrowserPath.Value
    # Getting student details into a PowerShell object
    $RawStudentListCsv = Get-Content $CsvFullPath
    # Remove any non-student entries and removing spaces from CSV property names
    $RemoveSpacesFromCsvTitles = (($RawStudentListCSV | Select-Object -First 1) -replace '(\s)|(\(.*?\)|\-)','' ) -split ','
    $RawStudentListCsvNoTitle = $RawStudentListCsv |  Select-Object -Skip 1
    $StudentListCSVtoObj = $RawStudentListCsvNoTitle | ConvertFrom-Csv -Header $RemoveSpacesFromCsvTitles
    $StudentCount = $StudentListCSVtoObj.Count
    # Calculating how much space for padding to fit all students one one page 
    if ($StudentCount -gt 12) {$Padding = 50}
    else {$Padding = 200 - (12.5 * $StudentCount) }
    # Setting up the CSS for the web output
    $CSSsmall = @"
    <style>
      table, tr,td,th {border:black 1pt solid;border-collapse:collapse;}
      td,th {padding-left:4pt;padding-right:4px;}
      td:nth-child(1) {width: auto;}
      td:nth-child(2) {width: auto;} 
    </style>
"@
    $CSSwide = @"
    <style>
      table, tr,td,th {border:black 1pt solid;border-collapse:collapse;}
      td,th {padding-left:4pt;padding-right:4px;}
      td {padding-bottom: ${Padding}px;}
      td:nth-child(1) {width: 20%;}
      td:nth-child(2) {text-align-last: justify;font-size:20px} 
      table {width: 100%}
    </style>
"@
    if ($LabList -eq $false -and $StudentIntro -eq $false) {
      #Check for attendance
      $StudentsWithAttendance = foreach ($Student in $StudentListCSVtoObj) {
        $AttendanceResult = Read-Host -Prompt "Is $($Student.StudentName) in attendance (Y or N) Default-Y"
        if ($AttendanceResult -eq '' -or $AttendanceResult -like 'y*') {
          $Student | Select-Object -Property *,@{n='InClass';e={'Y'}}
        }
        else {
          $Student | Select-Object -Property *,@{n='InClass';e={'N'}}
        }
      }
      try {
        $StudentsWithAttendance | 
          Select-Object -Property StudentName,InClass | 
          ConvertTo-Html -Head $CSSsmall -precontent "<h2>Attendance $UpCaseTrainer</h2> <br>" | 
          Out-File $AttendanceReportPath
        Start-Process -FilePath $BrowserPath -ArgumentList $AttendanceReportPath
      }
      catch {Write-Warning "The Attendance html document could not be written to disk"; break}
    }
    if ($LabList -eq $true) {
      $StudentsLabNumbers = $StudentListCSVtoObj | 
        Select-Object *, @{n='LabNumbers';e={(1..$NumberOfLabs) -join ' '}}
      try {
        $StudentsLabNumbers | 
          Select-Object -Property StudentName,LabNumbers | 
          ConvertTo-Html -Head $CSSwide | 
          Out-File $LabListReportPath
        Start-Process -FilePath $BrowserPath -ArgumentList $LabListReportPath
      }
      catch {Write-Warning "The Lablist html document could not be written to disk"; break}

    }
    if ($StudentIntro -eq $true) {
      try {
        write-debug "intro"
        $StudentListCSVtoObj | 
          Select-Object -Property StudentName,Intro | 
          ConvertTo-Html -Head $CSSwide | 
          Out-File $IntroReportPath
        Start-Process -FilePath $BrowserPath -ArgumentList $IntroReportPath
      }
      catch {Write-Warning "The Intro html document could not be written to disk"; break}
    }
  }
  else {
    Write-Warning "The CSV file path $CsvFullPath is not found"
  }
}

function Invoke-BreakTimer {
  <#
  .Synopsis
    Calculates the end of break times in multiple cities and shows a countdown timer
  .DESCRIPTION
    This program calclates break times for Brisbane, Sydney, Adelaide
    and one other timezone of your choice. Determining when each city 
    should return from their break relevant to their timezone.
    You can enter the "Length or break" time and then click 
    "Calculate Return Time" or you can just click the "Calculate Return Time"
    and it will automatically fill 15 minutes into the Break time.
    It will then display the return times for the 4 cities and also 
    start a countdown timer.
  .EXAMPLE
    Invoke-BreakTimer
    This will start a gui tool to determine end of break times
  .NOTES
    General notes
      Created By: Brent Denny
      Created On: 28 May 2020
      Last Changed: 25 Nov 2020
  #>

  [cmdletbinding()]
  Param ()
  
  Add-Type -AssemblyName System.Windows.Forms
  $AllTimeZones = [System.TimeZoneInfo]::GetSystemTimeZones()
  $TimeZoneNames = $AllTimeZones.DisplayName
  [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 # This allows PS to use TLS1.2
  [System.Windows.Forms.Application]::EnableVisualStyles()
  
  $LabForm                     = New-Object system.Windows.Forms.Form
  $LabForm.ClientSize          = '450,470'
  $LabForm.text                = "Class Break Timer"
  $LabForm.TopMost             = $true
  $LabForm.Select()
                               
  $HourGlass                     = New-Object system.Windows.Forms.PictureBox
  $HourGlass.width               = 30
  $HourGlass.height              = 30
  $HourGlass.location            = New-Object System.Drawing.Point(235,140)
  $HourGlass.imageLocation       = "https://media4.giphy.com/media/l4FGIO2vCfJkakBtC/source.gif"
  $HourGlass.SizeMode            = [System.Windows.Forms.PictureBoxSizeMode]::zoom
 
  $TopGroupBox                  = New-Object System.Windows.Forms.GroupBox
  $TopGroupBox.Location         = '10,10' 
  $TopGroupBox.size             = '420,170'
  $TopGroupBox.text             = ""
  $TopGroupBox.FlatStyle = 2
  $TopGroupBox.Visible          = $true

  $BottomGroupBox                  = New-Object System.Windows.Forms.GroupBox
  $BottomGroupBox.Location         = '10,180' 
  $BottomGroupBox.size             = '420,215'
  $BottomGroupBox.text             = ""
  $BottomGroupBox.FlatStyle = 2
  $BottomGroupBox.Visible          = $true
                               
  $HowlongLbl                  = New-Object system.Windows.Forms.Label
  $HowlongLbl.text             = "Length of break (min.)"
  $HowlongLbl.AutoSize         = $true
  $HowlongLbl.width            = 25
  $HowlongLbl.height           = 10
  $HowlongLbl.location         = New-Object System.Drawing.Point(70,80)
  $HowlongLbl.Font             = 'Microsoft Sans Serif,10'
                  
  $HowLongtbox                 = New-Object system.Windows.Forms.TextBox
  $HowLongtbox.multiline       = $false
  $HowLongtbox.width           = 40
  $HowLongtbox.height          = 60
  $HowLongtbox.location        = New-Object System.Drawing.Point(22,76)
  $HowLongtbox.RightToLeft    = [System.Windows.Forms.RightToLeft]::Yes
  $HowLongtbox.Font            = 'Microsoft Sans Serif,10'
                               
  $BorderStyle                 = [System.Windows.Forms.BorderStyle]::FixedSingle
  $CountDownLbl                = New-Object system.Windows.Forms.Label
  $CountDownLbl.BorderStyle    = $BorderStyle
  $CountDownLbl.text           = $HowLongtbox.Text
  $CountDownLbl.AutoSize       = $false
  $CountDownLbl.width          = 140
  $CountDownLbl.height         = 80
  $CountDownLbl.location       = New-Object System.Drawing.Point(270,52)
  $CountDownLbl.Font           = 'Microsoft Sans Serif,50'
  $CountDownLbl.RightToLeft    = [System.Windows.Forms.RightToLeft]::Yes
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
  $CalcEndBtn.location         = New-Object System.Drawing.Point(22,110)
  $CalcEndBtn.Font             = 'Microsoft Sans Serif,10'
  
  $EndTimetLblQld                 = New-Object system.Windows.Forms.Label
  $EndTimetLblQld.text            = "Return to Course"
  $EndTimetLblQld.AutoSize        = $true
  $EndTimetLblQld.width           = 25
  $EndTimetLblQld.height          = 10
  $EndTimetLblQld.location        = New-Object System.Drawing.Point(275,198)
  $EndTimetLblQld.Font            = 'Microsoft Sans Serif,10'
  
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
      $CalcEndBtn,
      $HowlongLbl,
      $EndTimetLblQld,
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
      $ResetBtn,
      $HourGlass,
      $TopGroupBox,
      $BottomGroupBox
    )
  )


  $CalcEndBtn.Add_Click(
    { 
      $Script:Now = Get-Date
      $Script:CurrentTime = $Now.ToShortTimeString() 
      $CountDownLbl.enabled    = $true
      $RemainingMinLbl.enabled = $true
      $CountDownLbl.Visible    = $true
      $RemainingMinLbl.Visible = $true
      $HourGlass.Visible       = $true
      if ($HowLongtbox.Text -notmatch '^\d+$') {$HowLongtbox.Text = 15}
      $TimeSpan = New-TimeSpan -Minutes ($HowLongtbox.Text -as [int])
      $Script:Futuretime = (Get-Date).AddMinutes($TimeSpan.TotalMinutes -as [int])
      $TimeSpan = $FutureTime - $Now
      $RemainingMinutes = $TimeSpan.TotalMinutes -as [int]
      $CountDownLbl.Text = $RemainingMinutes
      $script:ReturnTime = $Script:Now + $TimeSpan
      $ReturnTimeBrisbane = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($script:ReturnTime,'E. Australia Standard Time')
      $ReturnTimeSydney   = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($script:ReturnTime,'AUS Eastern Standard Time')
      $ReturnTimeAdeliade = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($script:ReturnTime,'Cen. Australia Standard Time')
      $EndTimetLblQld.text   = ($ReturnTimeBrisbane.DayofWeek -as [string]) + ' ' + $ReturnTimeBrisbane.toShortTimeString()
      if ($script:ReturnTime) {
        $TimeZoneId = ($AllTimeZones | Where-Object {$_.DisplayName -eq $($CityCombo.SelectedItem)}).Id 
        $ReturnTimechoice   = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($script:ReturnTime,$TimeZoneId)
        $EndTimeyLblCombo.text = ($ReturnTimechoice.DayofWeek -as [string]) + ' ' + $ReturnTimechoice.toShortTimeString()
      }
      $EndTimetLblSyd.Text  = ($ReturnTimeSydney.DayofWeek -as [string]) + ' ' + $ReturnTimeSydney.toShortTimeString()
      $EndTimetLblAdel.Text = ($ReturnTimeAdeliade.DayofWeek -as [string]) + ' ' + $ReturnTimeAdeliade.toShortTimeString()
      $Timer=New-Object System.Windows.Forms.Timer
      $Timer.Interval=30000
      $Timer.add_Tick({$CountDownLbl.Text = (($FutureTime-(Get-Date)).TotalMinutes -as [int]) -as [string] })
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
      $CalcEndBtn.Enabled      = $true
      $EndTimetLblQld.Text        = ''
      $EndTimetLblQld.Enabled     = $false  
      $EndTimetLblSyd.Text     = ''
      $EndTimetLblSyd.Enabled  = $false
      $EndTimetLblAdel.Text    = ''
      $EndTimetLblAdel.Enabled = $false
      $CitySydLbl.Enabled      = $false
      $CityAdelLbl.Enabled     = $false
      $EndTimeyLblCombo.Text   = ''
      $EndTimeyLblCombo.Enabled= $false
      $CityCombo.Enabled       = $true
      $CountDownLbl.enabled    = $false
      $RemainingMinLbl.enabled = $false
      $CountDownLbl.Visible    = $false
      $RemainingMinLbl.Visible = $false
      $HourGlass.Visible       = $false
      $HowLongtbox.Select()
    }
  )

  $CityCombo.Add_SelectedValueChanged(
    {
      if ($script:ReturnTime) {
        $TimeZoneId = ($AllTimeZones | Where-Object {$_.DisplayName -eq $($CityCombo.SelectedItem)}).Id 
        $ReturnTimechoice   = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($script:ReturnTime,$TimeZoneId)
        $EndTimeyLblCombo.text = ($ReturnTimechoice.DayofWeek -as [string]) + ' ' + $ReturnTimechoice.toShortTimeString()
      }
    }
  )

  $CityCombo.Add_Enter(
    {
      if ($script:ReturnTime) {
        $TimeZoneId = ($AllTimeZones | Where-Object {$_.DisplayName -eq $($CityCombo.SelectedItem)}).Id 
        $ReturnTimechoice   = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($script:ReturnTime,$TimeZoneId)
        $EndTimeyLblCombo.text = ($ReturnTimechoice.DayofWeek -as [string]) + ' ' + $ReturnTimechoice.toShortTimeString()
      }
    }
  )
  $LabForm.Add_Shown({
    $HowLongtbox.Text        = ''
    $CalcEndBtn.Enabled      = $true
    $EndTimetLblQld.Text        = ''
    $EndTimetLblQld.Enabled     = $false  
    $EndTimetLblSyd.Text     = ''
    $EndTimetLblSyd.Enabled  = $false
    $EndTimetLblAdel.Text    = ''
    $EndTimetLblAdel.Enabled = $false
    $CitySydLbl.Enabled      = $false
    $CityAdelLbl.Enabled     = $false
    $CityCombo.Text          = '(UTC+08:00) Perth'
    $EndTimeyLblCombo.Text   = ''
    $EndTimeyLblCombo.Enabled= $false
    $CityCombo.Enabled       = $true
    $CountDownLbl.enabled    = $false
    $RemainingMinLbl.enabled = $false
    $CountDownLbl.Visible    = $false
    $RemainingMinLbl.Visible = $false
    $HourGlass.Visible       = $false
    $LabForm.Activate()
    $HowLongtbox.Select()
  }
  )
  
  [void]$LabForm.ShowDialog()
}