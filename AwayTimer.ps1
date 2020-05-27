 <#
.Synopsis
   Calculates the end of break times in multiple cities
.DESCRIPTION
   This program calclates break times for Brisbane, Sydney, Adelaide
   and one other timezone of your choice. Determining wheneach city 
   should return from their break relevant to their timezone
.EXAMPLE
   AwayTimer
   This will start a gui tool to determine end of break times
.NOTES
   General notes
     Created By: Brent Denny
     Created On: 28 May 2020
#>

[cmdletbinding()]
Param ()
$AllTimeZones = [System.TimeZoneInfo]::GetSystemTimeZones()
$TimeZoneIds = $AllTimeZones.id
$TimeZoneNames = $AllTimeZones.DisplayName

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$LabForm                 = New-Object system.Windows.Forms.Form
$LabForm.ClientSize      = '450,470'
$LabForm.text            = "Return Timer"
$LabForm.TopMost         = $true
                         
$CurrentTimebtn          = New-Object system.Windows.Forms.Button
$CurrentTimebtn.text     = "Get Current Time"
$CurrentTimebtn.width    = 150
$CurrentTimebtn.height   = 30
$CurrentTimebtn.location = New-Object System.Drawing.Point(22,29)
$CurrentTimebtn.Font     = 'Microsoft Sans Serif,10'
                         
$CurrentTimelbl          = New-Object system.Windows.Forms.Label
$CurrentTimelbl.text     = ""
$CurrentTimelbl.AutoSize = $false
$CurrentTimelbl.width    = 300
$CurrentTimelbl.height   = 20
$CurrentTimelbl.location = New-Object System.Drawing.Point(185,35)
$CurrentTimelbl.Font     = 'Microsoft Sans Serif,10'
                         
$HowlongLbl              = New-Object system.Windows.Forms.Label
$HowlongLbl.text         = "Away for how many minutes?"
$HowlongLbl.AutoSize     = $true
$HowlongLbl.width        = 25
$HowlongLbl.height       = 10
$HowlongLbl.location     = New-Object System.Drawing.Point(82,87)
$HowlongLbl.Font         = 'Microsoft Sans Serif,10'

$HowLongtbox             = New-Object system.Windows.Forms.TextBox
$HowLongtbox.multiline   = $false
$HowLongtbox.width       = 40
$HowLongtbox.height      = 60
$HowLongtbox.location    = New-Object System.Drawing.Point(35,85)
$HowLongtbox.Font        = 'Microsoft Sans Serif,10'
                         
$CalcEndBtn              = New-Object system.Windows.Forms.Button
$CalcEndBtn.text         = "Calculate Return Time"
$CalcEndBtn.width        = 150
$CalcEndBtn.height       = 30
$CalcEndBtn.location     = New-Object System.Drawing.Point(22,140)
$CalcEndBtn.Font         = 'Microsoft Sans Serif,10'

$EndTimetLbl              = New-Object system.Windows.Forms.Label
$EndTimetLbl.text         = "Return to Course"
$EndTimetLbl.AutoSize     = $true
$EndTimetLbl.width        = 25
$EndTimetLbl.height       = 10
$EndTimetLbl.location     = New-Object System.Drawing.Point(275,198)
$EndTimetLbl.Font         = 'Microsoft Sans Serif,10'

$CityLocalLbl              = New-Object system.Windows.Forms.Label
$CityLocalLbl.text         = "Brisbane"
$CityLocalLbl.AutoSize     = $true
$CityLocalLbl.width        = 25
$CityLocalLbl.height       = 10
$CityLocalLbl.location     = New-Object System.Drawing.Point(22,196)
$CityLocalLbl.Font         = 'Microsoft Sans Serif,10'

$CitySydLbl              = New-Object system.Windows.Forms.Label
$CitySydLbl.text         = "Sydney"
$CitySydLbl.AutoSize     = $true
$CitySydLbl.width        = 25
$CitySydLbl.height       = 10
$CitySydLbl.location     = New-Object System.Drawing.Point(22,246)
$CitySydLbl.Font         = 'Microsoft Sans Serif,10'

$CityAdelLbl              = New-Object system.Windows.Forms.Label
$CityAdelLbl.text         = "Adelaide"
$CityAdelLbl.AutoSize     = $true
$CityAdelLbl.width        = 25
$CityAdelLbl.height       = 10
$CityAdelLbl.location     = New-Object System.Drawing.Point(22,296)
$CityAdelLbl.Font         = 'Microsoft Sans Serif,10'

$CityCombo                   = New-Object system.Windows.Forms.ComboBox
$CityCombo.text              = '(UTC+08:00) Perth'
$CityCombo.width             = 240
$CityCombo.height            = 20
$CityCombo.location          = New-Object System.Drawing.Point(22,346)
$CityCombo.Font              = 'Microsoft Sans Serif,10'
$CityCombo.SelectedItem      = '(UTC+08:00) Perth'
$CityCombo.DropDownStyle     = 'DropDownList'
$TimeZoneNames | ForEach-Object {[void] $CityCombo.Items.Add($_)}

$EndTimeyLblCombo              = New-Object system.Windows.Forms.Label
$EndTimeyLblCombo.text         = "Return to Course"
$EndTimeyLblCombo.AutoSize     = $true
$EndTimeyLblCombo.width        = 25
$EndTimeyLblCombo.height       = 10
$EndTimeyLblCombo.location     = New-Object System.Drawing.Point(275,348)
$EndTimeyLblCombo.Font         = 'Microsoft Sans Serif,10'                       

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

                         
$OKBtn              = New-Object system.Windows.Forms.Button
$OKBtn.text         = "Close"
$OKBtn.width        = 80
$OKBtn.height       = 30
$OKBtn.location     = New-Object System.Drawing.Point(320,410)
$OKBtn.Font         = 'Microsoft Sans Serif,10'
                         
$LabForm.controls.AddRange(@($CurrentTimebtn,
                             $CurrentTimelbl,
                             $HowLongtbox,
                             $HowlongLbl,
                             $EndTimetLbl,
                             $EndTimetLblAdel,
                             $EndTimetLblSyd,
                             $EndTimeyLblCombo,
                             $CitySydLbl,
                             $CityAdelLbl,
                             $CityCombo,
                             $CalcEndBtn,
                             $CityLocalLbl,
                             $OKBtn))

$CurrentTimebtn.Add_Click({ 
  $Script:Now = Get-Date
  $CurrentTimeLbl.text     = $Now.ToLongTimeString()
  $CalcEndBtn.Enabled      = $true
  $EndTimetLbl.Enabled     = $true 
  $EndTimeyLblCombo.Enabled  = $true
  $EndTimetLblSyd.Enabled  = $true
  $EndTimetLblAdel.Enabled = $true
  $CitySydLbl.Enabled      = $true
  $CityAdelLbl.Enabled     = $true
  $CityCombo.Enabled       = $true
 })
$CalcEndBtn.Add_Click({ 
  if ($HowLongtbox.Text -notmatch '^\d+$') {
    $HowLongtbox.Text = 15
  }
  $TimeSpan = New-TimeSpan -Minutes ($HowLongtbox.Text -as [int])
  $script:ReturnTimeBrisbane = $Script:Now + $TimeSpan
  $ReturnTimeSydney   = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($script:ReturnTimeBrisbane,'AUS Eastern Standard Time')
  $ReturnTimeAdeliade = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($script:ReturnTimeBrisbane,'Cen. Australia Standard Time')
  $ReturnTimePerth    = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($script:ReturnTimeBrisbane,'W. Australia Standard Time')
  $EndTimetLbl.text     = ($ReturnTimeBrisbane.DayofWeek -as [string]) + ' ' + $ReturnTimeBrisbane.toShortTimeString()
  $EndTimeyLblCombo.Text  = ($ReturnTimePerth.DayofWeek -as [string]) + ' ' + $ReturnTimePerth.toShortTimeString()
  $EndTimetLblSyd.Text  = ($ReturnTimeSydney.DayofWeek -as [string]) + ' ' + $ReturnTimeSydney.toShortTimeString()
  $EndTimetLblAdel.Text = ($ReturnTimeAdeliade.DayofWeek -as [string]) + ' ' + $ReturnTimeAdeliade.toShortTimeString()
 })
 $OKBtn.Add_Click({
   [void]$LabForm.Dispose()
 })
 $CityCombo.Add_SelectedValueChanged({
   if ($script:ReturnTimeBrisbane) {
     $TimeZoneId = ($AllTimeZones | Where-Object {$_.DisplayName -eq $($CityCombo.SelectedItem)}).Id 
     $ReturnTimechoice   = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($script:ReturnTimeBrisbane,$TimeZoneId)
     $EndTimeyLblCombo.text = ($ReturnTimechoice.DayofWeek -as [string]) + ' ' + $ReturnTimechoice.toShortTimeString()
   }
 })
 $CityCombo.Add_Enter({
   if ($script:ReturnTimeBrisbane) {
     $TimeZoneId = ($AllTimeZones | Where-Object {$_.DisplayName -eq $($CityCombo.SelectedItem)}).Id 
     $ReturnTimechoice   = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($script:ReturnTimeBrisbane,$TimeZoneId)
     $EndTimeyLblCombo.text = ($ReturnTimechoice.DayofWeek -as [string]) + ' ' + $ReturnTimechoice.toShortTimeString()
   }
 })


if ($CurrentTimelbl.text -eq ''){
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
  $EndTimeyLblCombo.Text     = ''
  $EndTimeyLblCombo.Enabled  = $false
  $CityCombo.Enabled       = $false
}

[void]$LabForm.ShowDialog()