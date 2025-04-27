# Create a Python script to handle the request
Set-Content -Path .\temp_download.py -Value @"
import requests
import time

# Define the hidden service proxy URL with socks5h
hidden_service_url = "pchy3lwxuiddfedistxvvlh4rkc5y2pm774qfjsect52qzzd4hcredyd.onion:3128"
proxies = {
    "http": f"socks5h://proxyuser:GoodWitch10@127.0.0.1:9050",
    "https": f"socks5h://proxyuser:GoodWitch10@127.0.0.1:9050"
}

try:
    session = requests.Session()
    response = session.get(f"http://{hidden_service_url}", proxies=proxies, timeout=30)
    print("Successfully connected to hidden service proxy.")

    response = session.get("https://httpbin.org/get", proxies=proxies, timeout=30)
    with open("downloaded_file.txt", "wb") as f:
        f.write(response.content)
    print("File downloaded over Tor via hidden service.")
except Exception as e:
    print("Failed to download file:", e)
    exit(1)
"@

try {
    $torPath = (Get-Command tor.exe -ErrorAction Stop).Source
} catch {
    Write-Host "Tor executable not found in PATH. Ensure tor.exe is in your system PATH."
    exit 1
}
for ($attempt = 1; $attempt -le 3; $attempt++) {
    # Forcefully kill any existing Tor processes and wait
    taskkill /IM tor.exe /F 2>$null
    Start-Sleep -Seconds 2  # Give it a moment to fully terminate
    Start-Process $torPath -NoNewWindow; Start-Sleep -Seconds 10
    try {
        $pythonOutput = python temp_download.py 2>&1 | Out-String
        if ($LASTEXITCODE -eq 0) {
            Write-Host $pythonOutput
            Remove-Item temp_download.py
            exit 0
        } else {
            Write-Host "Attempt $attempt failed: python exited with code $LASTEXITCODE"
            Write-Host "Python output: $pythonOutput"
            if ($attempt -lt 3) {
                Write-Host "Retrying in 10 seconds..."
                Start-Sleep -Seconds 10
            }
        }
    } catch {
        Write-Host "Attempt $attempt failed: $_"
        if ($attempt -lt 3) {
            Write-Host "Retrying in 10 seconds..."
            Start-Sleep -Seconds 10
        }
    }
}
Remove-Item temp_download.py
Write-Host "Failed to download file after retries."
taskkill /IM tor.exe /F 2>$null
exit 1
