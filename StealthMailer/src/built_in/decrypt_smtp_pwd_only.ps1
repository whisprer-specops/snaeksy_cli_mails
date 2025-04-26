# n.b. this is auto in the scripts!!!
# Import the secure string
$securePassword = Import-Clixml "$HOME\smtp_pass.xml"

# Convert back to plain text
$credential = New-Object System.Management.Automation.PSCredential("placeholder", $securePassword)
$smtpPass = $credential.GetNetworkCredential().Password
Write-Host "Decrypted password: $smtpPass"