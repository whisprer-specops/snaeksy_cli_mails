Add-Type -AssemblyName System.Security

# Path to the encrypted script
$encryptedFile = ".\longmail_dynamic_enc.xml"

# Check if the file exists
if (-not (Test-Path $encryptedFile)) {
    Write-Host "Encrypted script not found at $encryptedFile."
    exit 1
}

# Decrypt and execute the script
try {
    $secureScript = Import-Clixml $encryptedFile
    $scriptContent = (New-Object System.Management.Automation.PSCredential("placeholder", $secureScript)).GetNetworkCredential().Password
    Invoke-Expression $scriptContent
    Write-Host "Decrypted and executed script successfully."
} catch {
    Write-Host "Failed to decrypt or execute script: $_"
    exit 1
}