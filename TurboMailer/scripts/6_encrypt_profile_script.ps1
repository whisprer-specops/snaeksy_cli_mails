Set-Content -Path .\longmail_static_tor.ps1 -Value @'
$pass = Import-Clixml "$HOME\smtp_pass.xml"
$cred = New-Object System.Management.Automation.PSCredential("got.girl.camera@gmail.com", $pass)
Send-MailMessage -From "got.girl.camera@gmail.com" -To "troymetro@hotmail.com" -Subject "Test" -Body "Test email" -SmtpServer "smtp.gmail.com" -Port 587 -UseSsl -Credential $cred
'@
$scriptContent = Get-Content .\longmail_dynamic.ps1 | Out-String
ConvertTo-SecureString -String $scriptContent -AsPlainText -Force | Export-Clixml .\mail_ic_enc.xml