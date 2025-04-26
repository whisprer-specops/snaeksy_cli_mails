$scriptContent = Get-Content .\4_gi_set_env_var_enc.ps1 | Out-String
ConvertTo-SecureString -String $scriptContent -AsPlainText -Force | Export-Clixml .\set_env_vars_enc.xml
Remove-Item .\4_gi_set_env_var_enc.ps1