# Run as Administrator: Randomize MAC address of the Wi-Fi adapter
$adapter = Get-NetAdapter -Name "Wi-Fi"
$newMac = (1..6 | ForEach-Object { "{0:X2}" -f (Get-Random -Minimum 0 -Maximum 255) }) -join ":"
Set-NetAdapter -Name $adapter.Name -MacAddress $newMac
Restart-NetAdapter -Name $adapter.Name