# Path to the encrypted file (e.g., smtp_pass.xml)
$encryptedFile = "$HOME\smtp_pass.xml"

# Check if the file exists
if (-not (Test-Path $encryptedFile)) {
    Write-Host "Encrypted file not found at $encryptedFile."
    exit 1
}

# Read the file content
try {
    # Attempt to import as a SecureString (encrypted via Export-Clixml)
    $secureString = Import-Clixml $encryptedFile
    # If successful, decrypt it
    $decryptedContent = (New-Object System.Management.Automation.PSCredential("placeholder", $secureString)).GetNetworkCredential().Password
    Write-Host "Decrypted content: $decryptedContent"
} catch {
    # If it fails to import as a SecureString, assume it's not encrypted
    Write-Host "File does not contain an encrypted SecureString. Raw content:"
    Get-Content $encryptedFile
}