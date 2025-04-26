# Start Tor (update the path if needed)
$torPath = "tor.exe"
if (-not (Test-Path $torPath)) {
    Write-Host "Tor executable not found at $torPath. Please update the path."
    exit 1
}
Start-Process $torPath -NoNewWindow; Start-Sleep -Seconds 10

# Set proxy for Tor (Socks5)
[System.Net.WebRequest]::DefaultWebProxy = New-Object System.Net.WebProxy("socks5://127.0.0.1:9050")

# Download file over Tor (use a real URL)
$downloadUrl = "https://ryomodular.com/files/RYO_3xVCA_User_Manual.pdf"
try {
    [uri]::Parse($downloadUrl) | Out-Null  # Validate the URL
    Invoke-WebRequest -Uri $downloadUrl -OutFile "downloaded_tool.pdf"
    Write-Host "File downloaded over Tor."
} catch {
    Write-Host "Failed to download file: $_"
    exit 1
}