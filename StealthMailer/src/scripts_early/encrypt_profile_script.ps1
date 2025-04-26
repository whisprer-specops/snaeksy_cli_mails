$content = Get-Content $PROFILE | ConvertTo-SecureString -AsPlainText -Force
$content | Export-Clixml -Path "$HOME\profile.xml"
Remove-Item $PROFILE