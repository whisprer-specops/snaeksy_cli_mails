# Get all .ps1 files matching the pattern *mail_*.ps1
$scripts = Get-ChildItem -Filter "*mail*.ps1"

# Loop through each script file
foreach ($script in $scripts) {
    # Read the script content
    $scriptContent = Get-Content $script.FullName | Out-String
    # Encrypt and export to a corresponding .xml file (e.g., longmail_dynamic.ps1 -> longmail_dynamic_enc.xml)
    $encryptedFileName = $script.BaseName + "_enc.xml"
    ConvertTo-SecureString -String $scriptContent -AsPlainText -Force | Export-Clixml $encryptedFileName
    # Delete the original script
    Remove-Item $script.FullName
}