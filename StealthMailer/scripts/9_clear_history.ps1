$historyPath = "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt"
if (Test-Path $historyPath) {
    Remove-Item $historyPath -Force
    Write-Host "PowerShell history cleared."
    exit 0
} else {
    Write-Host "PowerShell history file not found - nothing to clear."
    exit 0
}

# Troubleshooting:
#
# Adapter Name: Find your adapter name with:
# powershell
# `Get-NetAdapter`
# `Update $adapter = Get-NetAdapter -Name "Wi-Fi"` to 
# match # (e.g., Ethernet, Wireless).
#
# Permission Error: If you get a permissions error, ensure # you’re running PowerShell as Administrator.
#
# MAC Format: Some adapters require a dash-separated MAC
# (`XX-XX-XX-XX-XX-XX`). If it fails, change the join to:
# powershell
# `$newMac = (1..6 | ForEach-Object { "{0:X2}" -f (Get-
# Random -Minimum 0 -Maximum 255) }) -join "-"`
#