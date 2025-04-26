[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$securePassword = Import-Clixml "$HOME\smtp_pass.xml"
$smtpPass = (New-Object System.Management.Automation.PSCredential("placeholder", $securePassword)).GetNetworkCredential().Password
$msg = New-Object Net.Mail.MailMessage($env:SENDER_EMAIL, "troymetro@hotmail.ca", "wofl says hi!", "from his cmd line and it's now encrypted and stealth!")
Start-Process "C:\tor_browser\tor.exe" -NoNewWindow; Start-Sleep -Seconds 10
[System.Net.WebRequest]::DefaultWebProxy = New-Object System.Net.WebProxy("socks5://127.0.0.1:9050")
$smtp = New-Object Net.Mail.SmtpClient($env:SMTP_SERVER, [int]$env:SMTP_PORT)
$smtp.EnableSsl = $true
$smtp.Credentials = New-Object Net.NetworkCredential($env:SMTP_USER, $smtpPass)
$smtp.Send($msg)