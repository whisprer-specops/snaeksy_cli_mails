# Encrypt the SMTP password
$smtpPassword = "imbysnbsdecvsnvf"
try {
    ConvertTo-SecureString -String $smtpPassword -AsPlainText -Force | Export-Clixml "$HOME\smtp_pass.xml"
    Write-Host "SMTP password encrypted to $HOME\smtp_pass.xml."
} catch {
    Write-Host "Failed to encrypt SMTP password: $_"
    exit 1
}