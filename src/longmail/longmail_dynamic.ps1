$msg.From = $env:SENDER_EMAIL

# Force TLS 1.2 for modern SMTP servers
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Pull values from environment variables
$from = $env:SENDER_EMAIL      # tomtho
$to = $env:TO_EMAIL            # rvosynth
$subject = "PowerShell Freed!"
$body = "No more .\! Stealth mode activated, Fren!"

# Decrypt SMTP password
$securePassword = Import-Clixml "$HOME\smtp_pass.xml"
$credential = New-Object System.Management.Automation.PSCredential("placeholder", $securePassword)
$smtpPass = $credential.GetNetworkCredential().Password

# Create email message
$msg = New-Object Net.Mail.MailMessage($from, $to, $subject, $body)

# SMTP server settings with Tor proxy
$smtpServer = $env:SMTP_SERVER  # smtp.gr
$smtpPort = [int]$env:SMTP_PORT # 587
Start-Process "C:\Users\phine\Desktop\Tor Browser\Browser\TorBrowser\Tor\tor.exe" -NoNewWindow; Start-Sleep -Seconds 10
[System.Net.WebRequest]::DefaultWebProxy = New-Object System.Net.WebProxy("socks5://127.0.0.1:9050")
$smtp = New-Object Net.Mail.SmtpClient($smtpServer, $smtpPort)
$smtp.EnableSsl = $true
$smtp.Credentials = New-Object Net.NetworkCredential($env:SMTP_USER, $smtpPass)

# Send email with error handling
try {
    $smtp.Send($msg)
    Write-Host "Email sent, Fren! You're a stealth legend!"
} catch {
    Write-Host "Oops, something broke: $_"
}
