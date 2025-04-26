# Start Tor
$torPath = "tor.exe"
if (-not (Test-Path $torPath)) {
    Write-Host "Tor executable not found at $torPath. Please update the path."
    exit 1
}
Start-Process $torPath -NoNewWindow; Start-Sleep -Seconds 10

# Test Tor connection
$result = Test-NetConnection -ComputerName 127.0.0.1 -Port 9050
if ($result.TcpTestSucceeded) {
    Write-Host "Tor is running on 127.0.0.1:9050."
} else {
    Write-Host "Tor failed to start on 127.0.0.1:9050."
    exit 1
}