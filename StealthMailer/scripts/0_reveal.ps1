$encryptedFile = "$HOME\smtp_pass.xml"
if (-not (Test-Path $encryptedFile)) {
    Write-Host "Encrypted file not found at $encryptedFile."
    exit 1
}
try {
    $secureString = Import-Clixml $encryptedFile
    $decryptedContent = (New-Object System.Management.Automation.PSCredential("placeholder", $secureString)).GetNetworkCredential().Password
    Write-Host "Decrypted content: $decryptedContent"
    exit 0
} catch {
    Write-Host "File does not contain an encrypted SecureString. Raw content:"
    Get-Content $encryptedFile
    exit 1
}
