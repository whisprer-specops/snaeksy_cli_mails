# Path to the script to encrypt
$scriptPath = $PROFILE
$outputPath = ".\profile_enc.xml"

# Check if the input script exists
if (-not (Test-Path $scriptPath)) {
    Write-Host "Script not found at $scriptPath."
    exit 1
}

# Encrypt the script
try {
    $scriptContent = Get-Content $scriptPath | Out-String
    ConvertTo-SecureString -String $scriptContent -AsPlainText -Force | Export-Clixml $outputPath
    Write-Host "Script encrypted to $outputPath."
    exit 0
} catch {
    Write-Host "Failed to encrypt script: $_"
    exit 1
}