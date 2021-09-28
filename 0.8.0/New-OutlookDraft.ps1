$Message = Get-Service | Where-Object name -like a* | Select-Object Status, StartType,Name | ConvertTo-Html -Fragment | Out-String 

$olFolderDrafts = 16
$ol = New-Object -comObject Outlook.Application 
Start-Process outlook.exe
$ns = $ol.GetNameSpace("MAPI")

# call the save method yo dave the email in the drafts folder
$mail = $ol.CreateItem(0)
$null = $Mail.Recipients.Add("brent.denny@ddls.com.au")  
$Mail.Subject = "PS1 Script TestMail"  
$Mail.HTMLBody = @"
<h2>SERVICES</h2>

$Message

"@
$mail.h
$Mail.save()

