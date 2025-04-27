$smtpPassword = "wpsdjdrtfhdcyvph"
try {
    ConvertTo-SecureString -String $smtpPassword -AsPlainText -Force | Export-Clixml "$HOME\smtp_pass.xml"
    Write-Host "SMTP password encrypted to $HOME\smtp_pass.xml."
    exit 0
} catch {
    Write-Host "Failed to encrypt SMTP password: $_"
    exit 1
}