# Start Tor (assumes Tor Browser is installed)
Start-Process "C:\Users\phine\Desktop\Tor Browser\Browser\TorBrowser\Tor\tor.exe" -NoNewWindow; Start-Sleep -Seconds 10

# Set proxy for Tor (Socks5)
[System.Net.WebRequest]::DefaultWebProxy = New-Object System.Net.WebProxy("socks5://127.0.0.1:9050")

# Download file over Tor
Invoke-WebRequest -Uri "https://releases.ubuntu.com/24.04/ubuntu-24.04-desktop-amd64.iso" -OutFile "ubuntu.iso"