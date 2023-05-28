$url = "https://www.google.com"
$hostname = ([System.Uri]$url).Host
$isReachable = Test-Connection -ComputerName $hostname -Quiet
$isReachable