try {
    $torPath = (Get-Command tor.exe -ErrorAction Stop).Source
} catch {
    Write-Host "Tor executable not found in PATH. Ensure tor.exe is in your system PATH."
    exit 1
}
Get-Process -Name "tor" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Process $torPath -NoNewWindow; Start-Sleep -Seconds 10
$downloadUrl = "https://example.com/test.txt"
try {
    $proxy = New-Object System.Net.WebProxy("http://[2604:a880:800:14:0:1:1326:9000]:3128")
    $proxy.Credentials = New-Object System.Net.NetworkCredential("proxyuser", "GoodWitch10")
    [System.Net.WebRequest]::DefaultWebProxy = $proxy
    curl.exe --socks5-hostname 127.0.0.1:9050 -o downloaded_file.txt $downloadUrl
    if ($LASTEXITCODE -eq 0) {
        Write-Host "File downloaded over Tor."
        exit 0
    } else {
        Write-Host "Failed to download file: curl exited with code $LASTEXITCODE"
        exit 1
    }
} catch {
    Write-Host "Failed to download file: $_"
    exit 1
}
Get-Process -Name "tor" -ErrorAction SilentlyContinue | Stop-Process -Force
