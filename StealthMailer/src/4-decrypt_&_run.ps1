# Specify the base name of the script to decrypt (e.g., "longmail_dynamic" for longmail_dynamic_enc.xml)
$scriptBaseName = "mail_ic"
$encryptedFile = "$scriptBaseName`_enc.xml"
$secureScript = Import-Clixml $encryptedFile
$scriptContent = (New-Object System.Management.Automation.PSCredential("placeholder", $secureScript)).GetNetworkCredential().Password
Invoke-Expression $scriptContent