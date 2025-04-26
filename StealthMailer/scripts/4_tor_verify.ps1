# Find tor.exe in PATH
try {
    $torPath = (Get-Command tor.exe -ErrorAction Stop).Source
} catch {
    Write-Host "Tor executable not found in PATH. Ensure tor.exe is in your system PATH."
    exit 1
}
Get-Process -Name "tor" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Process $torPath -NoNewWindow; Start-Sleep -Seconds 10

# Test Tor connection
$result = Test-NetConnection -ComputerName 127.0.0.1 -Port 9050
if ($result.TcpTestSucceeded) {
    Write-Host "Tor is running on 127.0.0.1:9050."
    exit 0
} else {
    Write-Host "Tor failed to start on 127.0.0.1:9050."
    exit 1
}
# Stop Tor to free up the port
Get-Process -Name "tor" -ErrorAction SilentlyContinue | Stop-Process -Force