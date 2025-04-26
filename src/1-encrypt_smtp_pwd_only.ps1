# Pull the password from env var
$password = $env:SMTP_PASSWORD

# Convert to secure string and export to XML
$securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
$securePassword | Export-Clixml -Path "$HOME\smtp_pass.xml"