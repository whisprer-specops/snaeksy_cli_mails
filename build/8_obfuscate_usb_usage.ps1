# Start Tor (update the path if needed)
$torPath = "C:\Users\phine\Desktop\Tor Browser\Browser\TorBrowser\Tor\tor.exe"
if (-not (Test-Path $torPath)) {
    Write-Host "Tor executable not found at $torPath. Please update the path."
    exit 1
}
# Stop any existing Tor processes to avoid port conflicts
Get-Process -Name "tor" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Process $torPath -NoNewWindow; Start-Sleep -Seconds 10

# Download file over Tor using curl (replace with a real URL)
$downloadUrl = "https://ryomodular.com/files/RYO_3xVCA_User_Manual.pdf"
try {
    curl --socks5-hostname 127.0.0.1:9050 -o downloaded_usb_tool.pdf $downloadUrl
    Write-Host "File downloaded over Tor to obfuscate USB usage."
} catch {
    Write-Host "Failed to download file: $_"
    exit 1
}
# Stop Tor to free up the port
Get-Process -Name "tor" -ErrorAction SilentlyContinue | Stop-Process -Force