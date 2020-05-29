$files = Get-ChildItem -Path .\ -file | Where-Object {$_.name -like 'mod*'}
foreach ($file in $files) {
  $Issue = get-content -Path $file.FullName   | Select-String -Pattern '^## Lab Issues' 
  $StartOfIssue = $Issue.LineNumber
  $endOfFile =  (get-content $file).count
  $TailLines = $endOfFile -$StartOfIssue  +1
  Write-Host $file.Name
  Get-Content $file -Tail $TailLines
  Write-Host '-------------------------------------'
}