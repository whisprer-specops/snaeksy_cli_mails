$proxy = New-Object System.Net.WebProxy("http://[2604:a880:800:14:0:1:1326:9000]:3128")
$proxy.Credentials = New-Object System.Net.NetworkCredential("proxyuser", "GoodWitch10")
[System.Net.WebRequest]::DefaultWebProxy = $proxy

$pass = Import-Clixml "$HOME\smtp_pass.xml"
$cred = New-Object System.Management.Automation.PSCredential("got.girl.camera@gmail.com", $pass)
Send-MailMessage -From "got.girl.camera@gmail.com" -To "troymetro@hotmail.com" -Subject "Test" -Body "Test email" -SmtpServer "smtp.gmail.com" -Port 587 -UseSsl -Credential $cred
