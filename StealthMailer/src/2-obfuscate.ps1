$scriptContent = Get-Content .\longmail_dynamic.ps1 | Out-String
ConvertTo-SecureString -String $scriptContent -AsPlainText -Force | Export-Clixml .\longmail_dynamic_enc.xml
Remove-Item .\longmail_dynamic.ps1