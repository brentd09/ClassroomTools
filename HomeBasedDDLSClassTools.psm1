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
  .EXAMPLE
     Submit-ClassRoll -CSVfilePath c:\exports\ClassList.csv
     This will consume the file c:\exports\ClassList.csv and as the attendance 
     status of each student from the list and from this will create the HTML tables
  .NOTES
     General notes
       Created By: Brent Denny
       Created On: 31 Aug 2020
       Changed on: 05 Oct 2020
  #>
  [CmdletBinding()]
  Param (
    [Parameter(Mandatory=$true)]
    [string]$CSVfilePath
  )
  if (Test-Path -Path $CSVfilePath -PathType Leaf) {
    $LeafPath = (Split-Path $CSVfilePath -Leaf ) -replace '\s+',''
    $LeafPathNoExt = $LeafPath -replace '\.csv$',''
    $FullPathToFile = (Resolve-Path $CSVfilePath).Path | Split-Path -Parent
    $ExportHTMLPath = $FullPathToFile.TrimEnd('\') +'\'+$LeafPathNoExt+'.html'
    
    $CSS = @'
    <style>
      table, tr,td,th {border:black 1pt solid;border-collapse:collapse;}
      td,th {padding-left:4pt;padding-right:4px;}
    </style>
'@
    
    $Attendees = @()
    $LateAttendees = @()
    Get-Content $CSVfilePath | ConvertFrom-Csv | Sort-Object  | Select-Object -Property "Student Name",'Attendance' | ForEach-Object {
      do {
        $Attendance = Read-Host -Prompt "Is `"$($_."student name")`" on the course (y - yes, n - no or l - late) Default=y"
      } until ($Attendance -in @('y','n','l',''))
      if ($Attendance -eq ''){$Attendance = 'y'}
      if ($Attendance -eq 'l'){$Attendance = 'LATE'}
      $_.Attendance = $Attendance.ToUpper()
      if ($Attendance -in @('y','n')){$Attendees += $_}
      else {$LateAttendees += $_}
    }
    [string]$FragAtttend = $Attendees | Sort-Object -Property "Student Name" | ConvertTo-Html -Fragment  -PreContent '<BR><BR>' 
    [string]$FragLate = $LateAttendees | Sort-Object -Property "Student Name"  | ConvertTo-Html -Fragment -PreContent '<BR><BR>' 
    try {ConvertTo-Html -Head $CSS -PreContent '<h2>attendance BRENT DENNY</h2><br>' -PostContent $FragAtttend,$FragLate | Out-File $ExportHTMLPath}
    Catch {Write-Warning "$ExportHTMLPath could not be written to disk";break}
    if (Test-Path -Path "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe") {
      Start-Process -FilePath "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" -ArgumentList $ExportHTMLPath
    }
    else {
      Write-Host "The HTML Attendance information is stored $ExportHTMLPath"
    }
  }
  else {Write-Warning "$CSVfilePath does not exist as a file"}
}