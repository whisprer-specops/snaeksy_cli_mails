# Find tor.exe in PATH
try {
    $torPath = (Get-Command tor.exe -ErrorAction Stop).Source
} catch {
    Write-Host "Tor executable not found in PATH. Ensure tor.exe is in your system PATH."
    exit 1
}
# Stop any existing Tor processes to avoid port conflicts
Get-Process -Name "tor" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Process $torPath -NoNewWindow; Start-Sleep -Seconds 10

# Set proxy for Tor (Socks5)
[System.Net.WebRequest]::DefaultWebProxy = New-Object System.Net.WebProxy("socks5://127.0.0.1:9050")

# Download file over Tor (use a real URL)
$downloadUrl = "https://ryomodular.com/files/RYO_3xVCA_User_Manual.pdf"
try {
    [uri]::Parse($downloadUrl) | Out-Null
    Invoke-WebRequest -Uri $downloadUrl -OutFile "downloaded_tool.pdf"
    Write-Host "File downloaded over Tor."
    exit 0
} catch {
    Write-Host "Failed to download file: $_"
    exit 1
}
# Stop Tor to free up the port
Get-Process -Name "tor" -ErrorAction SilentlyContinue | Stop-Process -Force