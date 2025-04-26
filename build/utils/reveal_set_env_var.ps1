$secureScript = Import-Clixml .\4_set_env_var_enc.xml
$scriptContent = (New-Object System.Management.Automation.PSCredential("placeholder", $secureScript)).GetNetworkCredential().Password
Invoke-Expression $scriptContent