Add-Type -AssemblyName System.Security
$encryptedFile = ".\longmail_dynamic_enc.xml"
if (-not (Test-Path $encryptedFile)) {
    Write-Host "Encrypted script not found at $encryptedFile."
    exit 1
}
try {
    $secureScript = Import-Clixml $encryptedFile
    $scriptContent = (New-Object System.Management.Automation.PSCredential("placeholder", $secureScript)).GetNetworkCredential().Password
    Invoke-Expression $scriptContent
    Write-Host "Decrypted and executed script successfully."
    exit 0
} catch {
    Write-Host "Failed to decrypt or execute script: $_"
    exit 1
}