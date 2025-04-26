# Path to the script to obfuscate
$scriptPath = ".\longmail_dynamic.ps1"
$outputPath = ".\longmail_dynamic_enc.xml"

# Check if the input script exists
if (-not (Test-Path $scriptPath)) {
    Write-Host "Script not found at $scriptPath."
    exit 1
}

# Encrypt the script
try {
    $scriptContent = Get-Content $scriptPath | Out-String
    ConvertTo-SecureString -String $scriptContent -AsPlainText -Force | Export-Clixml $outputPath
    Write-Host "Script obfuscated to $outputPath."
    exit 0
} catch {
    Write-Host "Failed to obfuscate script: $_"
    exit 1
}