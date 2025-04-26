How to Encrypt/Decrypt and Write script to send email from command line!

# Correct Encryption/Decryption for SMTP Password
Using `ConvertTo-SecureString` and `ConvertFrom-SecureString` properly to encrypt and decrypt the `SMTP_PASSWORD` (from env vars). PowerShell’s secure strings are tied to the user account and machine, so only you can decrypt them.

## Encrypt the Password (One-Time Setup):
First, let’s re-encrypt `SMTP_PASSWORD` correctly.

Run this in PowerShell:
powershell
`# Pull the password from env var`
`$password = $env:SMTP_PASSWORD`

`# Convert to secure string and export to XML`
`$securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force`
`$securePassword | Export-Clixml -Path "$HOME\smtp_pass.xml"`

This creates `smtp_pass.xml` in your user directory (`C:\Users\user`), encrypted with your user credentials.


## Decrypt the Password (For Use in Script):
To decrypt, use `Import-Clixml` and convert the secure string back to plain text using a credential object.

Run this test to verify:
powershell
`# Import the secure string`
`$securePassword = Import-Clixml "$HOME\smtp_pass.xml"`

`# Convert back to plain text`
`$credential = New-Object System.Management.Automation.PSCredential("placeholder", $securePassword)`
`$smtpPass = $credential.GetNetworkCredential().Password`
`Write-Host "Decrypted password: $smtpPass"`


If it prints `Decrypted password: [Gmail App Pass]`, you’re golden. The placeholder username is just a dummy for the PSCredential object—we only need the password.
Update the SMTP Script:

### Now, integrate this into the SMTP script, pulling other values from env vars (SENDER_EMAIL, TO_EMAIL, etc.):

powershell
`# Force TLS 1.2 for modern SMTP servers`
`[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12`

`# Pull values from environment variables`
`$from = $env:SENDER_EMAIL`
`$to = $env:TO_EMAIL`
`$subject = "PowerShell Freed!"`
`$body = "No more .\! Stealth mode activated, Fren!"`

`# Decrypt SMTP password`
`$securePassword = Import-Clixml "$HOME\smtp_pass.xml"`
`$credential = New-Object System.Management.Automation.PSCredential("placeholder", $securePassword)`
`$smtpPass = $credential.GetNetworkCredential().Password`

`# Create email message`
`$msg = New-Object Net.Mail.MailMessage($from, $to, $subject, $body)`

`# SMTP server settings`
`$smtpServer = $env:SMTP_SERVER`
`$smtpPort = [int]$env:SMTP_PORT # 587 or 465 for SSL`
`$smtp = New-Object Net.Mail.SmtpClient($smtpServer, $smtpPort)`
`$smtp.EnableSsl = $true`
`$smtp.Credentials = New-Object Net.NetworkCredential($env:SMTP_USER, $smtpPass)`

`# Send email with error handling`
`try {`
`    $smtp.Send($msg)`
`    Write-Host "Email sent, Fren! You're a stealth legend!"`
`} catch {`
`    Write-Host "Oops, something broke: $_"`
`}`


## To Run:

Simply:
Bash
`longmail_dynamic.ps1`


## Or Shorter Script

`[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12`
`$securePassword = Import-Clixml "$HOME\smtp_pass.xml"`
`$smtpPass = (New-Object System.Management.Automation.PSCredential("placeholder", $securePassword)).GetNetworkCredential().Password`
`$msg = New-Object Net.Mail.MailMessage($env:SENDER_EMAIL, $env:TO_EMAIL, "PowerShell Freed!", "No more .\!")`
`$smtp = New-Object Net.Mail.SmtpClient($env:SMTP_SERVER, [int]$env:SMTP_PORT)`
`$smtp.EnableSsl = $true`
`$smtp.Credentials = New-Object Net.NetworkCredential($env:SMTP_USER, $smtpPass)`
`$smtp.Send($msg)`

still sent by same command, i.e.
Bash
`shortmail_dynamic.ps1`


## Troubleshooting:

`Cannot Import Clixml`:
If `Import-Clixml` fails, ensure `smtp_pass.xml` exists (Test-Path `$HOME\smtp_pass.xml`) and was created by the same user account.
If you’re on a different machine/user, it won’t decrypt (secure strings are user- and machine-specific). Re-run the encryption step on this machine.
`SMTP Error`: If `smtp.gr` fails again, it’s likely not a valid SMTP server.
From your last attempt, `smtp.gr` threw a connection error. Try `smtp.gmail.com` (since we're using a Gmail App Password):

powershell
`[Environment]::SetEnvironmentVariable("SMTP_SERVER", "smtp.gmail.com", "User")`

If it’s a custom server, confirm the domain (e.g., `smtp.greenhost.gr` for a Greek provider) and credentials with your provider.
Permission Issue: If you get access errors with `smtp_pass.xml`, set perms:

powershell
`icacls "$HOME\smtp_pass.xml" /grant "$env:USERNAME:F"`



## Stealth Mode: Extra Covert Layers
You’re already encrypting SMTP_PASSWORD—let’s add more stealth:

### Obfuscate the Script:
Encode the script itself:
powershell
`$scriptContent = Get-Content .\sendmail.ps1 | Out-String`
`$secureScript = ConvertTo-SecureString -String $scriptContent -AsPlainText -Force`
`$secureScript | Export-Clixml .\sendmail_enc.xml`
`Remove-Item .\sendmail.ps1`

### Run it later:
powershell
`$scriptContent = Import-Clixml .\sendmail_enc.xml | ConvertFrom-SecureString`
`Invoke-Expression $scriptContent`

### Hide PowerShell History:
powershell
`Remove-Item "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt"`

### Tor for SMTP:
Route through Tor:
powershell
`Start-Process "tor.exe"`
`$smtp = New-Object Net.Mail.SmtpClient($smtpServer, $smtpPort, @{ Proxy = "127.0.0.1:9050"; ProxyType = "Socks5" })`


## The following is the Full Long Script with TOR Routing:

`# Force TLS 1.2 for modern SMTP servers`
`[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12`

`# Pull values from environment variables`
`$from = $env:SENDER_EMAIL      # tomtho`
`$to = $env:TO_EMAIL            # rvosynth`
`$subject = "PowerShell Freed!"`
`$body = "No more .\! Stealth mode activated, Fren!"`

`# Decrypt SMTP password`
`$securePassword = Import-Clixml "$HOME\smtp_pass.xml"`
`$credential = New-Object System.Management.Automation.PSCredential("placeholder", $securePassword)`
`$smtpPass = $credential.GetNetworkCredential().Password`

`# Create email message`
`$msg = New-Object Net.Mail.MailMessage($from, $to, $subject, $body)`

`# SMTP server settings with Tor proxy`
`$smtpServer = $env:SMTP_SERVER  # smtp.gr`
`$smtpPort = [int]$env:SMTP_PORT # 587`
`Start-Process "tor.exe" -NoNewWindow; Start-Sleep -Seconds 10`
`[System.Net.WebRequest]::DefaultWebProxy = New-Object System.Net.WebProxy("socks5://127.0.0.1:9050")`
`$smtp = New-Object Net.Mail.SmtpClient($smtpServer, $smtpPort)`
`$smtp.EnableSsl = $true`
`$smtp.Credentials = New-Object Net.NetworkCredential($env:SMTP_USER, $smtpPass`

`# Send email with error handling`
`try {`
`    $smtp.Send($msg)`
`    Write-Host "Email sent, Fren! You're a stealth legend!"`
`} catch {`
`    Write-Host "Oops, something broke: $_"`
`}`


## And the Short Script with TOR:

`[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12`
`$securePassword = Import-Clixml "$HOME\smtp_pass.xml"`
`$smtpPass = (New-Object System.Management.Automation.PSCredential("placeholder", $securePassword)).GetNetworkCredential().Password`
`$msg = New-Object Net.Mail.MailMessage($env:SENDER_EMAIL, "troymetro@hotmail.ca", "wofl says hi!", "from his cms line!")`
`Start-Process "tor.exe" -NoNewWindow; Start-Sleep -Seconds 10`
`[System.Net.WebRequest]::DefaultWebProxy = New-Object System.Net.WebProxy("socks5://127.0.0.1:9050")`
`$smtp = New-Object Net.Mail.SmtpClient($env:SMTP_SERVER, [int]$env:SMTP_PORT)`
`$smtp.EnableSsl = $true`
`$smtp.Credentials = New-Object Net.NetworkCredential($env:SMTP_USER, $smtpPass)`
`$smtp.Send($msg)`


### The Tor Browser installer placed tor.exe inside its installation directory. Look in:

`C:\tor_browser\Browser\TorBrowser\Tor\tor.exe`

To verify it works, run this in PowerShell to check if Tor’s proxy is live:
powershell
`Test-NetConnection -ComputerName 127.0.0.1 -Port 9050`

If `TcpTestSucceeded` is True, Tor is running on port `9050`, ready for your SMTP script.


## 

