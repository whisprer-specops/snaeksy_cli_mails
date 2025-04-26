# Find tor.exe in PATH
try {
    $torPath = (Get-Command tor.exe -ErrorAction Stop).Source
} catch {
    Write-Host "Tor executable not found in PATH. Ensure tor.exe is in your system PATH."
    exit 1
}
Get-Process -Name "tor" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Process $torPath -NoNewWindow; Start-Sleep -Seconds 10

# Download file over Tor using curl
$downloadUrl = "https://ryomodular.com/files/RYO_3xVCA_User_Manual.pdf"
try {
    curl --socks5-hostname 127.0.0.1:9050 -o downloaded_usb_tool.pdf $downloadUrl
    Write-Host "File downloaded over Tor to obfuscate USB usage."
    exit 0
} catch {
    Write-Host "Failed to download file: $_"
    exit 1
}
# Stop Tor to free up the port
Get-Process -Name "tor" -ErrorAction SilentlyContinue | Stop-Process -Force