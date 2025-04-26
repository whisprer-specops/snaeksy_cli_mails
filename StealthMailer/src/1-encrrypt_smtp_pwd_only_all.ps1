# Pull the password from env var
$password = $env:SMTP_PASSWORD

# Get all .ps1 files matching the pattern *mail_*.ps1
$scripts = Get-ChildItem -Filter "*mail*.ps1"

# Convert to secure string and export to XML

# Loop through each script file
foreach ($script in $scripts) {

# Read the script content
$scriptContent = Get-Content $script.FullName | Out-String

# Encrypt and export to a corresponding .xml file (e.g., longmail_dynamic.ps1 -> longmail_dynamic_smtp_pass_enc.xml)

#$securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
$securePassword | Export-Clixml -Path "$HOME\$script.BaseName + smtp_pass_enc.xml"
}