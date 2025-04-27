# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "This script requires Administrator privileges. Please run PowerShell as Administrator."
    exit 1
}

# Get all physical network adapters (exclude virtual adapters)
$adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.Name -notlike "*VPN*" -and $_.PhysicalMediaType -like "*802.*" }
if ($null -eq $adapters) {
    Write-Host "No suitable physical network adapters found. Run 'Get-NetAdapter' to see available adapters."
    exit 1
}

# Try each adapter until one works
$success = $false
foreach ($adapter in $adapters) {
    Write-Host "Attempting to change MAC address for adapter $($adapter.Name)..."
    # Randomize MAC address
    $newMac = (1..6 | ForEach-Object { "{0:X2}" -f (Get-Random -Minimum 0 -Maximum 255) }) -join ":"
    try {
        Set-NetAdapter -Name $adapter.Name -MacAddress $newMac -ErrorAction Stop -Confirm:$false
        Restart-NetAdapter -Name $adapter.Name -ErrorAction Stop
        # Verify the MAC address change
        $updatedAdapter = Get-NetAdapter -Name $adapter.Name
        if ($updatedAdapter.MacAddress -replace "-", ":" -eq $newMac) {
            Write-Host "MAC address successfully changed to $newMac for adapter $($adapter.Name)."
            $success = $true
            break
        } else {
            Write-Host "MAC address change failed for adapter $($adapter.Name). Current MAC is $($updatedAdapter.MacAddress)."
        }
    } catch {
        Write-Host "Failed to change MAC address for adapter $($adapter.Name): $_"
        Write-Host "This adapter may not support MAC address changes. Trying next adapter..."
    }
}

if (-not $success) {
    Write-Host "Unable to change MAC address on any adapter. Some drivers (e.g., Intel Wi-Fi) may not support this operation."
    Write-Host "Try updating your network driver or using a different adapter."
    exit 1
}

#
# Troubleshooting:
#
# Find the Correct Adapter Name: If you want to # target a specific adapter, list all adapters:
# powershell
# `Get-NetAdapter`
#
# Look at the Name column (e.g., Ethernet, 
# Wireless LAN, Wi-Fi 2). Update the script to 
# use the exact name:
# powershell
# `$adapter = Get-NetAdapter -Name "WiFi"`
#
# Permission Error: If you get a permissions 
# error, run PowerShell as Administrator:
# Right-click PowerShell, select “Run as 
# Administrator,” then rerun the script.
#
# MAC Format Issue: Some adapters require a 
# dash-separated MAC (XX-XX-XX-XX-XX-XX). If it # fails, change the join:
# powershell
# `$newMac = (1..6 | ForEach-Object 
# { "{0:X2}" -f (Get-Random -Minimum 0 -Maximum # 255) }) -join "-"`
#